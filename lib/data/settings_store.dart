import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Defaults verified against Groq's live model list on 2026-11-03.
const defaultChatModel = 'openai/gpt-oss-120b';
const defaultFallbackModel = 'openai/gpt-oss-20b';
const defaultVoiceModel = 'whisper-large-v3';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.chatModel = defaultChatModel,
    this.fallbackModel = defaultFallbackModel,
    this.voiceModel = defaultVoiceModel,
    this.voiceLanguage = 'auto',
    this.profileName = 'You',
    this.lastBackupAt,
    this.sinceIso,
  });

  final ThemeMode themeMode;
  final String chatModel;
  final String fallbackModel;
  final String voiceModel;

  /// 'auto', 'en' or 'kn'.
  final String voiceLanguage;
  final String profileName;

  /// ISO timestamp of the last successful backup, or null.
  final String? lastBackupAt;

  /// First day the app was used ('YYYY-MM-DD').
  final String? sinceIso;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? chatModel,
    String? fallbackModel,
    String? voiceModel,
    String? voiceLanguage,
    String? profileName,
    String? lastBackupAt,
    String? sinceIso,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        chatModel: chatModel ?? this.chatModel,
        fallbackModel: fallbackModel ?? this.fallbackModel,
        voiceModel: voiceModel ?? this.voiceModel,
        voiceLanguage: voiceLanguage ?? this.voiceLanguage,
        profileName: profileName ?? this.profileName,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
        sinceIso: sinceIso ?? this.sinceIso,
      );
}

class SettingsStore {
  SettingsStore(this._prefs);
  final SharedPreferences _prefs;

  static const _theme = 'theme_mode';
  static const _chat = 'chat_model';
  static const _fallback = 'fallback_model';
  static const _voice = 'voice_model';
  static const _voiceLang = 'voice_language';
  static const _name = 'profile_name';
  static const _backup = 'last_backup_at';
  static const _since = 'since';

  AppSettings load() => AppSettings(
        themeMode: _parseTheme(_prefs.getString(_theme)),
        chatModel: _nonEmpty(_prefs.getString(_chat)) ?? defaultChatModel,
        // An empty fallback is a deliberate choice ("no fallback"), unlike the
        // other models where empty means "use the default".
        fallbackModel: _prefs.containsKey(_fallback)
            ? (_prefs.getString(_fallback) ?? '').trim()
            : defaultFallbackModel,
        voiceModel: _nonEmpty(_prefs.getString(_voice)) ?? defaultVoiceModel,
        voiceLanguage: _parseLang(_prefs.getString(_voiceLang)),
        profileName: _nonEmpty(_prefs.getString(_name)) ?? 'You',
        lastBackupAt: _prefs.getString(_backup),
        sinceIso: _prefs.getString(_since),
      );

  Future<void> save(AppSettings s) async {
    await _prefs.setString(_theme, s.themeMode.name);
    await _prefs.setString(_chat, s.chatModel);
    await _prefs.setString(_fallback, s.fallbackModel);
    await _prefs.setString(_voice, s.voiceModel);
    await _prefs.setString(_voiceLang, s.voiceLanguage);
    await _prefs.setString(_name, s.profileName);
    if (s.lastBackupAt != null) await _prefs.setString(_backup, s.lastBackupAt!);
    if (s.sinceIso != null) await _prefs.setString(_since, s.sinceIso!);
  }

  static ThemeMode _parseTheme(String? v) => ThemeMode.values.firstWhere(
        (m) => m.name == v,
        orElse: () => ThemeMode.system,
      );

  static String _parseLang(String? v) =>
      (v == 'en' || v == 'kn') ? v! : 'auto';

  static String? _nonEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}
