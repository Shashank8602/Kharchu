import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../services/groq/groq_errors.dart';
import 'chat_controller.dart';

enum VoicePhase { idle, recording, transcribing }

class VoiceState {
  const VoiceState({
    this.phase = VoicePhase.idle,
    this.seconds = 0,
    this.levels = const [],
  });
  final VoicePhase phase;
  final int seconds;

  /// The most recent loudness readings, for the little bars.
  final List<double> levels;

  VoiceState copyWith({
    VoicePhase? phase,
    int? seconds,
    List<double>? levels,
  }) => VoiceState(
    phase: phase ?? this.phase,
    seconds: seconds ?? this.seconds,
    levels: levels ?? this.levels,
  );
}

/// Record, transcribe with Groq's Whisper, then send the words like any other
/// message. Each step that can fail returns a short message for a snackbar.
class VoiceController extends Notifier<VoiceState> {
  static const maxSeconds = 60;
  static const minSeconds = 1;
  static const _barCount = 20;

  Timer? _timer;
  StreamSubscription<double>? _levels;

  @override
  VoiceState build() {
    ref.onDispose(_stopTimers);
    return const VoiceState();
  }

  void _stopTimers() {
    _timer?.cancel();
    _timer = null;
    _levels?.cancel();
    _levels = null;
  }

  /// Returns a message to show the user, or null if recording started.
  Future<String?> start() async {
    if (state.phase != VoicePhase.idle) return null;
    final recorder = ref.read(voiceRecorderProvider);
    final bool allowed;
    try {
      allowed = await recorder.start();
    } catch (_) {
      return "Couldn't start the microphone.";
    }
    if (!allowed) {
      return 'Allow the microphone in Android settings to use voice.';
    }

    state = const VoiceState(phase: VoicePhase.recording);
    _levels = recorder.levels().listen((l) {
      final next = [...state.levels, l];
      state = state.copyWith(
        levels: next.length > _barCount
            ? next.sublist(next.length - _barCount)
            : next,
      );
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state.seconds + 1;
      state = state.copyWith(seconds: s);
      if (s >= maxSeconds) stopAndSend();
    });
    return null;
  }

  /// Stops, transcribes and sends. Returns a message to show, or null.
  Future<String?> stopAndSend() async {
    if (state.phase != VoicePhase.recording) return null;
    final seconds = state.seconds;
    _stopTimers();
    state = state.copyWith(phase: VoicePhase.transcribing);

    final recorder = ref.read(voiceRecorderProvider);
    final bytes = await _safely(recorder.stop);
    if (seconds < minSeconds) {
      state = const VoiceState();
      return 'Too short. Hold on a little longer.';
    }
    if (bytes == null || bytes.isEmpty) {
      state = const VoiceState();
      return "Couldn't record that. Try again.";
    }

    final String text;
    try {
      text = await ref.read(groqClientProvider).transcribe(bytes);
    } on GroqException catch (e) {
      state = const VoiceState();
      return e.userMessage;
    } catch (_) {
      state = const VoiceState();
      return "Couldn't understand that recording. Try again.";
    }
    state = const VoiceState();
    if (text.trim().isEmpty) return "Couldn't hear anything. Try again.";
    await ref.read(chatControllerProvider.notifier).send(text, source: 'voice');
    return null;
  }

  /// Throws the recording away (the cross button, or the app going to the
  /// background).
  Future<void> cancel() async {
    if (state.phase != VoicePhase.recording) return;
    _stopTimers();
    state = const VoiceState();
    await _safely(ref.read(voiceRecorderProvider).cancel);
  }

  Future<T?> _safely<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }
}

final voiceControllerProvider = NotifierProvider<VoiceController, VoiceState>(
  VoiceController.new,
);
