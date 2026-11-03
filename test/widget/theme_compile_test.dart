import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/core/theme.dart';

void main() {
  setUp(() => KharchuFonts.enabled = false);

  test('both themes build and expose the color extension', () {
    for (final b in Brightness.values) {
      final t = buildTheme(b);
      expect(t.extension<KharchuColors>(), isNotNull);
      expect(t.brightness, b);
    }
  });
}
