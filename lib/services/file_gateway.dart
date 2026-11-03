import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Saving and opening files through Android's system dialogs. Behind an
/// interface so tests can stand in for the dialogs.
abstract class FileGateway {
  /// Opens the system "Save to" dialog (Google Drive, Downloads, any folder).
  /// Returns false if the user cancelled.
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
  });

  /// Opens the system file picker. Returns null if the user cancelled.
  Future<Uint8List?> pick({String? dialogTitle});
}

class SystemFileGateway implements FileGateway {
  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      dialogTitle: dialogTitle,
    );
    return uri != null;
  }

  @override
  Future<Uint8List?> pick({String? dialogTitle}) async {
    final file = await FilePicker.pickFile(dialogTitle: dialogTitle);
    if (file == null) return null;
    return file.readAsBytes(); // works for content:// files such as Drive's
  }
}
