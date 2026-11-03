import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

class SeedCategory {
  const SeedCategory(this.name, this.icon, this.light, this.dark);
  final String name;
  final String icon;
  final int light;
  final int dark;
}

const seedCategories = <SeedCategory>[
  SeedCategory('Food & Dining', 'restaurant', 0xFF0F6B5C, 0xFF3FAE95),
  SeedCategory('Groceries', 'shopping_basket', 0xFF7FB8A6, 0xFF8CC9B6),
  SeedCategory('Transport', 'directions_car', 0xFF8A5BB0, 0xFFA983CC),
  SeedCategory('Shopping', 'shopping_bag', 0xFFD9822B, 0xFFE08A3C),
  SeedCategory('Bills & Utilities', 'receipt_long', 0xFF3A66C4, 0xFF6E95E6),
  SeedCategory('Rent & Housing', 'home', 0xFF6B7F3A, 0xFFA5BD65),
  SeedCategory('Health', 'favorite', 0xFFB5483C, 0xFFE5604F),
  SeedCategory('Entertainment', 'movie', 0xFF2C7FA3, 0xFF6FBBDD),
  SeedCategory('Travel', 'flight', 0xFF9A6B1F, 0xFFD4A24C),
  SeedCategory('Other', 'category', 0xFFA9B3AE, 0xFF5F6E68),
];

@DriftDatabase(
  tables: [
    Categories,
    Expenses,
    Budgets,
    People,
    Loans,
    LoanRepayments,
    ChatMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-device database.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'kharchu'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX idx_expenses_spent_on ON expenses(spent_on)');
          await customStatement(
              'CREATE INDEX idx_expenses_cat_date ON expenses(category_id, spent_on)');
          await customStatement(
              'CREATE INDEX idx_chat_day ON chat_messages(day)');
          await customStatement(
              'CREATE INDEX idx_loans_person ON loans(person_id)');
          await seedDefaults();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> seedDefaults() async {
    for (final c in seedCategories) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: c.name,
          colorLight: c.light,
          colorDark: c.dark,
          icon: c.icon,
          isDefault: const Value(true),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }
}
