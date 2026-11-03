import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/core/charts.dart';

void main() {
  test('niceAxisMax rounds up to a tidy top value', () {
    int rupees(int paise) => niceAxisMax(paise) ~/ 100;
    expect(rupees(0), 1000); // an empty month still gets a sensible scale
    expect(rupees(50000), 1000); // ₹500
    expect(rupees(100000), 1000); // ₹1,000 exactly
    expect(rupees(100100), 1500);
    expect(rupees(190000), 2000);
    expect(rupees(240000), 2500);
    expect(rupees(390000), 4000); // the mockup's ₹3,900 peak → ₹4k
    expect(rupees(480000), 5000);
    expect(rupees(510000), 7500);
    expect(rupees(900000), 10000);
    expect(rupees(12345600), 150000);
  });

  test('the result is never below the value and never absurdly above it', () {
    for (final paise in [1, 999, 100000, 123456, 987654, 5555555, 99999999]) {
      final top = niceAxisMax(paise);
      expect(top, greaterThanOrEqualTo(paise));
      if (paise >= 100000) expect(top, lessThanOrEqualTo(paise * 2));
    }
  });
}
