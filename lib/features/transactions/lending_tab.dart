import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/repositories/lending_repository.dart';
import '../../providers.dart';

final lendingBalancesProvider = StreamProvider.autoDispose<List<PersonBalance>>(
    (ref) => ref.watch(lendingRepoProvider).watchBalances());

final lendingTotalsProvider = StreamProvider.autoDispose<LendingTotals>(
    (ref) => ref.watch(lendingRepoProvider).watchTotals());

class LendingTab extends ConsumerWidget {
  const LendingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kc = context.kc;
    final totals = ref.watch(lendingTotalsProvider).asData?.value;
    final balances = ref.watch(lendingBalancesProvider);

    return balances.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const Center(child: Text("Couldn't load lending.")),
      data: (list) {
        final open = list.where((b) => !b.settled).toList();
        final settled = list.where((b) => b.settled).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            Row(
              children: [
                _Tile("You'll get", totals?.getPaise ?? 0, kc.lentBg, kc.lentInk),
                const SizedBox(width: 10),
                _Tile('You owe', totals?.owePaise ?? 0, kc.borrowedBg, kc.borrowedInk),
              ],
            ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                    child: Text('No lending yet', style: TextStyle(color: kc.muted))),
              ),
            if (open.isNotEmpty) ...[
              const _SectionLabel('Open'),
              _Group([for (final b in open) _PersonRow(b)]),
            ],
            if (settled.isNotEmpty) ...[
              const _SectionLabel('Settled'),
              _Group([for (final b in settled) _PersonRow(b)]),
            ],
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.paise, this.bg, this.fg);
  final String label;
  final int paise;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(formatINR(paise), style: headingStyle(size: 24, color: fg)),
              ),
            ],
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(text,
            style: TextStyle(
                color: context.kc.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

class _Group extends StatelessWidget {
  const _Group(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Container(
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
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: kc.hair),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow(this.b);
  final PersonBalance b;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final owesYou = b.netPaise >= 0;
    final bg = b.settled ? kc.field : (owesYou ? kc.lentBg : kc.borrowedBg);
    final fg = b.settled ? kc.muted : (owesYou ? kc.lentInk : kc.borrowedInk);
    return InkWell(
      onTap: () => context.go('/transactions/person/${b.person.id}'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: bg,
                child: Text(b.person.name.characters.first.toUpperCase(),
                    style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: b.settled ? kc.muted : kc.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(
                      b.settled
                          ? 'Settled ${dayLabel(b.lastActivity)}'
                          : 'Last ${dayLabel(b.lastActivity)}',
                      style: TextStyle(color: kc.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!b.settled)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatINR(b.netPaise.abs()),
                        style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                    Text(owesYou ? 'owes you' : 'you owe',
                        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
