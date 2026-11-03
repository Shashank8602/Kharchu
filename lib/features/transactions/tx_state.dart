import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/expense_repository.dart';

/// Which tab of Transactions is showing: 0 Expenses, 1 Lending. The Dashboard's
/// lending tiles set this to 1 before going there.
class TxTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void show(int tab) => state = tab;
}

final txTabProvider = NotifierProvider<TxTabNotifier, int>(TxTabNotifier.new);

/// The search box and filters on the Expenses tab.
class TxFilterState {
  const TxFilterState({
    this.text = '',
    this.categoryIds = const [],
    this.paymentMethods = const [],
    this.dateFrom,
    this.dateTo,
  });

  final String text;
  final List<int> categoryIds;
  final List<String> paymentMethods;
  final String? dateFrom;
  final String? dateTo;

  bool get hasFilters =>
      categoryIds.isNotEmpty ||
      paymentMethods.isNotEmpty ||
      dateFrom != null ||
      dateTo != null;

  bool get isEmpty => text.trim().isEmpty && !hasFilters;

  TxFilterState copyWith({
    String? text,
    List<int>? categoryIds,
    List<String>? paymentMethods,
    String? dateFrom,
    String? dateTo,
    bool clearDates = false,
  }) =>
      TxFilterState(
        text: text ?? this.text,
        categoryIds: categoryIds ?? this.categoryIds,
        paymentMethods: paymentMethods ?? this.paymentMethods,
        dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
        dateTo: clearDates ? null : (dateTo ?? this.dateTo),
      );

  ExpenseFilter toFilter() => ExpenseFilter(
        text: text,
        categoryIds: categoryIds,
        paymentMethods: paymentMethods,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
}

class TxFilterNotifier extends Notifier<TxFilterState> {
  @override
  TxFilterState build() => const TxFilterState();

  void setText(String t) => state = state.copyWith(text: t);
  void setFilters({
    required List<int> categoryIds,
    required List<String> paymentMethods,
    String? dateFrom,
    String? dateTo,
  }) =>
      state = TxFilterState(
        text: state.text,
        categoryIds: categoryIds,
        paymentMethods: paymentMethods,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
  void clearFilters() => state = TxFilterState(text: state.text);
}

final txFilterProvider =
    NotifierProvider<TxFilterNotifier, TxFilterState>(TxFilterNotifier.new);
