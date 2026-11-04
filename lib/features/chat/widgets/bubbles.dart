import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../data/db/app_database.dart';
import '../../../services/agent/proposals.dart';
import '../../../services/groq/groq_errors.dart';

class UserBubble extends StatelessWidget {
  const UserBubble(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: kc.accent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(color: kc.onAccent, fontSize: 15, height: 1.35),
          ),
        ),
      ),
    );
  }
}

class AssistantBubble extends StatelessWidget {
  const AssistantBubble(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: kc.soft,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(color: kc.softInk, fontSize: 15, height: 1.4),
          ),
        ),
      ),
    );
  }
}

/// Shown while the model is working.
class ThinkingBubble extends StatelessWidget {
  const ThinkingBubble({super.key, this.label = 'Thinking…'});
  final String label;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kc.surface,
          border: Border.all(color: kc.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label, style: TextStyle(color: kc.muted, fontSize: 14)),
      ),
    );
  }
}

/// The error row: what went wrong, with Retry and/or Open Profile.
class ErrorBubble extends StatelessWidget {
  const ErrorBubble({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.onManual,
  });
  final GroqException error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  /// Opens the manual entry forms, so nothing is blocked while the AI is down.
  final VoidCallback? onManual;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kc.dangerBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 20, color: kc.dangerInk),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error.userMessage,
                  style: TextStyle(
                    color: kc.dangerInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (error.canRetry)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kc.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              if (error.needsProfile)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kc.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    onDismiss?.call();
                    context.go('/profile/groq');
                  },
                  child: const Text('Open Profile'),
                ),
              if (onManual != null)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kc.dangerInk,
                    side: BorderSide(color: kc.dangerInk.withValues(alpha: 0.4)),
                  ),
                  onPressed: onManual,
                  child: const Text('Add manually'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One line for something already saved.
class SavedChip extends StatelessWidget {
  const SavedChip({super.key, required this.proposal});
  final Proposal proposal;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final (lead, trail) = _parts(proposal);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kc.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: kc.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lead,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: kc.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trail != null) ...[
            const SizedBox(width: 8),
            Text(trail, style: TextStyle(color: kc.muted, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  static (String, String?) _parts(Proposal p) => switch (p) {
    AddExpenseProposal() => (
      '${formatINR(p.amountPaise)}  ${p.item}',
      p.categoryName,
    ),
    UpdateExpenseProposal() => ('Updated · ${p.itemBefore}', null),
    DeleteExpenseProposal() => (
      'Deleted · ${formatINR(p.amountPaise)}  ${p.item}',
      null,
    ),
    SetBudgetProposal() => (
      '${p.categoryName} budget · ${formatINR(p.limitPaise)}/month',
      null,
    ),
    LoanProposal() => (p.summary, null),
    RepaymentProposal() => (p.summary, null),
    PickProposal() => (p.summary, null),
  };
}

/// A budget warning from the app (not the AI).
class BudgetNoticeTile extends StatelessWidget {
  const BudgetNoticeTile(this.message, {super.key});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    var danger = false;
    try {
      danger =
          (jsonDecode(message.cardPayload ?? '{}') as Map)['level'] == 'danger';
    } catch (_) {}
    final bg = danger ? kc.dangerBg : kc.warnBg;
    final fg = danger ? kc.dangerInk : kc.warnInk;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.body ?? '',
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Today" divider at the top of the day's messages.
class DayLabel extends StatelessWidget {
  const DayLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.kc.muted,
      ),
    ),
  );
}
