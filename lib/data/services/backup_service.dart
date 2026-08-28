import 'dart:convert';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:printing/printing.dart';

/// Outcome of parsing a backup file the user picked or pasted.
sealed class BackupParseResult {
  const BackupParseResult();
}

class BackupParsed extends BackupParseResult {
  final Map<String, dynamic> state;
  final int boardCount;
  final int strokeCount;
  final DateTime? exportedAt;

  const BackupParsed({
    required this.state,
    required this.boardCount,
    required this.strokeCount,
    this.exportedAt,
  });

  String get summary {
    final boards = boardCount == 1 ? '1 board' : '$boardCount boards';
    final strokes = strokeCount == 1 ? '1 stroke' : '$strokeCount strokes';
    return '$boards · $strokes';
  }
}

class BackupInvalid extends BackupParseResult {
  final String message;
  const BackupInvalid(this.message);
}

/// Reads and writes a portable backup of every board, so the user always has a
/// copy that does not depend on iCloud having free space.
@lazySingleton
class BackupService {
  static const String formatTag = 'logiccanvas.backup';
  static const int formatVersion = 1;

  /// Wraps a `DrawingState.toJson()` payload in a versioned envelope.
  static String encodeBackup(Map<String, dynamic> state, {DateTime? now}) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': formatTag,
      'version': formatVersion,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'state': state,
    });
  }

  /// Parses a backup file. Accepts both the enveloped format written by
  /// [encodeBackup] and a bare state map (the shape stored in iCloud), so a
  /// file recovered from either source can be restored.
  static BackupParseResult parseBackup(String raw) {
    if (raw.trim().isEmpty) {
      return const BackupInvalid('That file is empty.');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const BackupInvalid(
        'That does not look like a LogicCanvas backup — it is not valid JSON.',
      );
    }

    if (decoded is! Map) {
      return const BackupInvalid('That backup file is not in a known format.');
    }

    final envelope = Map<String, dynamic>.from(decoded);
    final Map<String, dynamic> state;

    if (envelope['state'] is Map) {
      final version = (envelope['version'] as num?)?.toInt() ?? 1;
      if (version > formatVersion) {
        return BackupInvalid(
          'This backup was made by a newer version of LogicCanvas '
          '(format $version). Update the app, then import again.',
        );
      }
      state = Map<String, dynamic>.from(envelope['state'] as Map);
    } else if (envelope['boards'] is Map) {
      state = envelope;
    } else {
      return const BackupInvalid('That backup file has no boards in it.');
    }

    final boards = state['boards'];
    if (boards is! Map) {
      return const BackupInvalid('That backup file has no boards in it.');
    }

    var strokes = 0;
    for (final value in boards.values) {
      if (value is! List) {
        return const BackupInvalid(
          'That backup file is damaged — one of its boards could not be read.',
        );
      }
      strokes += value.length;
    }

    return BackupParsed(
      state: state,
      boardCount: boards.length,
      strokeCount: strokes,
      exportedAt: DateTime.tryParse(envelope['exportedAt'] as String? ?? ''),
    );
  }

  /// Hands the user a backup file through the system share sheet.
  Future<void> shareBackup(Map<String, dynamic> state) async {
    final json = encodeBackup(state);
    final stamp = DateTime.now().toIso8601String().split('T').first;
    await Printing.sharePdf(
      bytes: Uint8List.fromList(utf8.encode(json)),
      filename: 'LogicCanvas-backup-$stamp.json',
    );
  }
}
