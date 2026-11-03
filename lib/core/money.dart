import 'package:intl/intl.dart';

/// Money is stored as integer paise. These helpers convert and format.
int rupeesToPaise(num rupees) => (rupees * 100).round();

double paiseToRupees(int paise) => paise / 100;

final NumberFormat _whole =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final NumberFormat _fraction =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

/// ₹1,00,000 style. Shows decimals only when the paise part is non-zero.
String formatINR(int paise) {
  final negative = paise < 0;
  final abs = paise.abs();
  final text = abs % 100 == 0
      ? _whole.format(abs ~/ 100)
      : _fraction.format(abs / 100);
  return negative ? '-$text' : text;
}

/// Short form for chart axes: ₹4k, ₹1.2L.
String formatINRShort(int paise) {
  final r = paise / 100;
  if (r >= 10000000) return '₹${_trim(r / 10000000)}Cr';
  if (r >= 100000) return '₹${_trim(r / 100000)}L';
  if (r >= 1000) return '₹${_trim(r / 1000)}k';
  return '₹${_trim(r)}';
}

String _trim(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}
