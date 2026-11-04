import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Lets a screen nested in the shell (like Transactions, which has its own
/// swipe between Expenses and Lending) pass leftover swipes to the shell.
class ShellPager extends InheritedWidget {
  const ShellPager({super.key, required this.controller, required super.child});
  final PageController controller;

  static PageController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellPager>()?.controller;

  @override
  bool updateShouldNotify(ShellPager old) => controller != old.controller;
}

/// The bottom-bar screens side by side: swipe sideways to go to the next one,
/// or tap a tab and the page slides there. Each screen keeps its state.
class SwipeShellBody extends StatefulWidget {
  const SwipeShellBody({super.key, required this.shell, required this.children});
  final StatefulNavigationShell shell;
  final List<Widget> children;

  @override
  State<SwipeShellBody> createState() => _SwipeShellBodyState();
}

class _SwipeShellBodyState extends State<SwipeShellBody> {
  late final PageController _controller =
      PageController(initialPage: widget.shell.currentIndex);
  bool _animating = false;

  @override
  void didUpdateWidget(SwipeShellBody old) {
    super.didUpdateWidget(old);
    final target = widget.shell.currentIndex;
    final page = _controller.hasClients ? _controller.page?.round() : null;
    if (page != null && page != target) _slideTo(target);
  }

  Future<void> _slideTo(int index) async {
    _animating = true;
    try {
      await _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _animating = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShellPager(
      controller: _controller,
      child: PageView(
        controller: _controller,
        onPageChanged: (i) {
          // a tab tap slides through the pages in between; only a swipe lands here
          if (_animating || i == widget.shell.currentIndex) return;
          FocusManager.instance.primaryFocus?.unfocus();
          widget.shell.goBranch(i);
        },
        children: [for (final c in widget.children) _KeepAlive(child: c)],
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
