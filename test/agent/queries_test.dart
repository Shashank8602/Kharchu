import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/services/agent/tool_outcome.dart';

import 'agent_env.dart';
import 'edit_delete_test.dart' show dataOf, errorOf;

void main() {
  late AgentEnv t;
  setUp(() => t = AgentEnv());
  tearDown(() => t.close());

  Future<ToolOutcome> spend(Map<String, dynamic> a) =>
      t.executor.run('query_spending', {'date_from': '2026-10-01', 'date_to': '2026-10-31', ...a});

  Future<void> seed() async {
    await t.env.addExpense(paise: 100000, item: 'Chats', date: '2026-10-24', payment: 'upi', location: 'BLR');
    await t.env.addExpense(paise: 412000, item: 'Dinner', date: '2026-10-13', payment: 'card', location: 'BLR');
    await t.env.addExpense(paise: 105000, item: 'Petrol', category: 'Transport', date: '2026-10-22', payment: 'upi');
    await t.env.addExpense(paise: 24000, item: 'Auto', category: 'Transport', date: '2026-10-24');
    await t.env.addExpense(paise: 900000, item: 'Laptop bag', category: 'Shopping', date: '2026-09-30');
  }

  group('totals and counts', () {
    test('total for the month, bounded by the dates', () async {
      await seed();
      final d = dataOf(await spend({'metric': 'total'}));
      expect(d['total_text'], '₹6,410'); // 1000 + 4120 + 1050 + 240
      expect(d['expense_count'], 4);
    });

    test('an empty period is zero, not an error', () async {
      final d = dataOf(await spend({'metric': 'total'}));
      expect(d['total_text'], '₹0');
      expect(d['expense_count'], 0);
    });

    test('category filter, with the name resolved from a loose word', () async {
      await seed();
      final d = dataOf(await spend({'metric': 'total', 'category': 'food'}));
      expect(d['category'], 'Food & Dining');
      expect(d['total_text'], '₹5,120');
    });

    test('count', () async {
      await seed();
      expect(dataOf(await spend({'metric': 'count'}))['expense_count'], 4);
      expect(dataOf(await spend({'metric': 'count', 'category': 'Transport'}))['expense_count'], 2);
    });

    test('deleted expenses are not counted', () async {
      await seed();
      await t.env.expenses.softDelete(1);
      expect(dataOf(await spend({'metric': 'total'}))['total_text'], '₹5,410');
    });

    test('a single day range', () async {
      await seed();
      final d = dataOf(await t.executor.run('query_spending',
          {'metric': 'total', 'date_from': '2026-10-24', 'date_to': '2026-10-24'}));
      expect(d['total_text'], '₹1,240');
    });
  });

  group('breakdowns', () {
    test('by category, largest first, with shares that add up', () async {
      await seed();
      final d = dataOf(await spend({'metric': 'by_category'}));
      final cats = (d['categories'] as List).cast<Map>();
      expect(cats.first['category'], 'Food & Dining');
      expect(cats.first['total_text'], '₹5,120');
      expect(cats.first['share_percent'], 80);
      expect(cats.last['category'], 'Transport');
      expect(cats.fold<int>(0, (a, c) => a + (c['share_percent'] as int)), inInclusiveRange(99, 101));
    });

    test('top categories honours the limit and defaults to three', () async {
      await seed();
      await t.env.addExpense(paise: 5000, category: 'Health', date: '2026-10-05');
      await t.env.addExpense(paise: 4000, category: 'Travel', date: '2026-10-06');
      expect(((dataOf(await spend({'metric': 'top_categories'}))['categories']) as List).length, 3);
      expect(((dataOf(await spend({'metric': 'top_categories', 'limit': 1}))['categories']) as List).length, 1);
      expect(((dataOf(await spend({'metric': 'top_categories', 'limit': 99}))['categories']) as List).length, 4);
    });

    test('an archived category still appears under its name', () async {
      await seed();
      await t.env.categories.setArchived(await t.category('Transport'), true);
      final cats = (dataOf(await spend({'metric': 'by_category'}))['categories'] as List).cast<Map>();
      expect(cats.map((c) => c['category']), contains('Transport'));
    });

    test('by day finds the biggest day', () async {
      await seed();
      final d = dataOf(await spend({'metric': 'by_day', 'limit': 2}));
      final days = (d['highest_days'] as List).cast<Map>();
      expect(days.first['date'], '2026-10-13');
      expect(days.first['weekday'], 'Tuesday');
      expect(days.first['total_text'], '₹4,120');
      expect(days.length, 2);
      expect(d['days_with_spending'], 3);
    });

    test('by payment method keeps "unspecified" as its own group', () async {
      await seed();
      final rows = (dataOf(await spend({'metric': 'by_payment_method'}))['by_payment_method'] as List).cast<Map>();
      final byName = {for (final r in rows) r['name']: r['total_text']};
      expect(byName['card'], '₹4,120');
      expect(byName['upi'], '₹2,050');
      expect(byName['unspecified'], '₹240');
    });

    test('by location', () async {
      await seed();
      final rows = (dataOf(await spend({'metric': 'by_location'}))['by_location'] as List).cast<Map>();
      expect(rows.first['name'], 'BLR');
      expect(rows.first['total_text'], '₹5,120');
    });

    test('list is newest first and limited', () async {
      await seed();
      final d = dataOf(await spend({'metric': 'list', 'limit': 2}));
      final items = (d['expenses'] as List).cast<Map>();
      expect(items.length, 2);
      expect(items.first['date'], '2026-10-24');
    });

    test('category filter works on every breakdown', () async {
      await seed();
      final d = dataOf(await spend({'metric': 'by_payment_method', 'category': 'Transport'}));
      final rows = (d['by_payment_method'] as List).cast<Map>();
      expect(rows.map((r) => r['name']).toSet(), {'upi', 'unspecified'});
    });
  });

  group('budget status', () {
    test('on track, near limit and over', () async {
      await seed();
      await t.env.budgets.upsert(await t.category('Food & Dining'), 600000); // 5120/6000 = 85%
      await t.env.budgets.upsert(await t.category('Transport'), 100000); // 1290/1000 = over
      await t.env.budgets.upsert(null, 2500000); // 6410/25000 = 26%
      final rows = (dataOf(await spend({'metric': 'budget_status'}))['budgets'] as List).cast<Map>();
      final byName = {for (final r in rows) r['budget']: r};
      expect(byName['Food & Dining']!['status'], 'near limit');
      expect(byName['Food & Dining']!['percent_used'], 85);
      expect(byName['Food & Dining']!['left_text'], '₹880');
      expect(byName['Transport']!['status'], 'over');
      expect(byName['Transport']!['over_by_text'], '₹290');
      expect(byName['Overall']!['status'], 'on track');
    });

    test('no budgets says so', () async {
      final d = dataOf(await spend({'metric': 'budget_status'}));
      expect(d['note'], contains('No budgets'));
    });
  });

  group('bad requests are explained', () {
    test('missing, unknown or misordered inputs', () async {
      expect(errorOf(await t.executor.run('query_spending', {'date_from': '2026-10-01', 'date_to': '2026-10-31'})),
          contains('metric'));
      expect(errorOf(await spend({'metric': 'vibes'})), contains('Unknown metric'));
      expect(errorOf(await t.executor.run('query_spending', {'metric': 'total'})), contains('YYYY-MM-DD'));
      expect(errorOf(await spend({'metric': 'total', 'date_from': 'last month'})), contains('YYYY-MM-DD'));
      expect(errorOf(await spend({'metric': 'total', 'date_from': '2026-11-01', 'date_to': '2026-10-01'})),
          contains('after'));
      expect(errorOf(await spend({'metric': 'total', 'category': 'Yachts'})), contains('Unknown category'));
    });
  });

  group('lending questions', () {
    Future<void> lend(String who, int paise, {String dir = 'lent', String date = '2026-10-10', String? note}) async {
      final p = await t.env.lending.findOrCreatePerson(who);
      await t.env.lending.addLoan(
          personId: p.id, direction: dir, principalPaise: paise, happenedOn: date, note: note);
    }

    test('balances show who owes whom, and totals', () async {
      await lend('Rahul', 200000);
      await lend('Priya', 100000, dir: 'borrowed');
      final d = dataOf(await t.executor.run('query_lending', {'metric': 'balances'}));
      expect(d['you_will_get_text'], '₹2,000');
      expect(d['you_owe_text'], '₹1,000');
      final people = (d['people'] as List).cast<Map>();
      final rahul = people.firstWhere((p) => p['person'] == 'Rahul');
      expect(rahul['status'], 'owes you');
      expect(rahul['amount_text'], '₹2,000');
      expect(people.firstWhere((p) => p['person'] == 'Priya')['status'], 'you owe them');
    });

    test('a settled person is reported as settled, not as zero owed', () async {
      await lend('Anil', 80000);
      await t.env.lending.addRepayment(loanId: 1, amountPaise: 80000, paidOn: '2026-10-12');
      final d = dataOf(await t.executor.run('query_lending', {'metric': 'balances'}));
      final anil = (d['people'] as List).cast<Map>().single;
      expect(anil['status'], 'settled');
      expect(anil.containsKey('amount_text'), isFalse);
    });

    test('filtering by one person, and an unknown person', () async {
      await lend('Rahul', 200000);
      await lend('Priya', 100000);
      final d = dataOf(await t.executor.run('query_lending', {'metric': 'balances', 'person': 'rahul'}));
      expect((d['people'] as List).length, 1);
      final none = dataOf(await t.executor.run('query_lending', {'metric': 'balances', 'person': 'Zed'}));
      expect(none['note'], contains('No lending records'));
    });

    test('nothing lent at all', () async {
      final d = dataOf(await t.executor.run('query_lending', {'metric': 'balances'}));
      expect(d['note'], contains('No lending records'));
      expect(d['you_will_get_text'], '₹0');
    });

    test('person history lists loans and repayments in order', () async {
      await lend('Karthik', 250000, date: '2026-10-10', note: 'Laptop repair');
      await t.env.lending.addRepayment(loanId: 1, amountPaise: 100000, paidOn: '2026-10-15');
      final d = dataOf(await t.executor.run('query_lending', {'metric': 'person_history', 'person': 'Karthik'}));
      final ev = (d['events'] as List).cast<Map>();
      expect(ev.map((e) => e['type']), ['lent', 'repayment']);
      expect(ev.first['note'], 'Laptop repair');
      expect(ev.last['amount_text'], '₹1,000');
    });

    test('person history needs a person, and an unknown name is not an error', () async {
      expect(errorOf(await t.executor.run('query_lending', {'metric': 'person_history'})), contains('person'));
      final d = dataOf(await t.executor.run('query_lending', {'metric': 'person_history', 'person': 'Nobody'}));
      expect(d['events'], isEmpty);
      expect(errorOf(await t.executor.run('query_lending', {'metric': 'x'})), contains('Unknown metric'));
    });

    test('lending is never counted as spending', () async {
      await lend('Rahul', 5000000);
      await t.env.addExpense(paise: 1000, date: '2026-10-24');
      expect(dataOf(await spend({'metric': 'total'}))['total_text'], '₹10');
    });
  });
}
