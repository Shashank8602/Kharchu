import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Common words people use, mapped to the preset category they mean.
const _aliases = <String, String>{
  'food': 'Food & Dining',
  'dining': 'Food & Dining',
  'restaurant': 'Food & Dining',
  'eating': 'Food & Dining',
  'eat': 'Food & Dining',
  'lunch': 'Food & Dining',
  'dinner': 'Food & Dining',
  'breakfast': 'Food & Dining',
  'snacks': 'Food & Dining',
  'snack': 'Food & Dining',
  'groceries': 'Groceries',
  'grocery': 'Groceries',
  'vegetables': 'Groceries',
  'transport': 'Transport',
  'transportation': 'Transport',
  'auto': 'Transport',
  'cab': 'Transport',
  'taxi': 'Transport',
  'fuel': 'Transport',
  'petrol': 'Transport',
  'diesel': 'Transport',
  'bus': 'Transport',
  'metro': 'Transport',
  'shopping': 'Shopping',
  'clothes': 'Shopping',
  'bills': 'Bills & Utilities',
  'bill': 'Bills & Utilities',
  'utilities': 'Bills & Utilities',
  'electricity': 'Bills & Utilities',
  'internet': 'Bills & Utilities',
  'recharge': 'Bills & Utilities',
  'rent': 'Rent & Housing',
  'housing': 'Rent & Housing',
  'health': 'Health',
  'medical': 'Health',
  'medicine': 'Health',
  'pharmacy': 'Health',
  'doctor': 'Health',
  'entertainment': 'Entertainment',
  'movie': 'Entertainment',
  'movies': 'Entertainment',
  'travel': 'Travel',
  'trip': 'Travel',
  'vacation': 'Travel',
  'flight': 'Travel',
  'hotel': 'Travel',
  'misc': 'Other',
  'miscellaneous': 'Other',
  'others': 'Other',
  'other': 'Other',
};

/// Colors handed to categories the user (or the AI) creates.
const _extraPalette = <(int, int)>[
  (0xFF5B6B8C, 0xFF9AAAD0),
  (0xFF9C4E7A, 0xFFD58BB4),
  (0xFF3E8A4F, 0xFF7CCB8E),
  (0xFFB0702E, 0xFFE8A867),
  (0xFF4B7BA6, 0xFF8FB9E0),
];

class CategoryRepository {
  CategoryRepository(this.db);
  final AppDatabase db;

  Future<List<Category>> active() => (db.select(db.categories)
        ..where((c) => c.isArchived.equals(false))
        ..orderBy([(c) => OrderingTerm.asc(c.id)]))
      .get();

  Stream<List<Category>> watchAll() => (db.select(db.categories)
        ..orderBy([
          (c) => OrderingTerm.asc(c.isArchived),
          (c) => OrderingTerm.asc(c.id),
        ]))
      .watch();

  Future<Category?> byId(int id) => (db.select(db.categories)
        ..where((c) => c.id.equals(id)))
      .getSingleOrNull();

  Future<Category?> exact(String name) async {
    final n = normalize(name);
    if (n.isEmpty) return null;
    return (db.select(db.categories)..where((c) => c.name.equals(n)))
        .getSingleOrNull(); // column is COLLATE NOCASE
  }

  /// Maps what the AI or user wrote to an active category, or null.
  /// Order: exact (case-insensitive) → alias → single substring match.
  Future<Category?> resolve(String name) async {
    final n = normalize(name);
    if (n.isEmpty) return null;
    final list = await active();

    for (final c in list) {
      if (c.name.toLowerCase() == n.toLowerCase()) return c;
    }
    final alias = _aliases[n.toLowerCase()];
    if (alias != null) {
      for (final c in list) {
        if (c.name == alias) return c;
      }
    }
    final lower = n.toLowerCase();
    final partial = list.where((c) {
      final cl = c.name.toLowerCase();
      return cl.contains(lower) || lower.contains(cl);
    }).toList();
    return partial.length == 1 ? partial.first : null;
  }

  /// Creates a category, or returns the existing one with that name
  /// (un-archiving it). Throws [ArgumentError] for an empty or huge name.
  Future<Category> create(String name) async {
    final n = normalize(name);
    if (n.isEmpty) throw ArgumentError('Category name is empty');
    if (n.length > 40) throw ArgumentError('Category name is too long');

    final existing = await exact(n);
    if (existing != null) {
      if (existing.isArchived) {
        await setArchived(existing.id, false);
      }
      return (await byId(existing.id))!;
    }
    final count = await db.categories.count().getSingle();
    final colors = _extraPalette[count % _extraPalette.length];
    final id = await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            name: n,
            colorLight: colors.$1,
            colorDark: colors.$2,
            icon: 'category',
          ),
        );
    return (await byId(id))!;
  }

  /// Renames; returns false if another category already has that name.
  Future<bool> rename(int id, String newName) async {
    final n = normalize(newName);
    if (n.isEmpty || n.length > 40) return false;
    final clash = await exact(n);
    if (clash != null && clash.id != id) return false;
    await (db.update(db.categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(name: Value(n)));
    return true;
  }

  Future<void> setColor(int id, int light, int dark) =>
      (db.update(db.categories)..where((c) => c.id.equals(id))).write(
          CategoriesCompanion(colorLight: Value(light), colorDark: Value(dark)));

  /// Archived categories are hidden from pickers and the AI but kept so old
  /// expenses still show their category. Default categories can be archived,
  /// never deleted. The last active category cannot be archived.
  Future<bool> setArchived(int id, bool archived) async {
    if (archived) {
      final list = await active();
      if (list.length <= 1 && list.any((c) => c.id == id)) return false;
    }
    await (db.update(db.categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(isArchived: Value(archived)));
    return true;
  }

  /// The "Other" category, used when the user declines a suggested new one.
  Future<Category?> fallbackOther() async {
    final c = await exact('Other');
    if (c != null && !c.isArchived) return c;
    final list = await active();
    return list.isEmpty ? null : list.last;
  }

  static String normalize(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');
}
