import 'package:drift/drift.dart';

import '../../core/dates.dart';
import '../db/app_database.dart';
import '../db/tables.dart';

/// An expense joined with its category.
class ExpenseRow {
  const ExpenseRow(this.expense, this.category);
  final Expense expense;
  final Category category;
}

/// Filters shared by the Transactions screen and the agent's find_expenses.
class ExpenseFilter {
  const ExpenseFilter({
    this.text,
    this.categoryIds = const [],
    this.paymentMethods = const [],
    this.dateFrom,
    this.dateTo,
    this.amountPaise,
    this.latestOnly = false,
    this.nearDate,
    this.limit,
  });

  /// Every whitespace-separated word must appear in item, location or the
  /// original message (partial words and any word order match).
  final String? text;
  final List<int> categoryIds;
  final List<String> paymentMethods;
  final String? dateFrom;
  final String? dateTo;
  final int? amountPaise;

  /// Newest first (for "the last expense").
  final bool latestOnly;

  /// Rank by closeness to this date (for "last Sunday's dinner").
  final String? nearDate;
  final int? limit;
}

class ExpenseRepository {
  ExpenseRepository(this.db);
  final AppDatabase db;

  Future<int> add({
    required int amountPaise,
    required int categoryId,
    required String item,
    String? location,
    String? paymentMethod,
    required String spentOn,
    String? rawText,
    String source = 'chat',
  }) {
    return db.into(db.expenses).insert(
          ExpensesCompanion.insert(
            amountPaise: amountPaise,
            categoryId: categoryId,
            item: item.trim(),
            location: Value(_clean(location)),
            paymentMethod: Value(paymentMethod),
            spentOn: spentOn,
            rawText: Value(rawText),
            source: Value(source),
          ),
        );
  }

  /// Updates only the fields present in [changes]; always bumps updatedAt.
  Future<bool> update(int id, ExpensesCompanion changes) async {
    final n = await (db.update(db.expenses)
          ..where((e) => e.id.equals(id) & e.deletedAt.isNull()))
        .write(changes.copyWith(updatedAt: Value(DateTime.now())));
    return n > 0;
  }

