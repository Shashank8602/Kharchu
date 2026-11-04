import 'package:flutter/material.dart';

import '../../../core/dates.dart';
import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../services/agent/proposals.dart';

/// What the cards can ask the screen to do.
class CardCallbacks {
  const CardCallbacks({
    required this.onConfirm,
    required this.onCancel,
    required this.onEdit,
    required this.onPaymentChosen,
    required this.onUseOther,
    required this.onChoose,
  });

  final Future<void> Function() onConfirm;
  final Future<void> Function() onCancel;
  final Future<void> Function() onEdit;
  final Future<void> Function(String method) onPaymentChosen;
  final Future<void> Function() onUseOther;
  final Future<void> Function(int itemId) onChoose;
}

/// The pending card for a proposal.
class ProposalCard extends StatelessWidget {
  const ProposalCard({
    super.key,
    required this.proposal,
    required this.todayIso,
    required this.callbacks,
  });

  final Proposal proposal;
  final String todayIso;
  final CardCallbacks callbacks;

  @override
  Widget build(BuildContext context) => switch (proposal) {
    final AddExpenseProposal p => _AddCard(p, todayIso, callbacks),
    final UpdateExpenseProposal p => _UpdateCard(p, callbacks),
    final DeleteExpenseProposal p => _DeleteCard(p, todayIso, callbacks),
    final SetBudgetProposal p => _BudgetCard(p, callbacks),
    final LoanProposal p => _LoanCard(p, todayIso, callbacks),
    final RepaymentProposal p => _RepaymentCard(p, callbacks),
    final PickProposal p => _PickCard(p, callbacks),
  };
}

class _Shell extends StatelessWidget {
  const _Shell({required this.children, this.banner});
  final List<Widget> children;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?banner,
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount(this.paise);
  final int paise;

  /// Scales down instead of overflowing, so ₹10,00,000 still fits beside a
  /// long category name on a narrow phone.
  @override
  Widget build(BuildContext context) => Flexible(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        formatINR(paise),
        maxLines: 1,
        style: headingStyle(size: 28, color: context.kc.ink),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {required this.bg, required this.fg, this.icon});
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Cancel / primary buttons. Disables itself while the action runs so a quick
/// double tap cannot fire twice.
class _Buttons extends StatefulWidget {
  const _Buttons({
    required this.cancelLabel,
    required this.primaryLabel,
    required this.onCancel,
    required this.onPrimary,
    this.danger = false,
  });
  final String cancelLabel;
  final String primaryLabel;
  final Future<void> Function() onCancel;
  final Future<void> Function() onPrimary;
  final bool danger;

  @override
  State<_Buttons> createState() => _ButtonsState();
}

class _ButtonsState extends State<_Buttons> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await f();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _busy ? null : () => _run(widget.onCancel),
            child: Text(widget.cancelLabel),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton(
            style: widget.danger
                ? FilledButton.styleFrom(
                    backgroundColor: kc.danger,
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: _busy ? null : () => _run(widget.onPrimary),
            child: Text(widget.primaryLabel),
          ),
        ),
      ],
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard(this.p, this.todayIso, this.cb);
  final AddExpenseProposal p;
  final String todayIso;
  final CardCallbacks cb;

  static const _methods = [('cash', 'Cash'), ('upi', 'UPI'), ('card', 'Card')];

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final detail = [
      p.item,
      if (p.location != null) p.location!,
      friendlyDate(p.spentOn, todayIso),
    ].join(' · ');

    final banner = p.isNewCategory
        ? Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: kc.lentBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New category',
                  style: TextStyle(
                    color: kc.lentInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'None of your categories fit. Create "${p.categoryName}"?',
                  style: TextStyle(color: kc.lentInk, fontSize: 14),
                ),
              ],
            ),
          )
        : null;

    return _Shell(
      banner: banner,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Amount(p.amountPaise),
            Flexible(
              child: _Pill(p.categoryName, bg: kc.soft, fg: kc.softInk),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(detail, style: TextStyle(color: kc.muted, fontSize: 14)),
        if (p.warnings.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (p.warnings.contains('large_amount'))
                _Pill(
                  'Large amount, please check',
                  bg: kc.warnBg,
                  fg: kc.warnInk,
                ),
              if (p.warnings.contains('future_date'))
                _Pill('Date set to today', bg: kc.warnBg, fg: kc.warnInk),
            ],
          ),
        ],
        if (p.paymentMethod == null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < _methods.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () => cb.onPaymentChosen(_methods[i].$1),
                    child: Text(_methods[i].$2),
                  ),
                ),
              ],
            ],
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            _paymentLabel(p.paymentMethod!),
            style: TextStyle(
              color: kc.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (p.isNewCategory)
          _Buttons(
            cancelLabel: 'Use "Other"',
            primaryLabel: 'Create & save',
            onCancel: cb.onUseOther,
            onPrimary: cb.onConfirm,
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: cb.onEdit,
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _SaveOnly(label: 'Save', onTap: cb.onConfirm),
              ),
            ],
          ),
        // Dropping the whole entry, whichever way it was proposed.
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: cb.onCancel,
            style: TextButton.styleFrom(foregroundColor: kc.muted),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  static String _paymentLabel(String m) => switch (m) {
    'cash' => 'Cash',
    'upi' => 'UPI',
    'card' => 'Card',
    'netbanking' => 'Net banking',
    _ => 'Other',
  };
}

