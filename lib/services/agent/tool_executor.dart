import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/lending_repository.dart';
import 'parsing.dart';
import 'proposals.dart';
import 'query_engine.dart';
import 'tool_outcome.dart';

/// Limits that guard against a mis-read amount.
const double kMaxRupees = 1000000; // refuse above ₹10,00,000
const double kWarnRupees = 100000; // warn above ₹1,00,000
const double kMaxBudgetRupees = 100000000;

/// Runs the AI's tool calls. Lookups return data; proposals return a card.
/// Nothing here writes to the database.
class ToolExecutor {
  ToolExecutor({
    required this.expenses,
    required this.categories,
    required this.budgets,
    required this.lending,
    required this.today,
  }) : _queries = QueryEngine(
          expenses: expenses,
          categories: categories,
          budgets: budgets,
          lending: lending,
          today: today,
        );

  final ExpenseRepository expenses;
  final CategoryRepository categories;
  final BudgetRepository budgets;
  final LendingRepository lending;
  final String Function() today;
  final QueryEngine _queries;

  Future<ToolOutcome> run(
    String name,
    Map<String, dynamic> args, {
    String? rawText,
    String source = 'chat',
  }) async {
    try {
      return switch (name) {
        'find_expenses' => await _findExpenses(args),
        'find_loans' => await _findLoans(args),
        'query_spending' => await _queries.spending(args),
        'query_lending' => await _queries.lendingQuery(args),
        'propose_add_expense' => await _addExpense(args, rawText, source),
        'propose_update_expense' => await _updateExpense(args),
        'propose_delete_expense' => await _deleteExpense(args),
        'propose_set_budget' => await _setBudget(args),
        'propose_loan' => await _loan(args, rawText),
        'propose_repayment' => await _repayment(args, rawText),
        'ask_user_to_pick' => await _pick(args, rawText),
        _ => ToolError('Unknown tool "$name"'),
      };
    } on LendingException catch (e) {
      return ToolError(e.message);
    }
  }

  // ---- shared checks ------------------------------------------------------

