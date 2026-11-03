import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/repositories/expense_repository.dart';
import 'package:kharchu/data/repositories/lending_repository.dart';

import 'helpers.dart';

void main() {
  late TestEnv env;
  setUp(() => env = TestEnv());
  tearDown(() => env.close());

  Future<int> lend(String who, int paise,
      {String dir = 'lent', String date = '2026-10-24', String? note}) async {
    final p = await env.lending.findOrCreatePerson(who);
    return env.lending.addLoan(
        personId: p.id,
        direction: dir,
        principalPaise: paise,
        happenedOn: date,
        note: note);
  }

  group('people', () {
    test('same person regardless of case and spacing', () async {
      final a = await env.lending.findOrCreatePerson('Rahul');
      final b = await env.lending.findOrCreatePerson('  rahul ');
      final c = await env.lending.findOrCreatePerson('RAHUL');
      expect(b.id, a.id);
      expect(c.id, a.id);
      expect(await env.db.select(env.db.people).get(), hasLength(1));
    });

    test('display name is title-cased only when the input is all one case',
        () {
      expect(LendingRepository.displayName('rahul k'), 'Rahul K');
      expect(LendingRepository.displayName('PRIYA'), 'Priya');
      expect(LendingRepository.displayName('McDonald'), 'McDonald');
      expect(LendingRepository.displayName('  anil   kumar '), 'Anil Kumar');
    });

    test('empty and oversized names are rejected', () async {
      expect(() => env.lending.findOrCreatePerson('  '),
          throwsA(isA<LendingException>()));
      expect(() => env.lending.findOrCreatePerson('x' * 61),
          throwsA(isA<LendingException>()));
    });

    test('"Rahul" and "Rahul K" are different people but are flagged as candidates',
        () async {
      final rahul = await env.lending.findOrCreatePerson('Rahul');
      final rahulK = await env.lending.findOrCreatePerson('Rahul K');
      expect(rahulK.id, isNot(rahul.id));
      final c = await env.lending.candidatePeople('rahul');
      expect(c.map((p) => p.id), [rahul.id]); // exact wins
      final c2 = await env.lending.candidatePeople('Rahul Kumar');
      // "Rahul Kumar" extends "Rahul" at a word boundary, but not "Rahul K".
      expect(c2.map((p) => p.id).toSet(), {rahul.id});
      expect(await env.lending.candidatePeople('Priya'), isEmpty);
      expect(await env.lending.candidatePeople(''), isEmpty);
    });
  });

  group('loans and repayments', () {
    test('rejects bad direction and non-positive amounts', () async {
      final p = await env.lending.findOrCreatePerson('Rahul');
      expect(
          () => env.lending.addLoan(
              personId: p.id, direction: 'gave', principalPaise: 100, happenedOn: '2026-10-24'),
          throwsA(isA<LendingException>()));
      expect(
          () => env.lending.addLoan(
              personId: p.id, direction: 'lent', principalPaise: 0, happenedOn: '2026-10-24'),
          throwsA(isA<LendingException>()));
      expect(
          () => env.lending.addLoan(
              personId: p.id, direction: 'lent', principalPaise: -5, happenedOn: '2026-10-24'),
          throwsA(isA<LendingException>()));
    });

    test('partial then full repayment settles the loan', () async {
      final id = await lend('Rahul', 200000, note: 'Goa trip');
      await env.lending.addRepayment(loanId: id, amountPaise: 100000, paidOn: '2026-10-25');
      var v = (await env.lending.loanView(id))!;
      expect(v.outstandingPaise, 100000);
      expect(v.settled, isFalse);

      await env.lending.addRepayment(loanId: id, amountPaise: 100000, paidOn: '2026-10-26');
      v = (await env.lending.loanView(id))!;
      expect(v.outstandingPaise, 0);
      expect(v.settled, isTrue);
    });

    test('repaying more than outstanding is refused and reports the balance',
        () async {
      final id = await lend('Rahul', 200000);
      await env.lending.addRepayment(loanId: id, amountPaise: 150000, paidOn: '2026-10-25');
      try {
        await env.lending.addRepayment(loanId: id, amountPaise: 60000, paidOn: '2026-10-26');
        fail('should have thrown');
      } on RepaymentExceedsOutstanding catch (e) {
        expect(e.outstandingPaise, 50000);
      }
      expect((await env.lending.loanView(id))!.outstandingPaise, 50000);
    });

    test('repaying a settled loan is refused', () async {
      final id = await lend('Rahul', 100000);
      await env.lending.addRepayment(loanId: id, amountPaise: 100000, paidOn: '2026-10-25');
      expect(
          () => env.lending.addRepayment(loanId: id, amountPaise: 1, paidOn: '2026-10-26'),
          throwsA(isA<RepaymentExceedsOutstanding>()));
    });

    test('zero repayment, missing loan and deleted loan are refused', () async {
      final id = await lend('Rahul', 100000);
      expect(() => env.lending.addRepayment(loanId: id, amountPaise: 0, paidOn: '2026-10-25'),
          throwsA(isA<LendingException>()));
      expect(() => env.lending.addRepayment(loanId: 999, amountPaise: 10, paidOn: '2026-10-25'),
          throwsA(isA<LendingException>()));
      await env.lending.softDeleteLoan(id);
      expect(() => env.lending.addRepayment(loanId: id, amountPaise: 10, paidOn: '2026-10-25'),
          throwsA(isA<LendingException>()));
    });

    test('a failed repayment leaves no partial row behind', () async {
      final id = await lend('Rahul', 100000);
      try {
        await env.lending.addRepayment(loanId: id, amountPaise: 999999, paidOn: '2026-10-25');
      } catch (_) {}
      expect(await env.db.select(env.db.loanRepayments).get(), isEmpty);
    });
  });

  group('balances and totals', () {
    test('"you will get" and "you owe" are tracked separately', () async {
      await lend('Rahul', 200000);
      await lend('Karthik', 250000);
      await lend('Priya', 150000, dir: 'borrowed');
      final t = await env.lending.totals();
      expect(t.getPaise, 450000);
      expect(t.owePaise, 150000);
      expect(t.getPeople, 2);
      expect(t.owePeople, 1);
    });

    test('totals count only what is still outstanding', () async {
      final id = await lend('Karthik', 250000);
      await env.lending.addRepayment(loanId: id, amountPaise: 100000, paidOn: '2026-10-25');
      expect((await env.lending.totals()).getPaise, 150000);
      await env.lending.addRepayment(loanId: id, amountPaise: 150000, paidOn: '2026-10-26');
      final t = await env.lending.totals();
      expect(t.getPaise, 0);
      expect(t.getPeople, 0);
    });

    test('deleted loans vanish from totals and balances; restore brings them back',
        () async {
      final id = await lend('Rahul', 200000);
      await env.lending.softDeleteLoan(id);
      expect((await env.lending.totals()).getPaise, 0);
      expect(await env.lending.balances(), isEmpty);
      await env.lending.restoreLoan(id);
      expect((await env.lending.totals()).getPaise, 200000);
    });

    test('a person with both lent and borrowed shows the net', () async {
      await lend('Rahul', 200000);
      await lend('Rahul', 50000, dir: 'borrowed');
      final b = (await env.lending.balances()).single;
      expect(b.netPaise, 150000);
      expect(b.openLoans, 2);
      final t = await env.lending.totals();
      expect(t.getPaise, 200000);
      expect(t.owePaise, 50000);
    });

    test('net can be negative (you owe them)', () async {
      await lend('Priya', 100000, dir: 'borrowed');
      expect((await env.lending.balances()).single.netPaise, -100000);
    });

    test('open people come before settled, then newest activity first', () async {
      final a = await lend('Anil', 80000, date: '2026-10-02');
      await env.lending.addRepayment(loanId: a, amountPaise: 80000, paidOn: '2026-10-03');
      await lend('Rahul', 200000, date: '2026-10-24');
      await lend('Karthik', 250000, date: '2026-10-10');
      final names = (await env.lending.balances()).map((b) => b.person.name).toList();
      expect(names, ['Rahul', 'Karthik', 'Anil']);
      expect((await env.lending.balances()).last.settled, isTrue);
    });

    test('settled loans are filtered out by openOnly', () async {
      final a = await lend('Anil', 80000);
      await env.lending.addRepayment(loanId: a, amountPaise: 80000, paidOn: '2026-10-25');
      await lend('Rahul', 1000);
      expect((await env.lending.loanViews(openOnly: true)).length, 1);
      expect((await env.lending.loanViews()).length, 2);
    });

    test('loanViews filters by person and direction', () async {
      await lend('Rahul', 1000);
      await lend('Rahul', 2000, dir: 'borrowed');
      final p = await env.lending.personByExactName('rahul');
      expect((await env.lending.loanViews(personId: p!.id, direction: 'lent')).length, 1);
      expect((await env.lending.loanViews(personId: p.id)).length, 2);
    });

    test('history lists loans and repayments oldest first', () async {
      final id = await lend('Rahul', 200000, date: '2026-10-10', note: 'Goa');
      await env.lending.addRepayment(loanId: id, amountPaise: 50000, paidOn: '2026-10-12');
      await lend('Rahul', 30000, date: '2026-10-11');
      final p = await env.lending.personByExactName('Rahul');
      final h = await env.lending.history(p!.id);
      expect(h.map((e) => (e.date, e.isRepayment)), [
        ('2026-10-10', false),
        ('2026-10-11', false),
        ('2026-10-12', true),
      ]);
    });

    test('watchTotals updates after a repayment', () async {
      final id = await lend('Rahul', 200000);
      final seen = <int>[];
      final sub = env.lending.watchTotals().listen((t) => seen.add(t.getPaise));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await env.lending.addRepayment(loanId: id, amountPaise: 50000, paidOn: '2026-10-25');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await sub.cancel();
      expect(seen.first, 200000);
      expect(seen.last, 150000);
    });
  });

  test('lending never affects spending totals or budgets', () async {
    await env.addExpense(paise: 100000, date: '2026-10-24');
    await lend('Rahul', 5000000);
    await lend('Priya', 2000000, dir: 'borrowed');
    expect(await env.expenses.total('2026-10-01', '2026-10-31'), 100000);
    expect(await env.expenses.count('2026-10-01', '2026-10-31'), 1);
  });

  group('chat', () {
    test('messages come back in insertion order, even within one second',
        () async {
      for (var i = 0; i < 6; i++) {
        await env.chat.add(day: '2026-10-24', role: 'user', body: 'm$i');
      }
      final list = await env.chat.messagesForDay('2026-10-24');
      expect(list.map((m) => m.body), ['m0', 'm1', 'm2', 'm3', 'm4', 'm5']);
    });

    test('days are separate', () async {
      await env.chat.add(day: '2026-10-23', role: 'user', body: 'yesterday');
      await env.chat.add(day: '2026-10-24', role: 'user', body: 'today');
      expect((await env.chat.messagesForDay('2026-10-24')).single.body, 'today');
    });

    test('recentTurns returns the last N oldest-first and skips notices',
        () async {
      for (var i = 0; i < 8; i++) {
        await env.chat.add(day: '2026-10-24', role: 'user', body: 'm$i');
      }
      await env.chat.add(day: '2026-10-24', role: 'notice', body: 'budget 85%');
      final turns = await env.chat.recentTurns('2026-10-24', 6);
      expect(turns.map((m) => m.body), ['m2', 'm3', 'm4', 'm5', 'm6', 'm7']);
    });

    test('updateCard changes only what is given', () async {
      final id = await env.chat.add(
          day: '2026-10-24', role: 'card', cardType: 'add',
          cardPayload: '{"a":1}', cardStatus: 'pending');
      await env.chat.updateCard(id, status: 'confirmed', entityRef: 'expense:42');
      final m = (await env.chat.byId(id))!;
      expect(m.cardStatus, 'confirmed');
      expect(m.entityRef, 'expense:42');
      expect(m.cardPayload, '{"a":1}');
    });

    test('pastDays lists earlier days newest first and excludes today', () async {
      await env.chat.add(day: '2026-10-22', role: 'user', body: 'a');
      await env.chat.add(day: '2026-10-23', role: 'user', body: 'b');
      await env.chat.add(day: '2026-10-24', role: 'user', body: 'c');
      expect(await env.chat.pastDays('2026-10-24'), ['2026-10-23', '2026-10-22']);
    });

    test('purge deletes chat older than 30 days but keeps the boundary day',
        () async {
      await env.chat.add(day: '2026-09-23', role: 'user', body: 'old');   // 31 days
      await env.chat.add(day: '2026-09-24', role: 'user', body: 'edge');  // 30 days
      await env.chat.add(day: '2026-10-24', role: 'user', body: 'today');
      final n = await env.chat.purgeOlderThan('2026-10-24');
      expect(n, 1);
      expect(await env.chat.pastDays('2026-10-25'), ['2026-10-24', '2026-09-24']);
    });

    test('purge never touches expenses, loans or budgets', () async {
      final eid = await env.addExpense(paise: 1000, date: '2026-01-01');
      await lend('Rahul', 5000, date: '2026-01-01');
      await env.budgets.upsert(null, 100000);
      await env.chat.add(day: '2026-01-01', role: 'user', body: 'ancient');
      await env.chat.purgeOlderThan('2026-10-24');
      expect(await env.expenses.getById(eid), isNotNull);
      expect((await env.lending.loanViews()).length, 1);
      expect((await env.budgets.all()).length, 1);
      expect(await env.chat.pastDays('2026-10-24'), isEmpty);
    });

    test('purge across a year boundary', () async {
      await env.chat.add(day: '2025-12-01', role: 'user', body: 'old');
      await env.chat.add(day: '2025-12-31', role: 'user', body: 'new');
      await env.chat.purgeOlderThan('2026-01-15');
      expect(await env.chat.pastDays('2026-02-01'), ['2025-12-31']);
    });

    test('clearAll removes all chat but nothing else', () async {
      await env.addExpense(paise: 1000);
      await env.chat.add(day: '2026-10-24', role: 'user', body: 'x');
      expect(await env.chat.clearAll(), 1);
      expect(await env.expenses.find(const ExpenseFilter()), hasLength(1));
    });
  });
}
