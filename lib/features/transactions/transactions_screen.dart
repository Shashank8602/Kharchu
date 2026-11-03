import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'expenses_tab.dart';
import 'lending_tab.dart';
import 'tx_state.dart';

/// Expenses and Lending behind one switch.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kc = context.kc;
    final tab = ref.watch(txTabProvider);
    return Scaffold(
      backgroundColor: kc.bg,
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 16,
        title: SegmentedButton<int>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          segments: const [
            ButtonSegment(value: 0, label: Text('Expenses')),
            ButtonSegment(value: 1, label: Text('Lending')),
          ],
          selected: {tab},
          onSelectionChanged: (s) => ref.read(txTabProvider.notifier).show(s.first),
        ),
        shape: Border(bottom: BorderSide(color: kc.line)),
      ),
      body: tab == 0 ? const ExpensesTab() : const LendingTab(),
    );
  }
}
