import '../../core/dates.dart';

/// Models are loose with types: numbers arrive as "1000", "₹1,000", "1k".
/// These helpers accept what a person would mean and reject the rest.

/// Rupees from a number or text like "1000", "₹1,000.50", "Rs. 2.5k",
/// "1.5 lakh". Returns null when it cannot be read as a finite number.
double? parseRupees(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.isFinite ? v.toDouble() : null;
  if (v is! String) return null;
  var s = v.toLowerCase().trim();
  s = s.replaceAll(RegExp(r'(₹|rs\.?|inr|rupees?|/-)'), '').replaceAll(',', '').trim();
  if (s.isEmpty) return null;
  var mult = 1.0;
  final unit = RegExp(r'^([0-9]*\.?[0-9]+)\s*(k|thousand|l|lac|lakh|lakhs|cr|crore)$')
      .firstMatch(s);
  if (unit != null) {
    s = unit.group(1)!;
    mult = switch (unit.group(2)) {
      'k' || 'thousand' => 1000.0,
      'l' || 'lac' || 'lakh' || 'lakhs' => 100000.0,
      _ => 10000000.0,
    };
  }
  final n = double.tryParse(s);
  if (n == null || !n.isFinite) return null;
  return n * mult;
}

/// Trimmed text, or null for empty / "null" / "none" / "n/a" and similar.
String? cleanText(dynamic v, {int maxLength = 80}) {
  if (v == null) return null;
  var s = v.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) return null;
  const empties = {'null', 'none', 'n/a', 'na', 'nil', 'unknown', 'not mentioned', '-'};
  if (empties.contains(s.toLowerCase())) return null;
  if (s.length > maxLength) s = s.substring(0, maxLength).trim();
  return s;
}

/// cash | upi | card | netbanking | other, or null if not stated.
String? normalizePayment(dynamic v) {
  final s = cleanText(v)?.toLowerCase();
  if (s == null) return null;
  final compact = s.replaceAll(RegExp(r'[\s_\-]+'), '');
  if (compact == 'cash') return 'cash';
  if (RegExp(r'(upi|gpay|googlepay|phonepe|paytm|bhim|amazonpay|qr)').hasMatch(compact)) {
    return 'upi';
  }
  if (RegExp(r'(card|credit|debit|visa|mastercard|rupay)').hasMatch(compact)) {
    return 'card';
  }
  if (RegExp(r'(netbanking|internetbanking|neft|imps|rtgs|banktransfer|onlinebanking)')
      .hasMatch(compact)) {
    return 'netbanking';
  }
  if (compact == 'other') return 'other';
  return 'other';
}

bool? parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true' || s == 'yes') return true;
    if (s == 'false' || s == 'no') return false;
  }
  return null;
}

/// A valid 'YYYY-MM-DD' or null. Accepts a full ISO timestamp by cutting it
/// to its date part.
String? parseIsoDate(dynamic v) {
  if (v == null) return null;
  var s = v.toString().trim();
  if (s.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}[T ]').hasMatch(s)) {
    s = s.substring(0, 10);
  }
  return tryParseIso(s) == null ? null : s;
}

const _titleSmall = {'and', 'at', 'of', 'in', 'on', 'to', 'for', 'the', 'a', 'an', 'by'};

/// "dinner at  meghana's" → "Dinner at Meghana's". Only text that arrives
/// entirely lowercase is re-cased; anything with capitals ("McDonald's",
/// "KFC", "BMTC bus") is left alone so acronyms survive.
String tidyItem(String raw) {
  final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t != t.toLowerCase()) return t;
  final words = t.split(' ');
  final out = <String>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i].toLowerCase();
    if (w.isEmpty) continue;
    if (i > 0 && _titleSmall.contains(w)) {
      out.add(w);
    } else {
      out.add(w[0].toUpperCase() + w.substring(1));
    }
  }
  return out.join(' ');
}
