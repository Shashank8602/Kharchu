import 'package:drift/drift.dart';

import '../db/app_database.dart';

class BudgetRepository {
  BudgetRepository(this.db);
  final AppDatabase db;

  Stream<List<Budget>> watchAll() => db.select(db.budgets).watch();

  Future<List<Budget>> all() => db.select(db.budgets).get();

  /// The budget for [categoryId], or the overall budget when null.
  Future<Budget?> forCategory(int? categoryId) {
    final q = db.select(db.budgets);
    q.where((b) =>
        categoryId == null ? b.categoryId.isNull() : b.categoryId.equals(categoryId));
    return q.getSingleOrNull();
  }

  /// Creates or replaces the budget. [categoryId] null = overall.
  /// Returns false if [limitPaise] is not positive.
  Future<bool> upsert(int? categoryId, int limitPaise) async {
    if (limitPaise <= 0) return false;
    await db.transaction(() async {
      final existing = await forCategory(categoryId);
      if (existing == null) {
        await db.into(db.budgets).insert(BudgetsCompanion.insert(
              categoryId: Value(categoryId),
              monthlyLimitPaise: limitPaise,
            ));
      } else {
        await (db.update(db.budgets)..where((b) => b.id.equals(existing.id)))
            .write(BudgetsCompanion(
          monthlyLimitPaise: Value(limitPaise),
          updatedAt: Value(DateTime.now()),
        ));
      }
    });
    return true;
  }

  Future<void> delete(int id) =>
      (db.delete(db.budgets)..where((b) => b.id.equals(id))).go();
}
