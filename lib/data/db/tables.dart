// Drift's documented pattern for column checks refers to the column's own
// getter, which the recursive_getters lint flags.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

/// Money columns are integer paise. Date columns are 'YYYY-MM-DD' text (IST).

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  IntColumn get colorLight => integer()();
  IntColumn get colorDark => integer()();
  TextColumn get icon => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Expense')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountPaise =>
      integer().check(amountPaise.isBiggerThanValue(0))();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get item => text()();
  TextColumn get location => text().nullable()();

  /// cash | upi | card | netbanking | other
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get spentOn => text()();
  TextColumn get rawText => text().nullable()();

  /// chat | voice | manual
  TextColumn get source => text().withDefault(const Constant('chat'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft delete, so Undo is possible.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DataClassName('Budget')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// NULL means the overall monthly budget. SQLite allows several NULLs in a
  /// UNIQUE column, so the "one overall budget" rule is enforced in the
  /// repository (upsert), not here.
  IntColumn get categoryId =>
      integer().nullable().unique().references(Categories, #id)();
  IntColumn get monthlyLimitPaise =>
      integer().check(monthlyLimitPaise.isBiggerThanValue(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Person')
class People extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Lower-cased, trimmed name used to match "rahul" with "Rahul".
  TextColumn get nameKey => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Loan')
class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId => integer().references(People, #id)();

  /// lent = they owe you, borrowed = you owe them.
  TextColumn get direction =>
      text().check(direction.isIn(const ['lent', 'borrowed']))();
  IntColumn get principalPaise =>
      integer().check(principalPaise.isBiggerThanValue(0))();
  TextColumn get note => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get happenedOn => text()();
  TextColumn get rawText => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DataClassName('LoanRepayment')
class LoanRepayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get loanId => integer().references(Loans, #id)();
  IntColumn get amountPaise =>
      integer().check(amountPaise.isBiggerThanValue(0))();
  TextColumn get paidOn => text()();
  TextColumn get rawText => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ChatMessage')
class ChatMessages extends Table {
  TextColumn get id => text()();

  /// 'YYYY-MM-DD' (IST). The Chat tab shows only today's day.
  TextColumn get day => text()();

  /// user | assistant | card | notice
  TextColumn get role => text()();
  TextColumn get body => text().named('text').nullable()();
  TextColumn get cardType => text().nullable()();
  TextColumn get cardPayload => text().nullable()();

  /// pending | confirmed | cancelled | expired
  TextColumn get cardStatus => text().nullable()();

  /// e.g. 'expense:42', 'loan:7'
  TextColumn get entityRef => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
