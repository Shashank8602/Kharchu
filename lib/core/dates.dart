// Dates are stored as 'YYYY-MM-DD' text in IST (Asia/Kolkata, UTC+5:30).
// Functions that depend on the clock take `now` so tests can pin "today".

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Parses 'YYYY-MM-DD'. Returns null for anything invalid, including
/// impossible dates like 2026-02-31 (DateTime would silently roll those over).
DateTime? tryParseIso(String s) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s.trim());
  if (m == null) return null;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final dt = DateTime.utc(y, mo, d);
  if (dt.year != y || dt.month != mo || dt.day != d) return null;
  return dt;
}

/// Today's date in IST as 'YYYY-MM-DD'.
String todayIst([DateTime? now]) {
  final ist = (now ?? DateTime.now()).toUtc().add(
        const Duration(hours: 5, minutes: 30),
      );
  return isoDate(ist);
}

String addDays(String iso, int days) {
  final d = tryParseIso(iso)!;
  return isoDate(d.add(Duration(days: days)));
}

/// First and last day of the month containing [iso].
({String from, String to}) monthRange(String iso) {
  final d = tryParseIso(iso)!;
  final first = DateTime.utc(d.year, d.month, 1);
  final last = DateTime.utc(d.year, d.month + 1, 0);
  return (from: isoDate(first), to: isoDate(last));
}

/// First day of the month before [iso]'s month.
String previousMonthStart(String iso) {
  final d = tryParseIso(iso)!;
  return isoDate(DateTime.utc(d.year, d.month - 1, 1));
}

String nextMonthStart(String iso) {
  final d = tryParseIso(iso)!;
  return isoDate(DateTime.utc(d.year, d.month + 1, 1));
}

/// Days left in the month, counting today as a remaining day only when
/// [includeToday] is true. Example: on the 24th of a 31-day month, 7 days left.
int daysLeftInMonth(String todayIso, {bool includeToday = false}) {
  final d = tryParseIso(todayIso)!;
  final last = DateTime.utc(d.year, d.month + 1, 0).day;
  final left = last - d.day;
  return includeToday ? left + 1 : left;
}

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const _monthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

String weekdayName(String iso) => _weekdays[tryParseIso(iso)!.weekday - 1];

/// 'Sat, 24 Oct'
String dayLabel(String iso) {
  final d = tryParseIso(iso)!;
  return '${_weekdays[d.weekday - 1].substring(0, 3)}, '
      '${d.day} ${_months[d.month - 1]}';
}

/// '24 Oct 2026'
String fullDateLabel(String iso) {
  final d = tryParseIso(iso)!;
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// 'October'
String monthName(String iso) => _monthsFull[tryParseIso(iso)!.month - 1];
