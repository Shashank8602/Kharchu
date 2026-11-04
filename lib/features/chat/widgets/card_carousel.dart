import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Several pending cards from one message, shown one at a time. Swipe sideways
/// (or use the arrows) to go to the previous or next card; each card is saved,
/// edited or cancelled on its own. When one is dealt with it leaves and the
/// next takes its place.
class CardCarousel extends StatefulWidget {
  const CardCarousel({super.key, required this.ids, required this.cards})
    : assert(ids.length == cards.length);

  /// Stable id of each card (the chat message id).
  final List<String> ids;
  final List<Widget> cards;

  @override
  State<CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<CardCarousel> {
  int _index = 0;
  int _dir = 1; // 1: the next card comes in from the right, -1 from the left
  String? _currentId;

  int get _safeIndex {
    final i = _currentId == null ? -1 : widget.ids.indexOf(_currentId!);
    // the current card is gone (saved or cancelled): its neighbour moves up
    return i >= 0 ? i : _index.clamp(0, widget.ids.length - 1);
  }

  void _go(int to) {
    if (to < 0 || to >= widget.ids.length || to == _safeIndex) return;
    setState(() {
      _dir = to > _safeIndex ? 1 : -1;
      _index = to;
      _currentId = widget.ids[to];
    });
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final n = widget.ids.length;
    final i = _safeIndex;
    _index = i;
    _currentId = widget.ids[i];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${i + 1} of $n to confirm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kc.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              for (var d = 0; d < n; d++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: d == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: d == i ? kc.accent : kc.track,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              IconButton(
                tooltip: 'Previous card',
                visualDensity: VisualDensity.compact,
                onPressed: i > 0 ? () => _go(i - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Next card',
                visualDensity: VisualDensity.compact,
                onPressed: i < n - 1 ? () => _go(i + 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        GestureDetector(
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -250) _go(i + 1);
            if (v > 250) _go(i - 1);
          },
          child: ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(widget.ids[i]);
                  final from = Offset((incoming ? 1 : -1) * _dir.toDouble(), 0);
                  return SlideTransition(
                    position: Tween(
                      begin: from,
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(widget.ids[i]),
                  child: widget.cards[i],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
