import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../core/money.dart';
import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../services/agent/parsing.dart';
import '../services/agent/tool_executor.dart' show kMaxRupees;

/// What the Edit sheet returns.
class ExpenseFormResult {
  const ExpenseFormResult({
    required this.amountPaise,
    required this.item,
    required this.categoryId,
    required this.categoryName,
    required this.location,
    required this.paymentMethod,
    required this.spentOn,
  });
  final int amountPaise;
  final String item;

  /// -1 means "the new category named [categoryName]".
  final int categoryId;
  final String categoryName;
  final String? location;
  final String? paymentMethod;
  final String spentOn;
}

const kNewCategoryId = -1;

/// Opens the Edit sheet. [newCategoryName] adds a "(new)" choice for a
/// category the AI suggested that does not exist yet.
Future<ExpenseFormResult?> showExpenseSheet(
  BuildContext context, {
  required List<Category> categories,
  required String todayIso,
  required String title,
  required String actionLabel,
  int? amountPaise,
  String item = '',
  int? categoryId,
  String? newCategoryName,
  String? location,
  String? paymentMethod,
  String? spentOn,
}) {
  return showModalBottomSheet<ExpenseFormResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.kc.surface,
    builder: (_) => _ExpenseSheet(
      categories: categories,
      todayIso: todayIso,
      title: title,
      actionLabel: actionLabel,
      amountPaise: amountPaise,
      item: item,
      categoryId: categoryId,
      newCategoryName: newCategoryName,
      location: location,
      paymentMethod: paymentMethod,
      spentOn: spentOn ?? todayIso,
    ),
  );
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({
    required this.categories,
    required this.todayIso,
    required this.title,
    required this.actionLabel,
    required this.amountPaise,
    required this.item,
    required this.categoryId,
    required this.newCategoryName,
    required this.location,
    required this.paymentMethod,
    required this.spentOn,
  });

  final List<Category> categories;
  final String todayIso;
  final String title;
  final String actionLabel;
  final int? amountPaise;
  final String item;
  final int? categoryId;
  final String? newCategoryName;
  final String? location;
  final String? paymentMethod;
  final String spentOn;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.amountPaise == null
        ? ''
        : (widget.amountPaise! % 100 == 0
              ? '${widget.amountPaise! ~/ 100}'
              : (widget.amountPaise! / 100).toStringAsFixed(2)),
  );
  late final TextEditingController _item = TextEditingController(
    text: widget.item,
  );
  late final TextEditingController _location = TextEditingController(
    text: widget.location ?? '',
  );
  late int? _category = widget.newCategoryName != null
      ? kNewCategoryId
      : widget.categoryId;
  late String? _payment = widget.paymentMethod;
  late String _date = widget.spentOn;
  String? _amountError;
  String? _itemError;
  String? _categoryError;

  static const _methods = [
    ('cash', 'Cash'),
    ('upi', 'UPI'),
    ('card', 'Card'),
    ('netbanking', 'Net banking'),
  ];

  @override
  void dispose() {
    _amount.dispose();
    _item.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = tryParseIso(_date) ?? tryParseIso(widget.todayIso)!;
    final last = tryParseIso(widget.todayIso)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(last) ? last : current,
      firstDate: DateTime.utc(2000),
      lastDate: last,
    );
    if (picked != null) setState(() => _date = isoDate(picked));
  }

  void _save() {
    final rupees = parseRupees(_amount.text);
    final item = cleanText(_item.text, maxLength: 60);
    String? amountError;
    if (rupees == null || rupees <= 0) {
      amountError = 'Enter an amount';
    } else if (rupees > kMaxRupees) {
      amountError = 'That is above ₹10,00,000';
    } else if (rupeesToPaise(rupees) <= 0) {
      amountError = 'Enter an amount';
    }
    final itemError = item == null ? 'Enter what it was for' : null;
    final categoryError = _category == null ? 'Pick a category' : null;
    if (amountError != null || itemError != null || categoryError != null) {
      setState(() {
        _amountError = amountError;
        _itemError = itemError;
        _categoryError = categoryError;
      });
      return;
    }
    final name = _category == kNewCategoryId
        ? widget.newCategoryName!
        : widget.categories.firstWhere((c) => c.id == _category).name;
    Navigator.pop(
      context,
      ExpenseFormResult(
        amountPaise: rupeesToPaise(rupees!),
        item: tidyItem(item!),
        categoryId: _category!,
        categoryName: name,
        location: cleanText(_location.text, maxLength: 60),
        paymentMethod: _payment,
        spentOn: _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: headingStyle(size: 19, color: kc.ink),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amount,
                      autofocus: widget.amountPaise == null,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        errorText: _amountError,
                      ),
                      onChanged: (_) => setState(() => _amountError = null),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _item,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 60,
                      decoration: InputDecoration(
                        labelText: 'What for',
                        counterText: '',
                        errorText: _itemError,
                      ),
                      onChanged: (_) => setState(() => _itemError = null),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        errorText: _categoryError,
                      ),
                      items: [
                        if (widget.newCategoryName != null)
                          DropdownMenuItem(
                            value: kNewCategoryId,
                            child: Text('${widget.newCategoryName} (new)'),
                          ),
                        for (final c in widget.categories)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => setState(() {
                        _category = v;
                        _categoryError = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _location,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Place (optional)',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Paid with',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kc.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in _methods)
                          ChoiceChip(
                            label: Text(m.$2),
                            selected: _payment == m.$1,
                            onSelected: (on) =>
                                setState(() => _payment = on ? m.$1 : null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(friendlyDate(_date, widget.todayIso)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(widget.actionLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
