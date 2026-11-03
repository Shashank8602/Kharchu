/// Keeps requests under Groq's per-minute cap by waiting instead of letting
/// a 429 happen. A sliding 60-second window.
class RateLimiter {
  RateLimiter({
    this.maxPerMinute = 28,
    DateTime Function()? now,
    Future<void> Function(Duration)? delay,
  })  : _now = now ?? DateTime.now,
        _delay = delay ?? Future<void>.delayed;

  final int maxPerMinute;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _delay;
  final List<DateTime> _stamps = [];

  Future<void> acquire() async {
    while (true) {
      final now = _now();
      _stamps.removeWhere((t) => now.difference(t) >= const Duration(minutes: 1));
      if (_stamps.length < maxPerMinute) {
        _stamps.add(now);
        return;
      }
      final wait = _stamps.first
          .add(const Duration(minutes: 1))
          .difference(now);
      await _delay(wait + const Duration(milliseconds: 50));
    }
  }
}
