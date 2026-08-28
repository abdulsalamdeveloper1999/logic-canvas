import 'dart:convert';
import 'dart:io';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';

enum SyncOutcome { success, quotaExceeded, failed, unsupportedPlatform, queued }

/// Outcome of a sync attempt. Previously every failure was a `debugPrint` and
/// nothing else, so a full iCloud account meant backups silently never
/// happened while the UI looked healthy.
class SyncResult {
  final SyncOutcome outcome;
  final String message;

  const SyncResult(this.outcome, this.message);

  bool get isSuccess => outcome == SyncOutcome.success;

  static const unsupported = SyncResult(
    SyncOutcome.unsupportedPlatform,
    'iCloud sync is only available on iOS and macOS.',
  );
}

/// Describes what is sitting in iCloud, so the user can decide whether to let
/// it replace what is on this device.
class CloudSnapshotInfo {
  final Map<String, dynamic> data;
  final int boardCount;
  final int strokeCount;

  const CloudSnapshotInfo({
    required this.data,
    required this.boardCount,
    required this.strokeCount,
  });

  String get summary {
    final boards = boardCount == 1 ? '1 board' : '$boardCount boards';
    final strokes = strokeCount == 1 ? '1 stroke' : '$strokeCount strokes';
    return '$boards · $strokes';
  }
}

@lazySingleton
class ICloudSyncService {
  final SettingsCubit _settingsCubit;
  static const String _containerId = 'iCloud.com.asdevify.logiccanvas';
  static const String _fileName = 'boards_state.json';
  static const String _metaBoxName = 'settings';
  static const String _lastSyncKey = 'icloud_last_successful_sync';

  ICloudSyncService(this._settingsCubit);

  bool _isSyncing = false;
  Map<String, dynamic>? _pendingData;
  DateTime? _nextRetryTime;
  SyncResult? _lastResult;

  SyncResult? get lastResult => _lastResult;

  Future<DateTime?> lastSuccessfulSync() async {
    try {
      final box = await Hive.openBox(_metaBoxName);
      final raw = box.get(_lastSyncKey);
      return raw is String ? DateTime.tryParse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordSuccess() async {
    try {
      final box = await Hive.openBox(_metaBoxName);
      await box.put(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('iCloud Sync: could not record success timestamp ($e)');
    }
  }

  Future<SyncResult> syncToCloud(Map<String, dynamic> data) async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      _lastResult = SyncResult.unsupported;
      return SyncResult.unsupported;
    }

    _pendingData = data;
    if (_isSyncing) {
      return const SyncResult(
        SyncOutcome.queued,
        'A sync is already in progress.',
      );
    }

    if (_nextRetryTime != null && DateTime.now().isBefore(_nextRetryTime!)) {
      const result = SyncResult(
        SyncOutcome.quotaExceeded,
        'iCloud storage is full — your boards are NOT being backed up.',
      );
      _lastResult = result;
      return result;
    }

    _isSyncing = true;
    var result = const SyncResult(SyncOutcome.queued, 'Nothing to sync.');
    try {
      while (_pendingData != null) {
        final dataToSync = _pendingData!;
        _pendingData = null;
        result = await _performSync(dataToSync);
        await Future.delayed(const Duration(milliseconds: 500));

        if (!result.isSuccess) break;
      }
    } finally {
      _isSyncing = false;
    }

    _lastResult = result;
    return result;
  }

  Future<SyncResult> _performSync(Map<String, dynamic> data) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$_fileName');
      await file.writeAsString(jsonEncode(data));

      await ICloudStorage.upload(
        containerId: _containerId,
        filePath: file.path,
        destinationRelativePath: _fileName,
        onProgress: (stream) {
          stream.listen(
            (progress) => debugPrint('iCloud Upload Progress: $progress'),
            onError: (e) => debugPrint('iCloud Upload Stream Error: $e'),
            cancelOnError: true,
          );
        },
      );

      _nextRetryTime = null;
      _settingsCubit.setICloudQuotaExceeded(false);
      await _recordSuccess();
      return const SyncResult(SyncOutcome.success, 'Boards backed up.');
    } catch (e) {
      final errorStr = e.toString();
      debugPrint('iCloud Sync Error (Upload): $errorStr');

      if (errorStr.contains('Quota exceeded')) {
        _nextRetryTime = DateTime.now().add(const Duration(minutes: 5));
        _settingsCubit.setICloudQuotaExceeded(true);
        return const SyncResult(
          SyncOutcome.quotaExceeded,
          'iCloud storage is full — your boards are NOT being backed up. '
          'Free up iCloud space, or use Export to save a backup file.',
        );
      }

      return SyncResult(
        SyncOutcome.failed,
        'Backup to iCloud failed. Your work is still saved on this device.',
      );
    }
  }

  /// Fetches the cloud copy and describes it, without touching local state.
  /// The caller decides whether to apply it.
  Future<CloudSnapshotInfo?> peekCloudSnapshot() async {
    final data = await downloadFromCloud();
    if (data == null) return null;

    var strokes = 0;
    final boards = data['boards'];
    if (boards is Map) {
      for (final value in boards.values) {
        if (value is List) strokes += value.length;
      }
    }

    return CloudSnapshotInfo(
      data: data,
      boardCount: boards is Map ? boards.length : 0,
      strokeCount: strokes,
    );
  }

  Future<Map<String, dynamic>?> downloadFromCloud() async {
    if (!Platform.isIOS && !Platform.isMacOS) return null;

    try {
      final directory = await getTemporaryDirectory();
      final downloadPath = '${directory.path}/downloaded_$_fileName';

      await ICloudStorage.download(
        containerId: _containerId,
        relativePath: _fileName,
        destinationFilePath: downloadPath,
        onProgress: (stream) {
          stream.listen((progress) {
            debugPrint('iCloud Download Progress: $progress');
          });
        },
      );

      final file = File(downloadPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('iCloud Sync Error (Download): $e');
    }
    return null;
  }
}
