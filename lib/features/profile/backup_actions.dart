import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../providers.dart';
import '../../services/backup_service.dart';
import '../../services/export_service.dart';
import '../chat/chat_controller.dart' show todayProvider;

typedef _Toast = void Function(String text);

/// Grabbed before any await, so nothing needs the BuildContext afterwards.
_Toast _toaster(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return (text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

String _stamp(DateTime moment) {
  final now = moment.toLocal(); // file names use the phone's own clock
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}';
}

/// "Back up to file": Android's Save dialog, where Google Drive is one choice.
Future<void> runBackup(BuildContext context, WidgetRef ref) async {
  final toast = _toaster(context);
  final now = ref.read(clockProvider)();
  final String json;
  try {
    json = await ref.read(backupServiceProvider).exportJson(now: now);
  } catch (_) {
    toast("Couldn't create the backup.");
    return;
  }
  final saved = await ref.read(fileGatewayProvider).save(
        fileName: 'kharchu-backup-${_stamp(now)}.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
        dialogTitle: 'Save backup',
      );
  if (!saved) return; // cancelled: say nothing
  await ref.read(settingsProvider.notifier).markBackupDone(now);
  toast('Backup saved');
}

/// "Restore from file": check it, say what is in it, then replace everything.
Future<void> runRestore(BuildContext context, WidgetRef ref) async {
  final toast = _toaster(context);
  final bytes = await ref.read(fileGatewayProvider).pick(dialogTitle: 'Choose a backup');
  if (bytes == null || !context.mounted) return;

  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    toast("That file isn't a Kharchu backup.");
    return;
  }
  final service = ref.read(backupServiceProvider);
  final BackupSummary summary;
  try {
    summary = service.inspect(text);
  } on BackupException catch (e) {
    toast(e.message);
    return;
  }
  if (!context.mounted) return;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final kc = ctx.kc;
      final parts = <String>[
        '${summary.expenses} ${summary.expenses == 1 ? 'expense' : 'expenses'}',
        '${summary.loans} ${summary.loans == 1 ? 'loan' : 'loans'}',
        '${summary.budgets} ${summary.budgets == 1 ? 'budget' : 'budgets'}',
      ];
      final when = DateTime.tryParse(summary.exportedAt);
      return AlertDialog(
        title: const Text('Restore this backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(parts.join(', ')),
            if (when != null)
              Text('From ${fullDateLabel(isoDate(when))}',
                  style: TextStyle(color: kc.muted)),
            const SizedBox(height: 12),
            Text('This replaces everything on this phone.',
                style: TextStyle(color: kc.dangerInk, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: kc.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      );
    },
  );
  if (ok != true) return;

  try {
    await service.restore(text);
  } on BackupException catch (e) {
    toast(e.message);
    return;
  } catch (_) {
    toast("Couldn't restore. Your data is unchanged.");
    return;
  }
  toast('Backup restored');
}

enum _Range { thisMonth, lastMonth, thisYear, allTime, custom }

/// "Export CSV": pick a period, then save through the system dialog.
Future<void> runExport(BuildContext context, WidgetRef ref) async {
  final toast = _toaster(context);
  final choice = await showDialog<_Range>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Export expenses'),
      children: [
        for (final (r, label) in [
          (_Range.thisMonth, 'This month'),
          (_Range.lastMonth, 'Last month'),
          (_Range.thisYear, 'This year'),
          (_Range.allTime, 'All time'),
          (_Range.custom, 'Pick dates…'),
        ])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, r),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(label, style: const TextStyle(fontSize: 16)),
            ),
          ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;

  final today = ref.read(todayProvider);
  late final String from;
  late final String to;
  switch (choice) {
    case _Range.thisMonth:
      (from: from, to: to) = monthRange(today);
    case _Range.lastMonth:
      (from: from, to: to) = monthRange(previousMonthStart(today));
    case _Range.thisYear:
      from = '${tryParseIso(today)!.year}-01-01';
      to = today;
    case _Range.allTime:
      from = '2000-01-01';
      to = today;
    case _Range.custom:
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime.utc(2000),
        lastDate: tryParseIso(today)!,
      );
      if (picked == null || !context.mounted) return;
      from = isoDate(picked.start);
      to = isoDate(picked.end);
  }

  final csv = await ref.read(exportServiceProvider).buildCsv(from: from, to: to);
  // header only: nothing to export
  if (!csv.contains('\n')) {
    toast('No expenses in that period');
    return;
  }
  final saved = await ref.read(fileGatewayProvider).save(
        fileName: ExportService.fileName(from, to),
        bytes: Uint8List.fromList(utf8.encode(csv)),
        mimeType: 'text/csv',
        dialogTitle: 'Save expenses',
      );
  if (saved) toast('Expenses exported');
}