  Future<void> softDelete(int id) async {
    await (db.update(db.expenses)..where((e) => e.id.equals(id))).write(
      ExpensesCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  Future<void> restore(int id) async {
    await (db.update(db.expenses)..where((e) => e.id.equals(id)))
        .write(const ExpensesCompanion(deletedAt: Value(null)));
  }

  Future<ExpenseRow?> getById(int id) async {
    final rows = await _query(const ExpenseFilter(), extra: (e, c) =>
        e.id.equals(id)).get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<ExpenseRow>> find(ExpenseFilter f) => _query(f).get();

  Stream<List<ExpenseRow>> watch(ExpenseFilter f) => _query(f).watch();

  /// The newest [n] expenses, for the agent's context.
  Future<List<ExpenseRow>> recent(int n) =>
      find(ExpenseFilter(latestOnly: true, limit: n));

  Selectable<ExpenseRow> _query(
    ExpenseFilter f, {
    Expression<bool> Function(Expenses e, Categories c)? extra,
  }) {
    final e = db.expenses;
    final c = db.categories;
    final q = db.select(e).join([
      innerJoin(c, c.id.equalsExp(e.categoryId)),
    ]);

    Expression<bool> where = e.deletedAt.isNull();
    if (extra != null) where = where & extra(e, c);
    if (f.categoryIds.isNotEmpty) where = where & e.categoryId.isIn(f.categoryIds);
    if (f.paymentMethods.isNotEmpty) {
      where = where & e.paymentMethod.isIn(f.paymentMethods);
    }
    if (f.dateFrom != null) where = where & e.spentOn.isBiggerOrEqualValue(f.dateFrom!);
    if (f.dateTo != null) where = where & e.spentOn.isSmallerOrEqualValue(f.dateTo!);
    if (f.amountPaise != null) where = where & e.amountPaise.equals(f.amountPaise!);
    for (final token in _tokens(f.text)) {
      final pattern = '%${_escapeLike(token)}%';
      where = where &
          (e.item.like(pattern, escapeChar: r'\') |
              e.location.like(pattern, escapeChar: r'\') |
              e.rawText.like(pattern, escapeChar: r'\'));
    }
    q.where(where);

    final near = f.nearDate != null && tryParseIso(f.nearDate!) != null
        ? f.nearDate
        : null;
    q.orderBy([
      if (near != null)
        OrderingTerm.asc(CustomExpression<double>(
            "ABS(julianday(expenses.spent_on) - julianday('$near'))")),
      OrderingTerm.desc(e.spentOn),
      OrderingTerm.desc(e.id),
    ]);
    if (f.limit != null) q.limit(f.limit!);

    return q.map((row) => ExpenseRow(row.readTable(e), row.readTable(c)));
  }

  // ---- aggregates (all exclude soft-deleted rows) -------------------------

  Selectable<QueryRow> _agg(String select, String groupBy, String from,
      String to, {int? categoryId}) {
    return db.customSelect(
      'SELECT $select AS k, SUM(amount_paise) AS total, COUNT(*) AS n '
      'FROM expenses WHERE deleted_at IS NULL AND spent_on >= ? AND spent_on <= ? '
      '${categoryId != null ? 'AND category_id = ? ' : ''}'
      'GROUP BY $groupBy',
      variables: [
        Variable.withString(from),
        Variable.withString(to),
        if (categoryId != null) Variable.withInt(categoryId),
      ],
      readsFrom: {db.expenses},
    );
  }

  Future<int> total(String from, String to, {int? categoryId}) =>
      watchTotal(from, to, categoryId: categoryId).first;

  Stream<int> watchTotal(String from, String to, {int? categoryId}) {
    return db
        .customSelect(
          'SELECT COALESCE(SUM(amount_paise), 0) AS t FROM expenses '
          'WHERE deleted_at IS NULL AND spent_on >= ? AND spent_on <= ? '
          '${categoryId != null ? 'AND category_id = ?' : ''}',
          variables: [
            Variable.withString(from),
            Variable.withString(to),
            if (categoryId != null) Variable.withInt(categoryId),
          ],
          readsFrom: {db.expenses},
        )
        .watchSingle()
        .map((r) => r.read<int>('t'));
  }

  Future<int> count(String from, String to) async {
    final r = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM expenses '
          'WHERE deleted_at IS NULL AND spent_on >= ? AND spent_on <= ?',
          variables: [Variable.withString(from), Variable.withString(to)],
          readsFrom: {db.expenses},
        )
        .getSingle();
    return r.read<int>('n');
  }

  Stream<Map<int, int>> watchSumByCategory(String from, String to) =>
      _agg('category_id', 'category_id', from, to).watch().map(
          (rows) => {for (final r in rows) r.read<int>('k'): r.read<int>('total')});

  Future<Map<int, int>> sumByCategory(String from, String to) =>
      watchSumByCategory(from, to).first;

  Stream<Map<String, int>> watchSumByDay(String from, String to) =>
      _agg('spent_on', 'spent_on', from, to).watch().map((rows) =>
          {for (final r in rows) r.read<String>('k'): r.read<int>('total')});

  Future<Map<String, int>> sumByDay(String from, String to) =>
      watchSumByDay(from, to).first;

  Future<Map<String, int>> sumByPayment(String from, String to) async {
    final rows = await _agg("COALESCE(payment_method, 'unspecified')",
            "COALESCE(payment_method, 'unspecified')", from, to)
        .get();
    return {for (final r in rows) r.read<String>('k'): r.read<int>('total')};
  }

  Future<Map<String, int>> sumByLocation(String from, String to) async {
    final rows = await _agg("COALESCE(location, 'unspecified')",
            "COALESCE(location, 'unspecified')", from, to)
        .get();
    return {for (final r in rows) r.read<String>('k'): r.read<int>('total')};
  }

  // ---- helpers -------------------------------------------------------------

  static String? _clean(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static List<String> _tokens(String? text) => (text ?? '')
      .split(RegExp(r'\s+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  /// Escapes %, _ and \ so user text can't act as a LIKE wildcard.
  static String _escapeLike(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
