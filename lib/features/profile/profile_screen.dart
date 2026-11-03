import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../providers.dart';
import '../../widgets/settings_row.dart';
import 'backup_actions.dart';

/// "Last: 20 Oct", or a warning when there has never been a backup or the
/// last one is over 30 days old.
(String, TagTone) _backupTag(String? lastIso, DateTime now) {
  final last = lastIso == null ? null : DateTime.tryParse(lastIso);
  if (last == null) return ('Never', TagTone.warn);
  final stale = now.difference(last).inDays > 30;
  return (
    'Last: ${dayLabel(isoDate(last)).split(', ').last}',
    stale ? TagTone.warn : TagTone.neutral,
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kc = context.kc;
    final settings = ref.watch(settingsProvider);
    final hasKey = ref.watch(hasKeyProvider).asData?.value ?? false;
    final backup = _backupTag(
      settings.lastBackupAt,
      ref.watch(clockProvider)(),
    );
    final initial = settings.profileName.isEmpty
        ? '?'
        : settings.profileName[0].toUpperCase();
    final since =
        settings.sinceIso == null || tryParseIso(settings.sinceIso!) == null
        ? null
        : '${monthName(settings.sinceIso!).substring(0, 3)} '
              '${tryParseIso(settings.sinceIso!)!.year}';

    return Scaffold(
      backgroundColor: kc.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: kc.accent,
                  child: Text(
                    initial,
                    style: headingStyle(size: 24, color: kc.onAccent),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.profileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: headingStyle(size: 21, color: kc.ink),
                      ),
                      if (since != null)
                        Text(
                          'Using Kharchu since $since',
                          style: TextStyle(fontSize: 13, color: kc.muted),
                        ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Edit name',
                  onPressed: () =>
                      _editName(context, ref, settings.profileName),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kc.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kc.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kc.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (s) => ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(s.first),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            RowCard(
              children: [
                SettingsRow(
                  icon: Icons.key_outlined,
                  label: 'Groq API key',
                  tag: hasKey ? 'Connected' : 'Not set',
                  tagTone: hasKey ? TagTone.good : TagTone.warn,
                  onTap: () => context.go('/profile/groq'),
                ),
                SettingsRow(
                  icon: Icons.category_outlined,
                  label: 'Categories',
                  onTap: () => context.go('/profile/categories'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RowCard(
              children: [
                SettingsRow(
                  icon: Icons.file_download_outlined,
                  label: 'Back up to file',
                  tag: backup.$1,
                  tagTone: backup.$2,
                  onTap: () => runBackup(context, ref),
                ),
                SettingsRow(
                  icon: Icons.file_upload_outlined,
                  label: 'Restore from file',
                  onTap: () => runRestore(context, ref),
                ),
                SettingsRow(
                  icon: Icons.table_chart_outlined,
                  label: 'Export CSV',
                  onTap: () => runExport(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RowCard(
              children: [
                SettingsRow(
                  icon: Icons.delete_outline,
                  label: 'Clear chat history',
                  destructive: true,
                  onTap: () => _clearChat(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current == 'You' ? '' : current),
    );
    if (name != null) {
      await ref.read(settingsProvider.notifier).setProfileName(name);
    }
  }

  Future<void> _clearChat(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat history?'),
        content: const Text('Your expenses, loans and budgets are kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(chatRepoProvider).clearAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chat history cleared')));
    }
  }
}

/// Owns its controller so it is disposed only after the dialog is fully gone.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Name'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
