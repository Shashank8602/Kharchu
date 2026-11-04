import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/widgets/pill_nav_bar.dart';
import 'package:kharchu/data/db/app_database.dart';
import 'package:kharchu/data/repositories/expense_repository.dart';
import 'package:kharchu/services/agent/proposals.dart';
import 'package:kharchu/services/backup_service.dart';

import 'harness.dart';
import 'seed.dart';

late Harness h;

Future<void> start(WidgetTester tester, Future<void> Function(Seed s)? seed,
    {Map<String, Object> prefs = const {}}) async {
  h = await Harness.create(prefs: prefs);
  if (seed != null) await tester.runAsync(() => seed(Seed(h.db)));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(h.app());
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(PillNavBar), matching: find.text('Profile')));
  await tester.pumpAndSettle();
}

/// Reads the database after the app has been taken down (see harnessTest).
Future<T> afterShutdown<T>(WidgetTester tester, Future<T> Function() read) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
  final result = await tester.runAsync(read);
  return result as T;
}

Future<Uint8List> backupOf(Future<void> Function(Seed s) fill) async {
  final db = AppDatabase(NativeDatabase.memory());
  await fill(Seed(db));
  final json = await BackupService(db).exportJson();
  await db.close();
  return Uint8List.fromList(utf8.encode(json));
}

Future<void> ledger(Seed s) async {
  await s.expense(1000, 'Chats', location: 'BLR');
  await s.expense(4120, 'Dinner', date: '2026-10-13');
  final id = await s.loan('Rahul', 2000, note: 'Goa trip');
  await s.repay(id, 500);
  await s.budget(25000);
}

