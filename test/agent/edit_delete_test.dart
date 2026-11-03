import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/db/app_database.dart';
import 'package:kharchu/services/agent/proposals.dart';
import 'package:kharchu/services/agent/tool_outcome.dart';
import 'package:kharchu/services/card_actions.dart';

import 'agent_env.dart';

Proposal proposalOf(ToolOutcome o) {
  expect(o, isA<ProposalResult>(), reason: o is ToolError ? o.message : '$o');
  return (o as ProposalResult).proposal;
}

String errorOf(ToolOutcome o) {
  expect(o, isA<ToolError>(), reason: '$o');
  return (o as ToolError).message;
}

Map<String, dynamic> dataOf(ToolOutcome o) {
  expect(o, isA<ReadResult>(), reason: o is ToolError ? o.message : '$o');
  return (o as ReadResult).data;
}

/// Puts a proposal on the chat as a pending card and returns its id.
Future<String> cardFor(AgentEnv t, Proposal p) => t.env.chat.add(
      day: kToday,
      role: 'card',
      cardType: p.type,
      cardPayload: jsonEncode(p.toJson()),
      cardStatus: 'pending',
    );

void main() {
  late AgentEnv t;
  setUp(() => t = AgentEnv());
  tearDown(() => t.close());

  Future<int> seed({
    int paise = 120000,
    String item = 'Dinner',
    String category = 'Food & Dining',
    String? location = "Meghana's",
    String date = '2026-10-18',
    String? payment = 'card',
    String? raw,
  }) =>
      t.env.addExpense(
          paise: paise, item: item, category: category, location: location, date: date, payment: payment, raw: raw);

  group('find_expenses', () {
    test('finds an old expense by words, even when the chat that created it is gone',
        () async {
      await seed(raw: "dinner at Meghana's 1200");
      final d = dataOf(await t.executor.run('find_expenses', {'text': "meghana dinner"}));
      expect(d['count'], 1);
      final m = (d['matches'] as List).single as Map;
      expect(m['id'], 1);
      expect(m['amount_text'], '₹1,200');
      expect(m['date'], '2026-10-18');
    });

    test('ranks by closeness to near_date', () async {
      await seed(item: 'Petrol', date: '2026-10-22', category: 'Transport');
      await seed(item: 'Petrol', date: '2026-10-19', category: 'Transport');
      final d = dataOf(await t.executor
          .run('find_expenses', {'text': 'petrol', 'near_date': '2026-10-19'}));
      expect(((d['matches'] as List).first as Map)['date'], '2026-10-19');
    });

    test('latest_only returns the newest first', () async {
      await seed(date: '2026-10-01');
      await seed(item: 'Newest', date: '2026-10-23');
      final d = dataOf(await t.executor.run('find_expenses', {'latest_only': true, 'limit': 1}));
      expect(((d['matches'] as List).single as Map)['item'], 'Newest');
    });

    test('no match says so', () async {
      final d = dataOf(await t.executor.run('find_expenses', {'text': 'nothing'}));
      expect(d['count'], 0);
      expect(d['note'], contains('No matching'));
    });

    test('never returns more than five, and ignores a silly limit', () async {
      for (var i = 0; i < 8; i++) {
        await seed(item: 'Tea $i', date: '2026-10-1$i'.substring(0, 10));
      }
      expect((dataOf(await t.executor.run('find_expenses', {'limit': 100}))['matches'] as List).length, 5);
      expect((dataOf(await t.executor.run('find_expenses', {'limit': -3}))['matches'] as List).length, 1);
      expect((dataOf(await t.executor.run('find_expenses', {'limit': 'abc'}))['matches'] as List).length, 5);
    });

    test('bad inputs are explained', () async {
      expect(errorOf(await t.executor.run('find_expenses', {'category': 'Spaceships'})),
          contains('Unknown category'));
      expect(errorOf(await t.executor.run('find_expenses', {'date_from': 'last week'})),
          contains('date_from'));
      expect(errorOf(await t.executor.run('find_expenses', {'date_to': '2026-13-45'})),
          contains('date_to'));
    });

    test('filters by amount and ignores a junk amount', () async {
      await seed(paise: 120000);
      await seed(paise: 5000, item: 'Tea');
      expect(dataOf(await t.executor.run('find_expenses', {'amount_rupees': 50}))['count'], 1);
      expect(dataOf(await t.executor.run('find_expenses', {'amount_rupees': 'x'}))['count'], 2);
    });

    test('a deleted expense is not found', () async {
      final id = await seed();
      await t.env.expenses.softDelete(id);
      expect(dataOf(await t.executor.run('find_expenses', {}))['count'], 0);
    });
  });

  group('update', () {
    test('changes the amount and shows before and after', () async {
      final id = await seed();
      final p = proposalOf(await t.executor
          .run('propose_update_expense', {'expense_id': id, 'amount_rupees': 1450})) as UpdateExpenseProposal;
      expect(p.before['amountPaise'], 120000);
      expect(p.changes, {'amountPaise': 145000});
      expect(p.summary, contains('₹1,200 → ₹1,450'));
    });

    test('accepts the id as text or with a hash', () async {
      final id = await seed();
      expect(proposalOf(await t.executor.run('propose_update_expense', {'expense_id': '$id', 'amount_rupees': 1})),
          isA<UpdateExpenseProposal>());
      expect(proposalOf(await t.executor.run('propose_update_expense', {'expense_id': '#$id', 'amount_rupees': 1})),
          isA<UpdateExpenseProposal>());
    });

    test('only lists what actually differs', () async {
      final id = await seed();
      final p = proposalOf(await t.executor.run('propose_update_expense', {
        'expense_id': id,
        'amount_rupees': 1200, // same
        'item': 'Dinner', // same
        'location': 'Koramangala', // different
        'payment_method': 'upi',
      })) as UpdateExpenseProposal;
      expect(p.changes.keys.toSet(), {'location', 'paymentMethod'});
    });

    test('changing the category records its id and name', () async {
      final id = await seed();
      final p = proposalOf(await t.executor
          .run('propose_update_expense', {'expense_id': id, 'category': 'entertainment'})) as UpdateExpenseProposal;
      expect(p.changes['categoryName'], 'Entertainment');
      expect(p.changes['categoryId'], await t.category('Entertainment'));
    });

    test('rejects: nothing to change, unknown id, deleted id, bad values', () async {
      final id = await seed();
      expect(errorOf(await t.executor.run('propose_update_expense', {'expense_id': id})),
          contains('Nothing to change'));
      expect(errorOf(await t.executor.run('propose_update_expense', {'expense_id': id, 'amount_rupees': 1200})),
          contains('Nothing to change'));
      expect(errorOf(await t.executor.run('propose_update_expense', {'expense_id': 999, 'amount_rupees': 5})),
          contains('No expense with id 999'));
      expect(errorOf(await t.executor.run('propose_update_expense', {'amount_rupees': 5})),
          contains('expense_id is required'));
      expect(errorOf(await t.executor.run('propose_update_expense', {'expense_id': id, 'amount_rupees': 0})),
          contains('more than 0'));
      expect(errorOf(await t.executor.run('propose_update_expense', {'expense_id': id, 'category': 'Nope'})),
          contains('does not exist'));
      expect(errorOf(await t.executor.run('propose_update_expense', {'expense_id': id, 'spent_on': 'x'})),
          contains('YYYY-MM-DD'));
      await t.env.expenses.softDelete(id);
      expect(errorOf(await t.executor.run('propose_update_expense', {'expense_id': id, 'amount_rupees': 5})),
          contains('No expense'));
    });

    test('a future date is clamped to today', () async {
      final id = await seed();
      final p = proposalOf(await t.executor
          .run('propose_update_expense', {'expense_id': id, 'spent_on': '2027-01-01'})) as UpdateExpenseProposal;
      expect(p.changes['spentOn'], kToday);
    });

    test('confirming applies only the changes and leaves other fields alone', () async {
      final id = await seed();
      final p = proposalOf(await t.executor
          .run('propose_update_expense', {'expense_id': id, 'amount_rupees': 1450}));
      final r = await t.actions.confirm(await cardFor(t, p));
      expect(r, isA<Committed>());
      final e = (await t.env.expenses.getById(id))!.expense;
      expect(e.amountPaise, 145000);
      expect(e.item, 'Dinner');
      expect(e.location, "Meghana's");
      expect(e.paymentMethod, 'card');
      expect(e.spentOn, '2026-10-18');
    });

    test('moving an expense to another category and date', () async {
      final id = await seed();
      final p = proposalOf(await t.executor.run('propose_update_expense',
          {'expense_id': id, 'category': 'Travel', 'spent_on': '2026-10-20'}));
      await t.actions.confirm(await cardFor(t, p));
      final row = (await t.env.expenses.getById(id))!;
      expect(row.category.name, 'Travel');
      expect(row.expense.spentOn, '2026-10-20');
    });

    test('if the expense changed after the card appeared, the card expires and nothing is written',
        () async {
      final id = await seed();
      final p = proposalOf(await t.executor
          .run('propose_update_expense', {'expense_id': id, 'amount_rupees': 1450}));
      final card = await cardFor(t, p);
      // someone else (the Transactions screen, say) edits it meanwhile
      await t.env.db.update(t.env.db.expenses).write(
          ExpensesCompanion(amountPaise: const Value(99900), updatedAt: Value(DateTime(2030))));
      final r = await t.actions.confirm(card);
      expect(r, isA<Expired>());
      expect((await t.env.chat.byId(card))!.cardStatus, 'expired');
      expect((await t.env.expenses.getById(id))!.expense.amountPaise, 99900);
    });

    test('if the expense was deleted after the card appeared, the card expires', () async {
      final id = await seed();
      final p = proposalOf(await t.executor
          .run('propose_update_expense', {'expense_id': id, 'amount_rupees': 1450}));
      final card = await cardFor(t, p);
      await t.env.expenses.softDelete(id);
      expect(await t.actions.confirm(card), isA<Expired>());
    });

    test('a category archived after the card appeared still saves the change', () async {
      final id = await seed();
      final p = proposalOf(await t.executor
          .run('propose_update_expense', {'expense_id': id, 'category': 'Travel'}));
      final card = await cardFor(t, p);
      await t.env.categories.setArchived(await t.category('Travel'), true);
      expect(await t.actions.confirm(card), isA<Committed>());
      expect((await t.env.expenses.getById(id))!.category.name, 'Travel');
    });
  });

  group('delete', () {
    test('proposes with a snapshot, saves nothing until confirmed', () async {
      final id = await seed();
      final p = proposalOf(await t.executor.run('propose_delete_expense', {'expense_id': id}))
          as DeleteExpenseProposal;
      expect(p.item, 'Dinner');
      expect(p.amountPaise, 120000);
      expect(await t.env.expenses.getById(id), isNotNull);
    });

    test('confirm soft-deletes; undo brings it back and hides the chip', () async {
      final id = await seed();
      final p = proposalOf(await t.executor.run('propose_delete_expense', {'expense_id': id}));
      final card = await cardFor(t, p);
      await t.actions.confirm(card);
      expect(await t.env.expenses.getById(id), isNull);
      await t.actions.undoDelete(card, id);
      expect(await t.env.expenses.getById(id), isNotNull);
      expect((await t.env.chat.byId(card))!.cardStatus, 'cancelled');
    });

    test('unknown or already deleted ids are explained', () async {
      expect(errorOf(await t.executor.run('propose_delete_expense', {'expense_id': 5})),
          contains('No expense with id 5'));
      expect(errorOf(await t.executor.run('propose_delete_expense', {})), contains('required'));
      final id = await seed();
      await t.env.expenses.softDelete(id);
      expect(errorOf(await t.executor.run('propose_delete_expense', {'expense_id': id})),
          contains('No expense'));
    });

    test('deleting something already deleted since the card appeared expires the card', () async {
      final id = await seed();
      final p = proposalOf(await t.executor.run('propose_delete_expense', {'expense_id': id}));
      final card = await cardFor(t, p);
      await t.env.expenses.softDelete(id);
      expect(await t.actions.confirm(card), isA<Expired>());
    });

    test('totals drop after a delete and rise after an undo', () async {
      final id = await seed(date: '2026-10-20');
      Future<int> total() => t.env.expenses.total('2026-10-01', '2026-10-31');
      expect(await total(), 120000);
      final card = await cardFor(
          t, proposalOf(await t.executor.run('propose_delete_expense', {'expense_id': id})));
      await t.actions.confirm(card);
      expect(await total(), 0);
      await t.actions.undoDelete(card, id);
      expect(await total(), 120000);
    });
  });

  group('ask_user_to_pick', () {
    Future<List<int>> twoPetrols() async => [
          await seed(item: 'Petrol', category: 'Transport', paise: 105000, date: '2026-10-22'),
          await seed(item: 'Petrol', category: 'Transport', paise: 90000, date: '2026-10-19'),
        ];

    test('several matches become a list to choose from', () async {
      final ids = await twoPetrols();
      final p = proposalOf(await t.executor.run('ask_user_to_pick', {
        'kind': 'expense',
        'ids': ids,
        'then': 'update',
        'amount_rupees': 800,
      })) as PickProposal;
      expect(p.items.length, 2);
      expect(p.items.first.title, 'Petrol');
      expect(p.items.first.subtitle, contains('Thu, 22 Oct'));
      expect(p.then, 'update');
    });

    test('choosing one produces the real edit card, and closes the pick card', () async {
      final ids = await twoPetrols();
      final pick = proposalOf(await t.executor.run('ask_user_to_pick', {
        'kind': 'expense',
        'ids': ids,
        'then': 'update',
        'amount_rupees': 800,
      }));
      final pickCard = await cardFor(t, pick);
      expect(await t.actions.choose(pickCard, ids.last), isNull);

      expect((await t.env.chat.byId(pickCard))!.cardStatus, 'confirmed');
      final msgs = await t.env.chat.messagesForDay(kToday);
      final next = msgs.last;
      expect(next.cardType, 'update_expense');
      expect(next.cardStatus, 'pending');
      final u = Proposal.fromJson(jsonDecode(next.cardPayload!) as Map<String, dynamic>)
          as UpdateExpenseProposal;
      expect(u.expenseId, ids.last);
      expect(u.changes['amountPaise'], 80000);
    });

    test('picking for a delete goes to a delete card', () async {
      final ids = await twoPetrols();
      final pick = proposalOf(await t.executor
          .run('ask_user_to_pick', {'kind': 'expense', 'ids': ids, 'then': 'delete'}));
      final card = await cardFor(t, pick);
      await t.actions.choose(card, ids.first);
      expect((await t.env.chat.messagesForDay(kToday)).last.cardType, 'delete_expense');
    });

    test('a single valid id skips the question', () async {
      final ids = await twoPetrols();
      final p = proposalOf(await t.executor.run('ask_user_to_pick', {
        'kind': 'expense',
        'ids': [ids.first, 9999],
        'then': 'delete',
      }));
      expect(p, isA<DeleteExpenseProposal>());
    });

    test('duplicates and junk ids are cleaned; more than five are cut', () async {
      final ids = <int>[];
      for (var i = 0; i < 7; i++) {
        ids.add(await seed(item: 'Tea', date: '2026-10-0${i + 1}'));
      }
      final p = proposalOf(await t.executor.run('ask_user_to_pick', {
        'kind': 'expense',
        'ids': [...ids, ids.first, 'abc', null],
        'then': 'delete',
      })) as PickProposal;
      expect(p.items.length, 5);
    });

    test('invalid combinations are explained', () async {
      expect(errorOf(await t.executor.run('ask_user_to_pick', {'kind': 'expense', 'ids': [], 'then': 'update'})),
          contains('at least one'));
      expect(errorOf(await t.executor.run('ask_user_to_pick', {'kind': 'car', 'ids': [1], 'then': 'update'})),
          contains('kind'));
      expect(errorOf(await t.executor.run('ask_user_to_pick', {'kind': 'expense', 'ids': [1], 'then': 'dance'})),
          contains('then'));
      expect(errorOf(await t.executor.run('ask_user_to_pick', {'kind': 'expense', 'ids': [1], 'then': 'repay'})),
          contains('loans go with repay'));
      expect(errorOf(await t.executor.run('ask_user_to_pick', {'kind': 'expense', 'ids': [404], 'then': 'update'})),
          contains('None of those ids'));
    });

    test('choosing something that vanished meanwhile expires the pick with a message', () async {
      final ids = await twoPetrols();
      final pick = proposalOf(await t.executor.run('ask_user_to_pick', {
        'kind': 'expense',
        'ids': ids,
        'then': 'update',
        'amount_rupees': 800,
      }));
      final card = await cardFor(t, pick);
      await t.env.expenses.softDelete(ids.last);
      final msg = await t.actions.choose(card, ids.last);
      expect(msg, contains('No expense'));
      expect((await t.env.chat.byId(card))!.cardStatus, 'expired');
    });

    test('a pick card cannot be confirmed like a normal card', () async {
      final ids = await twoPetrols();
      final pick = proposalOf(await t.executor
          .run('ask_user_to_pick', {'kind': 'expense', 'ids': ids, 'then': 'delete'}));
      expect(await t.actions.confirm(await cardFor(t, pick)), isA<CommitFailed>());
    });
  });

  test('every proposal type survives a JSON round trip', () async {
    final id = await seed();
    final outcomes = [
      await t.executor.run('propose_add_expense', {
        'amount_rupees': 100, 'item': 'x', 'category': 'Other', 'spent_on': kToday
      }),
      await t.executor.run('propose_update_expense', {'expense_id': id, 'amount_rupees': 5}),
      await t.executor.run('propose_delete_expense', {'expense_id': id}),
      await t.executor.run('propose_set_budget', {'category': 'Food', 'monthly_limit_rupees': 5000}),
      await t.executor.run('propose_loan', {
        'direction': 'lent', 'person': 'Rahul', 'amount_rupees': 100, 'happened_on': kToday
      }),
    ];
    for (final o in outcomes) {
      final p = proposalOf(o);
      final back = Proposal.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
      expect(back.toJson(), p.toJson());
      expect(back.summary, p.summary);
    }
  });

  test('an unreadable stored card cannot crash Save', () async {
    final card = await t.env.chat.add(
        day: kToday, role: 'card', cardType: 'add_expense', cardPayload: '{not json', cardStatus: 'pending');
    expect(await t.actions.confirm(card), isA<CommitFailed>());
    final unknown = await t.env.chat.add(
        day: kToday, role: 'card', cardType: 'zzz', cardPayload: '{"type":"zzz"}', cardStatus: 'pending');
    expect(await t.actions.confirm(unknown), isA<CommitFailed>());
    expect(await t.actions.confirm('no-such-id'), isA<CommitFailed>());
  });
}
