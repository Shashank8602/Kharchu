import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/repositories/expense_repository.dart';
import 'package:kharchu/data/repositories/lending_repository.dart';

import 'harness.dart';

void main() {
  late Harness h;

  Future<void> start(WidgetTester tester, {String? key}) async {
    h = await Harness.create(key: key);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(h.app());
    await tester.pumpAndSettle();
  }

  Future<void> openTransactions(WidgetTester tester) async {
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Transactions')));
    await tester.pumpAndSettle();
  }

  harnessTest('an expense can be added by hand with no Groq key at all', (tester) async {
    await start(tester); // no key
    await openTransactions(tester);
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '250');
    await tester.enterText(find.widgetWithText(TextField, 'What for'), 'tea and snacks');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Dining').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final rows = (await tester.runAsync(() => ExpenseRepository(h.db).find(const ExpenseFilter())))!;
    expect(rows.length, 1);
    expect(rows.single.expense.amountPaise, 25000);
    expect(rows.single.expense.item, 'Tea and Snacks');
    expect(rows.single.expense.source, 'manual');
    expect(find.text('Tea and Snacks'), findsOneWidget);
  });

  harnessTest('an empty manual form is refused', (tester) async {
    await start(tester);
    await openTransactions(tester);
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Pick a category'), findsOneWidget);
  });

  harnessTest('lending can be added by hand, in either direction', (tester) async {
    await start(tester);
    await openTransactions(tester);
    await tester.tap(find.text('Lending'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add lending'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I borrowed'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Borrowed from'), 'Rahul');
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '1500');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final totals = (await tester.runAsync(() => LendingRepository(h.db).totals()))!;
    expect(totals.owePaise, 150000);
    expect(totals.getPaise, 0);
    expect(find.text('Rahul'), findsOneWidget);
  });

  harnessTest('when Groq says no, the error offers manual entry', (tester) async {
    await start(tester); // no key
    await tester.enterText(find.byType(TextField), 'chats 1000');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Add your Groq key to start.'), findsOneWidget);
    await tester.tap(find.text('Add manually').last);
    await tester.pumpAndSettle();
    expect(find.text('Lent or borrowed'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
  });
}
