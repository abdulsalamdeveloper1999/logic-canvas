import 'dart:convert';
import 'dart:io';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';

@lazySingleton
class ICloudSyncService {
  final SettingsCubit _settingsCubit;
  static const String _containerId = 'iCloud.com.asdevify.logiccanvas';
  static const String _fileName = 'boards_state.json';

  ICloudSyncService(this._settingsCubit);

  bool _isSyncing = false;
  Map<String, dynamic>? _pendingData;
  DateTime? _nextRetryTime;

  Future<void> syncToCloud(Map<String, dynamic> data) async {
    if (!Platform.isIOS && !Platform.isMacOS) return;

    _pendingData = data;
    if (_isSyncing) return;

    // Check if we are in a back-off period due to quota exceeded
    if (_nextRetryTime != null && DateTime.now().isBefore(_nextRetryTime!)) {
      debugPrint('iCloud Sync: Skipping sync due to quota exceeded back-off');
      return;
    }

    _isSyncing = true;
    while (_pendingData != null) {
      final dataToSync = _pendingData!;
      _pendingData = null;
      await _performSync(dataToSync);
      // Small delay to let the native plugin settle between consecutive uploads
      await Future.delayed(const Duration(milliseconds: 500));

      // If a sync failed with quota error, stop the loop early
      if (_nextRetryTime != null && DateTime.now().isBefore(_nextRetryTime!)) {
        break;
      }
    }
    _isSyncing = false;
  }

  Future<void> _performSync(Map<String, dynamic> data) async {
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
      debugPrint('iCloud Sync: Uploaded successfully');
      _nextRetryTime = null; // Reset on success
      _settingsCubit.setICloudQuotaExceeded(false);
    } catch (e) {
      final errorStr = e.toString();
      debugPrint('iCloud Sync Error (Upload): $errorStr');

      if (errorStr.contains('Quota exceeded')) {
        debugPrint(
          'iCloud Sync: Quota exceeded detected. Backing off for 5 minutes.',
        );
        _nextRetryTime = DateTime.now().add(const Duration(minutes: 5));
        _settingsCubit.setICloudQuotaExceeded(true);
      }
    }
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
