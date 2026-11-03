import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/app_database.dart' show Category;
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/lending_repository.dart';
import 'parsing.dart';
import 'tool_outcome.dart';

/// Answers the user's questions. The model never does arithmetic: every
/// figure comes back already summed and formatted.
class QueryEngine {
  QueryEngine({
    required this.expenses,
    required this.categories,
    required this.budgets,
    required this.lending,
    required this.today,
  });

  final ExpenseRepository expenses;
  final CategoryRepository categories;
  final BudgetRepository budgets;
  final LendingRepository lending;

  /// Today's date in IST ('YYYY-MM-DD').
  final String Function() today;

  static int _int(dynamic v, int def, int max) {
    final n = v is num ? v.toInt() : int.tryParse('$v');
    if (n == null || n < 1) return def;
    return n > max ? max : n;
  }

  Future<String> _categoryNames() async =>
      (await categories.active()).map((c) => c.name).join(', ');

  Future<ToolOutcome> spending(Map<String, dynamic> a) async {
    final metric = cleanText(a['metric'])?.toLowerCase();
    if (metric == null) return const ToolError('metric is required');
    final from = parseIsoDate(a['date_from']);
    final to = parseIsoDate(a['date_to']);
    if (from == null || to == null) {
      return const ToolError('date_from and date_to must be YYYY-MM-DD');
    }
    if (from.compareTo(to) > 0) return const ToolError('date_from is after date_to');

    int? catId;
    String? catName;
    final catRaw = cleanText(a['category']);
    if (catRaw != null) {
      final c = await categories.resolve(catRaw);
      if (c == null) {
        return ToolError("Unknown category '$catRaw'. Categories: ${await _categoryNames()}");
      }
      catId = c.id;
      catName = c.name;
    }
    final period = {'from': from, 'to': to, 'category': ?catName};

    switch (metric) {
      case 'total':
        final total = await expenses.total(from, to, categoryId: catId);
        final n = await expenses.count(from, to, categoryId: catId);
        return ReadResult({
          ...period,
          'total_text': formatINR(total),
          'total_rupees': paiseToRupees(total),
          'expense_count': n,
        });

      case 'count':
        return ReadResult(
            {...period, 'expense_count': await expenses.count(from, to, categoryId: catId)});

      case 'by_category':
      case 'top_categories':
        final sums = await expenses.sumByCategory(from, to);
        final all = {for (final c in await categories.active()) c.id: c.name};
        for (final c in await _archived()) {
          all[c.id] = c.name;
        }
        final total = sums.values.fold<int>(0, (a, b) => a + b);
        final rows = sums.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
        final limit = metric == 'top_categories' ? _int(a['limit'], 3, 10) : rows.length;
        return ReadResult({
          'from': from,
          'to': to,
          'total_text': formatINR(total),
          'categories': [
            for (final e in rows.take(limit))
              {
                'category': all[e.key] ?? 'Unknown',
                'total_text': formatINR(e.value),
                'share_percent': total == 0 ? 0 : (e.value * 100 / total).round(),
              }
          ],
        });

      case 'by_day':
        final days = await expenses.sumByDay(from, to, categoryId: catId);
        final rows = days.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
        final limit = _int(a['limit'], 5, 10);
        final total = days.values.fold<int>(0, (a, b) => a + b);
        return ReadResult({
          ...period,
          'days_with_spending': days.length,
          'total_text': formatINR(total),
          'highest_days': [
            for (final e in rows.take(limit))
              {'date': e.key, 'weekday': weekdayName(e.key), 'total_text': formatINR(e.value)}
          ],
        });

      case 'by_payment_method':
        return ReadResult({
          ...period,
          'by_payment_method': _grouped(await expenses.sumByPayment(from, to, categoryId: catId)),
        });

      case 'by_location':
        return ReadResult({
          ...period,
          'by_location': _grouped(
              await expenses.sumByLocation(from, to, categoryId: catId),
              limit: _int(a['limit'], 5, 10)),
        });

      case 'list':
        final rows = await expenses.find(ExpenseFilter(
          dateFrom: from,
          dateTo: to,
          categoryIds: catId == null ? const [] : [catId],
          latestOnly: true,
          limit: _int(a['limit'], 5, 10),
        ));
        return ReadResult({
          ...period,
          'expenses': [for (final r in rows) expenseJson(r)],
        });

      case 'budget_status':
        final month = monthRange(from);
        final list = await budgets.all();
        final names = {for (final c in await categories.active()) c.id: c.name};
        final out = <Map<String, dynamic>>[];
        for (final b in list) {
          final used = await expenses.total(month.from, month.to, categoryId: b.categoryId);
          final pct = (used * 100 / b.monthlyLimitPaise).round();
          final left = b.monthlyLimitPaise - used;
          out.add({
            'budget': b.categoryId == null ? 'Overall' : (names[b.categoryId] ?? 'Unknown'),
            'used_text': formatINR(used),
            'limit_text': formatINR(b.monthlyLimitPaise),
            'percent_used': pct,
            'status': left < 0 ? 'over' : (pct >= 80 ? 'near limit' : 'on track'),
            if (left >= 0) 'left_text': formatINR(left) else 'over_by_text': formatINR(-left),
          });
        }
        return ReadResult({
          'month': monthName(month.from),
          'budgets': out,
          if (out.isEmpty) 'note': 'No budgets are set.',
        });

      default:
        return ToolError('Unknown metric "$metric"');
    }
  }