  static int? _id(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}'.replaceAll('#', '').trim());
  }

  /// Validates an amount. Returns (paise, warnings) or an error message.
  ({int? paise, List<String> warnings, String? error}) _amount(dynamic v) {
    final r = parseRupees(v);
    if (r == null) return (paise: null, warnings: const [], error: 'amount_rupees must be a number');
    if (r <= 0) return (paise: null, warnings: const [], error: 'amount_rupees must be more than 0');
    if (r > kMaxRupees) {
      return (
        paise: null,
        warnings: const [],
        error: 'amount is above ₹10,00,000; ask the user to confirm the amount'
      );
    }
    final paise = rupeesToPaise(r);
    if (paise <= 0) return (paise: null, warnings: const [], error: 'amount_rupees is too small');
    return (paise: paise, warnings: [if (r > kWarnRupees) 'large_amount'], error: null);
  }

  /// A date that defaults to today, is clamped if in the future, and rejected
  /// if malformed or absurdly old. Returns (date, warnings) or an error.
  ({String? date, List<String> warnings, String? error}) _date(dynamic v, String field) {
    final t = today();
    if (cleanText(v) == null) return (date: t, warnings: const [], error: null);
    final d = parseIsoDate(v);
    if (d == null) return (date: null, warnings: const [], error: '$field must be YYYY-MM-DD');
    if (d.compareTo('2000-01-01') < 0) {
      return (date: null, warnings: const [], error: '$field is too far in the past');
    }
    if (d.compareTo(t) > 0) return (date: t, warnings: const ['future_date'], error: null);
    return (date: d, warnings: const [], error: null);
  }

  Future<String> _categoryNames() async =>
      (await categories.active()).map((c) => c.name).join(', ');

  // ---- lookups --------------------------------------------------------------

  Future<ToolOutcome> _findExpenses(Map<String, dynamic> a) async {
    int? catId;
    final catRaw = cleanText(a['category']);
    if (catRaw != null) {
      final c = await categories.resolve(catRaw);
      if (c == null) {
        return ToolError("Unknown category '$catRaw'. Categories: ${await _categoryNames()}");
      }
      catId = c.id;
    }
    final from = a['date_from'] == null ? null : parseIsoDate(a['date_from']);
    final to = a['date_to'] == null ? null : parseIsoDate(a['date_to']);
    if (cleanText(a['date_from']) != null && from == null) {
      return const ToolError('date_from must be YYYY-MM-DD');
    }
    if (cleanText(a['date_to']) != null && to == null) {
      return const ToolError('date_to must be YYYY-MM-DD');
    }
    final near = cleanText(a['near_date']) == null ? null : parseIsoDate(a['near_date']);
    int? paise;
    final amountRaw = a['amount_rupees'];
    if (amountRaw != null) {
      final r = parseRupees(amountRaw);
      if (r != null && r > 0) paise = rupeesToPaise(r);
    }
    final limit = (_id(a['limit']) ?? 5).clamp(1, 5);
    final rows = await expenses.find(ExpenseFilter(
      text: cleanText(a['text'], maxLength: 100),
      categoryIds: catId == null ? const [] : [catId],
      dateFrom: from,
      dateTo: to,
      amountPaise: paise,
      latestOnly: parseBool(a['latest_only']) ?? false,
      nearDate: near,
      limit: limit,
    ));
    return ReadResult({
      'count': rows.length,
      'matches': [for (final r in rows) QueryEngine.expenseJson(r)],
      if (rows.isEmpty) 'note': 'No matching expenses.',
    });
  }

  Future<ToolOutcome> _findLoans(Map<String, dynamic> a) async {
    final personRaw = cleanText(a['person'], maxLength: 60);
    final dir = cleanText(a['direction'])?.toLowerCase();
    if (dir != null && dir != 'lent' && dir != 'borrowed') {
      return const ToolError('direction must be lent or borrowed');
    }
    final openOnly = parseBool(a['open_only']) ?? true;
    Set<int>? people;
    if (personRaw != null) {
      people = (await lending.candidatePeople(personRaw)).map((p) => p.id).toSet();
      if (people.isEmpty) {
        return ReadResult({'loans': <dynamic>[], 'note': 'No person named "$personRaw".'});
      }
    }
    var views = await lending.loanViews(direction: dir, openOnly: openOnly);
    if (people != null) views = views.where((v) => people!.contains(v.person.id)).toList();
    // oldest first, so "apply to the oldest loan" is simply the first one
    views = views.reversed.toList();
    return ReadResult({
      'loans': [
        for (final v in views.take(10))
          {
            'loan_id': v.loan.id,
            'person': v.person.name,
            'direction': v.loan.direction,
            'principal_text': formatINR(v.loan.principalPaise),
            'outstanding_text': formatINR(v.outstandingPaise),
            'outstanding_rupees': paiseToRupees(v.outstandingPaise),
            'date': v.loan.happenedOn,
            if (v.loan.note != null) 'note': v.loan.note,
          }
      ],
      if (views.isEmpty) 'note': 'No matching loans.',
    });
  }

  // ---- proposals ------------------------------------------------------------

  Future<ToolOutcome> _addExpense(
      Map<String, dynamic> a, String? rawText, String source) async {
    final amt = _amount(a['amount_rupees']);
    if (amt.error != null) return ToolError(amt.error!);
    final item = cleanText(a['item'], maxLength: 60);
    if (item == null) return const ToolError('item is required');
    final date = _date(a['spent_on'], 'spent_on');
    if (date.error != null) return ToolError(date.error!);

    final catRaw = cleanText(a['category'], maxLength: 60);
    if (catRaw == null) return const ToolError('category is required');
    final isNew = parseBool(a['is_new_category']) ?? false;
    final existing = await categories.resolve(catRaw);

    String catName;
    int? catId;
    var makeNew = false;
    if (existing != null) {
      catName = existing.name;
      catId = existing.id;
    } else if (isNew) {
      catName = CategoryRepository.normalize(catRaw);
      if (catName.length > 40) return const ToolError('category name is too long; use a short name');
      makeNew = true;
    } else {
      return ToolError(
          "Category '$catRaw' does not exist. Choose one of: ${await _categoryNames()}. "
          'Only if none fit, set is_new_category=true with a short general name.');
    }

    return ProposalResult(AddExpenseProposal(
      amountPaise: amt.paise!,
      item: tidyItem(item),
      categoryName: catName,
      categoryId: catId,
      isNewCategory: makeNew,
      location: cleanText(a['location'], maxLength: 60),
      paymentMethod: normalizePayment(a['payment_method']),
      spentOn: date.date!,
      rawText: rawText,
      source: source,
      warnings: [...amt.warnings, ...date.warnings],
    ));
  }

  Future<ToolOutcome> _updateExpense(Map<String, dynamic> a) async {
    final id = _id(a['expense_id']);
    if (id == null) return const ToolError('expense_id is required');
    final row = await expenses.getById(id);
    if (row == null) return ToolError('No expense with id $id. Use find_expenses first.');
    final e = row.expense;

    final changes = <String, dynamic>{};
    if (a['amount_rupees'] != null) {
      final amt = _amount(a['amount_rupees']);
      if (amt.error != null) return ToolError(amt.error!);
      if (amt.paise != e.amountPaise) changes['amountPaise'] = amt.paise;
    }
    final item = cleanText(a['item'], maxLength: 60);
    if (item != null && tidyItem(item) != e.item) changes['item'] = tidyItem(item);

    final catRaw = cleanText(a['category'], maxLength: 60);
    if (catRaw != null) {
      final c = await categories.resolve(catRaw);
      if (c == null) {
        return ToolError("Category '$catRaw' does not exist. Choose one of: ${await _categoryNames()}.");
      }
      if (c.id != e.categoryId) {
        changes['categoryId'] = c.id;
        changes['categoryName'] = c.name;
      }
    }
    final loc = cleanText(a['location'], maxLength: 60);
    if (loc != null && loc != e.location) changes['location'] = loc;
    if (a['payment_method'] != null && cleanText(a['payment_method']) != null) {
      final p = normalizePayment(a['payment_method']);
      if (p != e.paymentMethod) changes['paymentMethod'] = p;
    }
    if (cleanText(a['spent_on']) != null) {
      final d = _date(a['spent_on'], 'spent_on');
      if (d.error != null) return ToolError(d.error!);
      if (d.date != e.spentOn) changes['spentOn'] = d.date;
    }
    if (changes.isEmpty) {
      return const ToolError('Nothing to change: the values already match, or no changes were given.');
    }
    return ProposalResult(UpdateExpenseProposal(
      expenseId: id,
      before: {
        'item': e.item,
        'amountPaise': e.amountPaise,
        'categoryName': row.category.name,
        'location': e.location,
        'paymentMethod': e.paymentMethod,
        'spentOn': e.spentOn,
      },
      changes: changes,
      updatedAtBefore: e.updatedAt.toIso8601String(),
    ));
  }

  Future<ToolOutcome> _deleteExpense(Map<String, dynamic> a) async {
    final id = _id(a['expense_id']);
    if (id == null) return const ToolError('expense_id is required');
    final row = await expenses.getById(id);
    if (row == null) return ToolError('No expense with id $id. Use find_expenses first.');
    return ProposalResult(DeleteExpenseProposal(
      expenseId: id,
      item: row.expense.item,
      amountPaise: row.expense.amountPaise,
      categoryName: row.category.name,
      spentOn: row.expense.spentOn,
      updatedAtBefore: row.expense.updatedAt.toIso8601String(),
    ));
  }

  Future<ToolOutcome> _setBudget(Map<String, dynamic> a) async {
    final r = parseRupees(a['monthly_limit_rupees']);
    if (r == null || r <= 0) return const ToolError('monthly_limit_rupees must be more than 0');
    if (r > kMaxBudgetRupees) return const ToolError('monthly_limit_rupees is unrealistically large');
    final paise = rupeesToPaise(r);
    if (paise <= 0) return const ToolError('monthly_limit_rupees is too small');

    final catRaw = cleanText(a['category'], maxLength: 60);
    int? catId;
    var name = 'Overall';
    if (catRaw != null && catRaw.toLowerCase() != 'overall' && catRaw.toLowerCase() != 'total') {
      final c = await categories.resolve(catRaw);
      if (c == null) {
        return ToolError("Unknown category '$catRaw'. Categories: ${await _categoryNames()}");
      }
      catId = c.id;
      name = c.name;
    }
    final prev = await budgets.forCategory(catId);
    return ProposalResult(SetBudgetProposal(
      categoryId: catId,
      categoryName: name,
      limitPaise: paise,
      previousLimitPaise: prev?.monthlyLimitPaise,
    ));
  }

  Future<ToolOutcome> _loan(Map<String, dynamic> a, String? rawText,
      {int? forcePersonId, bool forceNew = false}) async {
    final dir = cleanText(a['direction'])?.toLowerCase();
    if (dir != 'lent' && dir != 'borrowed') return const ToolError('direction must be lent or borrowed');
    final person = cleanText(a['person'], maxLength: 60);
    if (person == null) return const ToolError('person is required');
    final amt = _amount(a['amount_rupees']);
    if (amt.error != null) return ToolError(amt.error!);
    final date = _date(a['happened_on'], 'happened_on');
    if (date.error != null) return ToolError(date.error!);

    int? personId = forcePersonId;
    var displayName = LendingRepository.displayName(person);
    if (forcePersonId != null) {
      final p = (await lending.recentPeople(10000)).where((p) => p.id == forcePersonId);
      if (p.isNotEmpty) displayName = p.first.name;
    } else if (!forceNew) {
      final exact = await lending.personByExactName(person);
      if (exact != null) {
        personId = exact.id;
        displayName = exact.name;
      } else {
        final similar = await lending.candidatePeople(person);
        if (similar.isNotEmpty) {
          return ProposalResult(PickProposal(
            kind: 'person',
            then: 'loan',
            items: [
              for (final p in similar)
                PickItem(id: p.id, title: p.name, subtitle: 'Existing person'),
              PickItem(id: -1, title: displayName, subtitle: 'New person'),
            ],
            followUp: {...a, 'raw_text': rawText},
          ));
        }
      }
    }
    return ProposalResult(LoanProposal(
      direction: dir!,
      personName: displayName,
      personId: personId,
      amountPaise: amt.paise!,
      note: cleanText(a['note'], maxLength: 80),
      paymentMethod: normalizePayment(a['payment_method']),
      happenedOn: date.date!,
      rawText: rawText,
      warnings: [...amt.warnings, ...date.warnings],
    ));
  }

  Future<ToolOutcome> _repayment(Map<String, dynamic> a, String? rawText) async {
    final id = _id(a['loan_id']);
    if (id == null) return const ToolError('loan_id is required. Use find_loans first.');
    final view = await lending.loanView(id);
    if (view == null) return ToolError('No loan with id $id. Use find_loans first.');
    if (view.settled) return ToolError('That loan is already fully paid back.');
    final r = parseRupees(a['amount_rupees']);
    if (r == null || r <= 0) return const ToolError('amount_rupees must be more than 0');
    final paise = rupeesToPaise(r);
    if (paise > view.outstandingPaise) {
      return ToolError(
          'Only ${formatINR(view.outstandingPaise)} is outstanding on that loan, '
          'so the repayment cannot be ${formatINR(paise)}.');
    }
    final date = _date(a['paid_on'], 'paid_on');
    if (date.error != null) return ToolError(date.error!);
    return ProposalResult(RepaymentProposal(
      loanId: id,
      personName: view.person.name,
      direction: view.loan.direction,
      amountPaise: paise,
      paidOn: date.date!,
      outstandingBeforePaise: view.outstandingPaise,
      note: view.loan.note,
      rawText: rawText,
    ));
  }

  Future<ToolOutcome> _pick(Map<String, dynamic> a, String? rawText) async {
    final kind = cleanText(a['kind'])?.toLowerCase();
    final then = cleanText(a['then'])?.toLowerCase();
    final ids = <int>[];
    final rawIds = a['ids'];
    if (rawIds is List) {
      for (final v in rawIds) {
        final n = _id(v);
        if (n != null && !ids.contains(n)) ids.add(n);
      }
    }
    if (ids.isEmpty) return const ToolError('ids must list at least one id');
    if (kind != 'expense' && kind != 'loan') return const ToolError('kind must be expense or loan');
    if (!{'update', 'delete', 'repay'}.contains(then)) {
      return const ToolError('then must be update, delete or repay');
    }
    if ((kind == 'expense') != (then != 'repay')) {
      return const ToolError('expenses go with update or delete; loans go with repay');
    }

    final items = <PickItem>[];
    if (kind == 'expense') {
      for (final id in ids.take(5)) {
        final r = await expenses.getById(id);
        if (r == null) continue;
        items.add(PickItem(
          id: id,
          title: r.expense.item,
          subtitle: '${dayLabel(r.expense.spentOn)} · ${r.category.name}'
              '${r.expense.location != null ? ' · ${r.expense.location}' : ''}',
          amountPaise: r.expense.amountPaise,
        ));
      }
    } else {
      for (final id in ids.take(5)) {
        final v = await lending.loanView(id);
        if (v == null || v.settled) continue;
        items.add(PickItem(
          id: id,
          title: v.person.name,
          subtitle: '${v.loan.note ?? (v.lent ? 'Lent' : 'Borrowed')} · ${dayLabel(v.loan.happenedOn)}',
          amountPaise: v.outstandingPaise,
        ));
      }
    }
    if (items.isEmpty) return const ToolError('None of those ids exist. Use find first.');

    final followUp = Map<String, dynamic>.from(a)
      ..remove('kind')
      ..remove('ids')
      ..remove('then');
    if (items.length == 1) {
      return resolvePick(
          PickProposal(kind: kind!, then: then!, items: items, followUp: followUp),
          items.first.id,
          rawText: rawText);
    }
    return ProposalResult(
        PickProposal(kind: kind!, then: then!, items: items, followUp: {...followUp, 'raw_text': rawText}));
  }

  /// Turns the user's choice on a pick card into the real proposal.
  Future<ToolOutcome> resolvePick(PickProposal p, int chosenId, {String? rawText}) {
    final args = Map<String, dynamic>.from(p.followUp);
    final raw = rawText ?? args.remove('raw_text') as String?;
    switch (p.then) {
      case 'update':
        return run('propose_update_expense', {...args, 'expense_id': chosenId});
      case 'delete':
        return run('propose_delete_expense', {'expense_id': chosenId});
      case 'repay':
        return run('propose_repayment', {...args, 'loan_id': chosenId}, rawText: raw);
      case 'loan':
        return _loanFor(args, raw, chosenId);
    }
    return Future.value(ToolError('Unknown pick action "${p.then}"'));
  }

  Future<ToolOutcome> _loanFor(Map<String, dynamic> args, String? raw, int chosenId) {
    return chosenId < 0
        ? _loan(args, raw, forceNew: true)
        : _loan(args, raw, forcePersonId: chosenId);
  }
}

/// A convenience for building an update from a form (the Edit sheet).
Map<String, dynamic> updateChangesFromForm({
  required Map<String, dynamic> before,
  int? amountPaise,
  String? item,
  int? categoryId,
  String? categoryName,
  String? location,
  String? paymentMethod,
  String? spentOn,
}) {
  final c = <String, dynamic>{};
  if (amountPaise != null && amountPaise != before['amountPaise']) c['amountPaise'] = amountPaise;
  if (item != null && item != before['item']) c['item'] = item;
  if (categoryId != null && categoryName != before['categoryName']) {
    c['categoryId'] = categoryId;
    c['categoryName'] = categoryName;
  }
  if (location != before['location']) c['location'] = location;
  if (paymentMethod != before['paymentMethod']) c['paymentMethod'] = paymentMethod;
  if (spentOn != null && spentOn != before['spentOn']) c['spentOn'] = spentOn;
  return c;
}
