import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/lending_repository.dart';
import '../../data/repositories/watch.dart';
import '../../providers.dart';
import '../../services/agent/parsing.dart';
import '../chat/chat_controller.dart' show todayProvider;

class PersonDetail {
  const PersonDetail(this.person, this.loans, this.events);
  final Person person;
  final List<LoanView> loans;
  final List<LendingEvent> events;

  List<LoanView> get open => loans.where((l) => !l.settled).toList();

  int get net => loans.fold<int>(
      0, (a, l) => a + (l.lent ? l.outstandingPaise : -l.outstandingPaise));
}

/// Null when the person does not exist (for example a stale link).
final personDetailProvider =
    StreamProvider.autoDispose.family<PersonDetail?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  final repo = ref.watch(lendingRepoProvider);
  return watchQuery<PersonDetail?>(db, {db.loans, db.loanRepayments, db.people}, () async {
    final p = await repo.personById(id);
    if (p == null) return null;
    return PersonDetail(
      p,
      await repo.loanViews(personId: id),
      (await repo.history(id)).reversed.toList(),
    );
  });
});

class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.personId});
  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kc = context.kc;
    final detail = ref.watch(personDetailProvider(personId));
    final today = ref.watch(todayProvider);

    return Scaffold(
      backgroundColor: kc.bg,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/transactions'),
        ),
        title: Text(detail.asData?.value?.person.name ?? '',
            style: headingStyle(size: 19, color: kc.ink)),
        shape: Border(bottom: BorderSide(color: kc.line)),
      ),
      body: detail.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const Center(child: Text("Couldn't load this person.")),
        data: (d) {
          if (d == null) return Center(child: Text('Not found', style: TextStyle(color: kc.muted)));
          final owesYou = d.net >= 0;
          final settled = d.open.isEmpty;
          final bg = settled ? kc.field : (owesYou ? kc.lentBg : kc.borrowedBg);
          final fg = settled ? kc.muted : (owesYou ? kc.lentInk : kc.borrowedInk);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration:
                    BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(settled ? 'All settled' : (owesYou ? 'Owes you' : 'You owe'),
                        style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(formatINR(d.net.abs()),
                          style: headingStyle(size: 30, color: fg)),
                    ),
                  ],
                ),
              ),
              if (!settled) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _recordRepayment(context, ref, d, today),
                  icon: const Icon(Icons.payments_outlined, size: 20),
                  label: const Text('Record repayment'),
                ),
              ],
              const SizedBox(height: 20),
              Text('History',
                  style: TextStyle(
                      color: kc.muted, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 8),
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
                    for (var i = 0; i < d.events.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: kc.hair),
                      _EventRow(d.events[i], d, today),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _recordRepayment(
      BuildContext context, WidgetRef ref, PersonDetail d, String today) async {
    final result = await showModalBottomSheet<_RepaymentInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.kc.surface,
      builder: (_) => _RepaymentSheet(loans: d.open, todayIso: today),
    );
    if (result == null || !context.mounted) return;
    String? problem;
    try {
      await ref.read(lendingRepoProvider).addRepayment(
            loanId: result.loanId,
            amountPaise: result.paise,
            paidOn: result.date,
          );
    } on RepaymentExceedsOutstanding catch (e) {
      problem = 'Only ${formatINR(e.outstandingPaise)} is outstanding on that loan.';
    } on LendingException catch (e) {
      problem = e.message;
    }
    if (problem != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
    }
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow(this.e, this.d, this.today);
  final LendingEvent e;
  final PersonDetail d;
  final String today;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final loan = d.loans.where((l) => l.loan.id == e.loanId).firstOrNull;
    final lent = e.direction == 'lent';
    final title = e.isRepayment
        ? (lent ? 'Paid back' : 'You paid back')
        : (lent ? 'You lent' : 'You borrowed');
    final note = e.isRepayment ? loan?.loan.note : e.note;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              e.isRepayment
                  ? Icons.check_circle_outline
                  : (lent ? Icons.north_east : Icons.south_west),
              size: 20,
              color: e.isRepayment ? kc.accent : (lent ? kc.lentInk : kc.borrowedInk),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: kc.ink, fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(
                    [?note, friendlyDate(e.date, today)].join(' · '),
                    style: TextStyle(color: kc.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(formatINR(e.amountPaise),
                style: TextStyle(
                    color: kc.ink,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      ),
    );
  }
}

class _RepaymentInput {
  const _RepaymentInput(this.loanId, this.paise, this.date);
  final int loanId;
  final int paise;
  final String date;
}

class _RepaymentSheet extends StatefulWidget {
  const _RepaymentSheet({required this.loans, required this.todayIso});
  final List<LoanView> loans;
  final String todayIso;

  @override
  State<_RepaymentSheet> createState() => _RepaymentSheetState();
}

class _RepaymentSheetState extends State<_RepaymentSheet> {
  late LoanView _loan = widget.loans.first; // oldest-first is chosen by the caller
  late final TextEditingController _amount = TextEditingController(text: _fmt(_loan));
  late String _date = widget.todayIso;
  String? _error;

  static String _fmt(LoanView l) => l.outstandingPaise % 100 == 0
      ? '${l.outstandingPaise ~/ 100}'
      : (l.outstandingPaise / 100).toStringAsFixed(2);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final r = parseRupees(_amount.text);
    if (r == null || r <= 0) {
      setState(() => _error = 'Enter an amount');
      return;
    }
    final paise = rupeesToPaise(r);
    if (paise > _loan.outstandingPaise) {
      setState(() => _error = 'More than the ${formatINR(_loan.outstandingPaise)} outstanding');
      return;
    }
    Navigator.pop(context, _RepaymentInput(_loan.loan.id, paise, _date));
  }

  Future<void> _pickDate() async {
    final last = tryParseIso(widget.todayIso)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: tryParseIso(_date) ?? last,
      firstDate: DateTime.utc(2000),
      lastDate: last,
    );
    if (picked != null) setState(() => _date = isoDate(picked));
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
            Text('Record repayment', style: headingStyle(size: 19, color: kc.ink)),
            const SizedBox(height: 16),
            if (widget.loans.length > 1) ...[
              DropdownButtonFormField<int>(
                initialValue: _loan.loan.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Which loan'),
                items: [
                  for (final l in widget.loans)
                    DropdownMenuItem(
                      value: l.loan.id,
                      child: Text(
                          '${l.loan.note ?? (l.lent ? 'Lent' : 'Borrowed')} · '
                          '${dayLabel(l.loan.happenedOn)} · ${formatINR(l.outstandingPaise)}',
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (id) => setState(() {
                  _loan = widget.loans.firstWhere((l) => l.loan.id == id);
                  _amount.text = _fmt(_loan);
                  _error = null;
                }),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: 'Amount', prefixText: '₹ ', errorText: _error),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(friendlyDate(_date, widget.todayIso)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: FilledButton(onPressed: _save, child: const Text('Save'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
