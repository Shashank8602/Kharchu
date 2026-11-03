import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/db/app_database.dart';

class BackupException implements Exception {
  BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// What a backup file holds, shown before the user agrees to replace data.
class BackupSummary {
  const BackupSummary({
    required this.exportedAt,
    required this.categories,
    required this.expenses,
    required this.budgets,
    required this.people,
    required this.loans,
    required this.repayments,
  });
  final String exportedAt;
  final int categories;
  final int expenses;
  final int budgets;
  final int people;
  final int loans;
  final int repayments;
}

/// A restore that has been fully checked and is ready to write.
class _Parsed {
  _Parsed(this.summary);
  final BackupSummary summary;
  final categories = <CategoriesCompanion>[];
  final people = <PeopleCompanion>[];
  final expenses = <ExpensesCompanion>[];
  final budgets = <BudgetsCompanion>[];
  final loans = <LoansCompanion>[];
  final repayments = <LoanRepaymentsCompanion>[];
}

/// Backup and restore as one JSON file. JSON (not a raw database copy) so the
/// file is readable, survives app upgrades, and can be checked before it
/// replaces anything. Chat history and the Groq key are never included.
class BackupService {
  BackupService(this.db);
  final AppDatabase db;

  static const appId = 'kharchu';
  static const backupVersion = 1;

  /// Files bigger than this are not read (a personal ledger is far smaller).
  static const maxBytes = 50 * 1024 * 1024;

  // ---- export --------------------------------------------------------------

