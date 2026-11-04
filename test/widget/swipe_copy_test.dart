import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/widgets/pill_nav_bar.dart';

import 'harness.dart';
import 'seed.dart';

void main() {
  late Harness h;

  Future<void> start(WidgetTester tester, {String? key}) async {
    h = await Harness.create(key: key);
    await tester.runAsync(() async {
      final s = Seed(h.db);
      await s.expense(1000, 'Chats');
      await s.loan('Rahul', 1500);
    });
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(h.app());
    await tester.pumpAndSettle();
  }

  Future<void> tab(WidgetTester tester, String name) async {
    await tester.tap(find.descendant(of: find.byType(PillNavBar), matching: find.text(name)));
    await tester.pumpAndSettle();
  }

  Future<void> swipeLeft(WidgetTester tester) async {
    await tester.fling(find.byType(PageView).first, const Offset(-200, 0), 1500);
    await tester.pumpAndSettle();
  }

  Future<void> swipeRight(WidgetTester tester) async {
    await tester.fling(find.byType(PageView).first, const Offset(200, 0), 1500);
    await tester.pumpAndSettle();
  }

  harnessTest('swiping moves between the bottom-bar screens, both ways', (tester) async {
    await start(tester);
    expect(find.text('What did you spend?'), findsOneWidget);
    await swipeLeft(tester); // Chat -> Dashboard
    expect(find.text('October'), findsOneWidget);
    await swipeLeft(tester); // -> Transactions
    expect(find.text('Add expense'), findsOneWidget);
    await swipeRight(tester); // back to Dashboard
    expect(find.text('October'), findsOneWidget);
  });

  harnessTest('swiping inside Transactions switches Expenses and Lending, then carries on',
      (tester) async {
    await start(tester);
    await tab(tester, 'Transactions');
    expect(find.text('Add expense'), findsOneWidget);

    await tester.fling(find.text('Chats'), const Offset(-200, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Add lending'), findsOneWidget);
    expect(find.text('Rahul'), findsOneWidget);

    // one more swipe at the Lending end goes on to Budgets
    await tester.fling(find.text('Rahul'), const Offset(-200, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('No budgets set yet'), findsOneWidget);

    // and back to Transactions, landing on the screen it was left on
    await swipeRight(tester);
    expect(find.text('Add lending'), findsOneWidget);
  });

  harnessTest('tapping the switch slides Expenses to Lending', (tester) async {
    await start(tester);
    await tab(tester, 'Transactions');
    await tester.tap(find.text('Lending'));
    await tester.pumpAndSettle();
    expect(find.text('Add lending'), findsOneWidget);
    expect(find.text('Rahul'), findsOneWidget);
  });

  harnessTest('holding a message you sent lets you copy it', (tester) async {
    await start(tester, key: 'gsk_abcdefghijklmnopqrstuvwxyz');
    h.adapter.script.add((_) => throw StateError('offline')); // reply is irrelevant
    await tester.enterText(find.byType(TextField), 'chats 1000 at Meghana');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.longPress(find.text('chats 1000 at Meghana'));
    await tester.pumpAndSettle();
    expect(copied, 'chats 1000 at Meghana');
    expect(find.text('Copied'), findsOneWidget);
  });
}
