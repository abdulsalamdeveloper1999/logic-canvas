import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logic_canvas/core/injection.dart';
import 'package:logic_canvas/data/services/backup_service.dart';
import 'package:logic_canvas/data/services/icloud_sync_service.dart';
import 'package:logic_canvas/domain/entities/board_snapshot.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_state.dart';
import 'package:logic_canvas/presentation/widgets/app_toast.dart';

/// Formats a timestamp without pulling in a date-formatting package.
String formatTimestamp(DateTime time) {
  final now = DateTime.now();
  final difference = now.difference(time);

  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    return '$hours ${hours == 1 ? "hour" : "hours"} ago';
  }
  if (difference.inDays < 7) {
    final days = difference.inDays;
    return '$days ${days == 1 ? "day" : "days"} ago';
  }

  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '${time.year}-$month-$day $hour:$minute';
}

/// Backup status, export/import, and the list of restorable versions.
///
/// Losing work was the app's worst failure, and it was invisible: iCloud
/// upload errors only reached a debug log. Everything here exists to make the
/// state of the user's backups impossible to miss and always recoverable.
class BackupRecoverySection extends StatefulWidget {
  const BackupRecoverySection({super.key});

  @override
  State<BackupRecoverySection> createState() => _BackupRecoverySectionState();
}

