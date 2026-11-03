import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  late TestEnv env;
  setUp(() => env = TestEnv());
  tearDown(() => env.close());

  group('category resolve', () {
    test('exact match ignores case and extra spaces', () async {
      expect((await env.categories.resolve('food & dining'))!.name, 'Food & Dining');
      expect((await env.categories.resolve('  TRANSPORT  '))!.name, 'Transport');
      expect((await env.categories.resolve('Bills   &  Utilities'))!.name,
          'Bills & Utilities');
    });

    test('aliases map common words to presets', () async {
      expect((await env.categories.resolve('food'))!.name, 'Food & Dining');
      expect((await env.categories.resolve('Petrol'))!.name, 'Transport');
      expect((await env.categories.resolve('medicine'))!.name, 'Health');
      expect((await env.categories.resolve('movies'))!.name, 'Entertainment');
      expect((await env.categories.resolve('electricity'))!.name,
          'Bills & Utilities');
      expect((await env.categories.resolve('misc'))!.name, 'Other');
    });

    test('unknown or empty names resolve to null', () async {
      expect(await env.categories.resolve('Personal Care'), isNull);
      expect(await env.categories.resolve(''), isNull);
      expect(await env.categories.resolve('   '), isNull);
    });

    test('an ambiguous partial match resolves to null, not a guess', () async {
      // "s" appears inside several preset names, so there is no single answer.
      expect(await env.categories.resolve('s'), isNull);
    });

    test('archived categories are not resolved', () async {
      final id = await env.cat('Travel');
      await env.categories.setArchived(id, true);
      expect(await env.categories.resolve('Travel'), isNull);
      expect(await env.categories.resolve('trip'), isNull);
    });
  });

  group('category create / rename / archive', () {
    test('create adds a non-default category', () async {
      final c = await env.categories.create('Personal Care');
      expect(c.name, 'Personal Care');
      expect(c.isDefault, isFalse);
      expect((await env.categories.active()).length, 11);
    });

    test('creating an existing name (any case) returns the same one', () async {
      final a = await env.categories.create('Personal Care');
      final b = await env.categories.create('  personal   care ');
      expect(b.id, a.id);
      final food = await env.categories.create('food & dining');
      expect(food.id, await env.cat('Food & Dining'));
      expect((await env.categories.active()).length, 11);
    });

    test('creating an archived name un-archives it', () async {
      final id = await env.cat('Travel');
      await env.categories.setArchived(id, true);
      final c = await env.categories.create('travel');
      expect(c.id, id);
      expect(c.isArchived, isFalse);
    });

    test('rejects empty and oversized names', () async {
      expect(() => env.categories.create(''), throwsArgumentError);
      expect(() => env.categories.create('   '), throwsArgumentError);
      expect(() => env.categories.create('x' * 41), throwsArgumentError);
    });

    test('rename refuses a name another category already has', () async {
      final shopping = await env.cat('Shopping');
      expect(await env.categories.rename(shopping, 'transport'), isFalse);
      expect(await env.categories.rename(shopping, 'Retail'), isTrue);
      expect((await env.categories.byId(shopping))!.name, 'Retail');
      expect(await env.categories.rename(shopping, '  '), isFalse);
    });

    test('renaming to the same name with different case is allowed', () async {
      final shopping = await env.cat('Shopping');
      expect(await env.categories.rename(shopping, 'SHOPPING'), isTrue);
    });

    test('the last active category cannot be archived', () async {
      final all = await env.categories.active();
      for (final c in all.skip(1)) {
        expect(await env.categories.setArchived(c.id, true), isTrue);
      }
      expect(await env.categories.setArchived(all.first.id, true), isFalse);
      expect((await env.categories.active()).length, 1);
    });

    test('archiving keeps old expenses readable', () async {
      final id = await env.addExpense(paise: 5000, category: 'Travel');
      await env.categories.setArchived(await env.cat('Travel'), true);
      final row = await env.expenses.getById(id);
      expect(row!.category.name, 'Travel');
    });

    test('fallbackOther returns Other, or the last active if Other is gone',
        () async {
      expect((await env.categories.fallbackOther())!.name, 'Other');
      await env.categories.setArchived(await env.cat('Other'), true);
      expect(await env.categories.fallbackOther(), isNotNull);
    });
  });

  group('budgets', () {
    test('upsert creates then updates, never duplicating the overall budget',
        () async {
      expect(await env.budgets.upsert(null, 2500000), isTrue);
      expect(await env.budgets.upsert(null, 3000000), isTrue);
      final all = await env.budgets.all();
      expect(all.length, 1);
      expect(all.first.monthlyLimitPaise, 3000000);
      expect(all.first.categoryId, isNull);
    });

    test('category budgets are independent and unique per category', () async {
      final food = await env.cat('Food & Dining');
      final transport = await env.cat('Transport');
      await env.budgets.upsert(food, 600000);
      await env.budgets.upsert(transport, 300000);
      await env.budgets.upsert(food, 650000);
      expect((await env.budgets.all()).length, 2);
      expect((await env.budgets.forCategory(food))!.monthlyLimitPaise, 650000);
      expect((await env.budgets.forCategory(transport))!.monthlyLimitPaise, 300000);
      expect(await env.budgets.forCategory(await env.cat('Health')), isNull);
    });

    test('zero and negative limits are rejected and change nothing', () async {
      await env.budgets.upsert(null, 100000);
      expect(await env.budgets.upsert(null, 0), isFalse);
      expect(await env.budgets.upsert(null, -5), isFalse);
      expect((await env.budgets.forCategory(null))!.monthlyLimitPaise, 100000);
    });

    test('delete removes it', () async {
      await env.budgets.upsert(null, 100000);
      final b = (await env.budgets.forCategory(null))!;
      await env.budgets.delete(b.id);
      expect(await env.budgets.forCategory(null), isNull);
    });
  });
}
