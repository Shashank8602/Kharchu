import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' show WidgetTester, testWidgets;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kharchu/app.dart';
import 'package:kharchu/core/theme.dart';
import 'package:kharchu/data/db/app_database.dart';
import 'package:kharchu/data/key_store.dart';
import 'package:kharchu/providers.dart';
import 'package:kharchu/services/file_gateway.dart';
import 'package:kharchu/services/groq/groq_client.dart';
import 'package:kharchu/services/groq/rate_limiter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/fake_http.dart';

/// Everything a widget test needs: in-memory database, fake secure storage,
/// scripted Groq responses, mock preferences, and a pinned clock.
class Harness {
  Harness._(this.prefs, this.keys, this.adapter, this.db, this.now);

  final SharedPreferences prefs;
  final MemoryKeyStore keys;
  final FakeAdapter adapter;
  final AppDatabase db;
  final DateTime now;

  /// Stands in for Android's Save and Open dialogs.
  final FakeGateway files = FakeGateway();

  static Future<Harness> create({
    Map<String, Object> prefs = const {},
    String? key,
    DateTime? now,
  }) async {
    KharchuFonts.enabled = false;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues(prefs);
    return Harness._(
      await SharedPreferences.getInstance(),
      MemoryKeyStore(key),
      FakeAdapter([]),
      AppDatabase(NativeDatabase.memory()),
      now ?? DateTime.utc(2026, 10, 24, 6, 30),
    );
  }

  GroqClient get groq => GroqClient(
        dio: Dio(BaseOptions(baseUrl: GroqClient.baseUrl))
          ..httpClientAdapter = adapter,
        keyStore: keys,
        models: () => const ModelConfig(
          chatModel: 'openai/gpt-oss-120b',
          fallbackModel: 'openai/gpt-oss-20b',
          voiceModel: 'whisper-large-v3',
        ),
        limiter: RateLimiter(delay: (_) async {}),
      );

  /// Overrides with a custom clock (tests that move time use this).
  List<Override> overridesWith(DateTime Function() clock) => [
        sharedPrefsProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        keyStoreProvider.overrideWithValue(keys),
        groqClientProvider.overrideWithValue(groq),
        clockProvider.overrideWithValue(clock),
        fileGatewayProvider.overrideWithValue(files),
      ];

  List<Override> get overrides => overridesWith(() => now);

  Widget app() =>
      ProviderScope(overrides: overrides, child: const KharchuApp());
}

/// `testWidgets`, plus a clean shutdown: disposing the tree cancels Drift's
/// live queries, which schedule a zero-length timer; letting it fire avoids
/// "a Timer is still pending" at the end of every test that shows the Chat.
void harnessTest(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}

/// Records what the app tries to save, and hands back whatever file a test
/// chooses to "pick".
class FakeGateway implements FileGateway {
  final saved = <({String name, Uint8List bytes, String mime})>[];

  /// What the Save dialog returns: false means the user cancelled.
  bool saveResult = true;

  /// What the Open dialog returns: null means the user cancelled.
  Uint8List? toPick;

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
  }) async {
    if (saveResult) saved.add((name: fileName, bytes: bytes, mime: mimeType));
    return saveResult;
  }

  @override
  Future<Uint8List?> pick({String? dialogTitle}) async => toPick;
}
