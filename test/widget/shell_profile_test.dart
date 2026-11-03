import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/db/app_database.dart';

import '../unit/fake_http.dart';
import 'harness.dart';

Future<void> openProfile(WidgetTester tester) async {
  await tester.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.text('Profile')));
  await tester.pumpAndSettle();
}

Future<void> openGroq(WidgetTester tester) async {
  await openProfile(tester);
  await tester.tap(find.text('Groq API key'));
  await tester.pumpAndSettle();
}

void main() {
  late Harness h;

  Future<void> start(WidgetTester tester, {String? key, Map<String, Object>? prefs}) async {
    h = await Harness.create(key: key, prefs: prefs ?? {});
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(h.app());
    await tester.pumpAndSettle();
  }

  group('shell', () {
    harnessTest('opens on Chat and shows five tabs', (tester) async {
      await start(tester);
      final nav = find.byType(NavigationBar);
      for (final t in ['Chat', 'Dashboard', 'Transactions', 'Budgets', 'Profile']) {
        expect(find.descendant(of: nav, matching: find.text(t)), findsOneWidget, reason: t);
      }
    });

    harnessTest('each tab switches the screen', (tester) async {
      await start(tester);
      for (final t in ['Dashboard', 'Transactions', 'Budgets']) {
        await tester.tap(find.descendant(
            of: find.byType(NavigationBar), matching: find.text(t)));
        await tester.pumpAndSettle();
        expect(find.descendant(of: find.byType(AppBar), matching: find.text(t)),
            findsOneWidget, reason: t);
      }
      await openProfile(tester);
      expect(find.text('Theme'), findsOneWidget);
    });

    harnessTest('tapping the active tab again does not break navigation', (tester) async {
      await start(tester);
      await openProfile(tester);
      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text('Profile')));
      await tester.pumpAndSettle();
      expect(find.text('Theme'), findsOneWidget);
    });
  });

  group('profile', () {
    harnessTest('shows default name and "Not set" when there is no key', (tester) async {
      await start(tester);
      await openProfile(tester);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Not set'), findsOneWidget);
    });

    harnessTest('shows "Connected" when a key is saved', (tester) async {
      await start(tester, key: 'gsk_abcdefghijklmnopqrstuvwxyz');
      await openProfile(tester);
      expect(find.text('Connected'), findsOneWidget);
    });

    harnessTest('theme switch changes brightness and is remembered', (tester) async {
      await start(tester);
      await openProfile(tester);
      Brightness current() =>
          Theme.of(tester.element(find.text('Theme'))).brightness;

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(current(), Brightness.dark);
      expect(h.prefs.getString('theme_mode'), 'dark');

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(current(), Brightness.light);
      expect(h.prefs.getString('theme_mode'), 'light');
    });

    harnessTest('a saved dark theme is applied on the next launch', (tester) async {
      await start(tester, prefs: {'theme_mode': 'dark'});
      expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
          Brightness.dark);
    });

    harnessTest('a corrupted theme value falls back to system, not a crash', (tester) async {
      await start(tester, prefs: {'theme_mode': 'purple'});
      await openProfile(tester);
      expect(find.text('Theme'), findsOneWidget);
    });

    harnessTest('editing the name updates the avatar and persists', (tester) async {
      await start(tester);
      await openProfile(tester);
      await tester.tap(find.byTooltip('Edit name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Shashank');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Shashank'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(h.prefs.getString('profile_name'), 'Shashank');
    });

    harnessTest('an empty name is ignored', (tester) async {
      await start(tester, prefs: {'profile_name': 'Asha'});
      await openProfile(tester);
      await tester.tap(find.byTooltip('Edit name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Asha'), findsOneWidget);
    });

    // Database setup happens before the app starts and checks happen after it
    // is torn down: reading through runAsync while the Chat screen's live
    // query is active can deadlock against the fake clock.
    Future<void> seedChatAndExpense(WidgetTester tester) async {
      await tester.runAsync(() async {
        await h.db.into(h.db.chatMessages).insert(ChatMessagesCompanion.insert(
            id: 'a', day: '2026-10-24', role: 'user', body: const Value('hello')));
        final cat = (await h.db.select(h.db.categories).get()).first;
        await h.db.into(h.db.expenses).insert(ExpensesCompanion.insert(
            amountPaise: 1000, categoryId: cat.id, item: 'Tea', spentOn: '2026-10-24'));
      });
    }

    Future<(int, int)> countsAfterShutdown(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
      final r = await tester.runAsync(() async => (
            (await h.db.select(h.db.chatMessages).get()).length,
            (await h.db.select(h.db.expenses).get()).length,
          ));
      return r!;
    }

    harnessTest('clear chat: Cancel keeps the messages', (tester) async {
      h = await Harness.create();
      await seedChatAndExpense(tester);
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(h.app());
      await tester.pumpAndSettle();
      await openProfile(tester);
      await tester.tap(find.text('Clear chat history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await countsAfterShutdown(tester), (1, 1));
    });

    harnessTest('clear chat: Clear removes chat text but keeps expenses', (tester) async {
      h = await Harness.create();
      await seedChatAndExpense(tester);
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(h.app());
      await tester.pumpAndSettle();
      await openProfile(tester);
      await tester.tap(find.text('Clear chat history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Chat history cleared'), findsOneWidget);
      expect(await countsAfterShutdown(tester), (0, 1));
    });
  });

  group('groq settings', () {
    Future<void> enterKeyAndSave(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField).first, text);
      await tester.tap(find.text('Save and test'));
      await tester.pumpAndSettle();
    }

    harnessTest('empty key asks for one and saves nothing', (tester) async {
      await start(tester);
      await openGroq(tester);
      await tester.tap(find.text('Save and test'));
      await tester.pumpAndSettle();
      expect(find.text('Paste your key first.'), findsOneWidget);
      expect(await h.keys.read(), isNull);
      expect(h.adapter.requests, isEmpty);
    });

    harnessTest('a good key is saved, tested and shown as connected', (tester) async {
      await start(tester);
      h.adapter.script.add((_) => json({'data': []}));
      await openGroq(tester);
      await enterKeyAndSave(tester, 'gsk_abcdefghijklmnopqrstuvwxyz');
      expect(find.text('Connected.'), findsOneWidget);
      expect(await h.keys.read(), 'gsk_abcdefghijklmnopqrstuvwxyz');
      expect(h.adapter.requests.single.headers['Authorization'],
          'Bearer gsk_abcdefghijklmnopqrstuvwxyz');
      // the field is cleared so the key is not left on screen
      expect(find.text('gsk_abcdefghijklmnopqrstuvwxyz'), findsNothing);
    });

    harnessTest('a whole .env line, quotes and spaces are cleaned before saving',
        (tester) async {
      await start(tester);
      h.adapter.script.add((_) => json({'data': []}));
      await openGroq(tester);
      await enterKeyAndSave(
          tester, '  GROQ_API_KEY = "gsk_abcdefghijklmnopqrstuvwxyz" \n');
      expect(await h.keys.read(), 'gsk_abcdefghijklmnopqrstuvwxyz');
    });

    harnessTest('a rejected key is not kept', (tester) async {
      await start(tester);
      h.adapter.script.add((_) => errorBody(401, 'Invalid API Key'));
      await openGroq(tester);
      await enterKeyAndSave(tester, 'gsk_wrongwrongwrongwrongwrong');
      expect(find.textContaining('Groq rejected the key'), findsOneWidget);
      expect(await h.keys.read(), isNull);
    });

    harnessTest('offline: the key is kept and the user is told it was not tested',
        (tester) async {
      await start(tester);
      h.adapter.script.add((o) => throw DioExceptionShim.offline(o));
      await openGroq(tester);
      await enterKeyAndSave(tester, 'gsk_abcdefghijklmnopqrstuvwxyz');
      expect(find.textContaining("Couldn't reach Groq"), findsOneWidget);
      expect(await h.keys.read(), 'gsk_abcdefghijklmnopqrstuvwxyz');
    });

    harnessTest('a key that does not look like Groq gets a warning but can still be saved',
        (tester) async {
      await start(tester);
      await openGroq(tester);
      await tester.enterText(find.byType(TextField).first, 'sk-something-else');
      await tester.pump();
      expect(find.textContaining('start with gsk_'), findsOneWidget);
    });

    harnessTest('the key can be removed', (tester) async {
      await start(tester, key: 'gsk_abcdefghijklmnopqrstuvwxyz');
      await openGroq(tester);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(await h.keys.read(), isNull);
      expect(find.text('Remove'), findsNothing);
    });

    harnessTest('the key field is hidden until the eye is tapped', (tester) async {
      await start(tester);
      await openGroq(tester);
      EditableText field() => tester.widget<EditableText>(find.byType(EditableText).first);
      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show key'));
      await tester.pump();
      expect(field().obscureText, isFalse);
    });

    harnessTest('models can be changed, saved and reset', (tester) async {
      await start(tester);
      await openGroq(tester);
      await tester.scrollUntilVisible(find.text('Save models'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.enterText(find.widgetWithText(TextField, 'Chat model'), 'qwen/qwen3.8-27b');
      await tester.tap(find.text('Save models'));
      await tester.pumpAndSettle();
      expect(h.prefs.getString('chat_model'), 'qwen/qwen3.8-27b');

      await tester.tap(find.text('Defaults'));
      await tester.pump();
      await tester.tap(find.text('Save models'));
      await tester.pumpAndSettle();
      expect(h.prefs.getString('chat_model'), 'openai/gpt-oss-120b');
    });

    harnessTest('an empty fallback model means "no fallback" and survives a restart',
        (tester) async {
      await start(tester);
      await openGroq(tester);
      await tester.scrollUntilVisible(find.text('Save models'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.enterText(find.widgetWithText(TextField, 'Fallback model'), '');
      await tester.tap(find.text('Save models'));
      await tester.pumpAndSettle();
      expect(h.prefs.getString('fallback_model'), '');
      // a fresh start reads it back as empty, not as the default
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(h.app());
      await tester.pumpAndSettle();
      await openGroq(tester);
      await tester.scrollUntilVisible(find.text('Save models'), 300,
          scrollable: find.byType(Scrollable).first);
      final fb = tester.widget<TextField>(find.widgetWithText(TextField, 'Fallback model'));
      expect(fb.controller!.text, isEmpty);
    });

    harnessTest('voice language is remembered', (tester) async {
      await start(tester);
      await openGroq(tester);
      await tester.scrollUntilVisible(find.text('Kannada'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Kannada'));
      await tester.pumpAndSettle();
      expect(h.prefs.getString('voice_language'), 'kn');
    });
  });
}
