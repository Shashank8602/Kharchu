import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/manual_entry.dart';
import '../../widgets/pill_toggle.dart';
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
        title: PillToggle(
          labels: const ['Expenses', 'Lending'],
          selected: tab,
          onChanged: (i) => ref.read(txTabProvider.notifier).show(i),
          selectedColors: [
            (kc.accent, kc.onAccent),
            (kc.lentInk, kc.lentBg),
          ],
        ),
        shape: Border(bottom: BorderSide(color: kc.line)),
      ),
      body: tab == 0 ? const ExpensesTab() : const LendingTab(),
      // works without the AI, so entries can still be made when Groq cannot
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => tab == 0
            ? addExpenseManually(context, ref)
            : addLoanManually(context, ref),
        backgroundColor: tab == 0 ? kc.accent : kc.lentInk,
        foregroundColor: tab == 0 ? kc.onAccent : kc.lentBg,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: Text(tab == 0 ? 'Add expense' : 'Add lending'),
      ),
    );
  }
}
