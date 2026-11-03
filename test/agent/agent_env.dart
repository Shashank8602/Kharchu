import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:kharchu/data/key_store.dart';
import 'package:kharchu/services/agent/agent_service.dart';
import 'package:kharchu/services/agent/tool_executor.dart';
import 'package:kharchu/services/budget_alerts.dart';
import 'package:kharchu/services/card_actions.dart';
import 'package:kharchu/services/groq/groq_client.dart';
import 'package:kharchu/services/groq/rate_limiter.dart';

import '../unit/fake_http.dart';
import '../unit/helpers.dart';

/// Saturday 24 October 2026, as in the mockups.
const kToday = '2026-10-24';

/// The whole agent stack over an in-memory database and scripted Groq replies.
class AgentEnv {
  AgentEnv({String? today}) {
    if (today != null) _today = today;
    adapter = FakeAdapter([]);
    final dio = Dio(BaseOptions(baseUrl: GroqClient.baseUrl))..httpClientAdapter = adapter;
    groq = GroqClient(
      dio: dio,
      keyStore: MemoryKeyStore('gsk_test_key_0123456789'),
      models: () => const ModelConfig(
        chatModel: 'openai/gpt-oss-120b',
        fallbackModel: '',
        voiceModel: 'whisper-large-v3',
      ),
      limiter: RateLimiter(delay: (_) async {}),
    );
    executor = ToolExecutor(
      expenses: env.expenses,
      categories: env.categories,
      budgets: env.budgets,
      lending: env.lending,
      today: () => _today,
    );
    agent = AgentService(
      groq: groq,
      chat: env.chat,
      executor: executor,
      expenses: env.expenses,
      categories: env.categories,
      lending: env.lending,
      today: () => _today,
    );
    alerts = BudgetAlerts(
        expenses: env.expenses, budgets: env.budgets, categories: env.categories);
    actions = CardActions(
      db: env.db,
      expenses: env.expenses,
      categories: env.categories,
      budgets: env.budgets,
      lending: env.lending,
      chat: env.chat,
      executor: executor,
      alerts: alerts,
      today: () => _today,
    );
  }

  final TestEnv env = TestEnv();
  String _today = kToday;
  late final FakeAdapter adapter;
  late final GroqClient groq;
  late final ToolExecutor executor;
  late final AgentService agent;
  late final BudgetAlerts alerts;
  late final CardActions actions;

  set today(String v) => _today = v;
  Future<void> close() => env.close();

  /// Queue a model reply that calls one tool.
  void callTool(String name, Map<String, dynamic> args, {String id = 'call_1'}) {
    adapter.script.add((_) => json(chatCompletion(calls: [
          {
            'id': id,
            'type': 'function',
            'function': {'name': name, 'arguments': jsonEncode(args)},
          }
        ])));
  }

  /// Queue a model reply with raw (possibly malformed) argument text.
  void callToolRaw(String name, String rawArgs) {
    adapter.script.add((_) => json(chatCompletion(calls: [
          {
            'id': 'call_raw',
            'type': 'function',
            'function': {'name': name, 'arguments': rawArgs},
          }
        ])));
  }

  void say(String text) => adapter.script.add((_) => json(chatCompletion(content: text)));

  /// The messages sent in request number [i] (0-based).
  List<Map<String, dynamic>> sentMessages(int i) =>
      ((adapter.requests[i].data as Map)['messages'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Future<int> category(String name) => env.cat(name);
}
