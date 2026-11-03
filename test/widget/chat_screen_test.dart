import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/app.dart';
import 'package:kharchu/data/db/app_database.dart';
import 'package:kharchu/data/repositories/expense_repository.dart';

import '../unit/fake_http.dart';
import 'harness.dart';

Map<String, dynamic> toolReply(String name, Map<String, dynamic> args, {String id = 'c1'}) =>
    chatCompletion(calls: [
      {
        'id': id,
        'type': 'function',
        'function': {'name': name, 'arguments': jsonEncode(args)},
      }
    ]);

Map<String, dynamic> addArgs({
  Object amount = 1000,
  String item = 'Chats',
  String category = 'Food & Dining',
  String? location = 'Bengaluru',
  String? payment,
  bool? isNew,
}) =>
    {
      'amount_rupees': amount,
      'item': item,
      'category': category,
      'location': location,
      'payment_method': payment,
      'spent_on': '2026-10-24',
      'is_new_category': isNew,
    }..removeWhere((k, v) => v == null);

/// The sequence Android really goes through when the app is backgrounded and
/// brought back (Flutter asserts on impossible jumps like paused -> resumed).
void backgroundThenResume(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

/// The Save button inside the Edit sheet (the card behind it has one too).
final sheetSave = find.descendant(
    of: find.byType(BottomSheet), matching: find.widgetWithText(FilledButton, 'Save'));

void main() {
  late Harness h;
  late DateTime now;

  Future<void> start(WidgetTester tester, {String? key = 'gsk_abcdefghijklmnopqrstuvwxyz'}) async {
    h = await Harness.create(key: key);
    now = h.now;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: h.overridesWith(() => now),
      child: const KharchuApp(),
    ));
    await tester.pumpAndSettle();
  }

  void script(Map<String, dynamic> reply) => h.adapter.script.add((_) => json(reply));

  Future<void> say(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
  }

  Future<List<ExpenseRow>> saved(WidgetTester tester) async =>
      (await tester.runAsync(() => ExpenseRepository(h.db).find(const ExpenseFilter())))!;

  group('the basic flow', () {
    harnessTest('an empty chat shows only the prompt in the text box', (tester) async {
      await start(tester);
      expect(find.text('What did you spend?'), findsOneWidget);
      expect(find.text('Today'), findsNothing);
      expect(find.byType(Chip), findsNothing);
    });

    harnessTest('the headline example becomes a card with the right details',
        (tester) async {
      await start(tester);
      script(toolReply('propose_add_expense', addArgs()));
      await say(tester, 'I spent Rs.1000 to eat chats in Bengaluru');

      expect(find.text('I spent Rs.1000 to eat chats in Bengaluru'), findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget);
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('Chats · Bengaluru · Today'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('UPI'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(await saved(tester), isEmpty, reason: 'nothing saved before the tap');
    });

    harnessTest('Save stores the expense and collapses the card to one line', (tester) async {
      await start(tester);
      script(toolReply('propose_add_expense', addArgs()));
      await say(tester, 'chats 1000');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final rows = await saved(tester);
      expect(rows.length, 1);
      expect(rows.single.expense.amountPaise, 100000);
      expect(find.text('Save'), findsNothing);
      expect(find.text('₹1,000  Chats'), findsOneWidget);
    });

    harnessTest('picking a payment chip is remembered and saved', (tester) async {
      await start(tester);
      script(toolReply('propose_add_expense', addArgs()));
      await say(tester, 'chats 1000');
      await tester.tap(find.text('UPI'));
      await tester.pumpAndSettle();
      expect(find.text('Cash'), findsNothing, reason: 'chips are replaced by the choice');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect((await saved(tester)).single.expense.paymentMethod, 'upi');
    });

    harnessTest('a payment already given is shown, with no chips', (tester) async {
      await start(tester);
      script(toolReply('propose_add_expense', addArgs(payment: 'gpay')));
      await say(tester, 'chats 1000 gpay');
      expect(find.text('UPI'), findsOneWidget);
      expect(find.text('Cash'), findsNothing);
    });

    harnessTest('Edit changes the amount and saves it', (tester) async {
      await start(tester);
      script(toolReply('propose_add_expense', addArgs()));
      await say(tester, 'chats 1000');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Edit expense'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '850');
      await tester.tap(sheetSave);
      await tester.pumpAndSettle();
      final e = (await saved(tester)).single.expense;
      expect(e.amountPaise, 85000);
      expect(e.item, 'Chats');
    });

    harnessTest('the Edit sheet refuses an empty amount and an empty item', (tester) async {
      await start(tester);
      script(toolReply('propose_add_expense', addArgs()));
      await say(tester, 'chats 1000');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '');
      await tester.enterText(find.widgetWithText(TextField, 'What for'), '  ');
      await tester.tap(sheetSave);
      await tester.pumpAndSettle();
      expect(find.text('Enter an amount'), findsOneWidget);
      expect(find.text('Enter what it was for'), findsOneWidget);
      expect(find.text('Edit expense'), findsOneWidget, reason: 'sheet stays open');
      expect(await saved(tester), isEmpty);
    });

    harnessTest('the Edit sheet refuses a huge amount', (tester) async {
      await start(tester);
      script(toolReply('propose_add_expense', addArgs()));
      await say(tester, 'chats 1000');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '99999999');
      await tester.tap(sheetSave);
      await tester.pumpAndSettle();
      expect(find.textContaining('above ₹10,00,000'), findsOneWidget);
    });

    harnessTest('Cancel in the Edit sheet saves nothing and keeps the card', (tester) async {
      await start(tester);
      script(toolReply('propose_add_expense', addArgs()));
      await say(tester, 'chats 1000');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit expense'), findsNothing);
      expect(find.text('Save'), findsOneWidget, reason: 'the card is still waiting');
      expect(await saved(tester), isEmpty);
    });

    harnessTest('quickly tapping Save twice stores one expense', (tester) async {
      await start(tester);
      script(toolReply('propose_add_expense', addArgs()));
      await say(tester, 'chats 1000');
      await tester.tap(find.text('Save'));
      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect((await saved(tester)).length, 1);
    });
  });

  group('while it works', () {
    harnessTest('shows "Thinking…", blocks a second send, then shows the card', (tester) async {
      await start(tester);
      final gate = Completer<void>();
      h.adapter.script.add((_) async {
        await gate.future;
        return json(toolReply('propose_add_expense', addArgs()));
      });
      await tester.enterText(find.byType(TextField), 'chats 1000');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(find.text('Thinking…'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'second message');
      await tester.pump();
      final send = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_upward));
      expect(send.onPressed, isNull, reason: 'cannot send while waiting');

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Thinking…'), findsNothing);
      expect(find.text('Save'), findsOneWidget);
      expect(h.adapter.requests.length, 1);
    });

    harnessTest('an empty or blank message is not sent', (tester) async {
      await start(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      final send = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_upward));
      expect(send.onPressed, isNull);
      expect(h.adapter.requests, isEmpty);
    });

    harnessTest('the box is cleared after sending', (tester) async {
      await start(tester);
      script(chatCompletion(content: 'ok'));
      await say(tester, 'hello');
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    });
  });

  group('answers and notices', () {
    harnessTest('a plain answer appears as a reply bubble', (tester) async {
      await start(tester);
      script(chatCompletion(content: "You've spent ₹5,120 on Food & Dining this month."));
      await say(tester, 'how much on food this month?');
      expect(find.text("You've spent ₹5,120 on Food & Dining this month."), findsOneWidget);
    });

    harnessTest('Kannada input is shown as typed and answered in English', (tester) async {
      await start(tester);
      script(chatCompletion(content: 'You spent ₹5,120 on food this month.'));
      await say(tester, 'ಈ ತಿಂಗಳು ಊಟಕ್ಕೆ ಎಷ್ಟು ಖರ್ಚಾಯ್ತು?');
      expect(find.text('ಈ ತಿಂಗಳು ಊಟಕ್ಕೆ ಎಷ್ಟು ಖರ್ಚಾಯ್ತು?'), findsOneWidget);
      expect(find.text('You spent ₹5,120 on food this month.'), findsOneWidget);
    });

    harnessTest('crossing a budget threshold shows a warning after Save', (tester) async {
      await start(tester);
      await tester.runAsync(() async {
        final food = (await h.db.select(h.db.categories).get()).firstWhere((c) => c.name == 'Food & Dining');
        await h.db.into(h.db.budgets).insert(
            BudgetsCompanion.insert(categoryId: Value(food.id), monthlyLimitPaise: 500000));
      });
      script(toolReply('propose_add_expense', addArgs(amount: 4500)));
      await say(tester, 'dinner 4500');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Food & Dining is at 90% of budget'), findsOneWidget);
    });
  });

  group('new category', () {
    harnessTest('shows the suggestion and creates it on Create & save', (tester) async {
      await start(tester);
      script(toolReply(
          'propose_add_expense', addArgs(item: 'Haircut', category: 'Personal Care', isNew: true, amount: 350)));
      await say(tester, '350 haircut');
      expect(find.textContaining('Create "Personal Care"?'), findsOneWidget);
      await tester.tap(find.text('Create & save'));
      await tester.pumpAndSettle();
      final rows = await saved(tester);
      expect(rows.single.category.name, 'Personal Care');
    });

    harnessTest('Use "Other" saves it under Other and creates nothing new', (tester) async {
      await start(tester);
      script(toolReply(
          'propose_add_expense', addArgs(item: 'Haircut', category: 'Personal Care', isNew: true)));
      await say(tester, '350 haircut');
      await tester.tap(find.text('Use "Other"'));
      await tester.pumpAndSettle();
      final rows = await saved(tester);
      expect(rows.single.category.name, 'Other');
      final all = await tester.runAsync(() => h.db.select(h.db.categories).get());
      expect(all!.any((c) => c.name == 'Personal Care'), isFalse);
    });
  });

  group('failures', () {
    harnessTest('offline shows Retry; Retry works and does not repeat the message', (tester) async {
      await start(tester);
      h.adapter.script.add((o) => throw DioExceptionShim.offline(o));
      await say(tester, 'chats 1000');
      expect(find.text("Couldn't reach Groq."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('chats 1000'), findsOneWidget);

      script(toolReply('propose_add_expense', addArgs()));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't reach Groq."), findsNothing);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('chats 1000'), findsOneWidget, reason: 'shown once, not twice');
    });

    harnessTest('a missing key points to Profile', (tester) async {
      await start(tester, key: null);
      await say(tester, 'chats 1000');
      expect(find.text('Add your Groq key to start.'), findsOneWidget);
      await tester.tap(find.text('Open Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Groq API key'), findsWidgets);
      expect(find.text('Save and test'), findsOneWidget);
      expect(h.adapter.requests, isEmpty);
    });

    harnessTest('a rejected key points to Profile', (tester) async {
      await start(tester);
      h.adapter.script.add((_) => errorBody(401, 'bad'));
      await say(tester, 'chats 1000');
      expect(find.text('Groq rejected the key.'), findsOneWidget);
      expect(find.text('Open Profile'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    harnessTest('rate limiting tells the user how long to wait', (tester) async {
      await start(tester);
      // the main model, then the fallback model, are both limited
      h.adapter.script.add((_) => errorBody(429, 'x', headers: {'retry-after': ['7']}));
      h.adapter.script.add((_) => errorBody(429, 'x', headers: {'retry-after': ['12']}));
      await say(tester, 'chats 1000');
      expect(find.text('Busy right now. Try again in 12s.'), findsOneWidget);
    });

    harnessTest('the error clears when a new message is sent', (tester) async {
      await start(tester);
      h.adapter.script.add((o) => throw DioExceptionShim.offline(o));
      await say(tester, 'one');
      script(chatCompletion(content: 'fine'));
      await say(tester, 'two');
      expect(find.text("Couldn't reach Groq."), findsNothing);
      expect(find.text('fine'), findsOneWidget);
    });

    harnessTest('a database failure leaves the composer usable', (tester) async {
      await start(tester);
      await tester.runAsync(() => h.db.close());
      await say(tester, 'chats 1000');
      final send = find.widgetWithIcon(IconButton, Icons.arrow_upward);
      await tester.enterText(find.byType(TextField), 'again');
      await tester.pump();
      expect(tester.widget<IconButton>(send).onPressed, isNotNull);
    });
  });

  group('edit, delete and choose from the chat', () {
    Future<int> seedExpense(WidgetTester tester,
        {int paise = 120000, String item = 'Dinner', String date = '2026-10-18'}) async {
      return (await tester.runAsync(() async {
        final cat = (await h.db.select(h.db.categories).get()).first;
        return h.db.into(h.db.expenses).insert(ExpensesCompanion.insert(
            amountPaise: paise, categoryId: cat.id, item: item, spentOn: date));
      }))!;
    }

    harnessTest('an update card shows before and after, and Update applies it', (tester) async {
      await start(tester);
      final id = await seedExpense(tester);
      script(toolReply('propose_update_expense', {'expense_id': id, 'amount_rupees': 1450}));
      await say(tester, 'change dinner to 1450');
      expect(find.text('₹1,200'), findsOneWidget);
      expect(find.text('₹1,450'), findsOneWidget);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect((await saved(tester)).single.expense.amountPaise, 145000);
      expect(find.text('Updated · Dinner'), findsOneWidget);
    });

    harnessTest('Cancel on an update leaves the expense alone and removes the card', (tester) async {
      await start(tester);
      final id = await seedExpense(tester);
      script(toolReply('propose_update_expense', {'expense_id': id, 'amount_rupees': 1450}));
      await say(tester, 'change dinner to 1450');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Update'), findsNothing);
      expect((await saved(tester)).single.expense.amountPaise, 120000);
    });

    harnessTest('Delete removes it and Undo brings it back', (tester) async {
      await start(tester);
      final id = await seedExpense(tester);
      script(toolReply('propose_delete_expense', {'expense_id': id}));
      await say(tester, 'delete dinner');
      expect(find.text('Delete this expense?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(await saved(tester), isEmpty);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect((await saved(tester)).length, 1);
    });

    harnessTest('"Keep" on a delete card keeps the expense', (tester) async {
      await start(tester);
      final id = await seedExpense(tester);
      script(toolReply('propose_delete_expense', {'expense_id': id}));
      await say(tester, 'delete dinner');
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect((await saved(tester)).length, 1);
    });

    harnessTest('a pick card lists the matches and choosing one opens the edit card', (tester) async {
      await start(tester);
      final a = await seedExpense(tester, item: 'Petrol', paise: 105000, date: '2026-10-22');
      final b = await seedExpense(tester, item: 'Petrol', paise: 90000, date: '2026-10-19');
      script(toolReply('ask_user_to_pick', {
        'kind': 'expense', 'ids': [a, b], 'then': 'update', 'amount_rupees': 800,
      }));
      await say(tester, 'change petrol to 800');
      expect(find.text('Which one?'), findsOneWidget);
      expect(find.text('₹1,050'), findsOneWidget);
      expect(find.text('₹900'), findsOneWidget);
      await tester.tap(find.text('₹900'));
      await tester.pumpAndSettle();
      expect(find.text('Which one?'), findsNothing);
      expect(find.text('Update · Petrol'), findsOneWidget);
    });
  });

  group('lending cards', () {
    harnessTest('a loan card shows the direction and person, and Save records it', (tester) async {
      await start(tester);
      script(toolReply('propose_loan', {
        'direction': 'lent', 'person': 'Rahul', 'amount_rupees': 2000,
        'note': 'Goa trip', 'happened_on': '2026-10-24',
      }));
      await say(tester, 'lent 2000 to Rahul for his Goa trip');
      expect(find.text('You lent'), findsOneWidget);
      expect(find.text('Rahul'), findsOneWidget);
      expect(find.textContaining('new person'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final loans = await tester.runAsync(() => h.db.select(h.db.loans).get());
      expect(loans!.single.principalPaise, 200000);
      expect(await saved(tester), isEmpty, reason: 'a loan is not an expense');
      expect(find.text('Lent ₹2,000 to Rahul'), findsOneWidget);
    });

    harnessTest('a repayment card shows the balance falling to settled', (tester) async {
      await start(tester);
      final loanId = (await tester.runAsync(() async {
        final p = await h.db.into(h.db.people).insert(PeopleCompanion.insert(name: 'Rahul', nameKey: 'rahul'));
        return h.db.into(h.db.loans).insert(LoansCompanion.insert(
            personId: p, direction: 'lent', principalPaise: 100000, happenedOn: '2026-10-10'));
      }))!;
      script(toolReply('propose_repayment', {'loan_id': loanId, 'amount_rupees': 1000, 'paid_on': '2026-10-24'}));
      await say(tester, 'Rahul returned 1000');
      expect(find.text('Settled'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final reps = await tester.runAsync(() => h.db.select(h.db.loanRepayments).get());
      expect(reps!.single.amountPaise, 100000);
    });

    harnessTest('a budget card shows the new limit and Set budget saves it', (tester) async {
      await start(tester);
      script(toolReply('propose_set_budget', {'category': 'Food & Dining', 'monthly_limit_rupees': 6000}));
      await say(tester, 'set food budget to 6000');
      expect(find.text('Food & Dining budget'), findsOneWidget);
      await tester.tap(find.text('Set budget'));
      await tester.pumpAndSettle();
      final b = await tester.runAsync(() => h.db.select(h.db.budgets).get());
      expect(b!.single.monthlyLimitPaise, 600000);
    });
  });

  group('days', () {
    harnessTest("yesterday's messages are not on today's chat", (tester) async {
      await start(tester);
      await tester.runAsync(() async {
        await h.db.into(h.db.chatMessages).insert(ChatMessagesCompanion.insert(
            id: 'old', day: '2026-10-23', role: 'user', body: const Value('yesterday text')));
      });
      await tester.pumpAndSettle();
      expect(find.text('yesterday text'), findsNothing);
    });

    harnessTest('after midnight the chat starts fresh when the app resumes', (tester) async {
      await start(tester);
      script(chatCompletion(content: 'hello back'));
      await say(tester, 'hello');
      expect(find.text('hello back'), findsOneWidget);

      now = DateTime.utc(2026, 10, 24, 19, 0); // 00:30 IST on the 25th
      backgroundThenResume(tester);
      await tester.pumpAndSettle();
      expect(find.text('hello back'), findsNothing);
      expect(find.text('Today'), findsNothing);
    });

    harnessTest('the same day stays put when the app resumes', (tester) async {
      await start(tester);
      script(chatCompletion(content: 'hello back'));
      await say(tester, 'hello');
      backgroundThenResume(tester);
      await tester.pumpAndSettle();
      expect(find.text('hello back'), findsOneWidget);
    });
  });
}
