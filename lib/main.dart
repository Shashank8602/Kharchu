import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/dates.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
  );
  final today = todayIst();
  await container.read(settingsProvider.notifier).ensureSince(today);
  try {
    // chat text older than 30 days goes; entries, loans and budgets never do
    await container.read(chatRepoProvider).purgeOlderThan(today);
  } catch (_) {
    // a failed tidy-up must never stop the app from opening
  }
  runApp(
    UncontrolledProviderScope(container: container, child: const KharchuApp()),
  );
}
