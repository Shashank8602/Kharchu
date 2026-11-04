import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/manual_entry.dart';
import '../../widgets/pill_toggle.dart';
import '../../widgets/swipe_shell.dart';
import 'expenses_tab.dart';
import 'lending_tab.dart';
import 'tx_state.dart';

/// Expenses and Lending side by side: tap the switch or swipe. A swipe past
/// either end carries on to the neighbouring screen of the bottom bar.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late final PageController _pages =
      PageController(initialPage: ref.read(txTabProvider));

  // Swipe handed over to the shell while the inner pages are at their end.
  PageController? _outer;
  int _outerStart = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.horizontal) return false;
    final outer = _outer;
    if (outer == null || !outer.hasClients) return false;
    if (n is ScrollStartNotification) {
      _outerStart = outer.page?.round() ?? 0;
    } else if (n is OverscrollNotification) {
      final o = outer.position;
      outer.jumpTo((o.pixels + n.overscroll).clamp(o.minScrollExtent, o.maxScrollExtent));
    } else if (n is ScrollEndNotification) {
      final page = outer.page ?? _outerStart.toDouble();
      if ((page - _outerStart).abs() > 0.001) {
        // past a fifth of the way: go on to the next screen, else spring back
        final moved = page - _outerStart;
        final target = moved.abs() > 0.2 ? _outerStart + (moved > 0 ? 1 : -1) : _outerStart;
        outer.animateToPage(
          target.clamp(0, 4),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final tab = ref.watch(txTabProvider);
    _outer = ShellPager.maybeOf(context);

    // taps on the switch (or the Dashboard tile) slide the pages
    ref.listen(txTabProvider, (_, next) {
      if (_pages.hasClients && _pages.page?.round() != next) {
        _pages.animateToPage(
          next,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });

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
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: PageView(
          controller: _pages,
          onPageChanged: (i) => ref.read(txTabProvider.notifier).show(i),
          children: const [
            _Keep(child: ExpensesTab()),
            _Keep(child: LendingTab()),
          ],
        ),
      ),
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

class _Keep extends StatefulWidget {
  const _Keep({required this.child});
  final Widget child;

  @override
  State<_Keep> createState() => _KeepState();
}

class _KeepState extends State<_Keep> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
