import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';
import 'seed.dart';

late Harness h;

Future<void> start(WidgetTester tester, Future<void> Function(Seed s)? seed,
    {String tab = 'Dashboard'}) async {
  h = await Harness.create();
  if (seed != null) await tester.runAsync(() => seed(Seed(h.db)));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(h.app());
  await tester.pumpAndSettle();
  await goTo(tester, tab);
}

Future<void> goTo(WidgetTester tester, String name) async {
  await tester.tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.text(name)));
  await tester.pumpAndSettle();
}

Future<void> october(Seed s) async {
  await s.expense(1000, 'Chats', location: 'BLR', payment: 'upi');
  await s.expense(4120, 'Dinner', date: '2026-10-13');
  await s.expense(1050, 'Petrol', category: 'Transport', date: '2026-10-22');
  await s.expense(240, 'Auto', category: 'Transport');
  await s.expense(4350, 'Shoes', category: 'Shopping', date: '2026-10-05');
  await s.expense(900, 'Rice', category: 'Groceries', date: '2026-09-30');
}

void main() {
  group('Dashboard', () {
    harnessTest('an empty month shows zeros, not a blank screen', (tester) async {
      await start(tester, null);
      expect(find.text('₹0'), findsWidgets);
      expect(find.text('No spending this month'), findsOneWidget);
      expect(find.text('0 expenses'), findsOneWidget);
      expect(find.text('0 people'), findsNWidgets(2));
    });

    harnessTest('totals, categories and today appear', (tester) async {
      await start(tester, october);
      expect(find.text('₹10,760'), findsOneWidget);
      expect(find.text('5 expenses'), findsOneWidget);
      expect(find.text('Food & Dining'), findsWidgets); // donut centre and legend
      expect(find.text('₹5,120'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('Today ₹1,240'), findsOneWidget);
    });

    harnessTest('September money is not in October', (tester) async {
      await start(tester, october);
      expect(find.text('Groceries'), findsNothing);
    });

    harnessTest('an overall budget shows what is left and the days remaining',
        (tester) async {
      await start(tester, (s) async {
        await october(s);
        await s.budget(25000);
      });
      expect(find.text('of ₹25,000'), findsOneWidget);
      expect(find.text('₹14,240 left · 7 days'), findsOneWidget);
    });

    harnessTest('over the overall budget says by how much', (tester) async {
      await start(tester, (s) async {
        await october(s);
        await s.budget(10000);
      });
      expect(find.text('Over by ₹760'), findsOneWidget);
    });

    harnessTest('a category over its budget is named', (tester) async {
      await start(tester, (s) async {
        await october(s);
        await s.budget(4000, category: 'Shopping');
      });
      expect(find.text('Shopping over budget'), findsOneWidget);
    });

    harnessTest('more than five categories are grouped as Others', (tester) async {
      await start(tester, (s) async {
        for (final c in [
          'Food & Dining',
          'Groceries',
          'Transport',
          'Shopping',
          'Bills & Utilities',
          'Health',
          'Travel'
        ]) {
          await s.expense(1000, 'x', category: c);
        }
      });
      expect(find.text('Others'), findsOneWidget);
    });

    harnessTest('month arrows move through months, and Next stops at this month',
        (tester) async {
      await start(tester, october);
      IconButton next() =>
          tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right));
      expect(next().onPressed, isNull, reason: 'cannot go past this month');

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('September'), findsOneWidget);
      expect(find.text('₹900'), findsWidgets);
      expect(find.text('Chats'), findsNothing);
      expect(next().onPressed, isNotNull);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('October'), findsOneWidget);
      expect(find.text('₹10,760'), findsOneWidget);
    });

    harnessTest('going back past January labels the year', (tester) async {
      await start(tester, null);
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byTooltip('Previous month'));
        await tester.pumpAndSettle();
      }
      expect(find.text('December 2025'), findsOneWidget);
    });

    harnessTest('lending tiles show amounts and open the Lending tab', (tester) async {
      await start(tester, (s) async {
        await s.loan('Rahul', 2000);
        await s.loan('Priya', 1000, dir: 'borrowed');
      });
      expect(find.text('₹2,000'), findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget);
      expect(find.text('1 person'), findsNWidgets(2));
      await tester.tap(find.text("You'll get"));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Rahul'), findsOneWidget);
    });

    harnessTest('a deleted expense is not in the totals', (tester) async {
      await start(tester, (s) async {
        final id = await s.expense(500, 'Gone');
        await s.deleteExpense(id);
      });
      expect(find.text('0 expenses'), findsOneWidget);
    });
  });

  group('Budgets', () {
    harnessTest('with nothing set, offers to add one', (tester) async {
      await start(tester, null, tab: 'Budgets');
      expect(find.text('No budgets yet'), findsOneWidget);
      expect(find.text('Add budget'), findsOneWidget);
    });

    harnessTest('statuses, figures and order (over first)', (tester) async {
      await start(tester, (s) async {
        await october(s);
        await s.budget(25000);
        await s.budget(6000, category: 'Food & Dining'); // 5120 = 85% near
        await s.budget(4000, category: 'Shopping'); // 4350 over
        await s.budget(5000, category: 'Transport'); // 1290 on track
      }, tab: 'Budgets');
      expect(find.text('Over'), findsOneWidget);
      expect(find.text('Near limit'), findsOneWidget);
      expect(find.text('On track'), findsOneWidget);
      expect(find.text('₹350 over'), findsOneWidget);
      expect(find.text('₹880 left'), findsOneWidget);
      expect(find.text('/ ₹25,000'), findsOneWidget);
      final over = tester.getTopLeft(find.text('Shopping')).dy;
      final near = tester.getTopLeft(find.text('Food & Dining')).dy;
      final ok = tester.getTopLeft(find.text('Transport')).dy;
      expect(over, lessThan(near));
      expect(near, lessThan(ok));
    });

    harnessTest('categories with spending but no budget are offered', (tester) async {
      await start(tester, (s) async {
        await october(s);
        await s.budget(6000, category: 'Food & Dining');
      }, tab: 'Budgets');
      expect(find.text('+ Shopping'), findsOneWidget);
      expect(find.text('+ Food & Dining'), findsNothing);
    });

    harnessTest('adding a budget from a chip makes it appear', (tester) async {
      await start(tester, (s) async {
        await october(s);
        await s.budget(6000, category: 'Food & Dining');
      }, tab: 'Budgets');
      await tester.tap(find.text('+ Shopping'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Monthly limit'), '5000');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('₹4,350 of ₹5,000'), findsOneWidget);
      expect(find.text('+ Shopping'), findsNothing);
    });

    harnessTest('the + button adds an overall budget', (tester) async {
      await start(tester, null, tab: 'Budgets');
      await tester.tap(find.byTooltip('Add budget'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Monthly limit'), '25k');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('/ ₹25,000'), findsOneWidget);
    });

    harnessTest('editing a budget changes its limit; Delete removes it', (tester) async {
      await start(tester, (s) async {
        await october(s);
        await s.budget(6000, category: 'Food & Dining');
      }, tab: 'Budgets');
      await tester.tap(find.text('Food & Dining'));
      await tester.pumpAndSettle();
      expect(find.text('Edit budget'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Monthly limit'), '9000');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('₹5,120 of ₹9,000'), findsOneWidget);

      await tester.tap(find.text('Food & Dining'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('₹5,120 of ₹9,000'), findsNothing);
    });

    harnessTest('empty, zero and huge limits are refused', (tester) async {
      await start(tester, null, tab: 'Budgets');
      await tester.tap(find.byTooltip('Add budget'));
      await tester.pumpAndSettle();
      for (final (text, message) in [
        ('', 'Enter an amount'),
        ('0', 'Enter an amount'),
        ('-5', 'Enter an amount'),
        ('abc', 'Enter an amount'),
        ('999999999', 'unrealistically large'),
      ]) {
        await tester.enterText(find.widgetWithText(TextField, 'Monthly limit'), text);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.textContaining(message), findsOneWidget, reason: text);
      }
    });
  });
}
