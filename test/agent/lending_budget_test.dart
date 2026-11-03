import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/db/app_database.dart';
import 'package:kharchu/data/repositories/lending_repository.dart';
import 'package:kharchu/services/agent/proposals.dart';
import 'package:kharchu/services/card_actions.dart';

import 'agent_env.dart';
import 'edit_delete_test.dart' show cardFor, dataOf, errorOf, proposalOf;

void main() {
  late AgentEnv t;
  setUp(() => t = AgentEnv());
  tearDown(() => t.close());

  Map<String, dynamic> loanArgs({
    String dir = 'lent',
    String person = 'Rahul',
    Object amount = 2000,
    String? note = 'Goa trip',
    Object? pay,
    Object? date = kToday,
  }) =>
      {
        'direction': dir,
        'person': person,
        'amount_rupees': amount,
        'note': note,
        'payment_method': pay,
        'happened_on': date,
      }..removeWhere((k, v) => v == null);

  Future<int> makeLoan(String who, int paise,
      {String dir = 'lent', String date = '2026-10-10', String? note}) async {
    final p = await t.env.lending.findOrCreatePerson(who);
    return t.env.lending
        .addLoan(personId: p.id, direction: dir, principalPaise: paise, happenedOn: date, note: note);
  }

  group('propose_loan', () {
    test('lent to a new person', () async {
      final p = proposalOf(await t.executor.run('propose_loan', loanArgs(pay: 'gpay'),
          rawText: 'lent 2000 to Rahul')) as LoanProposal;
      expect(p.lent, isTrue);
      expect(p.personName, 'Rahul');
      expect(p.isNewPerson, isTrue);
      expect(p.amountPaise, 200000);
      expect(p.note, 'Goa trip');
      expect(p.paymentMethod, 'upi');
      expect(p.summary, 'Lent ₹2,000 to Rahul');
    });

    test('borrowed reads the other way round', () async {
      final p = proposalOf(await t.executor.run('propose_loan', loanArgs(dir: 'borrowed', person: 'Priya')))
          as LoanProposal;
      expect(p.lent, isFalse);
      expect(p.summary, 'Borrowed ₹2,000 from Priya');
    });

    test('a lowercase name is tidied; an existing person is matched in any case', () async {
      await t.env.lending.findOrCreatePerson('Rahul');
      final a = proposalOf(await t.executor.run('propose_loan', loanArgs(person: 'rahul'))) as LoanProposal;
      expect(a.isNewPerson, isFalse);
      expect(a.personName, 'Rahul');
      final b = proposalOf(await t.executor.run('propose_loan', loanArgs(person: 'anil kumar'))) as LoanProposal;
      expect(b.personName, 'Anil Kumar');
    });

    test('a similar existing name asks which person was meant', () async {
      await t.env.lending.findOrCreatePerson('Rahul');
      final p = proposalOf(await t.executor.run('propose_loan', loanArgs(person: 'Rahul Kumar')))
          as PickProposal;
      expect(p.kind, 'person');
      expect(p.items.map((i) => i.title), ['Rahul', 'Rahul Kumar']);
      expect(p.items.last.id, -1);
    });

    test('choosing the existing person, or a new one', () async {
      final rahul = await t.env.lending.findOrCreatePerson('Rahul');
      final pick = proposalOf(await t.executor.run('propose_loan', loanArgs(person: 'Rahul Kumar')));

      final c1 = await cardFor(t, pick);
      expect(await t.actions.choose(c1, rahul.id), isNull);
      final existing = Proposal.fromJson(
          jsonDecode((await t.env.chat.messagesForDay(kToday)).last.cardPayload!) as Map<String, dynamic>)
          as LoanProposal;
      expect(existing.personId, rahul.id);
      expect(existing.personName, 'Rahul');

      final c2 = await cardFor(t, pick);
      expect(await t.actions.choose(c2, -1), isNull);
      final fresh = Proposal.fromJson(
          jsonDecode((await t.env.chat.messagesForDay(kToday)).last.cardPayload!) as Map<String, dynamic>)
          as LoanProposal;
      expect(fresh.isNewPerson, isTrue);
      expect(fresh.personName, 'Rahul Kumar');
    });

    test('rejects a bad direction, person, amount or date', () async {
      expect(errorOf(await t.executor.run('propose_loan', loanArgs(dir: 'gave'))), contains('lent or borrowed'));
      expect(errorOf(await t.executor.run('propose_loan', loanArgs(person: '  '))), contains('person is required'));
      expect(errorOf(await t.executor.run('propose_loan', loanArgs(amount: 0))), contains('more than 0'));
      expect(errorOf(await t.executor.run('propose_loan', loanArgs(amount: 'x'))), contains('number'));
      expect(errorOf(await t.executor.run('propose_loan', loanArgs(date: 'soon'))), contains('YYYY-MM-DD'));
    });

    test('a missing date is today and a future one is clamped', () async {
      expect((proposalOf(await t.executor.run('propose_loan', loanArgs(date: null))) as LoanProposal).happenedOn,
          kToday);
      final f = proposalOf(await t.executor.run('propose_loan', loanArgs(date: '2027-05-05'))) as LoanProposal;
      expect(f.happenedOn, kToday);
      expect(f.warnings, contains('future_date'));
    });

    test('confirming creates the person and the loan; a second loan reuses the person', () async {
      final c1 = await cardFor(t, proposalOf(await t.executor.run('propose_loan', loanArgs())));
      expect(await t.actions.confirm(c1), isA<Committed>());
      final c2 = await cardFor(t, proposalOf(await t.executor.run('propose_loan', loanArgs(amount: 500))));
      await t.actions.confirm(c2);
      expect(await t.env.db.select(t.env.db.people).get(), hasLength(1));
      expect((await t.env.lending.loanViews()).length, 2);
      expect((await t.env.lending.totals()).getPaise, 250000);
    });

    test('a lent loan is not an expense and does not touch spending', () async {
      final c = await cardFor(t, proposalOf(await t.executor.run('propose_loan', loanArgs(amount: 50000))));
      await t.actions.confirm(c);
      expect(await t.env.expenses.total('2026-10-01', '2026-10-31'), 0);
    });
  });

  group('find_loans and repayments', () {
    test('lists open loans oldest first, with outstanding amounts', () async {
      await makeLoan('Rahul', 200000, date: '2026-10-20', note: 'Goa');
      final older = await makeLoan('Rahul', 100000, date: '2026-10-01', note: 'Lunch');
      await t.env.lending.addRepayment(loanId: older, amountPaise: 40000, paidOn: '2026-10-05');
      final d = dataOf(await t.executor.run('find_loans', {'person': 'Rahul'}));
      final loans = (d['loans'] as List).cast<Map>();
      expect(loans.first['note'], 'Lunch');
      expect(loans.first['outstanding_text'], '₹600');
      expect(loans.last['note'], 'Goa');
    });

    test('settled loans are hidden unless asked for', () async {
      final id = await makeLoan('Anil', 80000);
      await t.env.lending.addRepayment(loanId: id, amountPaise: 80000, paidOn: '2026-10-12');
      expect((dataOf(await t.executor.run('find_loans', {}))['loans'] as List), isEmpty);
      expect((dataOf(await t.executor.run('find_loans', {'open_only': false}))['loans'] as List).length, 1);
    });

    test('filters by direction; unknown person and bad direction are explained', () async {
      await makeLoan('Rahul', 1000);
      await makeLoan('Priya', 2000, dir: 'borrowed');
      expect((dataOf(await t.executor.run('find_loans', {'direction': 'borrowed'}))['loans'] as List).length, 1);
      expect(dataOf(await t.executor.run('find_loans', {'person': 'Zed'}))['note'], contains('No person'));
      expect(errorOf(await t.executor.run('find_loans', {'direction': 'sideways'})), contains('lent or borrowed'));
    });

    test('a partial repayment shows the balance before and after', () async {
      final id = await makeLoan('Rahul', 200000);
      final p = proposalOf(await t.executor.run(
          'propose_repayment', {'loan_id': id, 'amount_rupees': 1000, 'paid_on': kToday})) as RepaymentProposal;
      expect(p.outstandingBeforePaise, 200000);
      expect(p.outstandingAfterPaise, 100000);
      expect(p.summary, 'Rahul paid back ₹1,000');
    });

    test('paying someone back reads differently from being paid back', () async {
      final id = await makeLoan('Priya', 150000, dir: 'borrowed');
      final p = proposalOf(await t.executor.run(
          'propose_repayment', {'loan_id': id, 'amount_rupees': 500, 'paid_on': kToday})) as RepaymentProposal;
      expect(p.summary, 'Paid back Priya ₹500');
    });

    test('more than outstanding is refused with the real balance', () async {
      final id = await makeLoan('Rahul', 200000);
      final msg = errorOf(await t.executor
          .run('propose_repayment', {'loan_id': id, 'amount_rupees': 2500, 'paid_on': kToday}));
      expect(msg, contains('₹2,000'));
      expect(msg, contains('cannot be ₹2,500'));
    });

    test('settled, unknown, zero and missing-id repayments are refused', () async {
      final id = await makeLoan('Rahul', 100000);
      await t.env.lending.addRepayment(loanId: id, amountPaise: 100000, paidOn: '2026-10-12');
      expect(errorOf(await t.executor.run('propose_repayment', {'loan_id': id, 'amount_rupees': 1, 'paid_on': kToday})),
          contains('already fully paid'));
      expect(errorOf(await t.executor.run('propose_repayment', {'loan_id': 77, 'amount_rupees': 1, 'paid_on': kToday})),
          contains('No loan with id 77'));
      final open = await makeLoan('Karthik', 5000);
      expect(errorOf(await t.executor.run('propose_repayment', {'loan_id': open, 'amount_rupees': 0, 'paid_on': kToday})),
          contains('more than 0'));
      expect(errorOf(await t.executor.run('propose_repayment', {'amount_rupees': 5, 'paid_on': kToday})),
          contains('loan_id is required'));
    });

    test('full flow: lend, part pay, pay the rest, and the person becomes settled', () async {
      final id = await makeLoan('Rahul', 200000);
      for (final amount in [1000, 1000]) {
        final p = proposalOf(await t.executor.run(
            'propose_repayment', {'loan_id': id, 'amount_rupees': amount, 'paid_on': kToday}));
        expect(await t.actions.confirm(await cardFor(t, p)), isA<Committed>());
      }
      expect((await t.env.lending.loanView(id))!.settled, isTrue);
      expect((await t.env.lending.totals()).getPaise, 0);
      expect((await t.env.lending.balances()).single.settled, isTrue);
    });

    test('if the balance dropped after the card appeared, an over-large repayment is refused and stays pending',
        () async {
      final id = await makeLoan('Rahul', 200000);
      final p = proposalOf(await t.executor
          .run('propose_repayment', {'loan_id': id, 'amount_rupees': 1500, 'paid_on': kToday}));
      final card = await cardFor(t, p);
      await t.env.lending.addRepayment(loanId: id, amountPaise: 100000, paidOn: kToday);
      final r = await t.actions.confirm(card);
      expect(r, isA<CommitFailed>());
      expect((r as CommitFailed).message, contains('₹1,000'));
      expect((await t.env.chat.byId(card))!.cardStatus, 'pending');
      expect((await t.env.lending.loanView(id))!.outstandingPaise, 100000);
    });

    test('ask_user_to_pick for repay offers open loans and goes to a repayment card', () async {
      final a = await makeLoan('Rahul', 200000, date: '2026-10-01', note: 'Lunch');
      final b = await makeLoan('Rahul', 100000, date: '2026-10-10', note: 'Goa');
      final pick = proposalOf(await t.executor.run('ask_user_to_pick', {
        'kind': 'loan',
        'ids': [a, b],
        'then': 'repay',
        'amount_rupees': 500,
        'paid_on': kToday,
      })) as PickProposal;
      expect(pick.items.length, 2);
      final card = await cardFor(t, pick);
      expect(await t.actions.choose(card, b), isNull);
      final next = (await t.env.chat.messagesForDay(kToday)).last;
      expect(next.cardType, 'repayment');
    });
  });

  group('budgets', () {
    test('overall and per category', () async {
      final o = proposalOf(await t.executor.run('propose_set_budget', {'monthly_limit_rupees': 25000}))
          as SetBudgetProposal;
      expect(o.categoryId, isNull);
      expect(o.categoryName, 'Overall');
      expect(o.summary, 'Overall budget ₹25,000/month');
      final c = proposalOf(await t.executor
          .run('propose_set_budget', {'category': 'food', 'monthly_limit_rupees': '6k'})) as SetBudgetProposal;
      expect(c.categoryName, 'Food & Dining');
      expect(c.limitPaise, 600000);
    });

    test('the words "overall" and "total" mean the overall budget', () async {
      for (final w in ['overall', 'Total']) {
        final p = proposalOf(await t.executor
            .run('propose_set_budget', {'category': w, 'monthly_limit_rupees': 1000})) as SetBudgetProposal;
        expect(p.categoryId, isNull, reason: w);
      }
    });

    test('shows the previous limit when replacing one', () async {
      await t.env.budgets.upsert(null, 2000000);
      final p = proposalOf(await t.executor.run('propose_set_budget', {'monthly_limit_rupees': 3000}))
          as SetBudgetProposal;
      expect(p.previousLimitPaise, 2000000);
    });

    test('rejects zero, negative, huge and non-numeric limits and unknown categories', () async {
      for (final v in [0, -5, 'abc', 500000000]) {
        expect(errorOf(await t.executor.run('propose_set_budget', {'monthly_limit_rupees': v})), isNotEmpty,
            reason: '$v');
      }
      expect(errorOf(await t.executor.run('propose_set_budget', {'category': 'Yachts', 'monthly_limit_rupees': 5})),
          contains('Unknown category'));
    });

    test('confirming saves it and replaces an older one', () async {
      final c1 = await cardFor(
          t, proposalOf(await t.executor.run('propose_set_budget', {'monthly_limit_rupees': 20000})));
      await t.actions.confirm(c1);
      final c2 = await cardFor(
          t, proposalOf(await t.executor.run('propose_set_budget', {'monthly_limit_rupees': 30000})));
      await t.actions.confirm(c2);
      final all = await t.env.budgets.all();
      expect(all.length, 1);
      expect(all.single.monthlyLimitPaise, 3000000);
    });
  });

  group('budget alerts', () {
    late int food;
    setUp(() async {
      food = await t.category('Food & Dining');
      await t.env.budgets.upsert(food, 600000); // ₹6,000
    });

    Future<CommitResult> spendFood(int rupees, {String date = kToday, String category = 'Food & Dining'}) async {
      final p = AddExpenseProposal(
        amountPaise: rupees * 100,
        item: 'Meal',
        categoryName: category,
        categoryId: await t.category(category),
        spentOn: date,
      );
      return t.actions.confirm(await cardFor(t, p));
    }

    Future<List<ChatMessage>> notices() async =>
        (await t.env.chat.messagesForDay(kToday)).where((m) => m.role == 'notice').toList();

    test('no notice while under 80%', () async {
      await spendFood(4000);
      expect(await notices(), isEmpty);
    });

    test('crossing 80% warns once, with the figures', () async {
      await spendFood(4000);
      await spendFood(880); // 4880 = 81.3%
      final n = await notices();
      expect(n.length, 1);
      expect(n.single.body, startsWith('Food & Dining is at 81% of budget'));
      expect(n.single.body, contains('₹4,880 of ₹6,000'));
      expect(n.single.body, contains('₹1,120 left for 7 days'));
      expect(jsonDecode(n.single.cardPayload!)['level'], 'warn');
    });

    test('a further expense that stays between 80% and 100% does not repeat the warning', () async {
      await spendFood(5000);
      await spendFood(500);
      expect((await notices()).length, 1);
    });

    test('crossing 100% gives a danger notice with the overage', () async {
      await spendFood(5000);
      await spendFood(1200); // 6200
      final n = await notices();
      expect(n.length, 2);
      expect(n.last.body, 'Food & Dining is over budget · ₹6,200 of ₹6,000 · ₹200 over');
      expect(jsonDecode(n.last.cardPayload!)['level'], 'danger');
    });

    test('landing exactly on the budget says it has been reached', () async {
      await spendFood(6000);
      final n = await notices();
      expect(n.single.body, startsWith('Food & Dining has reached its budget'));
    });

    test('jumping from under 80% straight past 100% gives only the danger notice', () async {
      await spendFood(7000);
      final n = await notices();
      expect(n.length, 1);
      expect(jsonDecode(n.single.cardPayload!)['level'], 'danger');
    });

    test('once over, further spending does not repeat the notice', () async {
      await spendFood(7000);
      await spendFood(100);
      expect((await notices()).length, 1);
    });

    test('exactly 80% counts as crossing', () async {
      await spendFood(4800);
      expect((await notices()).single.body, contains('80%'));
    });

    test('other categories and other months do not trigger Food', () async {
      await spendFood(5000, category: 'Transport');
      await spendFood(5500, date: '2026-09-30');
      expect(await notices(), isEmpty);
    });

    test('an overall budget alerts on total spending', () async {
      await t.env.budgets.upsert(null, 1000000); // ₹10,000
      await spendFood(1000, category: 'Transport');
      await spendFood(500, category: 'Shopping');
      expect(await notices(), isEmpty);
      await spendFood(7500, category: 'Health'); // total 9000 = 90%
      final n = await notices();
      expect(n.single.body, startsWith('Overall is at 90% of budget'));
    });

    test('moving an expense into a category can trigger its alert', () async {
      final id = await t.env.addExpense(paise: 550000, category: 'Shopping', date: kToday);
      final p = proposalOf(await t.executor
          .run('propose_update_expense', {'expense_id': id, 'category': 'Food & Dining'}));
      await t.actions.confirm(await cardFor(t, p));
      expect((await notices()).single.body, startsWith('Food & Dining is at 91%'));
    });

    test('editing an amount down, or deleting, never alerts', () async {
      final id = await t.env.addExpense(paise: 500000, category: 'Food & Dining', date: kToday);
      final del = proposalOf(await t.executor.run('propose_delete_expense', {'expense_id': id}));
      await t.actions.confirm(await cardFor(t, del));
      expect(await notices(), isEmpty);
    });

    test('lending never alerts', () async {
      final p = LoanProposal(
          direction: 'lent', personName: 'Rahul', amountPaise: 99999999, happenedOn: kToday);
      await t.actions.confirm(await cardFor(t, p));
      expect(await notices(), isEmpty);
    });

    test('in the last days of the month the wording adapts', () async {
      t.today = '2026-10-31';
      await spendFood(5000, date: '2026-10-31');
      final lastDay = (await t.env.chat.messagesForDay('2026-10-31')).where((m) => m.role == 'notice');
      expect(lastDay.single.body, contains('left today'));

      t.today = '2026-10-30';
      await t.env.budgets.upsert(food, 500000); // now at 100%: the 80% step was passed earlier
      final env2 = await t.env.chat.messagesForDay('2026-10-30');
      expect(env2.where((m) => m.role == 'notice'), isEmpty);
    });

    test('with no budgets nothing is ever raised', () async {
      await t.env.budgets.delete((await t.env.budgets.forCategory(food))!.id);
      await spendFood(9999);
      expect(await notices(), isEmpty);
    });

    test('a notice is not sent to the AI as part of the conversation', () async {
      await spendFood(5000);
      t.say('ok');
      await t.agent.handle('hi');
      final all = t.sentMessages(0).map((m) => '${m['content']}').join('\n');
      expect(all, isNot(contains('of budget')));
    });
  });

  test('LendingRepository exceptions have readable messages', () {
    expect(RepaymentExceedsOutstanding(100).message, contains('more than'));
  });
}
