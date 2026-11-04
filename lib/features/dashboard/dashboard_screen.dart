import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/charts.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../chat/chat_controller.dart' show todayProvider;
import '../transactions/tx_state.dart';
import 'dashboard_data.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kc = context.kc;
    final month = ref.watch(monthProvider);
    final data = ref.watch(dashboardProvider);
    final notifier = ref.read(monthProvider.notifier);
    final year = tryParseIso(month)!.year;
    final thisYear = tryParseIso(monthRange(ref.watch(todayProvider)).from)!
        .year;
    final title = year == thisYear
        ? monthName(month)
        : '${monthName(month)} $year';

    return Scaffold(
      backgroundColor: kc.bg,
      appBar: AppBar(
        title: Text(title, style: headingStyle(size: 20, color: kc.ink)),
        shape: Border(bottom: BorderSide(color: kc.line)),
        actions: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: notifier.previous,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: notifier.isCurrent ? null : notifier.next,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: data.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) =>
            const Center(child: Text("Couldn't load the dashboard.")),
        data: (d) => LayoutBuilder(
          builder: (context, box) {
            // Enough room: everything fits on one screen and the daily chart
            // takes whatever height is left. Too little (a small phone, a big
            // font): the same cards, in a list that scrolls.
            final fits = box.maxHeight >= _kFitHeight;
            if (!fits) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryCard(d),
                  const SizedBox(height: 12),
                  _CategoryCard(d),
                  const SizedBox(height: 12),
                  _DailyCard(d),
                  const SizedBox(height: 12),
                  _LendingTiles(d),
                ],
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCard(d),
                  const SizedBox(height: 12),
                  _CategoryCard(d),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: _DailyCard(d, fill: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LendingTiles(d),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Body height from which the dashboard fits without scrolling: the fixed
/// cards (summary, categories, lending, gaps and padding) plus a daily chart
/// still tall enough to read.
const _kFitHeight = 640.0;

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kc.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kc.line),
      ),
      child: child,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.d);
  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final budget = d.overall;
    final pct = budget == null ? 0.0 : d.total / budget;
    final left = budget == null ? null : budget - d.total;

    final onHero = kc.onAccent;
    final heroMuted = kc.onAccent.withValues(alpha: 0.78);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kc.accent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatINR(d.total),
                    style: headingStyle(size: 32, color: onHero),
                  ),
                ),
              ),
              if (budget != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'of ${formatINR(budget)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: heroMuted, fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
          if (budget != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: kc.onAccent.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation(kc.onAccent),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              left! >= 0
                  ? '${formatINR(left)} left${d.isCurrentMonth && d.daysLeft > 0 ? ' · ${d.daysLeft} ${d.daysLeft == 1 ? 'day' : 'days'}' : ''}'
                  : 'Over by ${formatINR(-left)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: left < 0 ? kc.onAccent : heroMuted,
                fontWeight: left < 0 ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${d.count} ${d.count == 1 ? 'expense' : 'expenses'}',
                style: TextStyle(color: heroMuted, fontSize: 14),
              ),
            ),
          if (d.overBudget.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${d.overBudget.join(', ')} over budget',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: kc.onAccent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard(this.d);
  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    if (d.byCategory.isEmpty) {
      return _Card(
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'No spending this month',
              style: TextStyle(color: kc.muted, fontSize: 14),
            ),
          ),
        ),
      );
    }
    // top five, everything else grouped as "Others"
    final top = d.byCategory.take(5).toList();
    final rest = d.byCategory.skip(5).fold<int>(0, (a, b) => a + b.paise);
    final slices = <(String, int, Color)>[
      for (var i = 0; i < top.length; i++)
        (top[i].category.name, top[i].paise, kc.chart[i]),
      if (rest > 0) ('Others', rest, kc.chart[5]),
    ];

    return _Card(
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    pieTouchData: PieTouchData(enabled: false),
                    sections: [
                      for (final s in slices)
                        PieChartSectionData(
                          value: s.$2.toDouble(),
                          color: s.$3,
                          radius: 22,
                          showTitle: false,
                        ),
                    ],
                  ),
                  duration: Duration.zero,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Top',
                        style: TextStyle(color: kc.muted, fontSize: 11),
                      ),
                      Text(
                        top.first.category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: headingStyle(size: 13, color: kc.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (final s in slices)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.$3,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: kc.ink, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatINR(s.$2),
                          style: TextStyle(
                            color: kc.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyCard extends ConsumerWidget {
  const _DailyCard(this.d, {this.fill = false});
  final DashboardData d;

  /// The chart takes the height it is given instead of a fixed 160.
  final bool fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kc = context.kc;
    final today = ref.watch(todayProvider);
    final todayDay = d.isCurrentMonth ? tryParseIso(today)!.day : d.daysInMonth;
    final shownDays = todayDay.clamp(1, d.daysInMonth);

    int valueOn(int day) {
      final iso =
          '${d.monthStart.substring(0, 8)}${day.toString().padLeft(2, '0')}';
      return d.byDay[iso] ?? 0;
    }

    final values = [for (var i = 1; i <= shownDays; i++) valueOn(i)];
    final maxValue = values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = niceAxisMax(maxValue).toDouble();
    final todayTotal = d.isCurrentMonth ? valueOn(todayDay) : null;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily',
                maxLines: 1,
                style: TextStyle(
                  color: kc.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (todayTotal != null)
                Flexible(
                  child: Text(
                    'Today ${formatINR(todayTotal)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: kc.muted, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ChartSlot(
            fill: fill,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceBetween,
                barTouchData: BarTouchData(enabled: false),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 2,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: kc.hair, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: maxY / 2,
                      getTitlesWidget: (v, meta) => Text(
                        formatINRShort(v.round()),
                        style: TextStyle(color: kc.muted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final day = v.round();
                        final show =
                            day == 1 || day == shownDays || day % 7 == 1;
                        if (!show ||
                            (shownDays - day).abs() < 3 && day != shownDays) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$day',
                            style: TextStyle(color: kc.muted, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i + 1,
                      barRods: [
                        BarChartRodData(
                          toY: values[i].toDouble(),
                          width: shownDays > 20 ? 5 : 8,
                          color: (d.isCurrentMonth && i + 1 == todayDay)
                              ? kc.accent
                              : kc.bar,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              duration: Duration.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSlot extends StatelessWidget {
  const _ChartSlot({required this.fill, required this.child});
  final bool fill;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      fill ? Expanded(child: child) : SizedBox(height: 160, child: child);
}

class _LendingTiles extends ConsumerWidget {
  const _LendingTiles(this.d);
  final DashboardData d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kc = context.kc;

    Widget tile(String label, int paise, int people, Color bg, Color fg) =>
        Expanded(
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                ref.read(txTabProvider.notifier).show(1);
                context.go('/transactions');
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatINR(paise),
                        style: headingStyle(size: 22, color: fg),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$people ${people == 1 ? 'person' : 'people'}',
                      style: TextStyle(color: fg, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    return Row(
      children: [
        tile(
          "You'll get",
          d.lending.getPaise,
          d.lending.getPeople,
          kc.lentBg,
          kc.lentInk,
        ),
        const SizedBox(width: 10),
        tile(
          'You owe',
          d.lending.owePaise,
          d.lending.owePeople,
          kc.borrowedBg,
          kc.borrowedInk,
        ),
      ],
    );
  }
}
