import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/repositories/expense_repository.dart';
import 'package:kharchu/services/agent/agent_service.dart';
import 'package:kharchu/services/agent/proposals.dart';
import 'package:kharchu/services/card_actions.dart';
import 'package:kharchu/services/groq/groq_errors.dart';

import '../unit/fake_http.dart';
import 'agent_env.dart';

void main() {
  late AgentEnv t;
  setUp(() => t = AgentEnv());
  tearDown(() => t.close());

  Map<String, dynamic> addArgs({
    Object amount = 1000,
    String item = 'Chats',
    String category = 'Food & Dining',
    Object? location = 'Bengaluru',
    Object? payment,
    Object? date = kToday,
    Object? isNew,
  }) =>
      {
        'amount_rupees': amount,
        'item': item,
        'category': category,
        'location': location,
        'payment_method': payment,
        'spent_on': date,
        'is_new_category': isNew,
      }..removeWhere((k, v) => v == null);

  Future<AddExpenseProposal> proposeAdd(Map<String, dynamic> args, {String text = 'spent'}) async {
    t.callTool('propose_add_expense', args);
    final r = await t.agent.handle(text);
    expect(r, isA<AgentCard>(), reason: '$r');
    return (r as AgentCard).proposal as AddExpenseProposal;
  }

  group('adding an expense', () {
    test('the headline example becomes a pending card, and nothing is saved yet',
        () async {
      t.callTool('propose_add_expense', addArgs());
      final r = await t.agent.handle('I spent Rs.1000 to eat chats in Bengaluru');
      final p = (r as AgentCard).proposal as AddExpenseProposal;

      expect(p.amountPaise, 100000);
      expect(p.item, 'Chats');
      expect(p.categoryName, 'Food & Dining');
      expect(p.location, 'Bengaluru');
      expect(p.paymentMethod, isNull);
      expect(p.spentOn, kToday);
      expect(p.rawText, 'I spent Rs.1000 to eat chats in Bengaluru');
      expect(await t.env.expenses.find(const ExpenseFilter()), isEmpty);

      final msgs = await t.env.chat.messagesForDay(kToday);
      expect(msgs.map((m) => m.role), ['user', 'card']);
      expect(msgs.last.cardStatus, 'pending');
    });

    test('confirm writes the expense and links the card to it', () async {
      t.callTool('propose_add_expense', addArgs(payment: 'GPay'));
      final card = await t.agent.handle('chats 1000') as AgentCard;
      final result = await t.actions.confirm(card.messageId);

      expect(result, isA<Committed>());
      final rows = await t.env.expenses.find(const ExpenseFilter());
      expect(rows.length, 1);
      expect(rows.single.expense.amountPaise, 100000);
      expect(rows.single.expense.paymentMethod, 'upi');
      expect(rows.single.expense.source, 'chat');
      expect(rows.single.expense.rawText, 'chats 1000');
      final msg = (await t.env.chat.byId(card.messageId))!;
      expect(msg.cardStatus, 'confirmed');
      expect(msg.entityRef, 'expense:${rows.single.expense.id}');
    });

    test('tapping Save twice saves once', () async {
      final card = await _card(t, addArgs());
      final a = await t.actions.confirm(card);
      final b = await t.actions.confirm(card);
      expect(a, isA<Committed>());
      expect(b, isA<AlreadyHandled>());
      expect((await t.env.expenses.find(const ExpenseFilter())).length, 1);
    });

    test('two simultaneous taps still save once', () async {
      final card = await _card(t, addArgs());
      final results = await Future.wait([t.actions.confirm(card), t.actions.confirm(card)]);
      expect(results.whereType<Committed>().length, 1);
      expect((await t.env.expenses.find(const ExpenseFilter())).length, 1);
    });

    test('cancel saves nothing, and a later Save does nothing', () async {
      final card = await _card(t, addArgs());
      await t.actions.cancel(card);
      expect((await t.env.chat.byId(card))!.cardStatus, 'cancelled');
      expect(await t.actions.confirm(card), isA<AlreadyHandled>());
      expect(await t.env.expenses.find(const ExpenseFilter()), isEmpty);
    });

    test('Edit-sheet save uses the edited values', () async {
      final card = await _card(t, addArgs());
      final original = Proposal.fromJson(
          jsonDecode((await t.env.chat.byId(card))!.cardPayload!) as Map<String, dynamic>)
          as AddExpenseProposal;
      final edited = original.copyWith(amountPaise: 85000, item: 'Pani Puri', paymentMethod: 'cash');
      await t.actions.confirm(card, edited: edited);
      final e = (await t.env.expenses.find(const ExpenseFilter())).single.expense;
      expect(e.amountPaise, 85000);
      expect(e.item, 'Pani Puri');
      expect(e.paymentMethod, 'cash');
    });

    test('choosing a payment chip on a pending card is remembered', () async {
      final card = await _card(t, addArgs());
      final msg = (await t.env.chat.byId(card))!;
      final p = Proposal.fromJson(jsonDecode(msg.cardPayload!) as Map<String, dynamic>)
          as AddExpenseProposal;
      await t.actions.updatePending(card, p.copyWith(paymentMethod: 'card'));
      await t.actions.confirm(card);
      expect((await t.env.expenses.find(const ExpenseFilter())).single.expense.paymentMethod, 'card');
    });

    test('a word like "Food" is mapped to the real category', () async {
      final p = await proposeAdd(addArgs(category: 'Food'));
      expect(p.categoryName, 'Food & Dining');
      expect(p.isNewCategory, isFalse);
    });

    test('numbers sent as text are understood', () async {
      for (final (raw, paise) in [
        ('1000', 100000),
        ('₹1,000', 100000),
        ('Rs. 2.5k', 250000),
        ('1.5 lakh', 15000000),
        ('99.50', 9950),
      ]) {
        t.callTool('propose_add_expense', addArgs(amount: raw));
        final r = await t.agent.handle('x') as AgentCard;
        expect((r.proposal as AddExpenseProposal).amountPaise, paise, reason: raw);
      }
    });

    test('a brand-new category is proposed, then created on Save', () async {
      final p = await proposeAdd(addArgs(
          item: 'Haircut', category: 'Personal Care', isNew: true, amount: 350));
      expect(p.isNewCategory, isTrue);
      expect(p.categoryId, isNull);
      final card = (await t.env.chat.messagesForDay(kToday)).last.id;
      expect(await t.env.categories.exact('Personal Care'), isNull,
          reason: 'not created until confirmed');
      await t.actions.confirm(card);
      final cat = await t.env.categories.exact('Personal Care');
      expect(cat, isNotNull);
      expect((await t.env.expenses.find(const ExpenseFilter())).single.category.name, 'Personal Care');
    });

    test('cancelling a new-category card creates no category',
        () async {
      await proposeAdd(addArgs(category: 'Personal Care', isNew: true));
      final card = (await t.env.chat.messagesForDay(kToday)).last.id;
      await t.actions.cancel(card);
      expect(await t.env.categories.exact('Personal Care'), isNull);
    });

    test('saying "new category" for one that already exists reuses it', () async {
      final p = await proposeAdd(addArgs(category: 'transport', isNew: true));
      expect(p.isNewCategory, isFalse);
      expect(p.categoryName, 'Transport');
    });

    test('payment wording is normalised, and unknown stays unspecified', () async {
      expect((await proposeAdd(addArgs(payment: 'Google Pay'))).paymentMethod, 'upi');
      expect((await proposeAdd(addArgs(payment: 'credit card'))).paymentMethod, 'card');
      expect((await proposeAdd(addArgs(payment: 'net banking'))).paymentMethod, 'netbanking');
      expect((await proposeAdd(addArgs(payment: 'null'))).paymentMethod, isNull);
      expect((await proposeAdd(addArgs(payment: ''))).paymentMethod, isNull);
    });

    test('location of "null" or blank is treated as not stated', () async {
      expect((await proposeAdd(addArgs(location: 'null'))).location, isNull);
      expect((await proposeAdd(addArgs(location: '   '))).location, isNull);
    });

    test('item is tidied to Title Case but brand casing is kept', () async {
      expect((await proposeAdd(addArgs(item: 'pani   puri'))).item, 'Pani Puri');
      expect((await proposeAdd(addArgs(item: 'dinner at meghana\'s'))).item, "Dinner at Meghana's");
      expect((await proposeAdd(addArgs(item: 'KFC'))).item, 'KFC');
      expect((await proposeAdd(addArgs(item: 'McDonald\'s'))).item, "McDonald's");
    });

    test('a missing date means today; a future date is clamped and flagged', () async {
      final a = await proposeAdd(addArgs(date: null));
      expect(a.spentOn, kToday);
      expect(a.warnings, isEmpty);
      final b = await proposeAdd(addArgs(date: '2026-12-25'));
      expect(b.spentOn, kToday);
      expect(b.warnings, contains('future_date'));
    });

    test('a large amount is allowed but flagged', () async {
      final p = await proposeAdd(addArgs(amount: 150000));
      expect(p.warnings, contains('large_amount'));
      expect((await proposeAdd(addArgs(amount: 100000))).warnings, isEmpty);
    });

    test('a very long message is cut to 500 characters before it is sent', () async {
      t.say('ok');
      await t.agent.handle('a' * 900);
      final sent = t.sentMessages(0).last['content'] as String;
      expect(sent.length, 500);
    });
  });

  group('the model gets it wrong and corrects itself', () {
    test('an unknown category is explained back to the model, which then fixes it',
        () async {
      t.callTool('propose_add_expense', addArgs(category: 'Snacks Zone'));
      t.callTool('propose_add_expense', addArgs(category: 'Food & Dining'), id: 'call_2');
      final r = await t.agent.handle('chats 1000');
      expect(r, isA<AgentCard>());
      final second = t.sentMessages(1);
      final tool = second.last;
      expect(tool['role'], 'tool');
      expect(tool['content'], contains('does not exist'));
      expect(tool['content'], contains('Food & Dining'));
    });

    test('each invalid value gets a specific correction', () async {
      for (final (args, fragment) in <(Map<String, dynamic>, String)>[
        (addArgs(amount: 0), 'more than 0'),
        (addArgs(amount: -50), 'more than 0'),
        (addArgs(amount: 'lots'), 'must be a number'),
        (addArgs(amount: 5000000), 'above'),
        (addArgs(item: '   '), 'item is required'),
        (addArgs(date: 'yesterday'), 'YYYY-MM-DD'),
        (addArgs(date: '1990-01-01'), 'too far in the past'),
        (addArgs(date: '2026-02-30'), 'YYYY-MM-DD'),
      ]) {
        final env = AgentEnv();
        env.callTool('propose_add_expense', args);
        env.say('Sorry, let me try again.');
        await env.agent.handle('x');
        expect(env.sentMessages(1).last['content'], contains(fragment), reason: '$args');
        await env.close();
      }
    });

    test('malformed JSON arguments are reported, then the model retries', () async {
      t.callToolRaw('propose_add_expense', '{"amount_rupees": 1000, "item": ');
      t.callTool('propose_add_expense', addArgs(), id: 'call_2');
      final r = await t.agent.handle('x');
      expect(r, isA<AgentCard>());
      expect(t.sentMessages(1).last['content'], contains('not valid JSON'));
    });

    test('arguments that are valid JSON but not an object are rejected', () async {
      t.callToolRaw('propose_add_expense', '[1,2,3]');
      t.say('ok');
      await t.agent.handle('x');
      expect(t.sentMessages(1).last['content'], contains('JSON object'));
    });

    test('empty arguments are treated as an empty object and corrected', () async {
      t.callToolRaw('propose_add_expense', '');
      t.say('ok');
      await t.agent.handle('x');
      expect(t.sentMessages(1).last['content'], contains('must be a number'));
    });

    test('an invented tool name is refused without crashing', () async {
      t.callTool('delete_everything', {});
      t.say('I can only help with expenses.');
      final r = await t.agent.handle('wipe it all');
      expect(r, isA<AgentAnswer>());
      expect(t.sentMessages(1).last['content'], contains('Unknown tool'));
    });

    test('a model that never stops calling lookups is cut off after four rounds',
        () async {
      for (var i = 0; i < 6; i++) {
        t.callTool('find_expenses', {'text': 'x'}, id: 'c$i');
      }
      final r = await t.agent.handle('loop');
      expect((r as AgentAnswer).text, AgentService.stuckMessage);
      expect(t.adapter.requests.length, 4);
    });

    test('every tool call of a round is run, and ids stay consistent', () async {
      t.adapter.script.add((_) => json(chatCompletion(calls: [
            {
              'id': 'a',
              'type': 'function',
              'function': {'name': 'find_expenses', 'arguments': '{}'}
            },
            {
              'id': 'b',
              'type': 'function',
              'function': {'name': 'find_expenses', 'arguments': '{}'}
            },
          ])));
      t.say('done');
      await t.agent.handle('x');
      final second = t.sentMessages(1);
      final assistant = second.firstWhere((m) => m['role'] == 'assistant');
      expect((assistant['tool_calls'] as List).length, 2);
      final toolIds = second.where((m) => m['role'] == 'tool').map((m) => m['tool_call_id']);
      expect(toolIds, ['a', 'b']);
    });

    test('a malformed first reply is retried once', () async {
      t.adapter.script.add((_) => json({'oops': true}));
      t.say('Fine.');
      final r = await t.agent.handle('x');
      expect((r as AgentAnswer).text, 'Fine.');
    });

    test('an empty reply with no tool call gives the stuck message, not blank text',
        () async {
      t.adapter.script.add((_) => json(chatCompletion(content: '  ')));
      final r = await t.agent.handle('x');
      expect((r as AgentAnswer).text, AgentService.stuckMessage);
    });
  });

  group('one message, several tasks', () {
    Map<String, dynamic> call(String id, String name, Map<String, dynamic> args) => {
          'id': id,
          'type': 'function',
          'function': {'name': name, 'arguments': jsonEncode(args)},
        };

    test('an expense plus two questions gives a card and an answer', () async {
      t.adapter.script.add((_) => json(chatCompletion(calls: [
            call('a', 'propose_add_expense', addArgs(amount: 500, item: 'Dinner')),
            call('b', 'query_spending',
                {'metric': 'total', 'date_from': '2026-10-01', 'date_to': '2026-10-31'}),
            call('c', 'query_spending',
                {'metric': 'budget_status', 'date_from': '2026-10-01', 'date_to': '2026-10-31'}),
          ])));
      t.say('Dinner ₹500 is ready to confirm. You have spent ₹0 so far.');
      final r = await t.agent.handle(
          'i spent 500rs on dinner today and tell me the total and how much i am left with');

      expect(r, isA<AgentMulti>());
      final multi = r as AgentMulti;
      expect(multi.cards.length, 1);
      expect((multi.cards.single.proposal as AddExpenseProposal).amountPaise, 50000);
      expect(multi.text, contains('₹500'));
      // the model saw a result for every call, including the card
      final tools = t.sentMessages(1).where((m) => m['role'] == 'tool').toList();
      expect(tools.map((m) => m['tool_call_id']), ['a', 'b', 'c']);
      expect(tools.first['content'], contains('not saved until'));
      // nothing is saved before the user confirms
      expect(await t.env.expenses.find(const ExpenseFilter()), isEmpty);
      final msgs = await t.env.chat.messagesForDay(kToday);
      expect(msgs.map((m) => m.role), ['user', 'card', 'assistant']);
    });

    test('two expenses in one message give two cards', () async {
      t.adapter.script.add((_) => json(chatCompletion(calls: [
            call('a', 'propose_add_expense', addArgs(amount: 100, item: 'Tea')),
            call('b', 'propose_add_expense', addArgs(amount: 200, item: 'Lunch')),
          ])));
      final r = await t.agent.handle('tea 100 and lunch 200');
      expect(r, isA<AgentMulti>());
      expect((r as AgentMulti).cards.length, 2);
      expect(r.text, isNull);
      expect(t.adapter.requests.length, 1, reason: 'no extra round needed');
    });

    test('a card first and the question in the next round is still answered', () async {
      t.callTool('propose_add_expense', addArgs(amount: 500, item: 'Dinner'));
      t.callTool('query_spending',
          {'metric': 'total', 'date_from': '2026-10-01', 'date_to': '2026-10-31'},
          id: 'q');
      t.say('Spent so far: ₹0.');
      final r = await t.agent.handle('dinner 500, and what is my total?');
      expect(r, isA<AgentMulti>());
      expect((r as AgentMulti).cards.length, 1);
      expect(r.text, 'Spent so far: ₹0.');
    });

    test('a plain add is still one request and a single card', () async {
      t.callTool('propose_add_expense', addArgs());
      final r = await t.agent.handle('chats 1000');
      expect(r, isA<AgentCard>());
      expect(t.adapter.requests.length, 1);
    });
  });

  group('Groq rejects a tool call from the model', () {
    test('the problem is explained to the model, which then succeeds', () async {
      t.adapter.script.add((_) => errorBody(
          400, 'tool call validation failed: parameters for tool query_spending did not match schema'));
      t.callTool('propose_add_expense', addArgs());
      final r = await t.agent.handle('chats 1000');
      expect(r, isA<AgentCard>());
      final retry = t.sentMessages(1).last;
      expect(retry['role'], 'user');
      expect(retry['content'], contains('rejected'));
      expect(retry['content'], contains('did not match schema'));
    });

    test('a very long Groq message is shortened before it is sent back', () async {
      t.adapter.script.add((_) => errorBody(400, 'x' * 2000));
      t.say('ok');
      await t.agent.handle('hi');
      expect((t.sentMessages(1).last['content'] as String).length, lessThan(450));
    });

    test('if it keeps happening the user gets a plain message, after a bounded number of tries',
        () async {
      for (var i = 0; i < 6; i++) {
        t.adapter.script.add((_) => errorBody(400, 'tool call validation failed'));
      }
      final r = await t.agent.handle('hi');
      expect(r, isA<AgentFailure>());
      expect(t.adapter.requests.length, 4, reason: 'never more than four rounds');
      expect((r as AgentFailure).error.userMessage, "Couldn't understand that, try rephrasing.");
    });
  });

  group('Groq trouble', () {
    test('a rejected key is reported and the user message is kept once', () async {
      t.adapter.script.add((_) => errorBody(401, 'bad key'));
      final r = await t.agent.handle('chats 1000');
      expect((r as AgentFailure).error, isA<GroqUnauthorized>());
      expect(r.error.needsProfile, isTrue);
      final msgs = await t.env.chat.messagesForDay(kToday);
      expect(msgs.map((m) => m.role), ['user']);
    });

    test('Retry reuses the stored message instead of adding it again', () async {
      t.adapter.script.add((o) => throw DioExceptionShim.offline(o));
      final first = await t.agent.handle('chats 1000');
      expect((first as AgentFailure).error.canRetry, isTrue);

      t.callTool('propose_add_expense', addArgs());
      final second = await t.agent.handle('chats 1000', alreadyStored: true);
      expect(second, isA<AgentCard>());
      final msgs = await t.env.chat.messagesForDay(kToday);
      expect(msgs.where((m) => m.role == 'user').length, 1);
      // and the retried request does not repeat the user line in its history
      final sent = t.sentMessages(1);
      expect(sent.where((m) => m['role'] == 'user').length, 1);
    });

    test('rate limiting is reported with the wait time', () async {
      t.adapter.script.add((_) => errorBody(429, 'limit', headers: {'retry-after': ['9']}));
      final r = await t.agent.handle('x') as AgentFailure;
      expect(r.error.userMessage, contains('9s'));
    });

    test('no key means no network call', () async {
      final env = AgentEnv();
      await env.groq.keyStore.delete();
      final r = await env.agent.handle('x');
      expect((r as AgentFailure).error, isA<GroqNoKey>());
      expect(env.adapter.requests, isEmpty);
      await env.close();
    });
  });

  group('memory and context', () {
    test('plain answers are stored as assistant messages', () async {
      t.say('You can ask me about spending.');
      await t.agent.handle('hello');
      final msgs = await t.env.chat.messagesForDay(kToday);
      expect(msgs.map((m) => m.role), ['user', 'assistant']);
    });

    test('earlier turns, including saved cards with their ids, reach the next request',
        () async {
      final card = await _card(t, addArgs());
      await t.actions.confirm(card);
      t.say('ok');
      await t.agent.handle('change that to 800');
      final msgs = t.sentMessages(t.adapter.requests.length - 1);
      final texts = msgs.map((m) => '${m['content']}').join('\n');
      expect(texts, contains('[Saved #1]'));
      expect(texts, contains('₹1,000 Chats'));
      expect(msgs.last['content'], 'change that to 800');
    });

    test('a cancelled card is described as cancelled, so the model does not assume it exists',
        () async {
      final card = await _card(t, addArgs());
      await t.actions.cancel(card);
      t.say('ok');
      await t.agent.handle('hi');
      final texts = t.sentMessages(t.adapter.requests.length - 1).map((m) => '${m['content']}').join('\n');
      expect(texts, contains('Cancelled by user'));
    });

    test('only the last six turns are sent', () async {
      for (var i = 0; i < 10; i++) {
        await t.env.chat.add(day: kToday, role: 'user', body: 'old $i');
      }
      t.say('ok');
      await t.agent.handle('new');
      final userMsgs = t.sentMessages(0).where((m) => m['role'] == 'user').toList();
      expect(userMsgs.length, 7); // six from history + the new one
      expect(userMsgs.first['content'], 'old 4');
    });

    test('yesterday\'s chat is not sent today', () async {
      await t.env.chat.add(day: '2026-10-23', role: 'user', body: 'yesterday secret');
      t.say('ok');
      await t.agent.handle('hi');
      final all = t.sentMessages(0).map((m) => '${m['content']}').join();
      expect(all, isNot(contains('yesterday secret')));
    });

    test('the system prompt carries today, categories, people and recent expenses',
        () async {
      await t.env.addExpense(paise: 100000, item: 'Chats');
      await t.env.lending.findOrCreatePerson('Rahul');
      t.say('ok');
      await t.agent.handle('hi');
      final system = t.sentMessages(0).first['content'] as String;
      expect(system, contains('2026-10-24'));
      expect(system, contains('Saturday'));
      expect(system, contains('Food & Dining'));
      expect(system, contains('Rahul'));
      expect(system, contains('#1 ₹1,000 Chats'));
      expect(system, contains('ALWAYS reply in short, plain English'));
    });

    test('the request carries all eleven tools', () async {
      t.say('ok');
      await t.agent.handle('hi');
      final tools = (t.adapter.requests.single.data as Map)['tools'] as List;
      expect(tools.length, 11);
    });
  });
}

Future<String> _card(AgentEnv t, Map<String, dynamic> args) async {
  t.callTool('propose_add_expense', args);
  final r = await t.agent.handle('x') as AgentCard;
  return r.messageId;
}
