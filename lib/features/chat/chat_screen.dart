import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../providers.dart';
import '../../services/agent/proposals.dart';
import '../../services/card_actions.dart';
import '../../widgets/expense_form_sheet.dart';
import '../../widgets/manual_entry.dart';
import 'chat_controller.dart';
import 'voice_controller.dart';
import 'widgets/bubbles.dart';
import 'widgets/cards.dart';
import 'widgets/composer.dart';
import 'widgets/recording_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  // Messages already on screen. Only ones that arrive later slide in.
  final _known = <String>{};
  bool _primed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the background, possibly after midnight: start the new day.
    if (state == AppLifecycleState.resumed) {
      ref.read(todayProvider.notifier).refresh();
    }
    // never keep the microphone open in the background (not on `inactive`,
    // which is also what the system permission dialog causes)
    if (state == AppLifecycleState.paused) {
      ref.read(voiceControllerProvider.notifier).cancel();
    }
  }

  Future<void> _startVoice() async {
    final problem = await ref.read(voiceControllerProvider.notifier).start();
    if (problem != null) _toast(problem);
  }

  Future<void> _stopVoice() async {
    final problem = await ref
        .read(voiceControllerProvider.notifier)
        .stopAndSend();
    if (problem != null) _toast(problem);
  }

  Proposal? _proposalOf(ChatMessage m) {
    try {
      return Proposal.fromJson(
        jsonDecode(m.cardPayload!) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  void _toast(String text, {SnackBarAction? action, Duration? duration}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: action,
          duration: duration ?? const Duration(seconds: 4),
          // sit above the composer, so the mic and Send stay reachable
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 84),
        ),
      );
  }

  Future<void> _confirm(ChatMessage m, {Proposal? edited}) async {
    final actions = ref.read(cardActionsProvider);
    final proposal = edited ?? _proposalOf(m);
    final r = await actions.confirm(m.id, edited: edited);
    switch (r) {
      case Committed(:final expenseId):
        if (proposal is DeleteExpenseProposal && expenseId != null) {
          _toast(
            'Deleted ${formatINR(proposal.amountPaise)} ${proposal.item}',
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => actions.undoDelete(m.id, expenseId),
            ),
          );
        }
      case AlreadyHandled():
        break;
      case Expired(:final message):
        _toast(message);
      case CommitFailed(:final message):
        _toast(message);
    }
  }

  Future<void> _edit(ChatMessage m, AddExpenseProposal p) async {
    final cats = await ref.read(categoryRepoProvider).active();
    if (!mounted) return;
    final r = await showExpenseSheet(
      context,
      categories: cats,
      todayIso: ref.read(todayProvider),
      title: 'Edit expense',
      actionLabel: 'Save',
      amountPaise: p.amountPaise,
      item: p.item,
      categoryId: p.categoryId,
      newCategoryName: p.isNewCategory ? p.categoryName : null,
      location: p.location,
      paymentMethod: p.paymentMethod,
      spentOn: p.spentOn,
    );
    if (r == null) return;
    final isNew = r.categoryId == kNewCategoryId;
    await _confirm(
      m,
      edited: AddExpenseProposal(
        amountPaise: r.amountPaise,
        item: r.item,
        categoryName: r.categoryName,
        categoryId: isNew ? null : r.categoryId,
        isNewCategory: isNew,
        location: r.location,
        paymentMethod: r.paymentMethod,
        spentOn: r.spentOn,
        rawText: p.rawText,
        source: p.source,
      ),
    );
  }

  Future<void> _useOther(ChatMessage m, AddExpenseProposal p) async {
    final other = await ref.read(categoryRepoProvider).fallbackOther();
    if (other == null) return;
    await _confirm(
      m,
      edited: AddExpenseProposal(
        amountPaise: p.amountPaise,
        item: p.item,
        categoryName: other.name,
        categoryId: other.id,
        location: p.location,
        paymentMethod: p.paymentMethod,
        spentOn: p.spentOn,
        rawText: p.rawText,
        source: p.source,
        warnings: p.warnings,
      ),
    );
  }

  CardCallbacks _callbacks(ChatMessage m, Proposal p) {
    final actions = ref.read(cardActionsProvider);
    return CardCallbacks(
      onConfirm: () => _confirm(m),
      onCancel: () => actions.cancel(m.id),
      onEdit: () async {
        if (p is AddExpenseProposal) await _edit(m, p);
      },
      onPaymentChosen: (method) async {
        if (p is AddExpenseProposal) {
          await actions.updatePending(m.id, p.copyWith(paymentMethod: method));
        }
      },
      onUseOther: () async {
        if (p is AddExpenseProposal) await _useOther(m, p);
      },
      onChoose: (id) async {
        final problem = await actions.choose(m.id, id);
        if (problem != null) _toast(problem);
      },
    );
  }

  Widget? _messageView(ChatMessage m, String today) {
    switch (m.role) {
      case 'user':
        return m.body == null ? null : UserBubble(m.body!);
      case 'assistant':
        return m.body == null ? null : AssistantBubble(m.body!);
      case 'notice':
        return BudgetNoticeTile(m);
      case 'card':
        final p = _proposalOf(m);
        if (p == null) return null;
        return switch (m.cardStatus) {
          'pending' => ProposalCard(
            proposal: p,
            todayIso: today,
            callbacks: _callbacks(m, p),
          ),
          'confirmed' => p is PickProposal ? null : SavedChip(proposal: p),
          'expired' => const _ExpiredNote(),
          _ => null, // cancelled cards disappear
        };
    }
    return null;
  }

  Widget? _animated(ChatMessage m, String today) {
    final view = _messageView(m, today);
    if (view == null) return null;
    final fresh = _primed && !_known.contains(m.id);
    _known.add(m.id);
    return _Appear(
      key: ValueKey('msg-${m.id}'),
      animate: fresh,
      // a card turning into its "saved" line cross-fades and resizes
      child: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: KeyedSubtree(
            key: ValueKey('${m.id}-${m.cardStatus}'),
            child: view,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final today = ref.watch(todayProvider);
    final loaded = ref.watch(chatMessagesProvider).asData;
    final messages = loaded?.value ?? const <ChatMessage>[];
    final chat = ref.watch(chatControllerProvider);
    final voice = ref.watch(voiceControllerProvider);
    final transcribing = voice.phase == VoicePhase.transcribing;

    final items = <Widget>[
      if (messages.isNotEmpty) const DayLabel('Today'),
      for (final m in messages) ?_animated(m, today),
      if (transcribing) const ThinkingBubble(label: 'Transcribing…'),
      if (chat.sending) const ThinkingBubble(),
      if (chat.error != null)
        ErrorBubble(
          error: chat.error!,
          onRetry: () => ref.read(chatControllerProvider.notifier).retry(),
          onDismiss: () =>
              ref.read(chatControllerProvider.notifier).dismissError(),
          onManual: () => showManualEntryMenu(context, ref),
        ),
    ];

    if (loaded != null) _primed = true;

    return Scaffold(
      backgroundColor: kc.bg,
      appBar: AppBar(
        title: Text(
          'Kharchu',
          style: headingStyle(
            size: 22,
            color: kc.ink,
          ).copyWith(letterSpacing: -0.4),
        ),
        shape: Border(bottom: BorderSide(color: kc.line)),
        actions: [
          IconButton(
            tooltip: 'Add manually',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => showManualEntryMenu(context, ref),
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/chat/history'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              // reversed: index 0 is the newest, at the bottom
              itemBuilder: (_, i) => items[items.length - 1 - i],
            ),
          ),
          if (voice.phase == VoicePhase.recording)
            RecordingBar(
              seconds: voice.seconds,
              levels: voice.levels,
              onCancel: () =>
                  ref.read(voiceControllerProvider.notifier).cancel(),
              onStop: _stopVoice,
            )
          else
            Composer(
              sending: chat.sending || transcribing,
              onSend: (t) => ref.read(chatControllerProvider.notifier).send(t),
              trailing: IconButton.filled(
                tooltip: 'Speak',
                onPressed: (chat.sending || transcribing) ? null : _startVoice,
                style: IconButton.styleFrom(
                  backgroundColor: kc.accent,
                  foregroundColor: kc.onAccent,
                  disabledBackgroundColor: kc.track,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.mic_none),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpiredNote extends StatelessWidget {
  const _ExpiredNote();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      'That card expired because the entry changed. Ask again.',
      style: TextStyle(color: context.kc.muted, fontSize: 13),
    ),
  );
}

/// Fades and lifts a message in once, when it first appears.
class _Appear extends StatefulWidget {
  const _Appear({super.key, required this.animate, required this.child});
  final bool animate;
  final Widget child;

  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.animate ? 0 : 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(
      position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(_curve),
      child: widget.child,
    ),
  );
}