void main() {
  group('Back up to file', () {
    harnessTest('saves a JSON file with a dated name and updates the "Last" tag', (tester) async {
      await start(tester, ledger);
      expect(find.text('Never'), findsOneWidget);
      await tester.tap(find.text('Back up to file'));
      await tester.pumpAndSettle();

      expect(h.files.saved.length, 1);
      final f = h.files.saved.single;
      expect(f.name, matches(RegExp(r'^kharchu-backup-\d{8}-\d{4}\.json$')));
      expect(f.mime, 'application/json');
      final m = jsonDecode(utf8.decode(f.bytes)) as Map<String, dynamic>;
      expect(m['app'], 'kharchu');
      expect((m['expenses'] as List).length, 2);
      expect(find.text('Backup saved'), findsOneWidget);
      expect(find.text('Never'), findsNothing);
      expect(find.textContaining('Last:'), findsOneWidget);
      expect(h.prefs.getString('last_backup_at'), isNotNull);
    });

    harnessTest('cancelling the Save dialog says nothing and records nothing', (tester) async {
      await start(tester, ledger);
      h.files.saveResult = false;
      await tester.tap(find.text('Back up to file'));
      await tester.pumpAndSettle();
      expect(find.text('Backup saved'), findsNothing);
      expect(find.text('Never'), findsOneWidget);
      expect(h.prefs.getString('last_backup_at'), isNull);
    });

    harnessTest('the backup never contains the Groq key', (tester) async {
      h = await Harness.create(key: 'gsk_abcdefghijklmnopqrstuvwxyz');
      await tester.runAsync(() => ledger(Seed(h.db)));
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(h.app());
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(PillNavBar), matching: find.text('Profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back up to file'));
      await tester.pumpAndSettle();
      expect(utf8.decode(h.files.saved.single.bytes), isNot(contains('gsk_')));
    });
  });

  group('Restore from file', () {
    harnessTest('shows what is in the file, then replaces everything', (tester) async {
      final file = await backupOf(ledger);
      await start(tester, (s) async => s.expense(777, 'Old data'));
      h.files.toPick = file;
      await tester.tap(find.text('Restore from file'));
      await tester.pumpAndSettle();
      expect(find.text('Restore this backup?'), findsOneWidget);
      expect(find.textContaining('2 expenses, 1 loan, 1 budget'), findsOneWidget);
      expect(find.text('This replaces everything on this phone.'), findsOneWidget);
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(find.text('Backup restored'), findsOneWidget);

      final items = await afterShutdown(tester, () async =>
          (await ExpenseRepository(h.db).find(const ExpenseFilter())).map((r) => r.expense.item).toSet());
      expect(items, {'Chats', 'Dinner'});
    });

    harnessTest('Cancel leaves the current data alone', (tester) async {
      final file = await backupOf(ledger);
      await start(tester, (s) async => s.expense(777, 'Old data'));
      h.files.toPick = file;
      await tester.tap(find.text('Restore from file'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      final items = await afterShutdown(tester, () async =>
          (await ExpenseRepository(h.db).find(const ExpenseFilter())).map((r) => r.expense.item).toSet());
      expect(items, {'Old data'});
    });

    harnessTest('cancelling the file picker does nothing', (tester) async {
      await start(tester, (s) async => s.expense(777, 'Old data'));
      h.files.toPick = null;
      await tester.tap(find.text('Restore from file'));
      await tester.pumpAndSettle();
      expect(find.text('Restore this backup?'), findsNothing);
    });

    for (final (name, bytes, message) in <(String, List<int>, String)>[
      ('a text file', utf8.encode('hello world'), "isn't a Kharchu backup"),
      ('empty file', <int>[], "isn't a Kharchu backup"),
      ('invalid UTF-8', <int>[0xFF, 0xFE, 0xFA, 0x00], "isn't a Kharchu backup"),
      ('another app\'s JSON', utf8.encode('{"app":"other"}'), "isn't a Kharchu backup"),
      ('a newer backup', utf8.encode('{"app":"kharchu","backup_version":9}'), 'newer version'),
      ('a damaged backup', utf8.encode('{"app":"kharchu","backup_version":1}'), 'damaged'),
    ]) {
      harnessTest('refuses $name, tells the user, and keeps their data', (tester) async {
        await start(tester, (s) async => s.expense(777, 'Old data'));
        h.files.toPick = Uint8List.fromList(bytes);
        await tester.tap(find.text('Restore from file'));
        await tester.pumpAndSettle();
        expect(find.text('Restore this backup?'), findsNothing);
        expect(find.textContaining(message), findsOneWidget);
        final items = await afterShutdown(tester, () async =>
            (await ExpenseRepository(h.db).find(const ExpenseFilter())).map((r) => r.expense.item).toSet());
        expect(items, {'Old data'});
      });
    }
  });

  group('Export CSV', () {
    harnessTest('saves this month as a CSV file', (tester) async {
      await start(tester, ledger);
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('This month'));
      await tester.pumpAndSettle();
      expect(h.files.saved.length, 1);
      final f = h.files.saved.single;
      expect(f.name, 'expenses_2026-10-01_to_2026-10-31.csv');
      expect(f.mime, 'text/csv');
      final text = utf8.decode(f.bytes);
      // the raw file starts with the UTF-8 BOM (utf8.decode would strip it)
      expect(f.bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
      expect(text, contains('Chats'));
      expect(text, contains('Dinner'));
      expect(find.text('Expenses exported'), findsOneWidget);
    });

    harnessTest('an empty period explains itself and saves nothing', (tester) async {
      await start(tester, (s) async => s.expense(100, 'Old', date: '2026-01-05'));
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last month'));
      await tester.pumpAndSettle();
      expect(find.text('No expenses in that period'), findsOneWidget);
      expect(h.files.saved, isEmpty);
    });

    harnessTest('All time includes older expenses', (tester) async {
      await start(tester, (s) async => s.expense(100, 'Ancient', date: '2023-01-05'));
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All time'));
      await tester.pumpAndSettle();
      expect(utf8.decode(h.files.saved.single.bytes), contains('Ancient'));
    });

    harnessTest('dismissing the period dialog exports nothing', (tester) async {
      await start(tester, ledger);
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5)); // outside the dialog
      await tester.pumpAndSettle();
      expect(h.files.saved, isEmpty);
    });
  });

  group('Categories screen', () {
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
    }

    harnessTest('lists the ten presets', (tester) async {
      await start(tester, null);
      await open(tester);
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      expect(find.byTooltip('Add category'), findsOneWidget);
    });

    harnessTest('adding a category, and a duplicate in another case adds nothing', (tester) async {
      await start(tester, null);
      await open(tester);
      await tester.tap(find.byTooltip('Add category'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Personal Care');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Personal Care'), findsOneWidget);

      await tester.tap(find.byTooltip('Add category'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'personal care');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Personal Care'), findsOneWidget);
      expect(find.text('personal care'), findsNothing);
    });

    harnessTest('an empty name is explained', (tester) async {
      await start(tester, null);
      await open(tester);
      await tester.tap(find.byTooltip('Add category'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Category name is empty'), findsOneWidget);
    });

    harnessTest('renaming works, and a name already used is refused', (tester) async {
      await start(tester, null);
      await open(tester);
      await tester.tap(find.byTooltip('Rename Shopping'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Retail');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Retail'), findsOneWidget);
      expect(find.text('Shopping'), findsNothing);

      await tester.tap(find.byTooltip('Rename Retail'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'transport');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('That name is empty or already used.'), findsOneWidget);
      expect(find.text('Retail'), findsOneWidget);
    });

    harnessTest('archiving moves it down, and Restore brings it back', (tester) async {
      await start(tester, null);
      await open(tester);
      await tester.tap(find.byTooltip('Archive Travel'));
      await tester.pumpAndSettle();
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(find.text('Archived'), findsNothing);
    });

    harnessTest('the last active category cannot be archived', (tester) async {
      await start(tester, (s) async {
        await (s.db.update(s.db.categories)..where((c) => c.name.isNotValue('Other')))
            .write(const CategoriesCompanion(isArchived: Value(true)));
      });
      await open(tester);
      await tester.tap(find.byTooltip('Archive Other'));
      await tester.pumpAndSettle();
      expect(find.text('You need at least one active category.'), findsOneWidget);
    });
  });

  group('History', () {
    Future<void> seedHistory(Seed s) async {
      final db = s.db;
      Future<void> msg(String day, String role, {String? body, String? payload, String? status, String? type}) =>
          db.into(db.chatMessages).insert(ChatMessagesCompanion.insert(
                id: '${day}_${role}_${body ?? type}_${status ?? ''}',
                day: day,
                role: role,
                body: Value(body),
                cardType: Value(type),
                cardPayload: Value(payload),
                cardStatus: Value(status),
              ));
      String card(int paise, String item) => jsonEncode(AddExpenseProposal(
              amountPaise: paise, item: item, categoryName: 'Food & Dining', spentOn: '2026-10-23')
          .toJson());

      await msg('2026-10-23', 'user', body: 'chats 380');
      await msg('2026-10-23', 'card', type: 'add_expense', payload: card(38000, 'Chats'), status: 'confirmed');
      await msg('2026-10-23', 'user', body: 'food spend this week?');
      await msg('2026-10-23', 'assistant', body: 'You spent ₹1,890.');
      await msg('2026-10-22', 'card', type: 'add_expense', payload: card(105000, 'Petrol'), status: 'confirmed');
      // these must not appear:
      await msg('2026-10-22', 'card', type: 'add_expense', payload: card(1, 'Cancelled thing'), status: 'cancelled');
      await msg('2026-10-22', 'card', type: 'add_expense', payload: card(1, 'Pending thing'), status: 'pending');
      await msg('2026-10-24', 'user', body: "today's message");
    }

    Future<void> openHistory(WidgetTester tester) async {
      await tester.tap(find.descendant(of: find.byType(PillNavBar), matching: find.text('Chat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();
    }

    harnessTest('lists earlier days with a summary, newest first, and expands', (tester) async {
      await start(tester, seedHistory);
      await openHistory(tester);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('1 saved · 1 asked'), findsOneWidget);
      expect(find.text('Thu, 22 Oct'), findsOneWidget);
      expect(find.text('1 saved'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Yesterday')).dy,
          lessThan(tester.getTopLeft(find.text('Thu, 22 Oct')).dy));

      await tester.tap(find.text('Yesterday'));
      await tester.pumpAndSettle();
      expect(find.textContaining('₹380 Chats'), findsOneWidget);
      expect(find.text('food spend this week?'), findsOneWidget);
    });

    harnessTest("today's messages, cancelled and pending cards are not in History", (tester) async {
      await start(tester, seedHistory);
      await openHistory(tester);
      await tester.tap(find.text('Thu, 22 Oct'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Petrol'), findsOneWidget);
      expect(find.textContaining('Cancelled thing'), findsNothing);
      expect(find.textContaining('Pending thing'), findsNothing);
      expect(find.text("today's message"), findsNothing);
    });

    harnessTest('with no earlier chat it says so', (tester) async {
      await start(tester, null);
      await openHistory(tester);
      expect(find.text('Nothing earlier yet'), findsOneWidget);
    });

    harnessTest('Back returns to the chat', (tester) async {
      await start(tester, null);
      await openHistory(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('What did you spend?'), findsOneWidget);
    });
  });
}
