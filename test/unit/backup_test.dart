import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharchu/data/repositories/expense_repository.dart';
import 'package:kharchu/services/backup_service.dart';
import 'package:kharchu/services/export_service.dart';

import 'helpers.dart';

/// A ledger with a bit of everything: nulls, Kannada, both loan directions,
/// partial repayments, an archived custom category, a budget of each kind,
/// and a deleted expense and loan that must NOT travel.
Future<void> fillLedger(TestEnv e) async {
  final custom = await e.categories.create('Personal Care');
  await e.categories.setArchived(await e.cat('Travel'), true);
  await e.addExpense(paise: 100000, item: 'Chats', location: 'Bengaluru', payment: 'upi',
      date: '2026-10-24', raw: 'I spent Rs.1000 to eat chats in Bengaluru');
  await e.addExpense(paise: 3550, item: 'ಚಹಾ', category: 'Food & Dining', date: '2026-10-23',
      raw: 'ಚಹಾ 35.50 😀, "quoted"\nnew line');
  await e.expenses.add(
      amountPaise: 35000, categoryId: custom.id, item: 'Haircut', spentOn: '2026-10-20');
  final gone = await e.addExpense(paise: 999, item: 'Deleted one');
  await e.expenses.softDelete(gone);
  await e.budgets.upsert(null, 2500000);
  await e.budgets.upsert(await e.cat('Food & Dining'), 600000);

  final rahul = await e.lending.findOrCreatePerson('Rahul');
  final priya = await e.lending.findOrCreatePerson('Priya');
  final goa = await e.lending.addLoan(
      personId: rahul.id, direction: 'lent', principalPaise: 200000, note: 'Goa trip',
      paymentMethod: 'upi', happenedOn: '2026-10-10');
  await e.lending.addRepayment(loanId: goa, amountPaise: 50000, paidOn: '2026-10-12');
  await e.lending.addLoan(
      personId: priya.id, direction: 'borrowed', principalPaise: 100000, happenedOn: '2026-10-05');
  final deletedLoan = await e.lending.addLoan(
      personId: rahul.id, direction: 'lent', principalPaise: 5000, happenedOn: '2026-10-01');
  await e.lending.softDeleteLoan(deletedLoan);
  await e.chat.add(day: '2026-10-24', role: 'user', body: 'chat history is not backed up');
}

Map<String, dynamic> decode(String json) => jsonDecode(json) as Map<String, dynamic>;

/// Same data, ignoring when the file was made.
Map<String, dynamic> withoutStamp(String json) => decode(json)..remove('exported_at');

