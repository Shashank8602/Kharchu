import 'package:drift/native.dart';
import 'package:kharchu/data/db/app_database.dart';
import 'package:kharchu/data/repositories/budget_repository.dart';
import 'package:kharchu/data/repositories/category_repository.dart';
import 'package:kharchu/data/repositories/chat_repository.dart';
import 'package:kharchu/data/repositories/expense_repository.dart';
import 'package:kharchu/data/repositories/lending_repository.dart';

/// A fresh in-memory database with the seeded categories, plus repositories.
class TestEnv {
  TestEnv() : db = AppDatabase(NativeDatabase.memory()) {
    expenses = ExpenseRepository(db);
    categories = CategoryRepository(db);
    budgets = BudgetRepository(db);
    lending = LendingRepository(db);
    chat = ChatRepository(db);
  }

  final AppDatabase db;
  late final ExpenseRepository expenses;
  late final CategoryRepository categories;
  late final BudgetRepository budgets;
  late final LendingRepository lending;
  late final ChatRepository chat;

  Future<void> close() => db.close();

  /// Category id by name (seeded presets).
  Future<int> cat(String name) async => (await categories.exact(name))!.id;

  Future<int> addExpense({
    required int paise,
    String category = 'Food & Dining',
    String item = 'Chats',
    String? location,
    String? payment,
    String date = '2026-10-24',
    String? raw,
  }) async =>
      expenses.add(
        amountPaise: paise,
        categoryId: await cat(category),
        item: item,
        location: location,
        paymentMethod: payment,
        spentOn: date,
        rawText: raw,
      );
}
