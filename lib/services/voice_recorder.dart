import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// The microphone. Behind an interface so tests do not need a device.
abstract class VoiceRecorder {
  /// Starts recording. Returns false if the microphone is not allowed.
  Future<bool> start();

  /// Loudness from 0 to 1, about ten times a second while recording.
  Stream<double> levels();

  /// Stops and returns the recording, or null if there is none.
  Future<Uint8List?> stop();

  /// Stops and throws the recording away.
  Future<void> cancel();

  Future<void> dispose();
}

/// Records 16 kHz mono AAC, which is plenty for speech and keeps the upload
/// small. The temporary file is deleted as soon as it has been read.
class DeviceVoiceRecorder implements VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  @override
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/kharchu_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _path = path;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 48000,
      ),
      path: path,
    );
    return true;
  }

  @override
  Stream<double> levels() => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 100))
      // amplitude arrives in dB, about -45 (quiet room) to 0 (very loud)
      .map((a) => ((a.current + 45) / 45).clamp(0.0, 1.0));

  @override
  Future<Uint8List?> stop() async {
    final stopped = await _recorder.stop();
    final path = stopped ?? _path;
    _path = null;
    if (path == null) return null;
    final file = File(path);
    try {
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } finally {
      _delete(file);
    }
  }

  @override
  Future<void> cancel() async {
    final path = _path;
    _path = null;
    try {
      await _recorder.cancel();
    } catch (_) {}
    if (path != null) _delete(File(path));
  }

  void _delete(File f) {
    try {
      f.deleteSync();
    } catch (_) {}
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
