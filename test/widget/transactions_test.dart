import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/app.dart';
import 'package:kharchu/data/db/app_database.dart';

import 'harness.dart';
import 'seed.dart';

late Harness h;

Future<void> start(WidgetTester tester, Future<void> Function(Seed s)? seed,
    {bool lending = false}) async {
  h = await Harness.create();
  if (seed != null) await tester.runAsync(() => seed(Seed(h.db)));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(h.app());
  await tester.pumpAndSettle();
  await tester.tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('Transactions')));
  await tester.pumpAndSettle();
  if (lending) {
    await tester.tap(find.text('Lending'));
    await tester.pumpAndSettle();
  }
}

Future<void> seedExpenses(Seed s) async {
  await s.expense(1000, 'Chats', location: 'BLR', payment: 'upi');
  await s.expense(240, 'Auto', category: 'Transport');
  await s.expense(1050, 'Petrol', category: 'Transport', date: '2026-10-22', payment: 'card');
  await s.expense(4120, 'Dinner', date: '2026-10-13');
}

void main() {
  group('Expenses tab', () {
    harnessTest('empty', (tester) async {
      await start(tester, null);
      expect(find.text('No expenses yet'), findsOneWidget);
    });

    harnessTest('grouped by day, with day totals and details', (tester) async {
      await start(tester, seedExpenses);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('₹1,240'), findsOneWidget); // today's total
      expect(find.text('Thu, 22 Oct'), findsOneWidget);
      expect(find.text('Tue, 13 Oct'), findsOneWidget);
      expect(find.text('BLR · UPI'), findsOneWidget);
      expect(find.text('Chats'), findsOneWidget);
      // newest day first
      expect(tester.getTopLeft(find.text('Today')).dy,
          lessThan(tester.getTopLeft(find.text('Thu, 22 Oct')).dy));
    });

    harnessTest('search narrows the list; no match says so; clearing restores it',
        (tester) async {
      await start(tester, seedExpenses);
      await tester.enterText(find.byType(TextField), 'pet');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Petrol'), findsOneWidget);
      expect(find.text('Chats'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Petrol'), findsOneWidget);
    });

    harnessTest('search by place and by payment-free words', (tester) async {
      await start(tester, seedExpenses);
      await tester.enterText(find.byType(TextField), 'blr');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Auto'), findsNothing);
    });

    harnessTest('filtering by category, then clearing', (tester) async {
      await start(tester, seedExpenses);
      await tester.tap(find.byTooltip('Filter'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Transport'));
      await tester.tap(find.widgetWithText(FilterChip, 'Transport'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Petrol'), findsOneWidget);
      expect(find.text('Chats'), findsNothing);

      await tester.tap(find.byTooltip('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Chats'), findsOneWidget);
    });

    harnessTest('filtering by payment method', (tester) async {
      await start(tester, seedExpenses);
      await tester.tap(find.byTooltip('Filter'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Card'));
      await tester.tap(find.widgetWithText(FilterChip, 'Card'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Petrol'), findsOneWidget);
      expect(find.text('Chats'), findsNothing);
    });

    harnessTest('a filter that matches nothing says so, not "No expenses yet"',
        (tester) async {
      await start(tester, seedExpenses);
      await tester.tap(find.byTooltip('Filter'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Net banking'));
      await tester.tap(find.widgetWithText(FilterChip, 'Net banking'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches'), findsOneWidget);
    });

    harnessTest('tapping an expense edits it', (tester) async {
      await start(tester, seedExpenses);
      await tester.tap(find.text('Dinner'));
      await tester.pumpAndSettle();
      expect(find.text('Edit expense'), findsOneWidget);
      expect((tester.widget<TextField>(find.widgetWithText(TextField, 'Amount'))).controller!.text, '4120');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '4200');
      await tester.tap(find.descendant(
          of: find.byType(BottomSheet), matching: find.widgetWithText(FilledButton, 'Save')));
      await tester.pumpAndSettle();
      expect(find.text('₹4,200'), findsWidgets);
      expect(find.text('₹4,120'), findsNothing);
    });

    harnessTest('cancelling the edit changes nothing', (tester) async {
      await start(tester, seedExpenses);
      await tester.tap(find.text('Dinner'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '9');
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('₹4,120'), findsWidgets);
    });

    harnessTest('swipe to delete removes it, and Undo brings it back', (tester) async {
      await start(tester, seedExpenses);
      await tester.drag(find.text('Auto'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Auto'), findsNothing);
      expect(find.textContaining('Deleted ₹240 Auto'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Auto'), findsOneWidget);
    });

    harnessTest('an expense in an archived category can still be edited', (tester) async {
      await start(tester, (s) async {
        await s.expense(500, 'Old trip', category: 'Travel');
        await (s.db.update(s.db.categories)..where((c) => c.name.equals('Travel')))
            .write(const CategoriesCompanion(isArchived: Value(true)));
      });
      await tester.tap(find.text('Old trip'));
      await tester.pumpAndSettle();
      expect(find.text('Edit expense'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    harnessTest('an expense with a very long name does not overflow', (tester) async {
      await start(tester, (s) async {
        await s.expense(1234567, 'x' * 60, location: 'y' * 60, payment: 'netbanking');
      });
      expect(tester.takeException(), isNull);
      expect(find.text('₹12,34,567'), findsWidgets); // day total and the row
    });
  });

  group('Lending tab', () {
    harnessTest('empty', (tester) async {
      await start(tester, null, lending: true);
      expect(find.text('No lending yet'), findsOneWidget);
      expect(find.text('₹0'), findsNWidgets(2));
    });

    harnessTest('totals, open and settled', (tester) async {
      await start(tester, (s) async {
        await s.loan('Rahul', 2000);
        final k = await s.loan('Karthik', 2500);
        await s.repay(k, 1000);
        await s.loan('Priya', 1000, dir: 'borrowed');
        final a = await s.loan('Anil', 800);
        await s.repay(a, 800);
      }, lending: true);
      expect(find.text('₹3,500'), findsOneWidget); // you'll get: 2000 + 1500
      expect(find.text('₹1,000'), findsNWidgets(2)); // you owe: the tile and Priya's row
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Settled'), findsOneWidget);
      expect(find.text('owes you'), findsNWidgets(2));
      expect(find.text('you owe'), findsOneWidget);
      expect(find.text('₹1,500'), findsOneWidget); // Karthik's remaining
    });

    harnessTest('a person with both kinds of loan shows the net', (tester) async {
      await start(tester, (s) async {
        await s.loan('Rahul', 2000);
        await s.loan('Rahul', 500, dir: 'borrowed');
      }, lending: true);
      expect(find.text('₹1,500'), findsOneWidget);
      expect(find.text('owes you'), findsOneWidget);
    });
  });

  group('Person screen', () {
    Future<void> openRahul(WidgetTester tester) async {
      await tester.tap(find.text('Rahul'));
      await tester.pumpAndSettle();
    }

    Finder sheetSave() => find.descendant(
        of: find.byType(BottomSheet), matching: find.widgetWithText(FilledButton, 'Save'));

    harnessTest('shows the balance and the history', (tester) async {
      await start(tester, (s) async {
        final id = await s.loan('Rahul', 2000, note: 'Goa trip');
        await s.repay(id, 500);
      }, lending: true);
      await openRahul(tester);
      expect(find.text('Owes you'), findsOneWidget);
      expect(find.text('₹1,500'), findsOneWidget);
      expect(find.text('You lent'), findsOneWidget);
      expect(find.text('Paid back'), findsOneWidget);
      expect(find.text('Record repayment'), findsOneWidget);
    });

    harnessTest('recording a partial repayment lowers the balance', (tester) async {
      await start(tester, (s) async {
        await s.loan('Rahul', 2000);
      }, lending: true);
      await openRahul(tester);
      await tester.tap(find.text('Record repayment'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Amount')).controller!.text, '2000');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '500');
      await tester.tap(sheetSave());
      await tester.pumpAndSettle();
      expect(find.text('₹1,500'), findsOneWidget);
      expect(find.text('Paid back'), findsOneWidget);
    });

    harnessTest('repaying more than is owed is refused in the sheet', (tester) async {
      await start(tester, (s) async {
        await s.loan('Rahul', 2000);
      }, lending: true);
      await openRahul(tester);
      await tester.tap(find.text('Record repayment'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '3000');
      await tester.tap(sheetSave());
      await tester.pumpAndSettle();
      expect(find.textContaining('More than the ₹2,000 outstanding'), findsOneWidget);
      expect(find.text('Paid back'), findsNothing);
    });

    harnessTest('empty and zero amounts are refused', (tester) async {
      await start(tester, (s) async {
        await s.loan('Rahul', 2000);
      }, lending: true);
      await openRahul(tester);
      await tester.tap(find.text('Record repayment'));
      await tester.pumpAndSettle();
      for (final t in ['', '0', 'abc']) {
        await tester.enterText(find.widgetWithText(TextField, 'Amount'), t);
        await tester.tap(sheetSave());
        await tester.pumpAndSettle();
        expect(find.text('Enter an amount'), findsOneWidget, reason: t);
      }
    });

    harnessTest('paying everything settles them', (tester) async {
      await start(tester, (s) async {
        await s.loan('Rahul', 2000);
      }, lending: true);
      await openRahul(tester);
      await tester.tap(find.text('Record repayment'));
      await tester.pumpAndSettle();
      await tester.tap(sheetSave()); // prefilled with the full amount
      await tester.pumpAndSettle();
      expect(find.text('All settled'), findsOneWidget);
      expect(find.text('Record repayment'), findsNothing);
    });

    harnessTest('with two open loans you choose which one', (tester) async {
      await start(tester, (s) async {
        await s.loan('Rahul', 2000, note: 'Goa', date: '2026-10-10');
        await s.loan('Rahul', 1000, note: 'Lunch', date: '2026-10-01');
      }, lending: true);
      await openRahul(tester);
      await tester.tap(find.text('Record repayment'));
      await tester.pumpAndSettle();
      expect(find.text('Which loan'), findsOneWidget);
    });

    harnessTest('a person who does not exist shows "Not found"', (tester) async {
      await start(tester, null, lending: true);
      final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
      container.read(routerProvider).go('/transactions/person/999');
      await tester.pumpAndSettle();
      expect(find.text('Not found'), findsOneWidget);

      container.read(routerProvider).go('/transactions/person/abc');
      await tester.pumpAndSettle();
      expect(find.text('Not found'), findsOneWidget);
    });
  });
}