class _SaveOnly extends StatefulWidget {
  const _SaveOnly({required this.label, required this.onTap});
  final String label;
  final Future<void> Function() onTap;

  @override
  State<_SaveOnly> createState() => _SaveOnlyState();
}

class _SaveOnlyState extends State<_SaveOnly> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: _busy
        ? null
        : () async {
            setState(() => _busy = true);
            try {
              await widget.onTap();
            } finally {
              if (mounted) setState(() => _busy = false);
            }
          },
    child: Text(widget.label),
  );
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard(this.p, this.cb);
  final UpdateExpenseProposal p;
  final CardCallbacks cb;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final rows = <Widget>[];
    void row(String label, String before, String after) => rows.add(
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kc.field,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(label, style: TextStyle(color: kc.muted, fontSize: 13)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  before,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kc.muted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16, color: kc.muted),
              ),
              Flexible(
                child: Text(
                  after,
                  overflow: TextOverflow.ellipsis,
                  style: headingStyle(size: 17, color: kc.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final c = p.changes;
    final b = p.before;
    if (c.containsKey('amountPaise')) {
      row(
        'Amount',
        formatINR(b['amountPaise'] as int),
        formatINR(c['amountPaise'] as int),
      );
    }
    if (c.containsKey('item')) {
      row('Item', b['item'] as String, c['item'] as String);
    }
    if (c.containsKey('categoryName')) {
      row('Category', b['categoryName'] as String, c['categoryName'] as String);
    }
    if (c.containsKey('spentOn')) {
      row(
        'Date',
        fullDateLabel(b['spentOn'] as String),
        fullDateLabel(c['spentOn'] as String),
      );
    }
    if (c.containsKey('location')) {
      row(
        'Place',
        (b['location'] as String?) ?? 'none',
        (c['location'] as String?) ?? 'none',
      );
    }
    if (c.containsKey('paymentMethod')) {
      row(
        'Paid with',
        (b['paymentMethod'] as String?) ?? 'not set',
        (c['paymentMethod'] as String?) ?? 'not set',
      );
    }

    return _Shell(
      children: [
        Text(
          'Update · ${p.itemBefore}',
          style: TextStyle(
            color: kc.ink,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        Text(
          '${dayLabel(b['spentOn'] as String)} · ${b['categoryName']}',
          style: TextStyle(color: kc.muted, fontSize: 13),
        ),
        ...rows,
        const SizedBox(height: 14),
        _Buttons(
          cancelLabel: 'Cancel',
          primaryLabel: 'Update',
          onCancel: cb.onCancel,
          onPrimary: cb.onConfirm,
        ),
      ],
    );
  }
}

class _DeleteCard extends StatelessWidget {
  const _DeleteCard(this.p, this.todayIso, this.cb);
  final DeleteExpenseProposal p;
  final String todayIso;
  final CardCallbacks cb;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return _Shell(
      children: [
        Text(
          'Delete this expense?',
          style: TextStyle(
            color: kc.dangerInk,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Amount(p.amountPaise),
            Flexible(
              child: _Pill(p.categoryName, bg: kc.soft, fg: kc.softInk),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${p.item} · ${friendlyDate(p.spentOn, todayIso)}',
          style: TextStyle(color: kc.muted, fontSize: 14),
        ),
        const SizedBox(height: 14),
        _Buttons(
          cancelLabel: 'Keep',
          primaryLabel: 'Delete',
          danger: true,
          onCancel: cb.onCancel,
          onPrimary: cb.onConfirm,
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard(this.p, this.cb);
  final SetBudgetProposal p;
  final CardCallbacks cb;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return _Shell(
      children: [
        Text(
          '${p.categoryName} budget',
          style: TextStyle(
            color: kc.muted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            _Amount(p.limitPaise),
            const SizedBox(width: 6),
            Text('/ month', style: TextStyle(color: kc.muted)),
          ],
        ),
        if (p.previousLimitPaise != null) ...[
          const SizedBox(height: 6),
          Text(
            'Replaces ${formatINR(p.previousLimitPaise!)}',
            style: TextStyle(color: kc.muted, fontSize: 13),
          ),
        ],
        const SizedBox(height: 14),
        _Buttons(
          cancelLabel: 'Cancel',
          primaryLabel: 'Set budget',
          onCancel: cb.onCancel,
          onPrimary: cb.onConfirm,
        ),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard(this.p, this.todayIso, this.cb);
  final LoanProposal p;
  final String todayIso;
  final CardCallbacks cb;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final bg = p.lent ? kc.lentBg : kc.borrowedBg;
    final fg = p.lent ? kc.lentInk : kc.borrowedInk;
    final detail = [
      if (p.note != null) p.note!,
      if (p.paymentMethod != null) _AddCard._paymentLabel(p.paymentMethod!),
      friendlyDate(p.happenedOn, todayIso),
    ].join(' · ');
    return _Shell(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Amount(p.amountPaise),
            _Pill(
              p.lent ? 'You lent' : 'You borrowed',
              bg: bg,
              fg: fg,
              icon: p.lent ? Icons.north_east : Icons.south_west,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: bg,
              child: Text(
                p.personName.isEmpty ? '?' : p.personName[0].toUpperCase(),
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.personName,
                    style: TextStyle(
                      color: kc.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    p.isNewPerson ? '$detail · new person' : detail,
                    style: TextStyle(color: kc.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (p.warnings.contains('large_amount')) ...[
          const SizedBox(height: 10),
          _Pill('Large amount, please check', bg: kc.warnBg, fg: kc.warnInk),
        ],
        const SizedBox(height: 14),
        _Buttons(
          cancelLabel: 'Cancel',
          primaryLabel: 'Save',
          onCancel: cb.onCancel,
          onPrimary: cb.onConfirm,
        ),
      ],
    );
  }
}

class _RepaymentCard extends StatelessWidget {
  const _RepaymentCard(this.p, this.cb);
  final RepaymentProposal p;
  final CardCallbacks cb;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final bg = p.lent ? kc.lentBg : kc.borrowedBg;
    final fg = p.lent ? kc.lentInk : kc.borrowedInk;
    final settles = p.outstandingAfterPaise == 0;
    return _Shell(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Amount(p.amountPaise),
            _Pill(
              p.lent ? 'Paid back to you' : 'You paid back',
              bg: bg,
              fg: fg,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          p.personName,
          style: TextStyle(color: kc.ink, fontWeight: FontWeight.w700),
        ),
        if (p.note != null)
          Text(p.note!, style: TextStyle(color: kc.muted, fontSize: 13)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kc.field,
            borderRadius: BorderRadius.circular(12),
          ),
          // scales down rather than overflowing with large amounts
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.lent ? 'Owes you' : 'You owe',
                  style: TextStyle(color: kc.muted, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Text(
                  formatINR(p.outstandingBeforePaise),
                  style: TextStyle(
                    color: kc.muted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16, color: kc.muted),
                ),
                Text(
                  settles ? 'Settled' : formatINR(p.outstandingAfterPaise),
                  style: headingStyle(
                    size: 17,
                    color: settles ? kc.softInk : kc.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _Buttons(
          cancelLabel: 'Cancel',
          primaryLabel: 'Save',
          onCancel: cb.onCancel,
          onPrimary: cb.onConfirm,
        ),
      ],
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard(this.p, this.cb);
  final PickProposal p;
  final CardCallbacks cb;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final title = switch (p.kind) {
      'person' => 'Which person?',
      'loan' => 'Which loan?',
      _ => 'Which one?',
    };
    return _Shell(
      children: [
        Text(
          title,
          style: TextStyle(
            color: kc.ink,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in p.items)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Material(
              color: kc.field,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => cb.onChoose(item.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                color: kc.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              item.subtitle,
                              style: TextStyle(color: kc.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (item.amountPaise != null)
                        Text(
                          formatINR(item.amountPaise!),
                          style: TextStyle(
                            color: kc.ink,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: cb.onCancel,
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}
