// Live accuracy check of the AI against the real Groq API.
//
// Skipped unless you ask for it, because it spends your Groq quota
// (roughly 100K tokens for the whole set):
//
//   KHARCHU_EVAL=1 flutter test test/agent_eval/agent_eval_test.dart
//
// Optional: KHARCHU_EVAL_LIMIT=5 runs only the first five cases.
// Needs GROQ_API_KEY in the project's .env file. Results are also written to
// test/agent_eval/results/ (git-ignored).

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/db/app_database.dart';
import 'package:kharchu/data/key_store.dart';
import 'package:kharchu/data/repositories/budget_repository.dart';
import 'package:kharchu/data/repositories/category_repository.dart';
import 'package:kharchu/data/repositories/chat_repository.dart';
import 'package:kharchu/data/repositories/expense_repository.dart';
import 'package:kharchu/data/repositories/lending_repository.dart';
import 'package:kharchu/services/agent/agent_service.dart';
import 'package:kharchu/services/agent/tool_executor.dart';
import 'package:kharchu/services/groq/groq_client.dart';
import 'package:kharchu/services/groq/groq_errors.dart';

import 'eval_cases.dart';

String? readKey() {
  final f = File('.env');
  if (!f.existsSync()) return null;
  for (final line in f.readAsLinesSync()) {
    final m = RegExp(r'^\s*GROQ_API_KEY\s*=\s*(.*)$').firstMatch(line);
    if (m != null) {
      final k = cleanApiKey(m.group(1)!);
      return looksLikeGroqKey(k) ? k : null;
    }
  }
  return null;
}

Future<AgentService> freshAgent(String key, AppDatabase db) async {
  final expenses = ExpenseRepository(db);
  final categories = CategoryRepository(db);
  final budgets = BudgetRepository(db);
  final lending = LendingRepository(db);
  const today = '2026-10-24';

  Future<void> add(int rupees, String item, String category, String date, {String? location}) async {
    await expenses.add(
      amountPaise: rupees * 100,
      categoryId: (await categories.exact(category))!.id,
      item: item,
      location: location,
      spentOn: date,
    );
  }

  await add(1000, 'Chats', 'Food & Dining', '2026-10-24');
  await add(1200, 'Dinner', 'Food & Dining', '2026-10-18', location: "Meghana's");
  await add(2920, 'Dinner', 'Food & Dining', '2026-10-13');
  await add(1050, 'Petrol', 'Transport', '2026-10-22');
  final rahul = await lending.findOrCreatePerson('Rahul');
  await lending.addLoan(
      personId: rahul.id, direction: 'lent', principalPaise: 200000, note: 'Goa trip', happenedOn: '2026-10-10');
  final priya = await lending.findOrCreatePerson('Priya');
  await lending.addLoan(
      personId: priya.id, direction: 'borrowed', principalPaise: 150000, happenedOn: '2026-10-05');

  final groq = GroqClient(
    dio: GroqClient.buildDio(),
    keyStore: MemoryKeyStore(key),
    models: () => const ModelConfig(
      chatModel: 'openai/gpt-oss-120b',
      fallbackModel: 'openai/gpt-oss-20b',
      voiceModel: 'whisper-large-v3',
    ),
  );
  return AgentService(
    groq: groq,
    chat: ChatRepository(db),
    executor: ToolExecutor(
        expenses: expenses, categories: categories, budgets: budgets, lending: lending, today: () => today),
    expenses: expenses,
    categories: categories,
    lending: lending,
    today: () => today,
  );
}

void main() {
  final key = readKey();
  final enabled = Platform.environment['KHARCHU_EVAL'] == '1';
  final skipReason = !enabled
      ? 'live AI check: run with KHARCHU_EVAL=1 (uses Groq quota)'
      : key == null
          ? 'no valid GROQ_API_KEY in .env'
          : null;

  test('the AI reads real messages correctly', () async {
    final limit = int.tryParse(Platform.environment['KHARCHU_EVAL_LIMIT'] ?? '') ?? evalCases.length;
    // KHARCHU_EVAL_ONLY="paid back,top 3" runs only cases whose text contains one of these
    final only = (Platform.environment['KHARCHU_EVAL_ONLY'] ?? '')
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    final cases = evalCases
        .where((c) => only.isEmpty || only.any((o) => c.input.toLowerCase().contains(o)))
        .take(limit)
        .toList();
    final results = <Map<String, Object?>>[];
    var passed = 0, kannadaPassed = 0, kannadaTotal = 0;

    for (var i = 0; i < cases.length; i++) {
      final c = cases[i];
      final db = AppDatabase(NativeDatabase.memory());
      final agent = await freshAgent(key!, db);

      AgentReply? reply;
      // wait out Groq's per-minute token limit instead of failing on it
      for (var attempt = 0; attempt < 4; attempt++) {
        reply = await agent.handle(c.input);
        if (reply is AgentFailure && reply.error is GroqRateLimited) {
          final wait = (reply.error as GroqRateLimited).retryAfterSeconds ?? 20;
          stdout.writeln('   (rate limited, waiting ${wait + 2}s)');
          await Future<void>.delayed(Duration(seconds: wait + 2));
          continue;
        }
        break;
      }
      final problems = c.check(reply!);
      final ok = problems.isEmpty;
      if (ok) passed++;
      if (c.kannada) {
        kannadaTotal++;
        if (ok) kannadaPassed++;
      }
      stdout.writeln('${ok ? 'PASS' : 'FAIL'}  [${i + 1}/${cases.length}] ${c.input}');
      for (final p in problems) {
        stdout.writeln('        - $p');
      }
      results.add({'input': c.input, 'ok': ok, 'problems': problems, 'kannada': c.kannada});
      await db.close();
      // stay under the free tier's tokens-per-minute limit
      await Future<void>.delayed(const Duration(seconds: 18));
    }

    final pct = (100 * passed / cases.length).round();
    stdout.writeln('\n$passed of ${cases.length} correct ($pct%)'
        '${kannadaTotal > 0 ? '; Kannada $kannadaPassed of $kannadaTotal' : ''}');

    final dir = Directory('test/agent_eval/results')..createSync(recursive: true);
    File('${dir.path}/latest.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({'passed': passed, 'total': cases.length, 'results': results}));

    expect(pct, greaterThanOrEqualTo(80), reason: 'the AI should get most cases right');
  }, skip: skipReason, timeout: const Timeout(Duration(minutes: 40)));
}
