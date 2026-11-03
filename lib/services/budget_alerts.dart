import '../core/dates.dart';
import '../core/money.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/expense_repository.dart';

/// This month's spending, overall and per category.
class SpendSnapshot {
  const SpendSnapshot(this.overall, this.byCategory);
  final int overall;
  final Map<int, int> byCategory;
}

class BudgetNotice {
  const BudgetNotice({
    required this.level,
    required this.percent,
    required this.text,
  });

  /// 'warn' at 80%, 'danger' at 100%.
  final String level;
  final int percent;
  final String text;
}

/// Warns when a change takes a budget past 80% or 100% for the first time.
/// Only crossings upward count, so saving a second expense at 90% does not
/// repeat the warning. Lending is never part of this.
class BudgetAlerts {
  BudgetAlerts({
    required this.expenses,
    required this.budgets,
    required this.categories,
  });

  final ExpenseRepository expenses;
  final BudgetRepository budgets;
  final CategoryRepository categories;

  /// Spending for the month containing [todayIso]. Compared before and after
  /// a change, so edits that move an expense between categories or months
  /// are handled without special cases.
  Future<SpendSnapshot> snapshot(String todayIso) async {
    final m = monthRange(todayIso);
    return SpendSnapshot(
      await expenses.total(m.from, m.to),
      await expenses.sumByCategory(m.from, m.to),
    );
  }

  Future<List<BudgetNotice>> evaluate(
    SpendSnapshot before,
    SpendSnapshot after,
    String todayIso,
  ) async {
    final all = await budgets.all();
    if (all.isEmpty) return const [];
    final names = {for (final c in await categories.watchAll().first) c.id: c.name};
    final daysLeft = daysLeftInMonth(todayIso);
    final out = <BudgetNotice>[];

    for (final b in all) {
      final limit = b.monthlyLimitPaise;
      final used0 = b.categoryId == null ? before.overall : (before.byCategory[b.categoryId] ?? 0);
      final used1 = b.categoryId == null ? after.overall : (after.byCategory[b.categoryId] ?? 0);
      final name = b.categoryId == null ? 'Overall' : (names[b.categoryId] ?? 'A category');

      bool reached(int used, int pct) => used * 100 >= pct * limit;
      if (reached(used1, 100) && !reached(used0, 100)) {
        final text = used1 == limit
            ? '$name has reached its budget · ${formatINR(used1)} of ${formatINR(limit)}'
            : '$name is over budget · ${formatINR(used1)} of ${formatINR(limit)} · '
                '${formatINR(used1 - limit)} over';
        out.add(BudgetNotice(level: 'danger', percent: (used1 * 100 / limit).floor(), text: text));
      } else if (reached(used1, 80) && !reached(used0, 80) && !reached(used1, 100)) {
        final pct = (used1 * 100 / limit).floor();
        final left = daysLeft == 0
            ? 'left today'
            : 'left for $daysLeft ${daysLeft == 1 ? 'day' : 'days'}';
        out.add(BudgetNotice(
          level: 'warn',
          percent: pct,
          text: '$name is at $pct% of budget · ${formatINR(used1)} of ${formatINR(limit)} · '
              '${formatINR(limit - used1)} $left',
        ));
      }
    }
    return out;
  }
}
