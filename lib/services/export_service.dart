import 'package:csv/csv.dart';

import '../data/repositories/expense_repository.dart';

/// CSV of expenses for a date range, for opening in Excel or Sheets.
class ExportService {
  ExportService(this.expenses);
  final ExpenseRepository expenses;

  static const header = [
    'Date',
    'Item',
    'Category',
    'Amount (INR)',
    'Payment Method',
    'Location',
    'Original Text',
    'Created At',
  ];

  /// A spreadsheet runs a cell that starts with = + - @ as a formula. Text
  /// typed into a chat ("=HYPERLINK(...)") must never become one, so such
  /// cells are prefixed with an apostrophe.
  static dynamic _safe(dynamic field, int index, String? header) {
    if (field is String && RegExp(r'^[=+\-@\t\r]').hasMatch(field)) return "'$field";
    return field;
  }

  /// UTF-8 with a BOM so Excel shows Kannada correctly.
  Future<String> buildCsv({required String from, required String to}) async {
    final rows = await expenses.find(ExpenseFilter(dateFrom: from, dateTo: to));
    // oldest first reads naturally in a spreadsheet
    final ordered = rows.reversed.toList();
    final data = <List<dynamic>>[
      header,
      for (final r in ordered)
        [
          r.expense.spentOn,
          r.expense.item,
          r.category.name,
          _amount(r.expense.amountPaise),
          r.expense.paymentMethod ?? '',
          r.expense.location ?? '',
          r.expense.rawText ?? '',
          r.expense.createdAt.toIso8601String(),
        ],
    ];
    return Csv(addBom: true, encoderTransform: _safe).encode(data);
  }

  /// 1000 -> "1000", 1050 paise -> "10.50" (no thousands separators, so the
  /// cell stays a number).
  static String _amount(int paise) =>
      paise % 100 == 0 ? '${paise ~/ 100}' : (paise / 100).toStringAsFixed(2);

  /// File name like expenses_2026-10-01_to_2026-10-31.csv.
  static String fileName(String from, String to) => 'expenses_${from}_to_$to.csv';
}
