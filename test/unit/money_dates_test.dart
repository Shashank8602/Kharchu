import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/core/dates.dart';
import 'package:kharchu/core/money.dart';

void main() {
  group('money', () {
    test('rupees to paise rounds floating point noise', () {
      expect(rupeesToPaise(1000), 100000);
      expect(rupeesToPaise(0.1 + 0.2), 30);
      expect(rupeesToPaise(2.5), 250);
      expect(rupeesToPaise(19.99), 1999);
      expect(rupeesToPaise(1.005 * 100), 10050);
    });

    test('Indian digit grouping', () {
      expect(formatINR(0), '₹0');
      expect(formatINR(100000), '₹1,000');
      expect(formatINR(10000000), '₹1,00,000');
      expect(formatINR(1000000000), '₹1,00,00,000');
      expect(formatINR(2030000), '₹20,300');
    });

    test('decimals only when paise is non-zero', () {
      expect(formatINR(123456), '₹1,234.56');
      expect(formatINR(100050), '₹1,000.50');
      expect(formatINR(5), '₹0.05');
    });

    test('negative amounts', () {
      expect(formatINR(-250000), '-₹2,500');
      expect(formatINR(-1), '-₹0.01');
    });

    test('short axis labels', () {
      expect(formatINRShort(0), '₹0');
      expect(formatINRShort(40000), '₹400');
      expect(formatINRShort(400000), '₹4k');
      expect(formatINRShort(120000), '₹1.2k');
      expect(formatINRShort(15000000), '₹1.5L');
      expect(formatINRShort(1500000000), '₹1.5Cr');
    });
  });

  group('dates', () {
    test('parses valid ISO dates', () {
      expect(tryParseIso('2026-10-24'), isNotNull);
      expect(tryParseIso(' 2026-10-24 '), isNotNull);
    });

    test('rejects malformed and impossible dates', () {
      for (final bad in [
        '', 'today', '24-10-2026', '2026-1-5', '2026/10/24',
        '2026-13-01', '2026-00-10', '2026-02-30', '2026-02-31',
        '2026-04-31', '2026-02-29', '2026-10-32', '2026-10-00',
      ]) {
        expect(tryParseIso(bad), isNull, reason: bad);
      }
    });

    test('leap day is valid only in leap years', () {
      expect(tryParseIso('2028-02-29'), isNotNull);
      expect(tryParseIso('2100-02-29'), isNull); // 2100 is not a leap year
      expect(tryParseIso('2000-02-29'), isNotNull);
    });

    test('todayIst rolls over at 18:30 UTC', () {
      expect(todayIst(DateTime.utc(2026, 10, 24, 18, 29)), '2026-10-24');
      expect(todayIst(DateTime.utc(2026, 10, 24, 18, 30)), '2026-10-25');
      expect(todayIst(DateTime.utc(2026, 12, 31, 19, 0)), '2027-01-01');
    });

    test('addDays crosses month and year boundaries', () {
      expect(addDays('2026-10-31', 1), '2026-11-01');
      expect(addDays('2026-12-31', 1), '2027-01-01');
      expect(addDays('2026-03-01', -1), '2026-02-28');
      expect(addDays('2028-03-01', -1), '2028-02-29');
      expect(addDays('2026-10-24', -30), '2026-09-24');
    });

    test('monthRange', () {
      expect(monthRange('2026-10-24'), (from: '2026-10-01', to: '2026-10-31'));
      expect(monthRange('2026-02-10'), (from: '2026-02-01', to: '2026-02-28'));
      expect(monthRange('2028-02-10'), (from: '2028-02-01', to: '2028-02-29'));
      expect(monthRange('2026-12-31'), (from: '2026-12-01', to: '2026-12-31'));
    });

    test('previous and next month start across the year', () {
      expect(previousMonthStart('2026-01-15'), '2025-12-01');
      expect(nextMonthStart('2026-12-15'), '2027-01-01');
      expect(previousMonthStart('2026-10-24'), '2026-09-01');
    });

    test('daysLeftInMonth', () {
      expect(daysLeftInMonth('2026-10-24'), 7);
      expect(daysLeftInMonth('2026-10-31'), 0);
      expect(daysLeftInMonth('2026-10-24', includeToday: true), 8);
      expect(daysLeftInMonth('2026-02-01'), 27);
    });

    test('labels', () {
      expect(weekdayName('2026-10-24'), 'Saturday');
      expect(dayLabel('2026-10-24'), 'Sat, 24 Oct');
      expect(fullDateLabel('2026-10-24'), '24 Oct 2026');
      expect(monthName('2026-10-24'), 'October');
    });
  });
}
