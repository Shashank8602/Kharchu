import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/key_store.dart';
import '../../data/settings_store.dart';
import '../../providers.dart';
import '../../services/groq/groq_errors.dart';

enum _Check { idle, testing, ok, failed }

class GroqSettingsScreen extends ConsumerStatefulWidget {
  const GroqSettingsScreen({super.key});

  @override
  ConsumerState<GroqSettingsScreen> createState() => _GroqSettingsScreenState();
}

class _GroqSettingsScreenState extends ConsumerState<GroqSettingsScreen> {
  final _key = TextEditingController();
  late final TextEditingController _chat;
  late final TextEditingController _fallback;
  late final TextEditingController _voice;
  bool _hidden = true;
  _Check _check = _Check.idle;
  String? _message;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _chat = TextEditingController(text: s.chatModel);
    _fallback = TextEditingController(text: s.fallbackModel);
    _voice = TextEditingController(text: s.voiceModel);
  }

  @override
  void dispose() {
    _key.dispose();
    _chat.dispose();
    _fallback.dispose();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    final key = cleanApiKey(_key.text);
    if (key.isEmpty) {
      setState(() {
        _check = _Check.failed;
        _message = 'Paste your key first.';
      });
      return;
    }
    setState(() {
      _check = _Check.testing;
      _message = null;
    });
    final store = ref.read(keyStoreProvider);
    await store.write(key);
    ref.invalidate(hasKeyProvider);
    try {
      await ref.read(groqClientProvider).testKey();
      if (!mounted) return;
      _key.clear();
      setState(() {
        _check = _Check.ok;
        _message = 'Connected.';
      });
    } on GroqUnauthorized {
      await store.delete(); // a rejected key is no use; don't keep it
      ref.invalidate(hasKeyProvider);
      if (!mounted) return;
      setState(() {
        _check = _Check.failed;
        _message = 'Groq rejected the key. Check it and try again.';
      });
    } on GroqNetworkError {
      if (!mounted) return;
      setState(() {
        _check = _Check.failed;
        _message = "Key saved. Couldn't reach Groq to test it.";
      });
    } on GroqException catch (e) {
      if (!mounted) return;
      setState(() {
        _check = _Check.failed;
        _message = e.userMessage;
      });
    }
  }

  Future<void> _removeKey() async {
    await ref.read(keyStoreProvider).delete();
    ref.invalidate(hasKeyProvider);
    if (!mounted) return;
    setState(() {
      _check = _Check.idle;
      _message = null;
    });
  }

  Future<void> _saveModels() async {
    await ref.read(settingsProvider.notifier).setModels(
          chat: _chat.text,
          fallback: _fallback.text,
          voice: _voice.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Models saved')));
  }

  void _resetModels() {
    _chat.text = defaultChatModel;
    _fallback.text = defaultFallbackModel;
    _voice.text = defaultVoiceModel;
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final hasKey = ref.watch(hasKeyProvider).asData?.value ?? false;
    final lang = ref.watch(settingsProvider.select((s) => s.voiceLanguage));
    final typed = cleanApiKey(_key.text);
    final warnFormat = typed.isNotEmpty && !looksLikeGroqKey(typed);

    final (statusBg, statusFg, statusIcon) = switch (_check) {
      _Check.ok => (kc.soft, kc.softInk, Icons.check_circle_outline),
      _Check.failed => (kc.dangerBg, kc.dangerInk, Icons.error_outline),
      _ => (kc.field, kc.muted, Icons.info_outline),
    };

    return Scaffold(
      backgroundColor: kc.bg,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: Text('Groq API key', style: headingStyle(size: 19, color: kc.ink)),
        shape: Border(bottom: BorderSide(color: kc.line)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _key,
              obscureText: _hidden,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _saveAndTest(),
              decoration: InputDecoration(
                labelText: hasKey ? 'Paste a new key to replace it' : 'Groq API key',
                hintText: 'gsk_…',
                suffixIcon: IconButton(
                  tooltip: _hidden ? 'Show key' : 'Hide key',
                  icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
              ),
            ),
            if (warnFormat)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text("This doesn't look like a Groq key (they start with gsk_).",
                    style: TextStyle(fontSize: 13, color: kc.warnInk)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _check == _Check.testing ? null : _saveAndTest,
                    child: _check == _Check.testing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4))
                        : const Text('Save and test'),
                  ),
                ),
                if (hasKey) ...[
                  const SizedBox(width: 10),
                  OutlinedButton(onPressed: _removeKey, child: const Text('Remove')),
                ],
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: statusBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 20, color: statusFg),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_message!,
                            style: TextStyle(
                                color: statusFg, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text('Models', style: headingStyle(size: 16, color: kc.ink)),
            const SizedBox(height: 12),
            TextField(
              controller: _chat,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Chat model'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fallback,
              autocorrect: false,
              decoration: const InputDecoration(
                  labelText: 'Fallback model', hintText: 'Leave empty for none'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _voice,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Voice model'),
            ),
            const SizedBox(height: 16),
            Text('Voice language',
                style: TextStyle(fontWeight: FontWeight.w600, color: kc.ink)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'auto', label: Text('Auto')),
                  ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(value: 'kn', label: Text('Kannada')),
                ],
                selected: {lang},
                onSelectionChanged: (s) =>
                    ref.read(settingsProvider.notifier).setVoiceLanguage(s.first),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: FilledButton(
                        onPressed: _saveModels, child: const Text('Save models'))),
                const SizedBox(width: 10),
                OutlinedButton(
                    onPressed: _resetModels, child: const Text('Defaults')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
