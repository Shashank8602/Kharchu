import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../providers.dart';
import '../../services/agent/proposals.dart';
import 'chat_controller.dart' show todayProvider;

class HistoryLine {
  const HistoryLine(this.mark, this.text);

  /// '✓' for something saved, '?' for a question answered.
  final String mark;
  final String text;
}

class HistoryDay {
  const HistoryDay(this.day, this.lines);
  final String day;
  final List<HistoryLine> lines;

  int get saved => lines.where((l) => l.mark == '✓').length;
  int get asked => lines.length - saved;
}

/// Earlier days' chats, newest first, boiled down to what happened.
final historyProvider = FutureProvider.autoDispose<List<HistoryDay>>((
  ref,
) async {
  final chat = ref.watch(chatRepoProvider);
  final today = ref.watch(todayProvider);
  final days = <HistoryDay>[];
  for (final day in await chat.pastDays(today)) {
    final lines = <HistoryLine>[];
    String? lastUser;
    for (final m in await chat.messagesForDay(day)) {
      if (m.role == 'user') {
        lastUser = m.body;
      } else if (m.role == 'assistant' && lastUser != null) {
        lines.add(HistoryLine('?', lastUser));
        lastUser = null;
      } else if (m.role == 'card' &&
          m.cardStatus == 'confirmed' &&
          m.cardPayload != null) {
        try {
          final p = Proposal.fromJson(
            jsonDecode(m.cardPayload!) as Map<String, dynamic>,
          );
          if (p is! PickProposal) lines.add(HistoryLine('✓', p.summary));
        } catch (_) {}
      }
    }
    if (lines.isNotEmpty) days.add(HistoryDay(day, lines));
  }
  return days;
});

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String? _open;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final days = ref.watch(historyProvider);
    final today = ref.watch(todayProvider);
    return Scaffold(
      backgroundColor: kc.bg,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/chat'),
        ),
        title: Text('History', style: headingStyle(size: 19, color: kc.ink)),
        shape: Border(bottom: BorderSide(color: kc.line)),
      ),
      body: days.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const Center(child: Text("Couldn't load history.")),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                'Nothing earlier yet',
                style: TextStyle(color: kc.muted),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final d in list) ...[
                _DayCard(
                  day: d,
                  label: friendlyDate(d.day, today),
                  open: _open == d.day,
                  onToggle: () =>
                      setState(() => _open = _open == d.day ? null : d.day),
                ),
                const SizedBox(height: 8),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Chats clear after 30 days. Your entries stay.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kc.muted, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.label,
    required this.open,
    required this.onToggle,
  });

  final HistoryDay day;
  final String label;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final summary = [
      if (day.saved > 0) '${day.saved} saved',
      if (day.asked > 0) '${day.asked} asked',
    ].join(' · ');
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
          InkWell(
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: kc.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      summary,
                      style: TextStyle(color: kc.muted, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: kc.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  for (final l in day.lines)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: kc.field,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            l.mark,
                            style: TextStyle(
                              color: kc.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: kc.ink, fontSize: 14),
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
