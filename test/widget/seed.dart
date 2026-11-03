import 'package:drift/drift.dart' show Value;
import 'package:kharchu/data/db/app_database.dart';

/// Test data written straight to the database before the app starts. Doing it
/// before `pumpWidget` keeps it clear of the live queries (see harnessTest).
class Seed {
  Seed(this.db);
  final AppDatabase db;

  /// "Today" in the harness.
  static const day = '2026-10-24';

  Future<int> category(String name) async =>
      (await db.select(db.categories).get()).firstWhere((c) => c.name == name).id;

  Future<int> expense(
    int rupees,
    String item, {
    String category = 'Food & Dining',
    String date = day,
    String? location,
    String? payment,
  }) async {
    final id = await this.category(category);
    return db.into(db.expenses).insert(ExpensesCompanion.insert(
          amountPaise: rupees * 100,
          categoryId: id,
          item: item,
          spentOn: date,
          location: Value(location),
          paymentMethod: Value(payment),
        ));
  }

  Future<void> deleteExpense(int id) =>
      (db.update(db.expenses)..where((e) => e.id.equals(id)))
          .write(ExpensesCompanion(deletedAt: Value(DateTime.now())));

  Future<void> budget(int rupees, {String? category}) async {
    await db.into(db.budgets).insert(BudgetsCompanion.insert(
          categoryId: Value(category == null ? null : await this.category(category)),
          monthlyLimitPaise: rupees * 100,
        ));
  }

  /// Returns the loan id.
  Future<int> loan(
    String who,
    int rupees, {
    String dir = 'lent',
    String date = '2026-10-10',
    String? note,
  }) async {
    final key = who.toLowerCase();
    final existing = await (db.select(db.people)..where((p) => p.nameKey.equals(key)))
        .getSingleOrNull();
    final pid = existing?.id ??
        await db.into(db.people).insert(PeopleCompanion.insert(name: who, nameKey: key));
    return db.into(db.loans).insert(LoansCompanion.insert(
          personId: pid,
          direction: dir,
          principalPaise: rupees * 100,
          happenedOn: date,
          note: Value(note),
        ));
  }

  Future<void> repay(int loanId, int rupees, {String date = '2026-10-12'}) =>
      db.into(db.loanRepayments).insert(LoanRepaymentsCompanion.insert(
          loanId: loanId, amountPaise: rupees * 100, paidOn: date));
}
