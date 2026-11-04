import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/expense_repository.dart';
import '../../providers.dart';
import '../../widgets/expense_form_sheet.dart';
import '../chat/chat_controller.dart' show todayProvider;
import 'filter_sheet.dart';
import 'tx_state.dart';

final txExpensesProvider = StreamProvider.autoDispose<List<ExpenseRow>>((ref) {
  final filter = ref.watch(txFilterProvider).toFilter();
  return ref.watch(expenseRepoProvider).watch(filter);
});

Color categoryColor(BuildContext context, Category c) =>
    Color(Theme.of(context).brightness == Brightness.dark ? c.colorDark : c.colorLight);

String paymentLabel(String? m) => switch (m) {
      'cash' => 'Cash',
      'upi' => 'UPI',
      'card' => 'Card',
      'netbanking' => 'Net banking',
      'other' => 'Other',
      _ => '',
    };

OutlineInputBorder _pill(Color color, {double width = 1}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: color, width: width),
    );

class ExpensesTab extends ConsumerStatefulWidget {
  const ExpensesTab({super.key});

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(txFilterProvider.notifier).setText(text);
    });
  }

  Future<void> _openFilters() async {
    final cats = await ref.read(categoryRepoProvider).all();
    if (!mounted) return;
    await showFilterSheet(context, ref, cats);
  }

  Future<void> _edit(ExpenseRow row) async {
    final repo = ref.read(categoryRepoProvider);
    final active = await repo.active();
    final cats = active.any((c) => c.id == row.category.id) ? active : [...active, row.category];
    if (!mounted) return;
    final e = row.expense;
    final r = await showExpenseSheet(
      context,
      categories: cats,
      todayIso: ref.read(todayProvider),
      title: 'Edit expense',
      actionLabel: 'Save',
      amountPaise: e.amountPaise,
      item: e.item,
      categoryId: e.categoryId,
      location: e.location,
      paymentMethod: e.paymentMethod,
      spentOn: e.spentOn,
    );
    if (r == null) return;
    await ref.read(expenseRepoProvider).update(
          e.id,
          ExpensesCompanion(
            amountPaise: Value(r.amountPaise),
            item: Value(r.item),
            categoryId: Value(r.categoryId),
            location: Value(r.location),
            paymentMethod: Value(r.paymentMethod),
            spentOn: Value(r.spentOn),
          ),
        );
  }

  Future<void> _delete(ExpenseRow row) async {
    final repo = ref.read(expenseRepoProvider);
    await repo.softDelete(row.expense.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Deleted ${formatINR(row.expense.amountPaise)} ${row.expense.item}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => repo.restore(row.expense.id),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final filter = ref.watch(txFilterProvider);
    final rows = ref.watch(txExpensesProvider);
    final today = ref.watch(todayProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _search.clear();
                              _debounce?.cancel();
                              ref.read(txFilterProvider.notifier).setText('');
                              setState(() {});
                            },
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: _pill(kc.line),
                    enabledBorder: _pill(kc.line),
                    focusedBorder: _pill(kc.accent, width: 2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton.outlined(
                    tooltip: 'Filter',
                    onPressed: _openFilters,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      shape: const CircleBorder(),
                      side: BorderSide(color: kc.line),
                      backgroundColor: kc.field,
                    ),
                    icon: const Icon(Icons.tune, size: 20),
                  ),
                  if (filter.hasFilters)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: kc.accent, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: rows.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const Center(child: Text("Couldn't load expenses.")),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(filter.isEmpty ? 'No expenses yet' : 'Nothing matches',
                      style: TextStyle(color: kc.muted)),
                );
              }
              final groups = _groupByDay(list);
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                itemCount: groups.length,
                itemBuilder: (_, i) => _DayGroupView(
                  group: groups[i],
                  today: today,
                  onTap: _edit,
                  onDelete: _delete,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<_DayGroup> _groupByDay(List<ExpenseRow> list) {
    final groups = <_DayGroup>[];
    for (final r in list) {
      if (groups.isEmpty || groups.last.day != r.expense.spentOn) {
        groups.add(_DayGroup(r.expense.spentOn));
      }
      groups.last.rows.add(r);
    }
    return groups;
  }
}

class _DayGroup {
  _DayGroup(this.day);
  final String day;
  final List<ExpenseRow> rows = [];
  int get total => rows.fold<int>(0, (a, b) => a + b.expense.amountPaise);
}

/// One rounded card per day: a header with the day's total, then its rows
/// separated by hairlines.
class _DayGroupView extends StatelessWidget {
  const _DayGroupView({
    required this.group,
    required this.today,
    required this.onTap,
    required this.onDelete,
  });

  final _DayGroup group;
  final String today;
  final void Function(ExpenseRow) onTap;
  final Future<void> Function(ExpenseRow) onDelete;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(group.day == today ? 'Today' : dayLabel(group.day),
                  style: TextStyle(
                      color: kc.muted, fontWeight: FontWeight.w700, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: kc.soft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(formatINR(group.total),
                    maxLines: 1,
                    style: TextStyle(
                        color: kc.softInk, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kc.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          // painted over the children, so their corners never cover the border
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kc.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < group.rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: kc.hair),
                _ExpenseTile(
                  row: group.rows[i],
                  onTap: () => onTap(group.rows[i]),
                  onDelete: () => onDelete(group.rows[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.row,
    required this.onTap,
    required this.onDelete,
  });

  final ExpenseRow row;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final e = row.expense;
    final color = categoryColor(context, row.category);
    final sub = [
      if (e.location != null) e.location!,
      if (paymentLabel(e.paymentMethod).isNotEmpty) paymentLabel(e.paymentMethod),
    ].join(' · ');

    return Dismissible(
      key: ValueKey('expense-${e.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onDelete();
        return false; // the live list removes it; no animation to keep in sync
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: kc.dangerBg,
        child: Icon(Icons.delete_outline, color: kc.dangerInk),
      ),
      child: Material(
        color: kc.surface,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: color.withValues(alpha: 0.16),
                    child: Text(row.category.name.characters.first.toUpperCase(),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.item,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: kc.ink, fontWeight: FontWeight.w600, fontSize: 15)),
                        if (sub.isNotEmpty)
                          Text(sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: kc.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(formatINR(e.amountPaise),
                      style: TextStyle(
                          color: kc.ink,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
