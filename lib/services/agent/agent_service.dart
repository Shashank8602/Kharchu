import 'dart:convert';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/lending_repository.dart';
import '../groq/groq_client.dart';
import '../groq/groq_errors.dart';
import 'proposals.dart';
import 'system_prompt.dart';
import 'tool_executor.dart';
import 'tool_outcome.dart';
import 'tool_schemas.dart';

/// What came of one user message.
sealed class AgentReply {
  const AgentReply();
}

/// A plain answer, already stored in the chat.
class AgentAnswer extends AgentReply {
  const AgentAnswer(this.text);
  final String text;
}

/// A confirm card was added to the chat.
class AgentCard extends AgentReply {
  const AgentCard(this.messageId, this.proposal);
  final String messageId;
  final Proposal proposal;
}

/// One message produced several results: one or more confirm cards, and/or
/// a written answer (for example "Dinner ₹500 to confirm; spent ₹3,200 so far").
class AgentMulti extends AgentReply {
  const AgentMulti(this.cards, this.text);
  final List<AgentCard> cards;
  final String? text;
}

/// Groq could not be reached or refused. Nothing was stored but the user's
/// own message, so Retry can run it again.
class AgentFailure extends AgentReply {
  const AgentFailure(this.error);
  final GroqException error;
}

/// The loop: send the message and the list of actions to Groq, run whatever
/// it asks for (all the calls of a round, so one message can hold several
/// tasks), feed the results back, and stop when it has only proposals to show
/// (cards) or answers in words. At most [maxSteps] rounds.
class AgentService {
  AgentService({
    required this.groq,
    required this.chat,
    required this.executor,
    required this.expenses,
    required this.categories,
    required this.lending,
    required this.today,
    this.maxSteps = 4,
    this.historyTurns = 6,
  });

  final GroqClient groq;
  final ChatRepository chat;
  final ToolExecutor executor;
  final ExpenseRepository expenses;
  final CategoryRepository categories;
  final LendingRepository lending;
  final String Function() today;
  final int maxSteps;
  final int historyTurns;

  static const stuckMessage = "Sorry, I got stuck. Try rephrasing.";
  static const maxInputLength = 500;

  /// [alreadyStored] is true when retrying a message that is already in the
  /// chat, so it is not added twice.
  Future<AgentReply> handle(
    String text, {
    String source = 'chat',
    bool alreadyStored = false,
  }) async {
    final trimmed = text.trim();
    final input = trimmed.length > maxInputLength
        ? trimmed.substring(0, maxInputLength)
        : trimmed;
    final day = today();

    final history = await _history(day, input, alreadyStored);
    if (!alreadyStored) {
      await chat.add(day: day, role: 'user', body: input);
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': await _system(day)},
      ...history,
      {'role': 'user', 'content': input},
    ];

    // Cards made so far. A message like "add dinner 500 and tell me my total"
    // yields a card and an answer, so these are carried across rounds.
    final cards = <AgentCard>[];
    final wantsMore = _looksLikeMoreThanOneTask(input);

    for (var step = 0; step < maxSteps; step++) {
      final ChatResult result;
      try {
        result = await groq.chat(messages: messages, tools: toolSchemas);
      } on GroqException catch (e) {
        // A malformed reply is worth one more try before giving up.
        if (e is GroqBadResponse && step == 0) continue;
        // Groq rejected the model's tool call (for example a value of the wrong
        // type). Tell the model what was wrong, as we do for our own checks.
        if (e is GroqBadRequest && step < maxSteps - 1) {
          final detail = e.detail.length > 300 ? e.detail.substring(0, 300) : e.detail;
          messages.add({
            'role': 'user',
            'content': 'Your last tool call was rejected: $detail '
                'Call the tool again with arguments that match its schema.',
          });
          continue;
        }
        // Cards already shown stay useful even if the follow-up failed.
        if (cards.isNotEmpty) return _finish(day, cards, null);
        return AgentFailure(e);
      }

      if (result.toolCalls.isEmpty) {
        final answer = result.content ?? (cards.isEmpty ? stuckMessage : null);
        return _finish(day, cards, answer);
      }

      // Every call of the round is run, and each gets a matching result so
      // the ids line up.
      messages.add({
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          for (final call in result.toolCalls)
            {
              'id': call.id,
              'type': 'function',
              'function': {'name': call.name, 'arguments': call.arguments},
            }
        ],
      });

      var needsAnswer = false;
      for (final call in result.toolCalls) {
        final outcome = await _runCall(call, input, source);
        switch (outcome) {
          case ProposalResult(:final proposal):
            final id = await chat.add(
              day: day,
              role: 'card',
              cardType: proposal.type,
              cardPayload: jsonEncode(proposal.toJson()),
              cardStatus: 'pending',
            );
            cards.add(AgentCard(id, proposal));
            messages.add(_toolMessage(call.id, {
              'status': 'shown to the user as a card, not saved until they confirm',
            }));
          case ReadResult(:final data):
            needsAnswer = true;
            messages.add(_toolMessage(call.id, data));
          case ToolError(:final message):
            needsAnswer = true;
            messages.add(_toolMessage(call.id, {'error': message}));
        }
      }

      // Only changes to confirm and nothing to answer: done, unless the
      // message looks like it also asked a question.
      if (!needsAnswer && !(wantsMore && step < maxSteps - 1)) {
        return _finish(day, cards, null);
      }
    }

