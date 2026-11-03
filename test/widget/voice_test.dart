import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/repositories/expense_repository.dart';

import '../unit/fake_http.dart';
import 'harness.dart';

late Harness h;

Future<void> start(WidgetTester tester) async {
  h = await Harness.create(key: 'gsk_abcdefghijklmnopqrstuvwxyz');
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(h.app());
  await tester.pumpAndSettle();
}

void transcript(String text) => h.adapter.script.add((_) => json({'text': text}));

Map<String, dynamic> addCall() => chatCompletion(calls: [
      {
        'id': 'c1',
        'type': 'function',
        'function': {
          'name': 'propose_add_expense',
          'arguments': jsonEncode({
            'amount_rupees': 1000,
            'item': 'Chats',
            'category': 'Food & Dining',
            'spent_on': '2026-10-24',
          }),
        },
      }
    ]);

Future<void> tapMic(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Speak'));
  await tester.pump();
  await tester.pump();
}

Future<void> record(WidgetTester tester, {int seconds = 3}) async {
  await tapMic(tester);
  await tester.pump(Duration(seconds: seconds));
}

Future<void> stop(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Stop and send'));
  await tester.pumpAndSettle();
}

void main() {
  group('the mic button', () {
    harnessTest('shows when the box is empty and gives way to Send when typing', (tester) async {
      await start(tester);
      expect(find.byTooltip('Speak'), findsOneWidget);
      expect(find.byTooltip('Send'), findsNothing);
      await tester.enterText(find.byType(TextField), 'chats');
      await tester.pump();
      expect(find.byTooltip('Speak'), findsNothing);
      expect(find.byTooltip('Send'), findsOneWidget);
    });
  });

  group('recording', () {
    harnessTest('shows a timer and live bars in place of the text box', (tester) async {
      await start(tester);
      await tapMic(tester);
      expect(h.recorder.starts, 1);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('0:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('0:03'), findsOneWidget);
      h.recorder.emitLevel(0.7);
      h.recorder.emitLevel(0.2);
      await tester.pump();
      expect(find.byTooltip('Stop and send'), findsOneWidget);
      expect(find.byTooltip('Cancel recording'), findsOneWidget);
    });

    harnessTest('the timer counts minutes', (tester) async {
      await start(tester);
      await record(tester, seconds: 75);
      expect(find.text('0:59'), findsNothing);
    });

    harnessTest('tapping the mic twice quickly starts one recording', (tester) async {
      await start(tester);
      await tester.tap(find.byTooltip('Speak'));
      await tester.tap(find.byTooltip('Speak'), warnIfMissed: false);
      await tester.pump();
      await tester.pump();
      expect(h.recorder.starts, 1);
    });

    harnessTest('Cancel throws the recording away and sends nothing', (tester) async {
      await start(tester);
      await record(tester);
      await tester.tap(find.byTooltip('Cancel recording'));
      await tester.pumpAndSettle();
      expect(h.recorder.cancels, 1);
      expect(h.adapter.requests, isEmpty);
      expect(find.byType(TextField), findsOneWidget);
    });

    harnessTest('leaving the app while recording stops the microphone', (tester) async {
      await start(tester);
      await record(tester);
      for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      expect(h.recorder.cancels, 1, reason: 'the microphone is released at once');
      // frames are not drawn while paused, so come back before looking at the screen
      for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pumpAndSettle();
      expect(h.recorder.cancels, 1);
      expect(h.adapter.requests, isEmpty);
      expect(find.byType(TextField), findsOneWidget);
    });

    harnessTest('a system permission dialog (inactive) does not cancel the recording', (tester) async {
      await start(tester);
      await record(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(h.recorder.cancels, 0);
      expect(find.byTooltip('Stop and send'), findsOneWidget);
    });
  });

  group('stop, transcribe and send', () {
    harnessTest('the spoken words become a message and the usual card', (tester) async {
      await start(tester);
      transcript('chats 1000');
      h.adapter.script.add((_) => json(addCall()));
      await record(tester);
      await stop(tester);

      expect(h.recorder.stops, 1);
      expect(find.text('chats 1000'), findsOneWidget); // shown like a typed message
      expect(find.text('Save'), findsOneWidget);
      expect(h.adapter.requests.first.path, '/audio/transcriptions');
      expect(h.adapter.requests.last.path, '/chat/completions');
    });

    harnessTest('shows "Transcribing…" while waiting and blocks typing', (tester) async {
      await start(tester);
      final gate = Completer<void>();
      h.adapter.script.add((_) async {
        await gate.future;
        return json({'text': 'chats 1000'});
      });
      h.adapter.script.add((_) => json(addCall()));
      await record(tester);
      await tester.tap(find.byTooltip('Stop and send'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Transcribing…'), findsOneWidget);
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.mic_none)).onPressed, isNull);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Transcribing…'), findsNothing);
      expect(find.text('Save'), findsOneWidget);
    });

    harnessTest('an expense saved from a voice message is marked as voice', (tester) async {
      await start(tester);
      transcript('chats 1000');
      h.adapter.script.add((_) => json(addCall()));
      await record(tester);
      await stop(tester);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
      final rows = await tester.runAsync(() => ExpenseRepository(h.db).find(const ExpenseFilter()));
      expect(rows!.single.expense.source, 'voice');
      expect(rows.single.expense.rawText, 'chats 1000');
    });

    harnessTest('the recording is limited to 60 seconds and then sent automatically',
        (tester) async {
      await start(tester);
      transcript('chats 1000');
      h.adapter.script.add((_) => json(addCall()));
      await tapMic(tester);
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      expect(h.recorder.stops, 1);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('what can go wrong', () {
    harnessTest('microphone not allowed: says how to fix it, records nothing', (tester) async {
      await start(tester);
      h.recorder.allowed = false;
      await tapMic(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('Allow the microphone'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(h.adapter.requests, isEmpty);
    });

    harnessTest('the microphone failing to start is reported', (tester) async {
      await start(tester);
      h.recorder.throwOnStart = true;
      await tapMic(tester);
      await tester.pumpAndSettle();
      expect(find.text("Couldn't start the microphone."), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    harnessTest('a recording under a second is refused without calling Groq', (tester) async {
      await start(tester);
      await tapMic(tester);
      await stop(tester);
      expect(find.textContaining('Too short'), findsOneWidget);
      expect(h.adapter.requests, isEmpty);
      expect(find.byType(TextField), findsOneWidget);
    });

    harnessTest('silence gives a clear message and no chat message', (tester) async {
      await start(tester);
      transcript('   ');
      await record(tester);
      await stop(tester);
      expect(find.text("Couldn't hear anything. Try again."), findsOneWidget);
      expect(h.adapter.requests.length, 1, reason: 'only the transcription, no chat request');
    });

    harnessTest('an empty recording file is reported', (tester) async {
      await start(tester);
      h.recorder.audio = null;
      await record(tester);
      await stop(tester);
      expect(find.text("Couldn't record that. Try again."), findsOneWidget);
      expect(h.adapter.requests, isEmpty);
    });

    harnessTest('a rejected key is reported and nothing is added to the chat', (tester) async {
      await start(tester);
      h.adapter.script.add((_) => errorBody(401, 'bad'));
      await record(tester);
      await stop(tester);
      expect(find.text('Groq rejected the key.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    harnessTest('offline is reported and the mic works again afterwards', (tester) async {
      await start(tester);
      h.adapter.script.add((o) => throw DioExceptionShim.offline(o));
      await record(tester);
      await stop(tester);
      expect(find.text("Couldn't reach Groq."), findsOneWidget);

      transcript('chats 1000');
      h.adapter.script.add((_) => json(addCall()));
      await record(tester);
      await stop(tester);
      expect(find.text('Save'), findsOneWidget);
    });

    harnessTest('rate limiting is reported with the wait', (tester) async {
      await start(tester);
      h.adapter.script.add((_) => errorBody(429, 'x', headers: {'retry-after': ['9']}));
      await record(tester);
      await stop(tester);
      expect(find.textContaining('9s'), findsOneWidget);
    });
  });
}