  Future<List<Category>> _archived() async =>
      (await categories.watchAll().first).where((c) => c.isArchived).toList();

  List<Map<String, dynamic>> _grouped(Map<String, int> sums, {int? limit}) {
    final rows = sums.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
    final total = sums.values.fold<int>(0, (a, b) => a + b);
    return [
      for (final e in (limit == null ? rows : rows.take(limit)))
        {
          'name': e.key,
          'total_text': formatINR(e.value),
          'share_percent': total == 0 ? 0 : (e.value * 100 / total).round(),
        }
    ];
  }

  Future<ToolOutcome> lendingQuery(Map<String, dynamic> a) async {
    final metric = cleanText(a['metric'])?.toLowerCase();
    final personRaw = cleanText(a['person'], maxLength: 60);

    if (metric == 'balances') {
      final totals = await lending.totals();
      var balances = await lending.balances();
      if (personRaw != null) {
        final keys = (await lending.candidatePeople(personRaw)).map((p) => p.id).toSet();
        balances = balances.where((b) => keys.contains(b.person.id)).toList();
      }
      return ReadResult({
        'you_will_get_text': formatINR(totals.getPaise),
        'you_owe_text': formatINR(totals.owePaise),
        'people': [
          for (final b in balances)
            {
              'person': b.person.name,
              'status': b.settled
                  ? 'settled'
                  : (b.netPaise >= 0 ? 'owes you' : 'you owe them'),
              if (!b.settled) 'amount_text': formatINR(b.netPaise.abs()),
              'open_loans': b.openLoans,
            }
        ],
        if (balances.isEmpty) 'note': 'No lending records found.',
      });
    }

    if (metric == 'person_history') {
      if (personRaw == null) return const ToolError('person is required for person_history');
      final people = await lending.candidatePeople(personRaw);
      if (people.isEmpty) {
        return ReadResult({'note': 'No person named "$personRaw".', 'events': <dynamic>[]});
      }
      final events = <Map<String, dynamic>>[];
      for (final p in people) {
        for (final e in await lending.history(p.id)) {
          events.add({
            'person': p.name,
            'date': e.date,
            'type': e.isRepayment ? 'repayment' : e.direction,
            'amount_text': formatINR(e.amountPaise),
            if (e.note != null) 'note': e.note,
          });
        }
      }
      return ReadResult({'events': events});
    }
    return ToolError('Unknown metric "$metric"');
  }

  static Map<String, dynamic> expenseJson(ExpenseRow r) => {
        'id': r.expense.id,
        'item': r.expense.item,
        'amount_text': formatINR(r.expense.amountPaise),
        'amount_rupees': paiseToRupees(r.expense.amountPaise),
        'category': r.category.name,
        'date': r.expense.spentOn,
        if (r.expense.location != null) 'location': r.expense.location,
        if (r.expense.paymentMethod != null) 'payment': r.expense.paymentMethod,
      };
}
