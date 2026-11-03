import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../services/agent/agent_service.dart';

/// The text box and send button. A mic button joins it in the voice phase.
class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.onSend,
    required this.sending,
    this.trailing,
  });

  final void Function(String text) onSend;
  final bool sending;

  /// Optional extra button shown instead of Send while the box is empty
  /// (the mic).
  final Widget? trailing;

  @override
  State<Composer> createState() => ComposerState();
}

class ComposerState extends State<Composer> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.sending) return;
    _controller.clear();
    widget.onSend(text);
  }

  /// Lets the voice flow put a transcript in the box.
  void setText(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final canSend = _hasText && !widget.sending;
    final showTrailing = widget.trailing != null && !_hasText;
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
            Expanded(
              child: TextField(
                controller: _controller,
                maxLength: AgentService.maxInputLength,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'What did you spend?',
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide(color: kc.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide(color: kc.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide(color: kc.accent, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (showTrailing)
              widget.trailing!
            else
              IconButton.filled(
                tooltip: 'Send',
                onPressed: canSend ? _send : null,
                style: IconButton.styleFrom(
                  backgroundColor: kc.accent,
                  foregroundColor: kc.onAccent,
                  disabledBackgroundColor: kc.track,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.arrow_upward),
              ),
          ],
        ),
      ),
    );
  }
}
