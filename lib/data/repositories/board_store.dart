import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';

/// Result of reading all boards back from disk.
class LoadedBoards {
  final Map<String, List<Stroke>> boards;
  final List<String> boardIds;
  final String activeBoardId;
  final Map<String, String?> boardProblems;

  /// Boards whose payload could not be decoded. They are reported rather than
  /// silently dropped so the user can be told which board was damaged instead
  /// of finding it missing.
  final List<String> failedBoardIds;

  final bool migratedFromLegacy;

  const LoadedBoards({
    required this.boards,
    required this.boardIds,
    required this.activeBoardId,
    required this.boardProblems,
    this.failedBoardIds = const [],
    this.migratedFromLegacy = false,
  });
}

/// Persists each board under its own key, with a small index describing the
/// board list. Replaces the previous design where every board lived inside a
/// single JSON blob — there, one bad write lost everything at once.
///
/// The legacy blob is never deleted: it stays on disk as a last-resort backup.
@lazySingleton
class BoardStore {
  static const String boxName = 'drawing_v3';
  static const String indexKey = '__board_index__';
  static const String legacyStateKey = 'drawing_state_v2';
  static const int schemaVersion = 4;
  static const String fallbackBoardId = 'Board 1';

  static String boardKey(String id) => 'board::$id';

  Box? _testBox;

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  void useBoxForTesting(Box box) => _testBox = box;

  Future<Box> _box() async => _testBox ?? await Hive.openBox(boxName);

  static List<Stroke> _decodeStrokes(Object? raw) {
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((s) => Stroke.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }

  static String _encodeStrokes(List<Stroke> strokes) {
    return jsonEncode(strokes.map((s) => s.toJson()).toList());
  }

  Future<LoadedBoards?> load() async {
    final box = await _box();
    final rawIndex = box.get(indexKey);

    if (rawIndex is String) {
      return _loadFromIndex(box, rawIndex);
    }

    final legacy = box.get(legacyStateKey);
    if (legacy != null) {
      return _migrateFromLegacy(box, legacy);
    }

    return null;
  }

  Future<LoadedBoards> _loadFromIndex(Box box, String rawIndex) async {
    Map<String, dynamic> index;
    try {
      index = Map<String, dynamic>.from(jsonDecode(rawIndex) as Map);
    } catch (e) {
      debugPrint('BoardStore: corrupt index ($e), falling back to legacy blob');
      final legacy = box.get(legacyStateKey);
      if (legacy != null) return _migrateFromLegacy(box, legacy);
      return const LoadedBoards(
        boards: {fallbackBoardId: []},
        boardIds: [fallbackBoardId],
        activeBoardId: fallbackBoardId,
        boardProblems: {},
      );
    }

    final boardIds = (index['boardIds'] as List? ?? const [])
        .whereType<String>()
        .toList();
    final boardProblems = <String, String?>{};
    final rawProblems = index['boardProblems'];
    if (rawProblems is Map) {
      rawProblems.forEach((key, value) {
        if (key is String) boardProblems[key] = value as String?;
      });
    }

    final boards = <String, List<Stroke>>{};
    final failed = <String>[];

    for (final id in boardIds) {
      try {
        boards[id] = _decodeStrokes(box.get(boardKey(id)));
      } catch (e) {
        debugPrint('BoardStore: board "$id" failed to decode ($e)');
        failed.add(id);
        boards[id] = const [];
      }
    }

    if (boardIds.isEmpty) {
      boards[fallbackBoardId] = const [];
      boardIds.add(fallbackBoardId);
    }

    final storedActive = index['activeBoardId'] as String?;
    final activeBoardId = boardIds.contains(storedActive)
        ? storedActive!
        : boardIds.first;

    return LoadedBoards(
      boards: boards,
      boardIds: boardIds,
      activeBoardId: activeBoardId,
      boardProblems: boardProblems,
      failedBoardIds: failed,
    );
  }

  Future<LoadedBoards> _migrateFromLegacy(Box box, Object legacy) async {
    final data = Map<String, dynamic>.from(legacy as Map);

    final boards = <String, List<Stroke>>{};
    final failed = <String>[];
    final rawBoards = data['boards'];
    if (rawBoards is Map) {
      rawBoards.forEach((key, value) {
        if (key is! String) return;
        try {
          boards[key] = _decodeStrokes(value);
        } catch (e) {
          debugPrint('BoardStore: legacy board "$key" failed to decode ($e)');
          failed.add(key);
          boards[key] = const [];
        }
      });
    }

    final boardIds = (data['boardIds'] as List? ?? const [])
        .whereType<String>()
        .toList();
    for (final id in boards.keys) {
      if (!boardIds.contains(id)) boardIds.add(id);
    }
    if (boardIds.isEmpty) {
      boardIds.add(fallbackBoardId);
      boards[fallbackBoardId] = const [];
    }

    final boardProblems = <String, String?>{};
    final rawProblems = data['boardProblems'];
    if (rawProblems is Map) {
      rawProblems.forEach((key, value) {
        if (key is String) boardProblems[key] = value as String?;
      });
    }

    final storedActive = data['activeBoardId'] as String?;
    final activeBoardId = boardIds.contains(storedActive)
        ? storedActive!
        : boardIds.first;

    final loaded = LoadedBoards(
      boards: boards,
      boardIds: boardIds,
      activeBoardId: activeBoardId,
      boardProblems: boardProblems,
      failedBoardIds: failed,
      migratedFromLegacy: true,
    );

    // Write the new layout. The legacy blob is intentionally left in place.
    await saveAll(loaded);
    return loaded;
  }

  Future<void> saveAll(LoadedBoards data) async {
    final box = await _box();
    for (final id in data.boardIds) {
      await box.put(boardKey(id), _encodeStrokes(data.boards[id] ?? const []));
    }
    await saveIndex(
      boardIds: data.boardIds,
      activeBoardId: data.activeBoardId,
      boardProblems: data.boardProblems,
    );
  }

  Future<void> saveIndex({
    required List<String> boardIds,
    required String activeBoardId,
    required Map<String, String?> boardProblems,
  }) async {
    final box = await _box();
    await box.put(
      indexKey,
      jsonEncode({
        'version': schemaVersion,
        'boardIds': boardIds,
        'activeBoardId': activeBoardId,
        'boardProblems': boardProblems,
      }),
    );
  }

  Future<void> saveBoard(String id, List<Stroke> strokes) async {
    final box = await _box();
    await box.put(boardKey(id), _encodeStrokes(strokes));
  }

  Future<void> deleteBoard(String id) async {
    final box = await _box();
    await box.delete(boardKey(id));
  }

  Future<void> renameBoard(String oldId, String newId) async {
    final box = await _box();
    final payload = box.get(boardKey(oldId));
    if (payload != null) await box.put(boardKey(newId), payload);
    await box.delete(boardKey(oldId));
  }
}
