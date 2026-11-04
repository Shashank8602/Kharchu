import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/dates.dart';
import 'data/db/app_database.dart';
import 'data/key_store.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'data/repositories/lending_repository.dart';
import 'data/settings_store.dart';
import 'services/agent/agent_service.dart';
import 'services/agent/tool_executor.dart';
import 'services/budget_alerts.dart';
import 'services/backup_service.dart';
import 'services/card_actions.dart';
import 'services/export_service.dart';
import 'services/file_gateway.dart';
import 'services/voice_recorder.dart';
import 'services/groq/groq_client.dart';

/// Overridden in main() once SharedPreferences has loaded.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

final settingsStoreProvider =
    Provider((ref) => SettingsStore(ref.watch(sharedPrefsProvider)));

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsStoreProvider).load();

  Future<void> _set(AppSettings next) async {
    state = next;
    await ref.read(settingsStoreProvider).save(next);
  }

  Future<void> setThemeMode(ThemeMode m) => _set(state.copyWith(themeMode: m));

  Future<void> setProfileName(String name) {
    final n = name.trim();
    if (n.isEmpty) return Future.value();
    return _set(state.copyWith(profileName: n.length > 40 ? n.substring(0, 40) : n));
  }

  Future<void> setModels({String? chat, String? fallback, String? voice}) =>
      _set(state.copyWith(
        chatModel: chat?.trim().isEmpty ?? true ? null : chat!.trim(),
        fallbackModel: fallback?.trim(),
        voiceModel: voice?.trim().isEmpty ?? true ? null : voice!.trim(),
      ));

  Future<void> setVoiceLanguage(String lang) =>
      _set(state.copyWith(voiceLanguage: lang));

  Future<void> markBackupDone(DateTime when) =>
      _set(state.copyWith(lastBackupAt: when.toIso8601String()));

  Future<void> ensureSince(String todayIso) async {
    if (state.sinceIso == null) await _set(state.copyWith(sinceIso: todayIso));
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final expenseRepoProvider =
    Provider((ref) => ExpenseRepository(ref.watch(databaseProvider)));
final categoryRepoProvider =
    Provider((ref) => CategoryRepository(ref.watch(databaseProvider)));
final budgetRepoProvider =
    Provider((ref) => BudgetRepository(ref.watch(databaseProvider)));
final lendingRepoProvider =
    Provider((ref) => LendingRepository(ref.watch(databaseProvider)));
final chatRepoProvider =
    Provider((ref) => ChatRepository(ref.watch(databaseProvider)));

final keyStoreProvider = Provider<KeyStore>((ref) => SecureKeyStore());

/// Whether a Groq key is saved. Invalidate after saving or deleting it.
final hasKeyProvider = FutureProvider.autoDispose<bool>(
  (ref) async => (await ref.watch(keyStoreProvider).read()) != null,
);

final groqClientProvider = Provider<GroqClient>((ref) {
  return GroqClient(
    dio: GroqClient.buildDio(),
    keyStore: ref.watch(keyStoreProvider),
    models: () {
      final s = ref.read(settingsProvider);
      return ModelConfig(
        chatModel: s.chatModel,
        fallbackModel: s.fallbackModel,
        voiceModel: s.voiceModel,
        voiceLanguage: s.voiceLanguage,
      );
    },
  );
});

/// The clock. Tests override this to pin "now".
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Today's date in IST, read fresh each time so it is right after midnight.
final todayFnProvider = Provider<String Function()>((ref) {
  final clock = ref.watch(clockProvider);
  return () => todayIst(clock());
});

final toolExecutorProvider = Provider((ref) => ToolExecutor(
      expenses: ref.watch(expenseRepoProvider),
      categories: ref.watch(categoryRepoProvider),
      budgets: ref.watch(budgetRepoProvider),
      lending: ref.watch(lendingRepoProvider),
      today: ref.watch(todayFnProvider),
    ));

final budgetAlertsProvider = Provider((ref) => BudgetAlerts(
      expenses: ref.watch(expenseRepoProvider),
      budgets: ref.watch(budgetRepoProvider),
      categories: ref.watch(categoryRepoProvider),
    ));

final agentServiceProvider = Provider((ref) => AgentService(
      groq: ref.watch(groqClientProvider),
      chat: ref.watch(chatRepoProvider),
      executor: ref.watch(toolExecutorProvider),
      expenses: ref.watch(expenseRepoProvider),
      categories: ref.watch(categoryRepoProvider),
      lending: ref.watch(lendingRepoProvider),
      budgets: ref.watch(budgetRepoProvider),
      today: ref.watch(todayFnProvider),
    ));

final cardActionsProvider = Provider((ref) => CardActions(
      db: ref.watch(databaseProvider),
      expenses: ref.watch(expenseRepoProvider),
      categories: ref.watch(categoryRepoProvider),
      budgets: ref.watch(budgetRepoProvider),
      lending: ref.watch(lendingRepoProvider),
      chat: ref.watch(chatRepoProvider),
      executor: ref.watch(toolExecutorProvider),
      alerts: ref.watch(budgetAlertsProvider),
      today: ref.watch(todayFnProvider),
    ));

final fileGatewayProvider = Provider<FileGateway>((ref) => SystemFileGateway());

final backupServiceProvider =
    Provider((ref) => BackupService(ref.watch(databaseProvider)));

final exportServiceProvider =
    Provider((ref) => ExportService(ref.watch(expenseRepoProvider)));

final voiceRecorderProvider = Provider<VoiceRecorder>((ref) {
  final recorder = DeviceVoiceRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});
