import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../providers.dart';

final categoriesProvider = StreamProvider.autoDispose<List<Category>>(
    (ref) => ref.watch(categoryRepoProvider).watchAll());

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kc = context.kc;
    final cats = ref.watch(categoriesProvider);
    return Scaffold(
      backgroundColor: kc.bg,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: Text('Categories', style: headingStyle(size: 19, color: kc.ink)),
        shape: Border(bottom: BorderSide(color: kc.line)),
        actions: [
          IconButton(
            tooltip: 'Add category',
            icon: const Icon(Icons.add),
            onPressed: () => _add(context, ref),
          ),
        ],
      ),
      body: cats.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const Center(child: Text("Couldn't load categories.")),
        data: (list) {
          final active = list.where((c) => !c.isArchived).toList();
          final archived = list.where((c) => c.isArchived).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Group([for (final c in active) _Row(c, active.length)]),
              if (archived.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                  child: Text('Archived',
                      style: TextStyle(
                          color: kc.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                _Group([for (final c in archived) _Row(c, active.length)]),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = await _askName(context, title: 'New category', initial: '');
    if (name == null) return;
    try {
      await ref.read(categoryRepoProvider).create(name);
    } on ArgumentError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.message}')));
      }
    }
  }
}

Future<String?> _askName(BuildContext context,
    {required String title, required String initial}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(title: title, initial: initial),
  );
}

class _Group extends StatelessWidget {
  const _Group(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Container(
      decoration: BoxDecoration(
        color: kc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kc.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: kc.hair),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row(this.c, this.activeCount);
  final Category c;
  final int activeCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kc = context.kc;
    final color = Color(Theme.of(context).brightness == Brightness.dark ? c.colorDark : c.colorLight);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: c.isArchived ? kc.muted : kc.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
            if (!c.isArchived)
              IconButton(
                tooltip: 'Rename ${c.name}',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _rename(context, ref),
              ),
            if (c.isArchived)
              TextButton(
                onPressed: () => ref.read(categoryRepoProvider).setArchived(c.id, false),
                child: const Text('Restore'),
              )
            else
              IconButton(
                tooltip: 'Archive ${c.name}',
                icon: const Icon(Icons.archive_outlined, size: 20),
                onPressed: () => _archive(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await _askName(context, title: 'Rename category', initial: c.name);
    if (name == null) return;
    final ok = await ref.read(categoryRepoProvider).rename(c.id, name);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That name is empty or already used.')));
    }
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(categoryRepoProvider).setArchived(c.id, true);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need at least one active category.')));
    }
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});
  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Name'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, _controller.text),
              child: const Text('Save')),
        ],
      );
}
