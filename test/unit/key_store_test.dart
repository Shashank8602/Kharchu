import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/key_store.dart';

void main() {
  group('cleanApiKey', () {
    test('plain key is unchanged', () {
      expect(cleanApiKey('gsk_abc123'), 'gsk_abc123');
    });

    test('strips spaces, newlines, tabs and quotes', () {
      expect(cleanApiKey('  gsk_abc123 \n'), 'gsk_abc123');
      expect(cleanApiKey('"gsk_abc123"'), 'gsk_abc123');
      expect(cleanApiKey("'gsk_abc123'"), 'gsk_abc123');
      expect(cleanApiKey('gsk_abc\t123'), 'gsk_abc123');
    });

    test('strips a pasted .env line in any form', () {
      expect(cleanApiKey('GROQ_API_KEY=gsk_abc123'), 'gsk_abc123');
      expect(cleanApiKey('GROQ_API_KEY = "gsk_abc123"'), 'gsk_abc123');
      expect(cleanApiKey('export GROQ_API_KEY=gsk_abc123'), 'gsk_abc123');
      expect(cleanApiKey('groq_api_key=gsk_abc123'), 'gsk_abc123');
    });

    test('strips a Bearer prefix', () {
      expect(cleanApiKey('Bearer gsk_abc123'), 'gsk_abc123');
      expect(cleanApiKey('bearer   gsk_abc123'), 'gsk_abc123');
    });

    test('empty and whitespace-only become empty', () {
      expect(cleanApiKey(''), '');
      expect(cleanApiKey('   \n '), '');
    });
  });

  test('looksLikeGroqKey', () {
    expect(looksLikeGroqKey('gsk_abcdefghijklmnopqrstuvwxyz'), isTrue);
    expect(looksLikeGroqKey('gsk_short'), isFalse);
    expect(looksLikeGroqKey('sk-abcdefghijklmnopqrstuvwxyz'), isFalse);
    expect(looksLikeGroqKey(''), isFalse);
  });

  test('MemoryKeyStore round trip, trimming, delete', () async {
    final s = MemoryKeyStore();
    expect(await s.read(), isNull);
    await s.write('  gsk_x  ');
    expect(await s.read(), 'gsk_x');
    await s.delete();
    expect(await s.read(), isNull);
    expect(await MemoryKeyStore('   ').read(), isNull);
  });
}
