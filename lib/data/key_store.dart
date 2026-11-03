import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the Groq key lives. The real one uses the Android Keystore; tests
/// use [MemoryKeyStore]. The key is never written to backups or logs.
abstract class KeyStore {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> delete();
}

class SecureKeyStore implements KeyStore {
  SecureKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _name = 'groq_api_key';

  @override
  Future<String?> read() async {
    try {
      final v = await _storage.read(key: _name);
      return (v == null || v.trim().isEmpty) ? null : v.trim();
    } catch (_) {
      // A corrupted keystore entry (for example after a restore from a
      // device backup) must not crash the app; treat it as "no key".
      return null;
    }
  }

  @override
  Future<void> write(String key) => _storage.write(key: _name, value: key.trim());

  @override
  Future<void> delete() => _storage.delete(key: _name);
}

class MemoryKeyStore implements KeyStore {
  MemoryKeyStore([this._key]);
  String? _key;

  @override
  Future<String?> read() async =>
      (_key == null || _key!.trim().isEmpty) ? null : _key!.trim();

  @override
  Future<void> write(String key) async => _key = key.trim();

  @override
  Future<void> delete() async => _key = null;
}

/// Cleans up what people paste: surrounding spaces or quotes, a "Bearer "
/// prefix, or a whole `GROQ_API_KEY=...` line copied from a .env file.
String cleanApiKey(String raw) {
  var k = raw.trim();
  k = k.replaceFirst(
      RegExp(r'^(export\s+)?GROQ_API_KEY\s*=\s*', caseSensitive: false), '');
  k = k.replaceFirst(RegExp(r'^Bearer\s+', caseSensitive: false), '');
  return k.replaceAll(RegExp(r'''["'\s]'''), '');
}

/// Groq keys start with gsk_. Used only to show a gentle warning.
bool looksLikeGroqKey(String key) => key.startsWith('gsk_') && key.length >= 20;