class _BackupRecoverySectionState extends State<BackupRecoverySection> {
  bool _busy = false;
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _loadLastSync();
  }

  Future<void> _loadLastSync() async {
    final time = await getIt<ICloudSyncService>().lastSuccessfulSync();
    if (mounted) setState(() => _lastSync = time);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() => _run(() async {
    final result = await context.read<DrawingCubit>().syncToCloud();
    if (!mounted) return;
    await _loadLastSync();
    if (!mounted) return;
    AppToast.show(
      context,
      message: result.message,
      duration: const Duration(seconds: 4),
    );
  });

  /// Downloading used to replace every local board with no warning and no way
  /// back. It now merges instead: boards missing from this device are copied
  /// down, and any board that already holds work is left exactly as it is, so
  /// downloading can never overwrite something you drew.
  Future<void> _download() => _run(() async {
    final cubit = context.read<DrawingCubit>();
    AppToast.show(
      context,
      message: 'Checking iCloud…',
      duration: const Duration(seconds: 2),
    );

    final cloud = await cubit.peekCloudSnapshot();
    if (!mounted) return;

    if (cloud == null) {
      AppToast.show(
        context,
        message: 'No iCloud backup was found. Nothing on this device changed.',
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Work out what the merge would do, so the dialog can say it plainly.
    final local = cubit.state;
    final cloudBoards = cloud.data['boards'];
    final incomingNames = cloudBoards is Map
        ? cloudBoards.keys.whereType<String>().toList()
        : <String>[];

    final toAdd = <String>[];
    final toFill = <String>[];
    final keep = <String>[];
    for (final name in incomingNames) {
      final existing = local.boards[name];
      final incomingCount = cloudBoards is Map && cloudBoards[name] is List
          ? (cloudBoards[name] as List).length
          : 0;
      if (existing == null) {
        toAdd.add(name);
      } else if (existing.isEmpty && incomingCount > 0) {
        toFill.add(name);
      } else {
        keep.add(name);
      }
    }

    if (toAdd.isEmpty && toFill.isEmpty) {
      AppToast.show(
        context,
        message: keep.length == 1
            ? 'That board is already on this device — nothing to download.'
            : 'All ${keep.length} boards are already on this device — nothing '
                  'to download.',
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _MergeBoardsDialog(
        toAdd: toAdd,
        toFill: toFill,
        keepCount: keep.length,
      ),
    );

    if (confirmed != true || !mounted) return;

    final outcome = await cubit.mergeRestoredState(
      cloud.data,
      reason: SnapshotReason.beforeCloudRestore,
    );
    if (!mounted) return;

    AppToast.show(
      context,
      message: outcome.message,
      duration: const Duration(seconds: 5),
    );
  });

  Future<void> _export() => _run(() async {
    final cubit = context.read<DrawingCubit>();
    await cubit.flushPendingSave();
    await getIt<BackupService>().shareBackup(cubit.exportState());
  });

  Future<void> _import() => _run(() async {
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => const _PasteBackupDialog(),
    );
    if (raw == null || !mounted) return;

    final parsed = BackupService.parseBackup(raw);
    if (parsed is BackupInvalid) {
      AppToast.show(
        context,
        message: parsed.message,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    final backup = parsed as BackupParsed;
    final cubit = context.read<DrawingCubit>();
    final localStrokes = cubit.state.boards.values.fold<int>(
      0,
      (sum, strokes) => sum + strokes.length,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ReplaceBoardsDialog(
        incomingSummary: backup.summary,
        currentSummary:
            '${cubit.state.boardIds.length} '
            '${cubit.state.boardIds.length == 1 ? "board" : "boards"} · '
            '$localStrokes strokes',
        losesWork: backup.strokeCount < localStrokes,
        source: 'this file',
      ),
    );
    if (confirmed != true || !mounted) return;

    final outcome = await cubit.applyRestoredState(
      backup.state,
      reason: SnapshotReason.beforeImport,
    );
    if (!mounted) return;
    AppToast.show(
      context,
      message: outcome.message,
      duration: const Duration(seconds: 4),
    );
  });

  Future<void> _openRestoreList() async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<DrawingCubit>(),
        child: const SnapshotRestoreSheet(),
      ),
    );

    if (message == null || !mounted) return;
    AppToast.show(
      context,
      message: message,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackupStatusCard(
              quotaExceeded: settings.isICloudQuotaExceeded,
              syncEnabled: settings.isICloudSyncEnabled,
              lastSync: _lastSync,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.upload_rounded,
                    label: 'UPLOAD',
                    onPressed: _busy || !settings.isICloudSyncEnabled
                        ? null
                        : _upload,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.download_rounded,
                    label: 'DOWNLOAD',
                    onPressed: _busy ? null : _download,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.ios_share_rounded,
                    label: 'EXPORT FILE',
                    onPressed: _busy ? null : _export,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.file_download_outlined,
                    label: 'IMPORT FILE',
                    onPressed: _busy ? null : _import,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _busy ? null : _openRestoreList,
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text(
                  'Restore a previous version',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Text(
              'Every time something replaces or clears your boards, a copy is '
              'saved here first.',
              style: TextStyle(
                fontSize: 10.5,
                height: 1.4,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BackupStatusCard extends StatelessWidget {
  final bool quotaExceeded;
  final bool syncEnabled;
  final DateTime? lastSync;

  const _BackupStatusCard({
    required this.quotaExceeded,
    required this.syncEnabled,
    this.lastSync,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // The loud case: iCloud is full, so backups are silently not happening.
    if (quotaExceeded) {
      return _StatusBox(
        color: const Color(0xFFD1483A),
        icon: Icons.cloud_off_rounded,
        title: 'iCloud is full — your boards are NOT backed up',
        body:
            'Free up iCloud space, or use Export File to save a copy '
            'somewhere safe right now.',
      );
    }

    if (!syncEnabled) {
      return _StatusBox(
        color: const Color(0xFFE0A11B),
        icon: Icons.cloud_queue_rounded,
        title: 'iCloud backup is off',
        body:
            'Your boards are saved on this device only. If you lose the '
            'device, you lose the work. Turn on iCloud Sync above, or export '
            'a backup file.',
      );
    }

    return _StatusBox(
      color: const Color(0xFF1E9E6A),
      icon: Icons.cloud_done_rounded,
      title: lastSync == null
          ? 'iCloud backup is on — nothing uploaded yet'
          : 'Last backed up ${formatTimestamp(lastSync!)}',
      body: lastSync == null
          ? 'Tap Upload to make your first backup.'
          : 'Tap Upload any time to save the latest version.',
      dim: true,
      textColor: scheme.onSurface,
    );
  }
}

class _StatusBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final bool dim;
  final Color? textColor;

  const _StatusBox({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    this.dim = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dim ? 0.07 : 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: dim ? 0.25 : 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor ?? color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: FittedBox(
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      ),
    );
  }
}

/// Shown before an iCloud download. The download only adds what is missing,
/// so this names the boards that will arrive and reassures that existing work
/// is left alone.
class _MergeBoardsDialog extends StatelessWidget {
  final List<String> toAdd;
  final List<String> toFill;
  final int keepCount;

  const _MergeBoardsDialog({
    required this.toAdd,
    required this.toFill,
    required this.keepCount,
  });

  static const int _maxNamesShown = 6;

  Widget _names(BuildContext context, List<String> names) {
    final scheme = Theme.of(context).colorScheme;
    final shown = names.take(_maxNamesShown).toList();
    final extra = names.length - shown.length;
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final name in shown)
            Text(
              '• $name',
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
            ),
          if (extra > 0)
            Text(
              '• …and $extra more',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Download from iCloud'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (toAdd.isNotEmpty) ...[
              Text(
                '${toAdd.length} '
                '${toAdd.length == 1 ? "board is" : "boards are"} in iCloud '
                'but not on this device:',
                style: TextStyle(fontSize: 13.5, color: scheme.onSurface),
              ),
              _names(context, toAdd),
              const SizedBox(height: 12),
            ],
            if (toFill.isNotEmpty) ...[
              Text(
                '${toFill.length} empty '
                '${toFill.length == 1 ? "board" : "boards"} here will be '
                'filled in from iCloud:',
                style: TextStyle(fontSize: 13.5, color: scheme.onSurface),
              ),
              _names(context, toFill),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E9E6A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                keepCount == 0
                    ? 'Nothing already on this device will be changed.'
                    : 'The $keepCount '
                          '${keepCount == 1 ? "board" : "boards"} you already '
                          'have will be left exactly as they are. Downloading '
                          'never overwrites your work.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            toAdd.isEmpty ? 'Fill in' : 'Add ${toAdd.length + toFill.length}',
          ),
        ),
      ],
    );
  }
}

/// Shown before anything replaces the user's boards.
class _ReplaceBoardsDialog extends StatelessWidget {
  final String incomingSummary;
  final String currentSummary;
  final bool losesWork;
  final String source;

  const _ReplaceBoardsDialog({
    required this.incomingSummary,
    required this.currentSummary,
    required this.losesWork,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Replace your boards?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompareRow(label: 'On this device now', value: currentSummary),
          const SizedBox(height: 8),
          _CompareRow(label: 'Coming from $source', value: incomingSummary),
          const SizedBox(height: 16),
          if (losesWork)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD1483A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'The version from $source has less work in it than what is on '
                'this device. Replacing will hide the extra work.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: scheme.onSurface,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'A copy of your current boards is saved first, so you can undo '
            'this from "Restore a previous version".',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Replace'),
        ),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String value;

  const _CompareRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _PasteBackupDialog extends StatefulWidget {
  const _PasteBackupDialog();

  @override
  State<_PasteBackupDialog> createState() => _PasteBackupDialogState();
}

class _PasteBackupDialogState extends State<_PasteBackupDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import a backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Open your backup file, copy everything in it, and paste it here.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 6,
            minLines: 4,
            style: const TextStyle(fontSize: 11, fontFamily: 'Menlo'),
            decoration: const InputDecoration(
              hintText: '{ "format": "logiccanvas.backup", … }',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              final text = data?.text;
              if (text != null) _controller.text = text;
            },
            icon: const Icon(Icons.content_paste_rounded, size: 16),
            label: const Text('Paste from clipboard'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

/// The list of recoverable versions.
class SnapshotRestoreSheet extends StatefulWidget {
  const SnapshotRestoreSheet({super.key});

  @override
  State<SnapshotRestoreSheet> createState() => _SnapshotRestoreSheetState();
}

class _SnapshotRestoreSheetState extends State<SnapshotRestoreSheet> {
  List<SnapshotMeta>? _snapshots;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<DrawingCubit>().listSnapshots();
    if (mounted) setState(() => _snapshots = list);
  }

  Future<void> _restore(SnapshotMeta meta) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore this version?'),
        content: Text(
          'This replaces your current boards with the version from '
          '${formatTimestamp(meta.createdAt)} (${meta.summary}).\n\n'
          'Your current boards are saved first, so you can come back here and '
          'undo it.',
          style: const TextStyle(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final outcome = await context.read<DrawingCubit>().restoreSnapshot(meta.id);
    if (!mounted) return;

    // Hand the message back to the caller: showing a toast from this context
    // after the sheet closes would look it up on a dead element.
    Navigator.of(context).pop(outcome.message);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final snapshots = _snapshots;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restore a previous version',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Saved automatically before anything replaces or clears your '
              'boards.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (snapshots == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'No saved versions yet. One is kept every time your boards '
                  'are about to be replaced or cleared.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: snapshots.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final meta = snapshots[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        formatTimestamp(meta.createdAt),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${meta.reason.label} · ${meta.summary}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: meta.isEmpty
                              ? const Color(0xFFD1483A)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => _restore(meta),
                        child: const Text('Restore'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