    return _finish(day, cards, cards.isEmpty ? stuckMessage : null);
  }

  /// Stores the answer (if any) and picks the reply type.
  Future<AgentReply> _finish(String day, List<AgentCard> cards, String? answer) async {
    var text = answer?.trim();
    if (text != null && text.isEmpty) text = null;
    if (text == null && cards.isEmpty) text = stuckMessage;
    if (text != null) await chat.add(day: day, role: 'assistant', body: text);
    if (cards.isEmpty) return AgentAnswer(text!);
    if (cards.length == 1 && text == null) return cards.single;
    return AgentMulti(cards, text);
  }

  /// A cheap guess that the message asked for more than one thing, so a round
  /// with only a card in it is not the end. Costs one extra request at most.
  static bool _looksLikeMoreThanOneTask(String t) {
    final s = t.toLowerCase();
    return s.contains('?') ||
        RegExp(r'(total|how much|balance|left|remaining|tell me|show me|what|and also)')
            .hasMatch(s);
  }

  Future<ToolOutcome> _runCall(ToolCall call, String rawText, String source) async {
    if (!kReadTools.contains(call.name) && !kProposeTools.contains(call.name)) {
      return ToolError('Unknown tool "${call.name}"');
    }
    final Map<String, dynamic> args;
    try {
      final decoded = call.arguments.trim().isEmpty ? <String, dynamic>{} : jsonDecode(call.arguments);
      if (decoded is! Map) return const ToolError('Arguments must be a JSON object');
      args = Map<String, dynamic>.from(decoded);
    } on FormatException {
      return const ToolError('Arguments were not valid JSON. Call the tool again with valid JSON.');
    }
    return executor.run(call.name, args, rawText: rawText, source: source);
  }

  Map<String, dynamic> _toolMessage(String id, Map<String, dynamic> data) =>
      {'role': 'tool', 'tool_call_id': id, 'content': jsonEncode(data)};

  Future<String> _system(String day) async {
    final cats = (await categories.active()).map((c) => c.name).toList();
    final people = (await lending.recentPeople(15)).map((p) => p.name).toList();
    final recent = (await expenses.recent(5))
        .map((r) =>
            '#${r.expense.id} ${formatINR(r.expense.amountPaise)} ${r.expense.item} '
            '(${r.category.name}, ${r.expense.spentOn})')
        .toList();
    return buildSystemPrompt(
      todayIso: day,
      categories: cats,
      people: people,
      recentExpenses: recent,
    );
  }

  /// Today's last few turns as the model should remember them. Cards become
  /// one-liners that include the id, so "change that" can name the entry.
  Future<List<Map<String, dynamic>>> _history(
      String day, String input, bool alreadyStored) async {
    var turns = await chat.recentTurns(day, historyTurns + (alreadyStored ? 1 : 0));
    if (alreadyStored && turns.isNotEmpty) {
      final last = turns.last;
      if (last.role == 'user' && last.body == input) {
        turns = turns.sublist(0, turns.length - 1);
      }
    }
    if (turns.length > historyTurns) turns = turns.sublist(turns.length - historyTurns);

    final out = <Map<String, dynamic>>[];
    for (final m in turns) {
      switch (m.role) {
        case 'user':
          if (m.body != null) out.add({'role': 'user', 'content': m.body});
        case 'assistant':
          if (m.body != null) out.add({'role': 'assistant', 'content': m.body});
        case 'card':
          out.add({'role': 'assistant', 'content': _cardLine(m)});
      }
    }
    return out;
  }

  static String _cardLine(ChatMessage m) {
    String summary = 'a card';
    try {
      summary = Proposal.fromJson(jsonDecode(m.cardPayload!) as Map<String, dynamic>).summary;
    } catch (_) {}
    final ref = m.entityRef == null ? '' : ' #${m.entityRef!.split(':').last}';
    return switch (m.cardStatus) {
      'confirmed' => '[Saved$ref] $summary',
      'cancelled' => '[Cancelled by user] $summary',
      'expired' => '[Expired] $summary',
      _ => '[Waiting for the user to confirm] $summary',
    };
  }
}

/// Today's date as the agent sees it, for callers that only have a clock.
String Function() todayFrom(DateTime Function() clock) => () => todayIst(clock());
