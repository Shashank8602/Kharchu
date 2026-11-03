import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/lending_repository.dart';
import '../../data/repositories/watch.dart';
import '../../providers.dart';
import '../chat/chat_controller.dart';

/// The month the Dashboard shows, as the first day ('YYYY-MM-01').
class MonthNotifier extends Notifier<String> {
  @override
  String build() => monthRange(ref.watch(todayProvider)).from;

  String get _currentMonth => monthRange(ref.read(todayProvider)).from;

  bool get isCurrent => state == _currentMonth;

  void previous() => state = previousMonthStart(state);

  /// Never goes past the current month.
  void next() {
    final n = nextMonthStart(state);
    if (n.compareTo(_currentMonth) <= 0) state = n;
  }
}

final monthProvider = NotifierProvider<MonthNotifier, String>(MonthNotifier.new);

class CategorySpend {
  const CategorySpend(this.category, this.paise);
  final Category category;
  final int paise;
}

class DashboardData {
  const DashboardData({
    required this.monthStart,
    required this.monthEnd,
    required this.total,
    required this.count,
    required this.overall,
    required this.byCategory,
    required this.byDay,
    required this.overBudget,
    required this.lending,
    required this.isCurrentMonth,
    required this.daysLeft,
  });

  final String monthStart;
  final String monthEnd;
  final int total;
  final int count;

  /// Overall monthly budget in paise, or null.
  final int? overall;

  /// Largest first.
  final List<CategorySpend> byCategory;
  final Map<String, int> byDay;

  /// Names of categories whose spending is over their budget.
  final List<String> overBudget;
  final LendingTotals lending;
  final bool isCurrentMonth;
  final int daysLeft;

  int get daysInMonth => tryParseIso(monthEnd)!.day;
}

/// Live numbers for the selected month.
final dashboardProvider = StreamProvider.autoDispose<DashboardData>((ref) {
  final month = ref.watch(monthProvider);
  final today = ref.watch(todayProvider);
  final db = ref.watch(databaseProvider);
  final expenses = ref.watch(expenseRepoProvider);
  final categories = ref.watch(categoryRepoProvider);
  final budgets = ref.watch(budgetRepoProvider);
  final lending = ref.watch(lendingRepoProvider);

  return watchQuery<DashboardData>(
    db,
    {db.expenses, db.categories, db.budgets, db.loans, db.loanRepayments, db.people},
    () async {
      final range = monthRange(month);
      final sums = await expenses.sumByCategory(range.from, range.to);
      final cats = {for (final c in await categories.all()) c.id: c};
      final budgetList = await budgets.all();
      final rows = [
        for (final e in sums.entries)
          if (cats[e.key] != null) CategorySpend(cats[e.key]!, e.value)
      ]..sort((a, b) => b.paise.compareTo(a.paise));
      final byId = {for (final r in rows) r.category.id: r.paise};
      final over = [
        for (final b in budgetList)
          if (b.categoryId != null &&
              (byId[b.categoryId] ?? 0) > b.monthlyLimitPaise &&
              cats[b.categoryId] != null)
            cats[b.categoryId]!.name
      ];
      final current = monthRange(today).from == range.from;
      return DashboardData(
        monthStart: range.from,
        monthEnd: range.to,
        total: await expenses.total(range.from, range.to),
        count: await expenses.count(range.from, range.to),
        overall: budgetList.where((b) => b.categoryId == null).firstOrNull?.monthlyLimitPaise,
        byCategory: rows,
        byDay: await expenses.sumByDay(range.from, range.to),
        overBudget: over,
        lending: await lending.totals(),
        isCurrentMonth: current,
        daysLeft: current ? daysLeftInMonth(today) : 0,
      );
    },
  );
});
