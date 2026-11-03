import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../chat/chat_controller.dart' show todayProvider;
import 'tx_state.dart';

Future<void> showFilterSheet(
  BuildContext context,
  WidgetRef ref,
  List<Category> categories,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.kc.surface,
    builder: (_) => _FilterSheet(ref: ref, categories: categories),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.ref, required this.categories});
  final WidgetRef ref;
  final List<Category> categories;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<int> _cats = {
    ...widget.ref.read(txFilterProvider).categoryIds,
  };
  late final Set<String> _pay = {
    ...widget.ref.read(txFilterProvider).paymentMethods,
  };
  late String? _from = widget.ref.read(txFilterProvider).dateFrom;
  late String? _to = widget.ref.read(txFilterProvider).dateTo;

  static const _methods = [
    ('cash', 'Cash'),
    ('upi', 'UPI'),
    ('card', 'Card'),
    ('netbanking', 'Net banking'),
    ('other', 'Other'),
  ];

  Future<void> _pickRange() async {
    final today = tryParseIso(widget.ref.read(todayProvider))!;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.utc(2000),
      lastDate: today,
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: tryParseIso(_from!)!, end: tryParseIso(_to!)!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _from = isoDate(picked.start);
        _to = isoDate(picked.end);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final today = widget.ref.read(todayProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Filter',
                      style: headingStyle(size: 19, color: kc.ink),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kc.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in widget.categories)
                          FilterChip(
                            label: Text(c.name),
                            selected: _cats.contains(c.id),
                            onSelected: (on) => setState(
                              () => on ? _cats.add(c.id) : _cats.remove(c.id),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Paid with',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kc.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in _methods)
                          FilterChip(
                            label: Text(m.$2),
                            selected: _pay.contains(m.$1),
                            onSelected: (on) => setState(
                              () => on ? _pay.add(m.$1) : _pay.remove(m.$1),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Dates',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kc.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickRange,
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text(
                              _from == null
                                  ? 'Any date'
                                  : '${friendlyDate(_from!, today)} – ${friendlyDate(_to!, today)}',
                            ),
                          ),
                        ),
                        if (_from != null)
                          IconButton(
                            tooltip: 'Clear dates',
                            onPressed: () => setState(() {
                              _from = null;
                              _to = null;
                            }),
                            icon: const Icon(Icons.close),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.ref.read(txFilterProvider.notifier).clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      widget.ref
                          .read(txFilterProvider.notifier)
                          .setFilters(
                            categoryIds: _cats.toList(),
                            paymentMethods: _pay.toList(),
                            dateFrom: _from,
                            dateTo: _to,
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
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