void main() {
  late TestEnv a;
  late TestEnv b;
  setUp(() {
    a = TestEnv();
    b = TestEnv();
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  group('export', () {
    test('identifies the app and version, and never includes chat or the key', () async {
      await fillLedger(a);
      final j = await BackupService(a.db).exportJson();
      final m = decode(j);
      expect(m['app'], 'kharchu');
      expect(m['backup_version'], 1);
      expect(m.keys, isNot(contains('chat')));
      expect(j, isNot(contains('chat history is not backed up')));
      expect(j.toLowerCase(), isNot(contains('gsk_')));
    });

    test('leaves out deleted expenses and loans, and the repayments of deleted loans', () async {
      await fillLedger(a);
      final m = decode(await BackupService(a.db).exportJson());
      expect((m['expenses'] as List).length, 3);
      expect(jsonEncode(m['expenses']), isNot(contains('Deleted one')));
      expect((m['loans'] as List).length, 2);
      expect((m['repayments'] as List).length, 1);
      expect(m['counts'], containsPair('expenses', 3));
    });

    test('an empty ledger still exports its default categories', () async {
      final m = decode(await BackupService(a.db).exportJson());
      expect((m['categories'] as List).length, 10);
      expect(m['expenses'], isEmpty);
    });
  });

  group('round trip', () {
    test('everything survives backup -> restore into a different database', () async {
      await fillLedger(a);
      final first = await BackupService(a.db).exportJson();
      await BackupService(b.db).restore(first);
      final second = await BackupService(b.db).exportJson();
      expect(withoutStamp(second), withoutStamp(first));
    });

    test('restored data behaves: totals, lending balances and search all match', () async {
      await fillLedger(a);
      await BackupService(b.db).restore(await BackupService(a.db).exportJson());
      expect(await b.expenses.total('2026-10-01', '2026-10-31'),
          await a.expenses.total('2026-10-01', '2026-10-31'));
      expect((await b.lending.totals()).getPaise, 150000);
      expect((await b.lending.totals()).owePaise, 100000);
      expect((await b.expenses.find(const ExpenseFilter(text: 'ಚಹಾ'))).length, 1);
      expect((await b.categories.exact('Personal Care')), isNotNull);
      expect((await b.categories.exact('Travel'))!.isArchived, isTrue);
      expect((await b.budgets.forCategory(null))!.monthlyLimitPaise, 2500000);
    });

    test('Kannada, emoji, quotes and newlines come back exactly', () async {
      await fillLedger(a);
      await BackupService(b.db).restore(await BackupService(a.db).exportJson());
      final row = (await b.expenses.find(const ExpenseFilter(text: 'ಚಹಾ'))).single.expense;
      expect(row.rawText, 'ಚಹಾ 35.50 😀, "quoted"\nnew line');
      expect(row.amountPaise, 3550);
    });

    test('restore replaces what was there, and clears chat', () async {
      await fillLedger(a);
      await b.addExpense(paise: 777, item: 'Old data');
      await b.chat.add(day: '2026-10-24', role: 'user', body: 'old chat');
      await BackupService(b.db).restore(await BackupService(a.db).exportJson());
      expect((await b.expenses.find(const ExpenseFilter(text: 'Old data'))), isEmpty);
      expect(await b.chat.pastDays('2026-12-31'), isEmpty);
      expect((await b.expenses.find(const ExpenseFilter())).length, 3);
    });

    test('new entries after a restore get fresh ids, never clashing with restored ones',
        () async {
      await fillLedger(a);
      await BackupService(b.db).restore(await BackupService(a.db).exportJson());
      final existing = (await b.expenses.find(const ExpenseFilter())).map((r) => r.expense.id).toSet();
      final id = await b.addExpense(paise: 100, item: 'After restore');
      expect(existing, isNot(contains(id)));
      final loan = await b.lending.findOrCreatePerson('New Person');
      expect(await b.lending.addLoan(personId: loan.id, direction: 'lent', principalPaise: 5, happenedOn: '2026-10-24'),
          isPositive);
    });

    test('restoring the same file twice is harmless', () async {
      await fillLedger(a);
      final json = await BackupService(a.db).exportJson();
      await BackupService(b.db).restore(json);
      await BackupService(b.db).restore(json);
      expect(withoutStamp(await BackupService(b.db).exportJson()), withoutStamp(json));
    });

    test('an empty ledger round-trips', () async {
      final json = await BackupService(a.db).exportJson();
      await BackupService(b.db).restore(json);
      expect((await b.categories.active()).length, 10);
    });

    test('inspect reports counts and writes nothing', () async {
      await fillLedger(a);
      await b.addExpense(paise: 777, item: 'Keep me');
      final s = BackupService(b.db).inspect(await BackupService(a.db).exportJson());
      expect(s.expenses, 3);
      expect(s.loans, 2);
      expect(s.repayments, 1);
      expect(s.people, 2);
      expect(s.budgets, 2);
      expect(s.categories, 11);
      expect((await b.expenses.find(const ExpenseFilter())).single.expense.item, 'Keep me');
    });

    test('a restored backup can be backed up again, repeatedly, without drift', () async {
      await fillLedger(a);
      var json = await BackupService(a.db).exportJson();
      for (var i = 0; i < 3; i++) {
        final next = TestEnv();
        await BackupService(next.db).restore(json);
        final again = await BackupService(next.db).exportJson();
        expect(withoutStamp(again), withoutStamp(json));
        json = again;
        await next.close();
      }
    });
  });

  group('bad files are refused and nothing changes', () {
    late String good;
    setUp(() async {
      await fillLedger(a);
      good = await BackupService(a.db).exportJson();
      await b.addExpense(paise: 12345, item: 'My real data');
    });

    Future<void> refused(String json, {String? mentions}) async {
      final service = BackupService(b.db);
      try {
        await service.restore(json);
        fail('should have been refused');
      } on BackupException catch (e) {
        if (mentions != null) expect(e.message, contains(mentions));
        expect(e.message, isNotEmpty);
      }
      final rows = await b.expenses.find(const ExpenseFilter());
      expect(rows.single.expense.item, 'My real data', reason: 'existing data must survive');
      expect((await b.categories.active()).length, 10);
    }

    Future<void> broken(void Function(Map<String, dynamic> m) edit, {String? mentions}) async {
      final m = decode(good);
      edit(m);
      await refused(jsonEncode(m), mentions: mentions);
    }

    test('not JSON, empty, truncated, or the wrong kind of JSON', () async {
      await refused('', mentions: "isn't a Kharchu backup");
      await refused('not json at all');
      await refused(good.substring(0, good.length ~/ 2));
      await refused('[1,2,3]');
      await refused('"a string"');
      await refused('null');
      await refused('{}');
    });

    test('a different app\'s file', () => broken((m) => m['app'] = 'something-else', mentions: "isn't a Kharchu"));

    test('a newer backup format', () async {
      await broken((m) => m['backup_version'] = 99, mentions: 'newer version');
      await broken((m) => m['schema_version'] = 99, mentions: 'newer version');
    });

    test('a missing or mistyped version', () async {
      await broken((m) => m.remove('backup_version'));
      await broken((m) => m['backup_version'] = '1');
    });

    test('a missing table, or one of the wrong type', () async {
      for (final k in ['categories', 'people', 'expenses', 'budgets', 'loans', 'repayments']) {
        await broken((m) => m.remove(k), mentions: k);
        await broken((m) => m[k] = 'nope');
        await broken((m) => m[k] = [1, 2]);
      }
    });

    test('no categories at all', () => broken((m) {
          m['categories'] = [];
          m['expenses'] = [];
          m['budgets'] = [];
        }, mentions: 'no categories'));

    test('amounts that are zero, negative, fractional or not numbers', () async {
      for (final v in [0, -100, 12.5, '100', null]) {
        await broken((m) => (m['expenses'] as List).first['amountPaise'] = v);
      }
      await broken((m) => (m['loans'] as List).first['principalPaise'] = 0);
      await broken((m) => (m['budgets'] as List).first['monthlyLimitPaise'] = -1);
      await broken((m) => (m['repayments'] as List).first['amountPaise'] = 0);
    });

    test('references to things that are not in the file', () async {
      await broken((m) => (m['expenses'] as List).first['categoryId'] = 9999, mentions: 'category');
      await broken((m) => (m['budgets'] as List).last['categoryId'] = 9999, mentions: 'category');
      await broken((m) => (m['loans'] as List).first['personId'] = 9999, mentions: 'person');
      await broken((m) => (m['repayments'] as List).first['loanId'] = 9999, mentions: 'loan');
    });

    test('duplicate ids and duplicate names', () async {
      await broken((m) {
        final e = m['expenses'] as List;
        e[1]['id'] = e[0]['id'];
      });
      await broken((m) => (m['categories'] as List)[1]['name'] = (m['categories'] as List)[0]['name'].toString().toUpperCase(),
          mentions: 'duplicate category');
      await broken((m) {
        final p = m['people'] as List;
        p[1]['nameKey'] = p[0]['nameKey'];
      }, mentions: 'duplicate person');
      await broken((m) => (m['expenses'] as List).first['id'] = 0);
      await broken((m) => (m['expenses'] as List).first['id'] = 'x');
    });

    test('a loan repaid more than it was lent', () => broken((m) {
          final reps = m['repayments'] as List;
          reps.add({...Map<String, dynamic>.from(reps.first as Map), 'id': 999, 'amountPaise': 99999999});
        }, mentions: 'repaid more'));

    test('two overall budgets, or two budgets for one category', () async {
      await broken((m) {
        final b = m['budgets'] as List;
        b.add({'id': 50, 'categoryId': null, 'monthlyLimitPaise': 100, 'updatedAt': '2026-10-01T00:00:00.000'});
      }, mentions: 'overall');
      await broken((m) {
        final b = m['budgets'] as List;
        b.add({...Map<String, dynamic>.from(b.last as Map), 'id': 51});
      }, mentions: 'one category');
    });

    test('an unknown loan direction', () => broken((m) => (m['loans'] as List).first['direction'] = 'gifted', mentions: 'direction'));

    test('impossible or malformed dates', () async {
      for (final v in ['2026-02-30', '2026-13-01', '24/10/2026', '', 'today', 5, null]) {
        await broken((m) => (m['expenses'] as List).first['spentOn'] = v);
      }
      await broken((m) => (m['loans'] as List).first['happenedOn'] = '2026-04-31');
      await broken((m) => (m['repayments'] as List).first['paidOn'] = 'soon');
      await broken((m) => (m['expenses'] as List).first['createdAt'] = 'not a time');
    });

    test('blank or oversized text where text is required', () async {
      await broken((m) => (m['expenses'] as List).first['item'] = '   ');
      await broken((m) => (m['expenses'] as List).first['item'] = 'x' * 500);
      await broken((m) => (m['categories'] as List).first['name'] = '');
      await broken((m) => (m['expenses'] as List).first['rawText'] = 'y' * 5000);
      await broken((m) => (m['expenses'] as List).first['item'] = 42);
    });

    test('the good file still restores after all that', () async {
      await BackupService(b.db).restore(good);
      expect((await b.expenses.find(const ExpenseFilter())).length, 3);
    });
  });

  group('CSV export', () {
    Future<List<List<dynamic>>> rowsFor(TestEnv e, String from, String to) async {
      final csv = await ExportService(e.expenses).buildCsv(from: from, to: to);
      return Csv().decode(csv.replaceFirst('﻿', ''));
    }

    test('has a BOM so Excel reads Kannada, and the agreed columns', () async {
      await a.addExpense(paise: 100, item: 'ಚಹಾ');
      final csv = await ExportService(a.expenses).buildCsv(from: '2026-10-01', to: '2026-10-31');
      expect(csv.codeUnitAt(0), 0xFEFF);
      final rows = Csv().decode(csv.replaceFirst('﻿', ''));
      expect(rows.first, ExportService.header);
      expect(rows[1][1], 'ಚಹಾ');
    });

    test('rows are oldest first with plain numeric amounts', () async {
      await a.addExpense(paise: 100000, item: 'Chats', date: '2026-10-24', payment: 'upi', location: 'BLR');
      await a.addExpense(paise: 1050, item: 'Tea', date: '2026-10-02');
      final rows = await rowsFor(a, '2026-10-01', '2026-10-31');
      expect(rows.length, 3);
      expect(rows[1][0], '2026-10-02');
      expect(rows[1][3].toString(), anyOf('10.50', '10.5'));
      expect(rows[2][3].toString(), '1000');
      expect(rows[2][4], 'upi');
      expect(rows[2][5], 'BLR');
    });

    test('commas, quotes and line breaks in text do not break the file', () async {
      await a.addExpense(paise: 100, item: 'Lunch, "special"', raw: 'line one\nline two, with comma');
      final rows = await rowsFor(a, '2026-10-01', '2026-10-31');
      expect(rows[1][1], 'Lunch, "special"');
      expect(rows[1][6], 'line one\nline two, with comma');
      expect(rows[1].length, ExportService.header.length);
    });

    test('text that a spreadsheet would run as a formula is neutralised', () async {
      for (final evil in ['=HYPERLINK("http://x","y")', '+1+1', '-2+3', '@SUM(A1)']) {
        await a.addExpense(paise: 100, item: evil, raw: evil);
      }
      final rows = await rowsFor(a, '2026-10-01', '2026-10-31');
      for (final r in rows.skip(1)) {
        expect(r[1].toString(), startsWith("'"));
        expect(r[6].toString(), startsWith("'"));
      }
    });

    test('only the chosen dates, inclusive, and never deleted expenses', () async {
      await a.addExpense(paise: 100, item: 'In', date: '2026-10-01');
      await a.addExpense(paise: 100, item: 'In too', date: '2026-10-31');
      await a.addExpense(paise: 100, item: 'Before', date: '2026-09-30');
      await a.addExpense(paise: 100, item: 'After', date: '2026-11-01');
      final gone = await a.addExpense(paise: 100, item: 'Deleted', date: '2026-10-15');
      await a.expenses.softDelete(gone);
      final rows = await rowsFor(a, '2026-10-01', '2026-10-31');
      expect(rows.skip(1).map((r) => r[1]).toSet(), {'In', 'In too'});
    });

    test('an empty range is just the header', () async {
      final rows = await rowsFor(a, '2026-10-01', '2026-10-31');
      expect(rows.length, 1);
    });

    test('file name carries the range', () {
      expect(ExportService.fileName('2026-10-01', '2026-10-31'),
          'expenses_2026-10-01_to_2026-10-31.csv');
    });
  });
}
