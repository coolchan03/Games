import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// File-based backup: share/save the JSON from [BackupService.export] and read
/// it back from a picked file. Text copy/paste remains available as a fallback.
class BackupFile {
  /// Backups are a few KB; anything this large is not one of ours.
  static const int maxBytes = 5 * 1024 * 1024;

  static const _json = XTypeGroup(
    label: 'Puzzle Master backup',
    extensions: ['json'],
    mimeTypes: ['application/json'],
    uniformTypeIdentifiers: ['public.json'],
  );

  static String fileName([DateTime? now]) {
    final d = now ?? DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'puzzle-master-backup-${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  /// Phones and macOS use the system share sheet (Save to Files, Drive,
  /// messaging...). The web falls back to a download. Windows and Linux have
  /// no share sheet for files, so they get a save dialog instead.
  static bool get _usesSaveDialog =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Returns false when the user cancelled.
  static Future<bool> export(String json) async {
    final bytes = Uint8List.fromList(utf8.encode(json));
    final name = fileName();
    final file = XFile.fromData(bytes, mimeType: 'application/json', name: name);
    if (_usesSaveDialog) {
      final location = await getSaveLocation(
        acceptedTypeGroups: const [_json],
        suggestedName: name,
      );
      if (location == null) return false;
      await file.saveTo(location.path);
      return true;
    }
    final result = await SharePlus.instance.share(ShareParams(
      files: [file],
      fileNameOverrides: [name],
      subject: 'Puzzle Master backup',
    ));
    return result.status != ShareResultStatus.dismissed;
  }

  /// The text of the chosen backup file, or null when cancelled.
  /// Throws [FormatException] for files that are too large or not text.
  static Future<String?> pick() async {
    final file = await openFile(acceptedTypeGroups: const [_json]);
    if (file == null) return null;
    if (await file.length() > maxBytes) {
      throw const FormatException('That file is too large to be a backup.');
    }
    return file.readAsString();
  }
}
