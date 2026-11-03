import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Page frame used by the tab screens: a title bar and a body.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Scaffold(
      backgroundColor: kc.bg,
      appBar: AppBar(
        title: Text(title, style: headingStyle(size: 20, color: kc.ink)),
        actions: actions,
        shape: Border(bottom: BorderSide(color: kc.line)),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}
