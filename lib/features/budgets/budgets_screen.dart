import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/watch.dart';
import '../../providers.dart';
import '../../services/agent/parsing.dart';
import '../../services/agent/tool_executor.dart' show kMaxBudgetRupees;
import '../chat/chat_controller.dart' show todayProvider;

class BudgetRow {
  const BudgetRow({
    required this.budget,
    required this.name,
    required this.spent,
  });
  final Budget budget;
  final String name;
  final int spent;

  int get limit => budget.monthlyLimitPaise;
  int get percent => (spent * 100 / limit).floor();
  bool get over => spent > limit;
  bool get near => !over && spent * 100 >= 80 * limit;

  /// 0 over, 1 near limit, 2 on track (sort order).
  int get rank => over ? 0 : (near ? 1 : 2);
}

class BudgetsView {
  const BudgetsView({
    required this.month,
    required this.daysLeft,
    required this.overall,
    required this.categories,
    required this.unbudgeted,
  });
  final String month;
  final int daysLeft;
  final BudgetRow? overall;
  final List<BudgetRow> categories;

  /// Categories with spending this month and no budget.
  final List<(Category, int)> unbudgeted;

  bool get isEmpty => overall == null && categories.isEmpty;
}

final budgetsViewProvider = StreamProvider.autoDispose<BudgetsView>((ref) {
  final db = ref.watch(databaseProvider);
  final today = ref.watch(todayProvider);
  final expenses = ref.watch(expenseRepoProvider);
  final categories = ref.watch(categoryRepoProvider);
  final budgets = ref.watch(budgetRepoProvider);
  return watchQuery<BudgetsView>(db, {db.expenses, db.budgets, db.categories}, () async {
    final m = monthRange(today);
    final sums = await expenses.sumByCategory(m.from, m.to);
    final total = await expenses.total(m.from, m.to);
    final cats = {for (final c in await categories.all()) c.id: c};
    final list = await budgets.all();
    BudgetRow? overall;
    final rows = <BudgetRow>[];
    for (final b in list) {
      if (b.categoryId == null) {
        overall = BudgetRow(budget: b, name: 'Overall', spent: total);
      } else if (cats[b.categoryId] != null) {
        rows.add(BudgetRow(
            budget: b, name: cats[b.categoryId]!.name, spent: sums[b.categoryId] ?? 0));
      }
    }
    rows.sort((a, b) {
      final r = a.rank.compareTo(b.rank);
      return r != 0 ? r : b.percent.compareTo(a.percent);
    });
    final budgeted = {for (final b in list) b.categoryId};
    final unbudgeted = [
      for (final e in sums.entries)
        if (!budgeted.contains(e.key) && cats[e.key] != null && !cats[e.key]!.isArchived)
          (cats[e.key]!, e.value)
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return BudgetsView(
      month: m.from,
      daysLeft: daysLeftInMonth(today),
      overall: overall,
      categories: rows,
      unbudgeted: unbudgeted,
    );
  });
});

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kc = context.kc;
    final view = ref.watch(budgetsViewProvider);
    return Scaffold(
      backgroundColor: kc.bg,
      appBar: AppBar(
        title: Text('Budgets', style: headingStyle(size: 20, color: kc.ink)),
        shape: Border(bottom: BorderSide(color: kc.line)),
        actions: [
          IconButton(
            tooltip: 'Add budget',
            onPressed: () => _openForm(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: view.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const Center(child: Text("Couldn't load budgets.")),
        data: (v) {
          if (v.isEmpty && v.unbudgeted.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No budgets yet', style: TextStyle(color: kc.muted)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _openForm(context, ref),
                    child: const Text('Add budget'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (v.overall != null) ...[
                _OverallCard(v, onTap: () => _openForm(context, ref, row: v.overall)),
                const SizedBox(height: 12),
              ],
              if (v.categories.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: kc.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  // painted over the children, so their corners never cover the border
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kc.line),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < v.categories.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: kc.hair),
                        _CategoryRow(v.categories[i],
                            onTap: () => _openForm(context, ref, row: v.categories[i])),
                      ],
                    ],
                  ),
                ),
              if (v.unbudgeted.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final u in v.unbudgeted.take(6))
                      ActionChip(
                        label: Text('+ ${u.$1.name}'),
                        onPressed: () => _openForm(context, ref, category: u.$1),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {BudgetRow? row, Category? category}) async {
    final cats = await ref.read(categoryRepoProvider).active();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.kc.surface,
      builder: (_) => _BudgetSheet(
        categories: cats,
        editing: row?.budget,
        initialCategoryId: row != null ? row.budget.categoryId : category?.id,
        lockCategory: row != null,
        initialPaise: row?.limit,
        ref: ref,
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard(this.v, {required this.onTap});
  final BudgetsView v;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final r = v.overall!;
    final color = r.over ? kc.danger : (r.near ? kc.warn : kc.accent);
    return Material(
      color: kc.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kc.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(monthName(v.month),
                      style: TextStyle(color: kc.ink, fontWeight: FontWeight.w700)),
                  Text(v.daysLeft == 0 ? 'Last day' : '${v.daysLeft} ${v.daysLeft == 1 ? 'day' : 'days'} left',
                      style: TextStyle(color: kc.muted, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(formatINR(r.spent),
                          style: headingStyle(size: 30, color: kc.ink)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('/ ${formatINR(r.limit)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: kc.muted)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: (r.spent / r.limit).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: kc.track,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow(this.r, {required this.onTap});
  final BudgetRow r;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final (label, bg, fg, bar) = r.over
        ? ('Over', kc.dangerBg, kc.dangerInk, kc.danger)
        : r.near
            ? ('Near limit', kc.warnBg, kc.warnInk, kc.warn)
            : ('On track', kc.soft, kc.softInk, kc.accent);
    final remaining = r.limit - r.spent;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: kc.ink, fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration:
                      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                  child: Text(label,
                      style: TextStyle(
                          color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (r.spent / r.limit).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: kc.track,
                valueColor: AlwaysStoppedAnimation(bar),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text('${formatINR(r.spent)} of ${formatINR(r.limit)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: kc.muted, fontSize: 13)),
                ),
                Text(
                  remaining >= 0
                      ? '${formatINR(remaining)} left'
                      : '${formatINR(-remaining)} over',
                  style: TextStyle(color: kc.muted, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({
    required this.categories,
    required this.editing,
    required this.initialCategoryId,
    required this.lockCategory,
    required this.initialPaise,
    required this.ref,
  });

  final List<Category> categories;
  final Budget? editing;
  final int? initialCategoryId;

  /// When editing, the category cannot change (delete and add instead).
  final bool lockCategory;
  final int? initialPaise;
  final WidgetRef ref;

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late int? _category = widget.initialCategoryId;
  late final TextEditingController _amount = TextEditingController(
      text: widget.initialPaise == null
          ? ''
          : (widget.initialPaise! % 100 == 0
              ? '${widget.initialPaise! ~/ 100}'
              : (widget.initialPaise! / 100).toStringAsFixed(2)));
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final r = parseRupees(_amount.text);
    if (r == null || r <= 0) {
      setState(() => _error = 'Enter an amount');
      return;
    }
    if (r > kMaxBudgetRupees) {
      setState(() => _error = 'That is unrealistically large');
      return;
    }
    final paise = rupeesToPaise(r);
    if (paise <= 0) {
      setState(() => _error = 'Enter an amount');
      return;
    }
    setState(() => _busy = true);
    await widget.ref.read(budgetRepoProvider).upsert(_category, paise);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    await widget.ref.read(budgetRepoProvider).delete(widget.editing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.editing == null ? 'Add budget' : 'Edit budget',
                style: headingStyle(size: 19, color: kc.ink)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'For'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Overall')),
                for (final c in widget.categories)
                  DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
              ],
              onChanged: widget.lockCategory ? null : (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              autofocus: widget.editing == null,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly limit',
                prefixText: '₹ ',
                errorText: _error,
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (widget.editing != null) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: kc.danger),
                    onPressed: _busy ? null : _delete,
                    child: const Text('Delete'),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