  Future<String> exportJson({DateTime? now}) async {
    final cats = await db.select(db.categories).get();
    final people = await db.select(db.people).get();
    final expenses =
        await (db.select(db.expenses)..where((e) => e.deletedAt.isNull())).get();
    final budgets = await db.select(db.budgets).get();
    final loans = await (db.select(db.loans)..where((l) => l.deletedAt.isNull())).get();
    final loanIds = loans.map((l) => l.id).toSet();
    final repayments = (await db.select(db.loanRepayments).get())
        .where((r) => loanIds.contains(r.loanId))
        .toList();

    String ts(DateTime d) => d.toIso8601String();
    final data = <String, dynamic>{
      'app': appId,
      'backup_version': backupVersion,
      'schema_version': db.schemaVersion,
      'exported_at': ts(now ?? DateTime.now()),
      'counts': {
        'categories': cats.length,
        'expenses': expenses.length,
        'budgets': budgets.length,
        'people': people.length,
        'loans': loans.length,
        'repayments': repayments.length,
      },
      'categories': [
        for (final c in cats)
          {
            'id': c.id,
            'name': c.name,
            'colorLight': c.colorLight,
            'colorDark': c.colorDark,
            'icon': c.icon,
            'isDefault': c.isDefault,
            'isArchived': c.isArchived,
            'createdAt': ts(c.createdAt),
          }
      ],
      'people': [
        for (final p in people)
          {'id': p.id, 'name': p.name, 'nameKey': p.nameKey, 'createdAt': ts(p.createdAt)}
      ],
      'expenses': [
        for (final e in expenses)
          {
            'id': e.id,
            'amountPaise': e.amountPaise,
            'categoryId': e.categoryId,
            'item': e.item,
            'location': e.location,
            'paymentMethod': e.paymentMethod,
            'spentOn': e.spentOn,
            'rawText': e.rawText,
            'source': e.source,
            'createdAt': ts(e.createdAt),
            'updatedAt': ts(e.updatedAt),
          }
      ],
      'budgets': [
        for (final b in budgets)
          {
            'id': b.id,
            'categoryId': b.categoryId,
            'monthlyLimitPaise': b.monthlyLimitPaise,
            'updatedAt': ts(b.updatedAt),
          }
      ],
      'loans': [
        for (final l in loans)
          {
            'id': l.id,
            'personId': l.personId,
            'direction': l.direction,
            'principalPaise': l.principalPaise,
            'note': l.note,
            'paymentMethod': l.paymentMethod,
            'happenedOn': l.happenedOn,
            'rawText': l.rawText,
            'createdAt': ts(l.createdAt),
          }
      ],
      'repayments': [
        for (final r in repayments)
          {
            'id': r.id,
            'loanId': r.loanId,
            'amountPaise': r.amountPaise,
            'paidOn': r.paidOn,
            'rawText': r.rawText,
            'createdAt': ts(r.createdAt),
          }
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // ---- restore -------------------------------------------------------------

  /// Checks a backup and says what is in it. Writes nothing.
  BackupSummary inspect(String json) => _parse(json).summary;

  /// Replaces ALL current data with the backup. Checked first, then written
  /// in one transaction: if anything fails, nothing changes.
  Future<BackupSummary> restore(String json) async {
    final p = _parse(json);
    await db.transaction(() async {
      // children first, because foreign keys are enforced
      await db.delete(db.loanRepayments).go();
      await db.delete(db.loans).go();
      await db.delete(db.people).go();
      await db.delete(db.expenses).go();
      await db.delete(db.budgets).go();
      await db.delete(db.categories).go();
      // pending chat cards point at ids that no longer mean anything
      await db.delete(db.chatMessages).go();

      await db.batch((b) {
        b.insertAll(db.categories, p.categories);
        b.insertAll(db.people, p.people);
        b.insertAll(db.expenses, p.expenses);
        b.insertAll(db.budgets, p.budgets);
        b.insertAll(db.loans, p.loans);
        b.insertAll(db.loanRepayments, p.repayments);
      });
    });
    return p.summary;
  }

  _Parsed _parse(String json) {
    if (json.length > maxBytes) throw BackupException('That file is too large to be a backup.');
    final dynamic root;
    try {
      root = jsonDecode(json);
    } on FormatException {
      throw BackupException("That file isn't a Kharchu backup.");
    }
    if (root is! Map<String, dynamic>) throw BackupException("That file isn't a Kharchu backup.");
    if (root['app'] != appId) throw BackupException("That file isn't a Kharchu backup.");
    final version = root['backup_version'];
    if (version is! int) throw BackupException('That backup file is damaged.');
    if (version > backupVersion) {
      throw BackupException('That backup is from a newer version of Kharchu. Update the app first.');
    }
    final schema = root['schema_version'];
    if (schema is int && schema > db.schemaVersion) {
      throw BackupException('That backup is from a newer version of Kharchu. Update the app first.');
    }

    List<Map<String, dynamic>> rows(String key) {
      final v = root[key];
      if (v is! List) throw BackupException('That backup file is damaged ($key is missing).');
      return [
        for (final r in v)
          if (r is Map<String, dynamic>) r else throw BackupException('That backup file is damaged ($key).')
      ];
    }

    final catRows = rows('categories');
    final peopleRows = rows('people');
    final expRows = rows('expenses');
    final budRows = rows('budgets');
    final loanRows = rows('loans');
    final repRows = rows('repayments');

    if (catRows.isEmpty) throw BackupException('That backup has no categories, so it cannot be used.');

    final p = _Parsed(BackupSummary(
      exportedAt: root['exported_at'] is String ? root['exported_at'] as String : '',
      categories: catRows.length,
      expenses: expRows.length,
      budgets: budRows.length,
      people: peopleRows.length,
      loans: loanRows.length,
      repayments: repRows.length,
    ));

    final catIds = <int>{};
    final catNames = <String>{};
    for (final r in catRows) {
      final id = _id(r, 'categories', catIds);
      final name = _text(r, 'name', 'categories', max: 60);
      if (!catNames.add(name.toLowerCase())) {
        throw BackupException('That backup file is damaged (duplicate category "$name").');
      }
      p.categories.add(CategoriesCompanion(
        id: Value(id),
        name: Value(name),
        colorLight: Value(_int(r, 'colorLight', 'categories')),
        colorDark: Value(_int(r, 'colorDark', 'categories')),
        icon: Value(_text(r, 'icon', 'categories', max: 40)),
        isDefault: Value(_bool(r, 'isDefault', 'categories')),
        isArchived: Value(_bool(r, 'isArchived', 'categories')),
        createdAt: Value(_date(r, 'createdAt', 'categories')),
      ));
    }

    final personIds = <int>{};
    final personKeys = <String>{};
    for (final r in peopleRows) {
      final id = _id(r, 'people', personIds);
      final key = _text(r, 'nameKey', 'people', max: 60);
      if (!personKeys.add(key)) {
        throw BackupException('That backup file is damaged (duplicate person "$key").');
      }
      p.people.add(PeopleCompanion(
        id: Value(id),
        name: Value(_text(r, 'name', 'people', max: 60)),
        nameKey: Value(key),
        createdAt: Value(_date(r, 'createdAt', 'people')),
      ));
    }

    final expenseIds = <int>{};
    for (final r in expRows) {
      final id = _id(r, 'expenses', expenseIds);
      final cat = _int(r, 'categoryId', 'expenses');
      if (!catIds.contains(cat)) {
        throw BackupException('That backup file is damaged (an expense points to a missing category).');
      }
      p.expenses.add(ExpensesCompanion(
        id: Value(id),
        amountPaise: Value(_positive(r, 'amountPaise', 'expenses')),
        categoryId: Value(cat),
        item: Value(_text(r, 'item', 'expenses', max: 200)),
        location: Value(_optText(r, 'location', 'expenses')),
        paymentMethod: Value(_optText(r, 'paymentMethod', 'expenses')),
        spentOn: Value(_isoDay(r, 'spentOn', 'expenses')),
        rawText: Value(_optText(r, 'rawText', 'expenses')),
        source: Value(_text(r, 'source', 'expenses', max: 20)),
        createdAt: Value(_date(r, 'createdAt', 'expenses')),
        updatedAt: Value(_date(r, 'updatedAt', 'expenses')),
      ));
    }

    final budgetIds = <int>{};
    final budgetCats = <int?>{};
    for (final r in budRows) {
      final id = _id(r, 'budgets', budgetIds);
      final cat = r['categoryId'];
      if (cat != null && (cat is! int || !catIds.contains(cat))) {
        throw BackupException('That backup file is damaged (a budget points to a missing category).');
      }
      if (cat != null && !budgetCats.add(cat as int)) {
        throw BackupException('That backup file is damaged (two budgets for one category).');
      }
      if (cat == null && !budgetCats.add(null)) {
        throw BackupException('That backup file is damaged (two overall budgets).');
      }
      p.budgets.add(BudgetsCompanion(
        id: Value(id),
        categoryId: Value(cat as int?),
        monthlyLimitPaise: Value(_positive(r, 'monthlyLimitPaise', 'budgets')),
        updatedAt: Value(_date(r, 'updatedAt', 'budgets')),
      ));
    }

    final loanIds = <int>{};
    final principal = <int, int>{};
    for (final r in loanRows) {
      final id = _id(r, 'loans', loanIds);
      final person = _int(r, 'personId', 'loans');
      if (!personIds.contains(person)) {
        throw BackupException('That backup file is damaged (a loan points to a missing person).');
      }
      final dir = _text(r, 'direction', 'loans', max: 10);
      if (dir != 'lent' && dir != 'borrowed') {
        throw BackupException('That backup file is damaged (a loan has an unknown direction).');
      }
      final amount = _positive(r, 'principalPaise', 'loans');
      principal[id] = amount;
      p.loans.add(LoansCompanion(
        id: Value(id),
        personId: Value(person),
        direction: Value(dir),
        principalPaise: Value(amount),
        note: Value(_optText(r, 'note', 'loans')),
        paymentMethod: Value(_optText(r, 'paymentMethod', 'loans')),
        happenedOn: Value(_isoDay(r, 'happenedOn', 'loans')),
        rawText: Value(_optText(r, 'rawText', 'loans')),
        createdAt: Value(_date(r, 'createdAt', 'loans')),
      ));
    }

    final repIds = <int>{};
    final repaid = <int, int>{};
    for (final r in repRows) {
      final id = _id(r, 'repayments', repIds);
      final loan = _int(r, 'loanId', 'repayments');
      if (!loanIds.contains(loan)) {
        throw BackupException('That backup file is damaged (a repayment points to a missing loan).');
      }
      final amount = _positive(r, 'amountPaise', 'repayments');
      repaid[loan] = (repaid[loan] ?? 0) + amount;
      if (repaid[loan]! > principal[loan]!) {
        throw BackupException('That backup file is damaged (a loan is repaid more than it was lent).');
      }
      p.repayments.add(LoanRepaymentsCompanion(
        id: Value(id),
        loanId: Value(loan),
        amountPaise: Value(amount),
        paidOn: Value(_isoDay(r, 'paidOn', 'repayments')),
        rawText: Value(_optText(r, 'rawText', 'repayments')),
        createdAt: Value(_date(r, 'createdAt', 'repayments')),
      ));
    }
    return p;
  }

  // ---- field readers: strict, with errors a person can act on --------------

  static BackupException _bad(String table, String field) =>
      BackupException('That backup file is damaged ($table: $field).');

  int _int(Map<String, dynamic> r, String f, String t) {
    final v = r[f];
    if (v is! int) throw _bad(t, f);
    return v;
  }

  int _positive(Map<String, dynamic> r, String f, String t) {
    final v = _int(r, f, t);
    if (v <= 0) throw _bad(t, f);
    return v;
  }

  int _id(Map<String, dynamic> r, String t, Set<int> seen) {
    final v = _int(r, 'id', t);
    if (v <= 0 || !seen.add(v)) throw _bad(t, 'id');
    return v;
  }

  bool _bool(Map<String, dynamic> r, String f, String t) {
    final v = r[f];
    if (v is! bool) throw _bad(t, f);
    return v;
  }

  String _text(Map<String, dynamic> r, String f, String t, {required int max}) {
    final v = r[f];
    if (v is! String || v.trim().isEmpty || v.length > max) throw _bad(t, f);
    return v;
  }

  String? _optText(Map<String, dynamic> r, String f, String t) {
    final v = r[f];
    if (v == null) return null;
    if (v is! String || v.length > 2000) throw _bad(t, f);
    return v;
  }

  DateTime _date(Map<String, dynamic> r, String f, String t) {
    final v = r[f];
    final d = v is String ? DateTime.tryParse(v) : null;
    if (d == null) throw _bad(t, f);
    return d;
  }

  String _isoDay(Map<String, dynamic> r, String f, String t) {
    final v = r[f];
    if (v is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) throw _bad(t, f);
    final d = DateTime.tryParse(v);
    if (d == null || d.month != int.parse(v.substring(5, 7)) || d.day != int.parse(v.substring(8))) {
      throw _bad(t, f);
    }
    return v;
  }
}
