import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/db/app_database.dart';
import 'package:kharchu/data/repositories/expense_repository.dart';

import 'helpers.dart';

void main() {
  late TestEnv env;
  setUp(() => env = TestEnv());
  tearDown(() => env.close());

  test('seeds ten default categories', () async {
    final list = await env.categories.active();
    expect(list.length, 10);
    expect(list.map((c) => c.name), contains('Food & Dining'));
    expect(list.every((c) => c.isDefault), isTrue);
  });

  test('add then read back with its category', () async {
    final id = await env.addExpense(
        paise: 100000, item: 'Chats', location: 'Bengaluru', payment: 'upi');
    final row = await env.expenses.getById(id);
    expect(row, isNotNull);
    expect(row!.expense.amountPaise, 100000);
    expect(row.expense.item, 'Chats');
    expect(row.expense.location, 'Bengaluru');
    expect(row.category.name, 'Food & Dining');
  });

  test('blank location is stored as null and item is trimmed', () async {
    final id = await env.addExpense(paise: 5000, item: '  Tea  ', location: '   ');
    final e = (await env.expenses.getById(id))!.expense;
    expect(e.location, isNull);
    expect(e.item, 'Tea');
  });

  test('rejects zero and negative amounts at the database', () async {
    await expectLater(env.addExpense(paise: 0), throwsA(anything));
    await expectLater(env.addExpense(paise: -500), throwsA(anything));
    expect(await env.expenses.find(const ExpenseFilter()), isEmpty);
  });

  test('rejects an unknown category (foreign key enforced)', () async {
    await expectLater(
      env.expenses.add(
          amountPaise: 100, categoryId: 9999, item: 'x', spentOn: '2026-10-24'),
      throwsA(anything),
    );
  });

  test('soft delete hides, restore brings back', () async {
    final id = await env.addExpense(paise: 20000);
    await env.expenses.softDelete(id);
    expect(await env.expenses.getById(id), isNull);
    expect(await env.expenses.find(const ExpenseFilter()), isEmpty);
    await env.expenses.restore(id);
    expect(await env.expenses.getById(id), isNotNull);
  });

  test('update changes fields, can clear a field, and rejects deleted rows',
      () async {
    final id = await env.addExpense(
        paise: 120000, item: 'Dinner', location: "Meghana's", payment: 'card');
    expect(
      await env.expenses.update(id, const ExpensesCompanion(amountPaise: Value(145000))),
      isTrue,
    );
    expect((await env.expenses.getById(id))!.expense.amountPaise, 145000);

    await env.expenses.update(id, const ExpensesCompanion(location: Value(null)));
    expect((await env.expenses.getById(id))!.expense.location, isNull);

    await env.expenses.softDelete(id);
    expect(
      await env.expenses.update(id, const ExpensesCompanion(amountPaise: Value(1))),
      isFalse,
    );
    expect(
      await env.expenses.update(777, const ExpensesCompanion(amountPaise: Value(1))),
      isFalse,
    );
  });

  group('find', () {
    setUp(() async {
      await env.addExpense(
          paise: 120000, item: 'Dinner', location: "Meghana's",
          date: '2026-10-18', raw: "dinner at Meghana's 1200");
      await env.addExpense(
          paise: 105000, item: 'Petrol', category: 'Transport',
          location: 'Indiranagar', date: '2026-10-22', payment: 'upi');
      await env.addExpense(
          paise: 90000, item: 'Petrol', category: 'Transport',
          date: '2026-10-19');
      await env.addExpense(
          paise: 34000, item: 'Discount 50% off sale', category: 'Shopping',
          date: '2026-10-20');
      await env.addExpense(
          paise: 1000, item: 'Snack_pack', date: '2026-10-21');
    });

    test('words match in any order and as partial words', () async {
      expect(
          (await env.expenses.find(const ExpenseFilter(text: "meghana dinner"))).length, 1);
      expect(
          (await env.expenses.find(const ExpenseFilter(text: 'pet'))).length, 2);
    });

    test('matches the original message text, not just item and place', () async {
      final r = await env.expenses.find(const ExpenseFilter(text: '1200'));
      expect(r.length, 1);
      expect(r.first.expense.item, 'Dinner');
    });

    test('search is case-insensitive', () async {
      expect((await env.expenses.find(const ExpenseFilter(text: 'PETROL'))).length, 2);
    });

    test('percent and underscore are literal, not wildcards', () async {
      expect((await env.expenses.find(const ExpenseFilter(text: '%'))).length, 1);
      expect((await env.expenses.find(const ExpenseFilter(text: '50%'))).length, 1);
      expect((await env.expenses.find(const ExpenseFilter(text: '_'))).length, 1);
      expect((await env.expenses.find(const ExpenseFilter(text: r'\'))).length, 0);
    });

    test('quotes and SQL fragments in text are harmless', () async {
      expect(
          await env.expenses.find(const ExpenseFilter(text: "'; DROP TABLE expenses; --")),
          isEmpty);
      expect((await env.expenses.find(const ExpenseFilter())).length, 5);
    });

    test('blank or whitespace text means no text filter', () async {
      expect((await env.expenses.find(const ExpenseFilter(text: '   '))).length, 5);
    });

    test('no match returns empty', () async {
      expect(await env.expenses.find(const ExpenseFilter(text: 'zzzz')), isEmpty);
    });

    test('date range is inclusive on both ends', () async {
      final r = await env.expenses.find(
          const ExpenseFilter(dateFrom: '2026-10-19', dateTo: '2026-10-21'));
      expect(r.map((e) => e.expense.spentOn).toSet(),
          {'2026-10-19', '2026-10-20', '2026-10-21'});
    });

    test('latestOnly returns newest date first, ties broken by newest id', () async {
      final id = await env.addExpense(paise: 700, item: 'Later same day', date: '2026-10-22');
      final r = await env.expenses.find(const ExpenseFilter(latestOnly: true, limit: 2));
      expect(r.first.expense.id, id);
      expect(r.length, 2);
    });

    test('nearDate ranks by closeness to the requested day', () async {
      final r = await env.expenses.find(const ExpenseFilter(
          text: 'petrol', nearDate: '2026-10-19', limit: 5));
      expect(r.first.expense.spentOn, '2026-10-19');
      expect(r.last.expense.spentOn, '2026-10-22');
    });

    test('an invalid nearDate is ignored, never interpolated into SQL', () async {
      final r = await env.expenses.find(const ExpenseFilter(
          nearDate: "2026-10-19'); DROP TABLE expenses; --"));
      expect(r.length, 5);
    });

    test('filters by amount, category and payment method', () async {
      expect((await env.expenses.find(const ExpenseFilter(amountPaise: 105000))).length, 1);
      final transport = await env.cat('Transport');
      expect((await env.expenses.find(ExpenseFilter(categoryIds: [transport]))).length, 2);
      expect((await env.expenses.find(const ExpenseFilter(paymentMethods: ['upi']))).length, 1);
    });

    test('limit is respected', () async {
      expect((await env.expenses.find(const ExpenseFilter(limit: 2))).length, 2);
    });

    test('recent returns the newest n', () async {
      final r = await env.expenses.recent(3);
      expect(r.length, 3);
      expect(r.first.expense.spentOn, '2026-10-22');
    });
  });

  group('aggregates', () {
    setUp(() async {
      await env.addExpense(paise: 100000, date: '2026-10-01', payment: 'upi', location: 'BLR');
      await env.addExpense(paise: 50000, date: '2026-10-01', category: 'Transport');
      await env.addExpense(paise: 25000, date: '2026-10-31', category: 'Transport', payment: 'cash');
      await env.addExpense(paise: 999900, date: '2026-09-30'); // previous month
      await env.addExpense(paise: 888800, date: '2026-11-01'); // next month
    });

    test('total is bounded by the range and 0 when empty', () async {
      expect(await env.expenses.total('2026-10-01', '2026-10-31'), 175000);
      expect(await env.expenses.total('2026-01-01', '2026-01-31'), 0);
    });

    test('excludes soft-deleted expenses everywhere', () async {
      final id = await env.addExpense(paise: 40000, date: '2026-10-15');
      expect(await env.expenses.total('2026-10-01', '2026-10-31'), 215000);
      await env.expenses.softDelete(id);
      expect(await env.expenses.total('2026-10-01', '2026-10-31'), 175000);
      expect(await env.expenses.count('2026-10-01', '2026-10-31'), 3);
      final byDay = await env.expenses.sumByDay('2026-10-01', '2026-10-31');
      expect(byDay.containsKey('2026-10-15'), isFalse);
    });

    test('category total', () async {
      final transport = await env.cat('Transport');
      expect(await env.expenses.total('2026-10-01', '2026-10-31', categoryId: transport), 75000);
    });

    test('sum by category and by day', () async {
      final food = await env.cat('Food & Dining');
      final transport = await env.cat('Transport');
      expect(await env.expenses.sumByCategory('2026-10-01', '2026-10-31'),
          {food: 100000, transport: 75000});
      expect(await env.expenses.sumByDay('2026-10-01', '2026-10-31'),
          {'2026-10-01': 150000, '2026-10-31': 25000});
    });

    test('unspecified payment and location are grouped, not dropped', () async {
      final pay = await env.expenses.sumByPayment('2026-10-01', '2026-10-31');
      expect(pay, {'upi': 100000, 'unspecified': 50000, 'cash': 25000});
      final loc = await env.expenses.sumByLocation('2026-10-01', '2026-10-31');
      expect(loc['BLR'], 100000);
      expect(loc['unspecified'], 75000);
    });

    test('watchTotal emits again after a new expense', () async {
      final emitted = <int>[];
      final sub = env.expenses
          .watchTotal('2026-10-01', '2026-10-31')
          .listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await env.addExpense(paise: 5000, date: '2026-10-10');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();
      expect(emitted.first, 175000);
      expect(emitted.last, 180000);
    });
  });
}
