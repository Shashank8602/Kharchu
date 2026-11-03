import 'dart:math' as math;

/// Rounds [maxPaise] up to a tidy axis maximum (₹1k, ₹2k, ₹2.5k, ₹5k, ₹10k…)
/// so the y-axis labels read cleanly. Never below ₹1,000 so an almost-empty
/// month does not draw a silly scale.
int niceAxisMax(int maxPaise) {
  final rupees = math.max(maxPaise / 100, 1000);
  final magnitude = math.pow(10, (math.log(rupees) / math.ln10).floor()).toDouble();
  for (final step in [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 7.5, 10.0]) {
    if (rupees <= step * magnitude) return (step * magnitude * 100).round();
  }
  return (10 * magnitude * 100).round();
}
