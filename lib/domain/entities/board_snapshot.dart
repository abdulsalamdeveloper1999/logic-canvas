/// Why a snapshot was taken. Shown to the user in the restore list so they can
/// tell "the one before I hit Download" apart from routine saves.
enum SnapshotReason {
  beforeCloudRestore,
  beforeClear,
  beforeBoardDelete,
  beforeImport,
  manual,
  periodic,
}

extension SnapshotReasonX on SnapshotReason {
  String get label => switch (this) {
    SnapshotReason.beforeCloudRestore => 'Before iCloud restore',
    SnapshotReason.beforeClear => 'Before clearing board',
    SnapshotReason.beforeBoardDelete => 'Before deleting board',
    SnapshotReason.beforeImport => 'Before importing backup',
    SnapshotReason.manual => 'Manual backup',
    SnapshotReason.periodic => 'Automatic backup',
  };

  String get storageKey => name;

  static SnapshotReason fromStorageKey(String? key) {
    return SnapshotReason.values.firstWhere(
      (r) => r.name == key,
      orElse: () => SnapshotReason.periodic,
    );
  }
}

/// Lightweight description of a stored snapshot. The heavy board payload lives
/// under its own key so the restore list can be rendered without decoding it.
class SnapshotMeta {
  final String id;
  final DateTime createdAt;
  final SnapshotReason reason;
  final int boardCount;
  final int strokeCount;

  /// Content fingerprint, used to skip storing a snapshot identical to the
  /// previous one.
  final int contentHash;

  const SnapshotMeta({
    required this.id,
    required this.createdAt,
    required this.reason,
    required this.boardCount,
    required this.strokeCount,
    required this.contentHash,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'reason': reason.storageKey,
    'boardCount': boardCount,
    'strokeCount': strokeCount,
    'contentHash': contentHash,
  };

  factory SnapshotMeta.fromJson(Map<String, dynamic> json) {
    return SnapshotMeta(
      id: json['id'] as String,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      reason: SnapshotReasonX.fromStorageKey(json['reason'] as String?),
      boardCount: (json['boardCount'] as num?)?.toInt() ?? 0,
      strokeCount: (json['strokeCount'] as num?)?.toInt() ?? 0,
      contentHash: (json['contentHash'] as num?)?.toInt() ?? 0,
    );
  }

  /// "2 boards · 148 strokes"
  String get summary {
    final boards = boardCount == 1 ? '1 board' : '$boardCount boards';
    final strokes = strokeCount == 1 ? '1 stroke' : '$strokeCount strokes';
    return '$boards · $strokes';
  }

  /// True when this snapshot holds no drawn content at all. Restoring one of
  /// these would wipe the user's work, so the UI warns before offering it.
  bool get isEmpty => strokeCount == 0;
}
