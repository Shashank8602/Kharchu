import 'package:flutter/material.dart';

import '../core/theme.dart';

/// One tab of [PillNavBar]. The colors tint the selected pill.
class PillTab {
  const PillTab(this.icon, this.selectedIcon, this.label, this.bg, this.fg);
  final IconData icon, selectedIcon;
  final String label;
  final Color bg, fg;
}

/// The bottom bar: a floating, fully rounded pill. The selected tab sits in a
/// tinted pill of its own. Labels shrink to fit instead of wrapping.
class PillNavBar extends StatelessWidget {
  const PillNavBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<PillTab> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: kc.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: kc.line),
            boxShadow: [
              BoxShadow(
                color: kc.accent.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _Item(
                    tab: tabs[i],
                    selected: i == selected,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.tab, required this.selected, required this.onTap});
  final PillTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final color = selected ? tab.fg : kc.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // the tinted pill sits behind the icon only, so the label can
              // use the whole width of the tab
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: selected ? 52 : 36,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? tab.bg : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    selected ? tab.selectedIcon : tab.icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: color,
                    ),
                    child: Text(
                      tab.label,
                      maxLines: 1,
                      softWrap: false,
                      textScaler: MediaQuery.textScalerOf(
                        context,
                      ).clamp(maxScaleFactor: 1.15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
