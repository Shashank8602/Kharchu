import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/services/agent/parsing.dart';

void main() {
  group('parseRupees', () {
    test('numbers and numeric text', () {
      expect(parseRupees(1000), 1000);
      expect(parseRupees(12.5), 12.5);
      expect(parseRupees('1000'), 1000);
      expect(parseRupees(' 99.50 '), 99.5);
      expect(parseRupees('.5'), 0.5);
    });

    test('currency symbols, words and separators', () {
      expect(parseRupees('₹1,000'), 1000);
      expect(parseRupees('Rs.1000'), 1000);
      expect(parseRupees('rs 1,00,000'), 100000);
      expect(parseRupees('1000 rupees'), 1000);
      expect(parseRupees('INR 450'), 450);
      expect(parseRupees('500/-'), 500);
    });

    test('shorthand units', () {
      expect(parseRupees('1k'), 1000);
      expect(parseRupees('2.5k'), 2500);
      expect(parseRupees('1.5 lakh'), 150000);
      expect(parseRupees('2L'), 200000);
      expect(parseRupees('1 crore'), 10000000);
      expect(parseRupees('3 thousand'), 3000);
    });

    test('rejects what is not an amount', () {
      for (final v in [null, '', '   ', 'abc', 'lots', '1k2', '--5', true, [], {}]) {
        expect(parseRupees(v), isNull, reason: '$v');
      }
      expect(parseRupees(double.nan), isNull);
      expect(parseRupees(double.infinity), isNull);
    });

    test('negative numbers parse (the caller rejects them)', () {
      expect(parseRupees(-5), -5);
      expect(parseRupees('-5'), -5);
    });
  });

  group('cleanText', () {
    test('trims and collapses spaces', () {
      expect(cleanText('  a   b  '), 'a b');
    });
    test('treats placeholder words as not stated', () {
      for (final v in [null, '', '  ', 'null', 'None', 'N/A', 'unknown', 'Not mentioned', '-']) {
        expect(cleanText(v), isNull, reason: '$v');
      }
    });
    test('caps length', () {
      expect(cleanText('x' * 200, maxLength: 10), 'x' * 10);
    });
    test('keeps Kannada text intact', () {
      expect(cleanText(' ಬೆಂಗಳೂರು '), 'ಬೆಂಗಳೂರು');
    });
  });

  group('normalizePayment', () {
    test('maps wording to the five methods', () {
      expect(normalizePayment('Cash'), 'cash');
      expect(normalizePayment('UPI'), 'upi');
      expect(normalizePayment('gpay'), 'upi');
      expect(normalizePayment('Google Pay'), 'upi');
      expect(normalizePayment('PhonePe'), 'upi');
      expect(normalizePayment('paytm'), 'upi');
      expect(normalizePayment('credit card'), 'card');
      expect(normalizePayment('Debit-Card'), 'card');
      expect(normalizePayment('visa'), 'card');
      expect(normalizePayment('net banking'), 'netbanking');
      expect(normalizePayment('NEFT'), 'netbanking');
      expect(normalizePayment('other'), 'other');
      expect(normalizePayment('bitcoin'), 'other');
    });
    test('not stated stays null', () {
      expect(normalizePayment(null), isNull);
      expect(normalizePayment(''), isNull);
      expect(normalizePayment('null'), isNull);
    });
  });

  group('dates and booleans', () {
    test('parseIsoDate', () {
      expect(parseIsoDate('2026-10-24'), '2026-10-24');
      expect(parseIsoDate('2026-10-24T10:30:00Z'), '2026-10-24');
      expect(parseIsoDate('2026-10-24 10:30'), '2026-10-24');
      expect(parseIsoDate('2026-02-30'), isNull);
      expect(parseIsoDate('tomorrow'), isNull);
      expect(parseIsoDate(null), isNull);
    });
    test('parseBool', () {
      expect(parseBool(true), isTrue);
      expect(parseBool('true'), isTrue);
      expect(parseBool('Yes'), isTrue);
      expect(parseBool('false'), isFalse);
      expect(parseBool('no'), isFalse);
      expect(parseBool('maybe'), isNull);
      expect(parseBool(null), isNull);
    });
  });

  test('tidyItem only re-cases all-lowercase text', () {
    expect(tidyItem('pani puri'), 'Pani Puri');
    expect(tidyItem('dinner at meghana\'s'), "Dinner at Meghana's");
    expect(tidyItem('  lunch   for the team '), 'Lunch for the Team');
    expect(tidyItem('KFC'), 'KFC');
    expect(tidyItem('BMTC bus'), 'BMTC bus');
    expect(tidyItem('McDonald\'s'), "McDonald's");
    expect(tidyItem('Already Fine'), 'Already Fine');
    expect(tidyItem('ಚಾಟ್ಸ್'), 'ಚಾಟ್ಸ್');
  });
}
