import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Replaces the text box while recording: cancel, a timer with live bars, stop.
class RecordingBar extends StatelessWidget {
  const RecordingBar({
    super.key,
    required this.seconds,
    required this.levels,
    required this.onCancel,
    required this.onStop,
  });

  final int seconds;
  final List<double> levels;
  final VoidCallback onCancel;
  final VoidCallback onStop;

  static String clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: kc.surface,
        border: Border(top: BorderSide(color: kc.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton.outlined(
              tooltip: 'Cancel recording',
              onPressed: onCancel,
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.close, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: kc.dangerBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: kc.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      clock(seconds),
                      style: TextStyle(
                        color: kc.dangerInk,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (final l in levels)
                            Container(
                              width: 3,
                              height: 4 + 22 * l,
                              margin: const EdgeInsets.only(left: 3),
                              decoration: BoxDecoration(
                                color: kc.danger,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: 'Stop and send',
              onPressed: onStop,
              style: IconButton.styleFrom(
                backgroundColor: kc.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.stop_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
