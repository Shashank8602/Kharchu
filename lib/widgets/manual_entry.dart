import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import '../core/money.dart';
import '../core/theme.dart';
import '../features/chat/chat_controller.dart' show todayProvider;
import '../providers.dart';
import '../services/agent/parsing.dart';
import '../services/agent/tool_executor.dart' show kMaxRupees;
import 'expense_form_sheet.dart';
import 'pill_toggle.dart';

// Adding entries by hand, for when the AI is out of reach (no key, rate
// limit, offline). Writes the same rows the chat would, with source "manual".

/// Asks what to add, then opens the matching form.
Future<void> showManualEntryMenu(BuildContext context, WidgetRef ref) async {
  final kc = context.kc;
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: kc.surface,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add manually', style: headingStyle(size: 19, color: kc.ink)),
            const SizedBox(height: 12),
            _MenuRow(
              icon: Icons.receipt_long_outlined,
              title: 'Expense',
              subtitle: 'Something you spent',
              bg: kc.soft,
              fg: kc.softInk,
              onTap: () => Navigator.pop(ctx, 'expense'),
            ),
            const SizedBox(height: 8),
            _MenuRow(
              icon: Icons.swap_horiz,
              title: 'Lent or borrowed',
              subtitle: 'Money given to or taken from someone',
              bg: kc.lentBg,
              fg: kc.lentInk,
              onTap: () => Navigator.pop(ctx, 'loan'),
            ),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  if (choice == 'expense') {
    await addExpenseManually(context, ref);
  } else {
    await addLoanManually(context, ref);
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.fg,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final Color bg, fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Material(
      color: kc.field,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: bg,
                child: Icon(icon, color: fg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: kc.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: kc.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: kc.muted),
            ],
          ),
        ),
      ),
    );
  }
}

void _toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<void> addExpenseManually(BuildContext context, WidgetRef ref) async {
  final cats = await ref.read(categoryRepoProvider).active();
  if (!context.mounted) return;
  final r = await showExpenseSheet(
    context,
    categories: cats,
    todayIso: ref.read(todayProvider),
    title: 'Add expense',
    actionLabel: 'Save',
  );
  if (r == null) return;
  try {
    await ref
        .read(expenseRepoProvider)
        .add(
          amountPaise: r.amountPaise,
          categoryId: r.categoryId,
          item: r.item,
          location: r.location,
          paymentMethod: r.paymentMethod,
          spentOn: r.spentOn,
          source: 'manual',
        );
    if (context.mounted) {
      _toast(context, 'Saved ${formatINR(r.amountPaise)} ${r.item}');
    }
  } catch (_) {
    if (context.mounted) _toast(context, "Couldn't save that. Try again.");
  }
}

Future<void> addLoanManually(BuildContext context, WidgetRef ref) async {
  final people = (await ref.read(lendingRepoProvider).recentPeople(
    30,
  )).map((p) => p.name).toList();
  if (!context.mounted) return;
  final r = await showModalBottomSheet<_LoanInput>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.kc.surface,
    builder: (_) =>
        _LoanSheet(people: people, todayIso: ref.read(todayProvider)),
  );
  if (r == null) return;
  try {
    final repo = ref.read(lendingRepoProvider);
    final person = await repo.findOrCreatePerson(r.person);
    await repo.addLoan(
      personId: person.id,
      direction: r.lent ? 'lent' : 'borrowed',
      principalPaise: r.paise,
      note: r.note,
      happenedOn: r.date,
    );
    if (context.mounted) {
      _toast(
        context,
        '${r.lent ? 'Lent' : 'Borrowed'} ${formatINR(r.paise)} · ${person.name}',
      );
    }
  } catch (_) {
    if (context.mounted) _toast(context, "Couldn't save that. Try again.");
  }
}

class _LoanInput {
  const _LoanInput(this.lent, this.person, this.paise, this.note, this.date);
  final bool lent;
  final String person;
  final int paise;
  final String? note;
  final String date;
}

class _LoanSheet extends StatefulWidget {
  const _LoanSheet({required this.people, required this.todayIso});
  final List<String> people;
  final String todayIso;

  @override
  State<_LoanSheet> createState() => _LoanSheetState();
}

class _LoanSheetState extends State<_LoanSheet> {
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _lent = true;
  late String _date = widget.todayIso;
  String? _personError, _amountError;

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final last = tryParseIso(widget.todayIso)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: tryParseIso(_date) ?? last,
      firstDate: DateTime.utc(2000),
      lastDate: last,
    );
    if (picked != null) setState(() => _date = isoDate(picked));
  }

  void _save() {
    final name = cleanText(_person.text, maxLength: 60);
    final rupees = parseRupees(_amount.text);
    String? amountError;
    if (rupees == null || rupees <= 0 || rupeesToPaise(rupees) <= 0) {
      amountError = 'Enter an amount';
    } else if (rupees > kMaxRupees) {
      amountError = 'That is above ₹10,00,000';
    }
    final personError = name == null ? 'Enter a name' : null;
    if (amountError != null || personError != null) {
      setState(() {
        _amountError = amountError;
        _personError = personError;
      });
      return;
    }
    Navigator.pop(
      context,
      _LoanInput(
        _lent,
        name!,
        rupeesToPaise(rupees!),
        cleanText(_note.text, maxLength: 60),
        _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lent or borrowed',
              style: headingStyle(size: 19, color: kc.ink),
            ),
            const SizedBox(height: 16),
            PillToggle(
              labels: const ['I lent', 'I borrowed'],
              selected: _lent ? 0 : 1,
              onChanged: (i) => setState(() => _lent = i == 0),
              selectedColors: [
                (kc.lentInk, kc.lentBg),
                (kc.borrowedInk, kc.borrowedBg),
              ],
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (v) {
                final q = v.text.trim().toLowerCase();
                if (q.isEmpty) return widget.people.take(5);
                return widget.people.where((p) => p.toLowerCase().contains(q));
              },
              onSelected: (s) => _person.text = s,
              fieldViewBuilder: (_, controller, focus, _) {
                return TextField(
                  controller: controller,
                  focusNode: focus,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 60,
                  decoration: InputDecoration(
                    labelText: _lent ? 'Lent to' : 'Borrowed from',
                    counterText: '',
                    errorText: _personError,
                  ),
                  onChanged: (v) => setState(() {
                    _person.text = v;
                    _personError = null;
                  }),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                errorText: _amountError,
              ),
              onChanged: (_) => setState(() => _amountError = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(friendlyDate(_date, widget.todayIso)),
            ),
            const SizedBox(height: 20),
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
                    child: const Text('Save'),
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
