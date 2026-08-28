import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:logic_canvas/domain/entities/board_snapshot.dart';

/// Keeps a rolling history of whole-app board states so that no destructive
/// action is final. Snapshots are written before anything that replaces or
/// erases boards, and the newest [maxSnapshots] are retained.
@lazySingleton
class SnapshotService {
  static const String boxName = 'snapshots';
  static const String indexKey = '__snapshot_index__';
  static const int maxSnapshots = 20;

  static String payloadKey(String id) => 'snap::$id';

  Box? _testBox;

  /// Test seam: lets unit tests inject an already-open box.
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  void useBoxForTesting(Box box) => _testBox = box;

  Future<Box> _box() async => _testBox ?? await Hive.openBox(boxName);

  /// Counts boards and strokes in a `DrawingState.toJson()` payload.
  /// Tolerates malformed input rather than throwing — a snapshot summary is
  /// never worth crashing a save path over.
  static ({int boardCount, int strokeCount}) summarize(
    Map<String, dynamic> state,
  ) {
    final boards = state['boards'];
    if (boards is! Map) return (boardCount: 0, strokeCount: 0);

    var strokes = 0;
    for (final value in boards.values) {
      if (value is List) strokes += value.length;
    }
    return (boardCount: boards.length, strokeCount: strokes);
  }

  /// Stable fingerprint of a state payload, used to skip consecutive
  /// duplicate snapshots.
  static int fingerprint(Map<String, dynamic> state) {
    return jsonEncode(state).hashCode;
  }

  /// Returns the metas to keep, newest first, capped at [max].
  static List<SnapshotMeta> prune(List<SnapshotMeta> metas, int max) {
    final sorted = List<SnapshotMeta>.from(metas)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (sorted.length <= max) return sorted;
    return sorted.sublist(0, max);
  }

  Future<List<SnapshotMeta>> list() async {
    final box = await _box();
    final raw = box.get(indexKey);
    if (raw is! String) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => SnapshotMeta.fromJson(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('SnapshotService: corrupt index, ignoring ($e)');
      return const [];
    }
  }

  /// Stores [state] as a new snapshot. Returns the meta that was written, or
  /// null when the snapshot was skipped (identical to the previous one).
  ///
  /// [now] is injectable so tests can produce distinct, ordered timestamps.
  Future<SnapshotMeta?> capture(
    Map<String, dynamic> state, {
    required SnapshotReason reason,
    DateTime? now,
  }) async {
    final box = await _box();
    final timestamp = now ?? DateTime.now();
    final hash = fingerprint(state);

    final existing = await list();
    if (existing.isNotEmpty && existing.first.contentHash == hash) {
      return null;
    }

    final counts = summarize(state);
    final meta = SnapshotMeta(
      id: '${timestamp.microsecondsSinceEpoch}',
      createdAt: timestamp,
      reason: reason,
      boardCount: counts.boardCount,
      strokeCount: counts.strokeCount,
      contentHash: hash,
    );

    await box.put(payloadKey(meta.id), jsonEncode(state));

    final kept = prune([meta, ...existing], maxSnapshots);
    final keptIds = kept.map((m) => m.id).toSet();
    for (final dropped in existing.where((m) => !keptIds.contains(m.id))) {
      await box.delete(payloadKey(dropped.id));
    }

    await box.put(indexKey, jsonEncode(kept.map((m) => m.toJson()).toList()));
    return meta;
  }

  /// Reads back a stored snapshot payload, or null if it is missing/corrupt.
  Future<Map<String, dynamic>?> restore(String id) async {
    final box = await _box();
    final raw = box.get(payloadKey(id));
    if (raw is! String) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint('SnapshotService: corrupt snapshot $id ($e)');
      return null;
    }
  }

  Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(payloadKey(id));
    final remaining = (await list()).where((m) => m.id != id).toList();
    await box.put(
      indexKey,
      jsonEncode(remaining.map((m) => m.toJson()).toList()),
    );
  }
}
