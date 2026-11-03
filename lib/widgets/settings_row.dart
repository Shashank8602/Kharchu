import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A tappable row inside a rounded card, as used on the Profile screen.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.tag,
    this.tagTone = TagTone.neutral,
    this.destructive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? tag;
  final TagTone tagTone;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final color = destructive ? kc.danger : kc.ink;
    final (tagBg, tagFg) = switch (tagTone) {
      TagTone.good => (kc.soft, kc.softInk),
      TagTone.warn => (kc.warnBg, kc.warnInk),
      TagTone.neutral => (Colors.transparent, kc.muted),
    };
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: color, fontSize: 15)),
              ),
              if (tag != null)
                Container(
                  padding: tagTone == TagTone.neutral
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(tag!,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: tagFg)),
                ),
              if (onTap != null && !destructive) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 20, color: kc.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum TagTone { neutral, good, warn }

/// A white rounded card that stacks rows with hairline dividers.
class RowCard extends StatelessWidget {
  const RowCard({super.key, required this.children});
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
