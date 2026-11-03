import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../providers.dart';
import '../../services/agent/agent_service.dart';
import '../../services/groq/groq_errors.dart';

/// The chat's day. Refreshed when the app resumes so a chat left open past
/// midnight starts fresh.
class TodayNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(todayFnProvider)();

  void refresh() {
    final now = ref.read(todayFnProvider)();
    if (now != state) state = now;
  }
}

final todayProvider = NotifierProvider<TodayNotifier, String>(TodayNotifier.new);

/// Today's messages, live.
final chatMessagesProvider = StreamProvider.autoDispose<List<ChatMessage>>((ref) {
  final day = ref.watch(todayProvider);
  return ref.watch(chatRepoProvider).watchDay(day);
});

class ChatState {
  const ChatState({this.sending = false, this.error, this.failedText});
  final bool sending;

  /// Set when the last message could not be handled.
  final GroqException? error;
  final String? failedText;

  /// An error that is not Groq's (for example the database), shown generically.
  bool get hasError => error != null;
}

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty || state.sending) return;
    await _run(t, alreadyStored: false);
  }

  /// Runs the failed message again without adding it to the chat twice.
  Future<void> retry() async {
    final t = state.failedText;
    if (t == null || state.sending) return;
    await _run(t, alreadyStored: true);
  }

  void dismissError() => state = const ChatState();

  Future<void> _run(String text, {required bool alreadyStored}) async {
    state = const ChatState(sending: true);
    try {
      final reply = await ref
          .read(agentServiceProvider)
          .handle(text, alreadyStored: alreadyStored);
      state = reply is AgentFailure
          ? ChatState(error: reply.error, failedText: text)
          : const ChatState();
    } catch (_) {
      // Anything unexpected (a database error, say) must not leave the
      // composer stuck on "sending".
      state = ChatState(error: const GroqBadResponse('unexpected'), failedText: text);
    }
  }
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatState>(ChatController.new);
