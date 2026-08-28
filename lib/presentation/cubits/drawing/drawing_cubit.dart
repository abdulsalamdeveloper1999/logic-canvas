import 'package:logic_canvas/domain/entities/problem.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logic_canvas/domain/entities/board_snapshot.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_state.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logic_canvas/data/repositories/board_store.dart';
import 'package:logic_canvas/data/services/handwriting_service.dart';
import 'package:logic_canvas/data/services/ml_shape_service.dart';
import 'package:logic_canvas/data/services/icloud_sync_service.dart';
import 'package:logic_canvas/data/services/snapshot_service.dart';

/// What happened when the user asked to replace their boards from a backup.
class RestoreOutcome {
  final bool applied;
  final String message;
  const RestoreOutcome(this.applied, this.message);
}

/// Result of merging a cloud copy into the local boards without overwriting
/// anything the user has already drawn.
class MergeOutcome {
  final bool applied;

  /// Boards that existed only in the cloud and were copied down.
  final int added;

  /// Boards that existed locally but were empty, so the cloud version filled
  /// them in. Nothing was lost, because there was nothing there.
  final int filled;

  /// Boards left exactly as they are, because they already hold work.
  final int skipped;

  final String message;

  const MergeOutcome({
    required this.applied,
    required this.added,
    required this.filled,
    required this.skipped,
    required this.message,
  });
}

/// Strokes added by a single action, which have to undo as a single action.
///
/// The AI's "Write to Board" drops one text stroke per paragraph. Undo used to
/// peel those off one at a time, so a four-paragraph answer needed four presses
/// and left most of itself on the board in between.
class _StrokeBatch {
  const _StrokeBatch(this.boardId, this.strokes);

  final String boardId;
  final List<Stroke> strokes;
}

@injectable
class DrawingCubit extends Cubit<DrawingState> {
  /// Kept for the Hive box name so existing installs open the same box.
  static const String boxName = BoardStore.boxName;

  final HandwritingRecognitionService _handwritingService;
  final MLShapeService _mlShapeService;
  final ICloudSyncService _icloudSyncService;
  final BoardStore _boardStore;
  final SnapshotService _snapshotService;

  Timer? _recognitionTimer;
  Timer? _saveTimer;
  final List<int> _pendingStrokeIndices = [];

  /// The board the pending handwriting indices belong to. Those indices are
  /// positions in one board's stroke list, so they are meaningless anywhere
  /// else.
  String? _pendingRecognitionBoardId;

  /// Batches still undoable as one action, oldest first. Session-only, like
  /// the redo stack: neither is written to disk.
  final List<_StrokeBatch> _undoBatches = [];
  final List<_StrokeBatch> _redoBatches = [];
  static const int _maxTrackedBatches = 20;

  /// Boards changed since the last write. Only these are re-encoded, so a save
  /// costs one board instead of the whole app state.
  final Set<String> _dirtyBoards = {};
  bool _indexDirty = false;

  bool _isSyncEnabled = false;

  /// The launch-time safety snapshot, awaited on close so no write is left in
  /// flight after the cubit goes away.
  Future<void>? _launchSnapshot;

  DrawingCubit(
    this._handwritingService,
    this._mlShapeService,
    this._icloudSyncService,
    this._boardStore,
    this._snapshotService,
  ) : super(DrawingState.initial()) {
    _loadState();
  }

  Future<void> _loadState() async {
    final settingsBox = await Hive.openBox('settings');
    final settingsMap = settingsBox.get('user_settings');
    if (settingsMap != null) {
      _isSyncEnabled = settingsMap['isICloudSyncEnabled'] as bool? ?? false;
    }

    LoadedBoards? loaded;
    try {
      loaded = await _boardStore.load();
    } catch (e) {
      debugPrint('DrawingCubit: board load failed ($e)');
    }

    if (isClosed) return;

    if (loaded == null) {
      emit(state.copyWith(isLoaded: true));
      return;
    }

    emit(
      state.copyWith(
        boards: loaded.boards,
        activeBoardId: loaded.activeBoardId,
        boardIds: loaded.boardIds,
        boardProblems: loaded.boardProblems,
        damagedBoardIds: loaded.failedBoardIds,
        redoStack: [],
        isLoaded: true,
      ),
    );

    // A safety net taken at launch, before the user can destroy anything.
    // Deliberately not awaited so startup is not blocked, but tracked so
    // close() can wait for it rather than leaving a write in flight.
    _launchSnapshot = _snapshotService.capture(
      state.toJson(),
      reason: SnapshotReason.periodic,
    );
    unawaited(_launchSnapshot!);
  }

  // ------------------------------------------------------------- persistence

  void _markDirty({String? boardId, bool index = false}) {
    _dirtyBoards.add(boardId ?? state.activeBoardId);
    if (index) _indexDirty = true;
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), _performSave);
  }

  Future<void> _performSave() async {
    final boardsToWrite = Set<String>.from(_dirtyBoards);
    final writeIndex = _indexDirty;
    _dirtyBoards.clear();
    _indexDirty = false;

    try {
      for (final id in boardsToWrite) {
        final strokes = state.boards[id];
        if (strokes == null) continue;
        await _boardStore.saveBoard(id, strokes);
      }
      if (writeIndex || boardsToWrite.isNotEmpty) {
        await _boardStore.saveIndex(
          boardIds: state.boardIds,
          activeBoardId: state.activeBoardId,
          boardProblems: state.boardProblems,
        );
      }
    } catch (e) {
      // Put the work back so the next save retries it rather than losing it.
      _dirtyBoards.addAll(boardsToWrite);
      _indexDirty = _indexDirty || writeIndex;
      debugPrint('DrawingCubit: save failed, will retry ($e)');
    }
  }

  /// Flushes any pending write immediately. Called before backup and sync so
  /// what leaves the device matches what is on screen.
  Future<void> flushPendingSave() async {
    _saveTimer?.cancel();
    await _performSave();
  }

  void persistState() => _markDirty();

  void setSyncEnabled(bool enabled) {
    _isSyncEnabled = enabled;
  }

  // ------------------------------------------------------------ backup paths

  Map<String, dynamic> exportState() => state.toJson();

  Future<List<SnapshotMeta>> listSnapshots() => _snapshotService.list();

  Future<SnapshotMeta?> captureSnapshot({
    SnapshotReason reason = SnapshotReason.manual,
  }) {
    return _snapshotService.capture(state.toJson(), reason: reason);
  }

  Future<SyncResult> syncToCloud() async {
    if (!_isSyncEnabled) {
      return const SyncResult(
        SyncOutcome.failed,
        'Turn on iCloud sync in Settings first.',
      );
    }
    await flushPendingSave();
    return _icloudSyncService.syncToCloud(state.toJson());
  }

  /// Looks at what is in iCloud without changing anything locally, so the user
  /// can be shown what a restore would replace.
  Future<CloudSnapshotInfo?> peekCloudSnapshot() {
    return _icloudSyncService.peekCloudSnapshot();
  }

  /// Replaces local boards with [data]. Always snapshots first, so this is
  /// undoable — the previous behaviour overwrote everything with no way back.
  /// Decodes the board map from a cloud/backup payload, or null if unreadable.
  Map<String, List<Stroke>>? _decodeBoards(Map<String, dynamic> data) {
    try {
      final boards = <String, List<Stroke>>{};
      final stored = Map<String, dynamic>.from(data['boards'] ?? {});
      stored.forEach((key, value) {
        boards[key] = (value as List)
            .map((s) => Stroke.fromJson(Map<String, dynamic>.from(s)))
            .toList();
      });
      return boards;
    } catch (e) {
      debugPrint('DrawingCubit: could not decode boards ($e)');
      return null;
    }
  }

  /// Copies down only what is missing. A board that already holds work is left
  /// untouched, so downloading can never overwrite something you drew — which
  /// is what the plain replace-everything download used to do.
  ///
  /// A local board that is empty is filled from the cloud, since there is no
  /// work there to lose.
  Future<MergeOutcome> mergeRestoredState(
    Map<String, dynamic> data, {
    required SnapshotReason reason,
  }) async {
    _cancelPendingRecognition();
    final incoming = _decodeBoards(data);
    if (incoming == null) {
      return const MergeOutcome(
        applied: false,
        added: 0,
        filled: 0,
        skipped: 0,
        message: 'That backup could not be read, so nothing was changed.',
      );
    }
    if (incoming.isEmpty) {
      return const MergeOutcome(
        applied: false,
        added: 0,
        filled: 0,
        skipped: 0,
        message: 'That backup has no boards in it, so nothing was changed.',
      );
    }

    final toAdd = <String>[];
    final toFill = <String>[];
    var skipped = 0;

    incoming.forEach((id, strokes) {
      final local = state.boards[id];
      if (local == null) {
        toAdd.add(id);
      } else if (local.isEmpty && strokes.isNotEmpty) {
        toFill.add(id);
      } else {
        skipped++;
      }
    });

    if (toAdd.isEmpty && toFill.isEmpty) {
      return MergeOutcome(
        applied: false,
        added: 0,
        filled: 0,
        skipped: skipped,
        message: skipped == 1
            ? 'That board is already on this device, so nothing changed.'
            : 'All $skipped boards are already on this device, so nothing '
                  'changed.',
      );
    }

    await _snapshotService.capture(state.toJson(), reason: reason);

    final boards = Map<String, List<Stroke>>.from(state.boards);
    final boardIds = List<String>.from(state.boardIds);
    final problems = Map<String, String?>.from(state.boardProblems);
    final incomingProblems = Map<String, String?>.from(
      data['boardProblems'] ?? {},
    );

    for (final id in [...toAdd, ...toFill]) {
      boards[id] = incoming[id]!;
      if (!boardIds.contains(id)) boardIds.add(id);
      if (incomingProblems.containsKey(id)) {
        problems[id] = incomingProblems[id];
      }
    }

    emit(
      state.copyWith(
        boards: boards,
        boardIds: boardIds,
        boardProblems: problems,
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );

    _dirtyBoards.addAll([...toAdd, ...toFill]);
    _indexDirty = true;
    await flushPendingSave();

    final parts = <String>[];
    if (toAdd.isNotEmpty) {
      parts.add(
        'added ${toAdd.length} new '
        '${toAdd.length == 1 ? "board" : "boards"}',
      );
    }
    if (toFill.isNotEmpty) {
      parts.add(
        'filled ${toFill.length} empty '
        '${toFill.length == 1 ? "board" : "boards"}',
      );
    }
    if (skipped > 0) {
      parts.add('kept $skipped already here');
    }

    final summary = parts.join(', ');
    return MergeOutcome(
      applied: true,
      added: toAdd.length,
      filled: toFill.length,
      skipped: skipped,
      message:
          'Downloaded from iCloud — ${summary.isEmpty ? "nothing to do" : summary}.',
    );
  }

  Future<RestoreOutcome> applyRestoredState(
    Map<String, dynamic> data, {
    required SnapshotReason reason,
  }) async {
    await _snapshotService.capture(state.toJson(), reason: reason);

    final Map<String, List<Stroke>> boards = {};
    try {
      final storedBoards = Map<String, dynamic>.from(data['boards'] ?? {});
      storedBoards.forEach((key, value) {
        boards[key] = (value as List)
            .map((s) => Stroke.fromJson(Map<String, dynamic>.from(s)))
            .toList();
      });
    } catch (e) {
      return RestoreOutcome(
        false,
        'That backup could not be read, so nothing was changed. ($e)',
      );
    }

    if (boards.isEmpty) {
      return const RestoreOutcome(
        false,
        'That backup has no boards in it, so nothing was changed.',
      );
    }

    final boardIds = List<String>.from(
      data['boardIds'] ?? boards.keys.toList(),
    );
    for (final id in boards.keys) {
      if (!boardIds.contains(id)) boardIds.add(id);
    }
    final storedActive = data['activeBoardId'] as String?;
    final activeBoardId = boardIds.contains(storedActive)
        ? storedActive!
        : boardIds.first;
    final boardProblems = Map<String, String?>.from(
      data['boardProblems'] ?? {},
    );

    emit(
      state.copyWith(
        boards: boards,
        activeBoardId: activeBoardId,
        boardIds: boardIds,
        boardProblems: boardProblems,
        damagedBoardIds: const [],
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );

    _dirtyBoards.addAll(boardIds);
    _indexDirty = true;
    await flushPendingSave();

    final strokeCount = boards.values.fold<int>(0, (a, b) => a + b.length);
    return RestoreOutcome(
      true,
      'Restored ${boardIds.length} '
      '${boardIds.length == 1 ? "board" : "boards"} · $strokeCount strokes.',
    );
  }

  Future<RestoreOutcome> restoreSnapshot(String snapshotId) async {
    final data = await _snapshotService.restore(snapshotId);
    if (data == null) {
      return const RestoreOutcome(
        false,
        'That backup could not be found on this device.',
      );
    }
    return applyRestoredState(data, reason: SnapshotReason.beforeCloudRestore);
  }

  // --------------------------------------------------------- board management

  void createNewBoard(String name) {
    if (state.boardIds.contains(name)) return;

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[name] = [];

    final updatedBoardProblems = Map<String, String?>.from(state.boardProblems);
    updatedBoardProblems[name] = null;

    emit(
      state.copyWith(
        boards: updatedBoards,
        boardIds: List.from(state.boardIds)..add(name),
        boardProblems: updatedBoardProblems,
        activeBoardId: name,
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );
    _markDirty(boardId: name, index: true);
  }

  void createNewBoardFromTemplate(Problem problem, Color textColor) {
    final existingBoardId = state.boardProblems.entries
        .firstWhere(
          (e) => e.value == problem.id,
          orElse: () => const MapEntry('', null),
        )
        .key;

    if (existingBoardId.isNotEmpty) {
      switchToBoard(existingBoardId);
      return;
    }

    String name = problem.title;
    int count = 1;
    String baseName = name;
    while (state.boardIds.contains(name)) {
      name = '$baseName ($count)';
      count++;
    }

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);

    final descriptionStroke = Stroke(
      points: [const Offset(100, 100)],
      color: textColor,
      strokeWidth: 2.0,
      type: StrokeType.text,
      text:
          '${problem.title}\n\n${problem.difficulty.name.toUpperCase()} | ${problem.category}\n\n${problem.description}',
    );

    updatedBoards[name] = [descriptionStroke];

    final updatedBoardProblems = Map<String, String?>.from(state.boardProblems);
    updatedBoardProblems[name] = problem.id;

    emit(
      state.copyWith(
        boards: updatedBoards,
        boardIds: List.from(state.boardIds)..add(name),
        boardProblems: updatedBoardProblems,
        activeBoardId: name,
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );
    _markDirty(boardId: name, index: true);
  }

  void switchToBoard(String boardId) {
    if (boardId == state.activeBoardId) return;
    _cancelPendingRecognition();
    emit(
      state.copyWith(
        activeBoardId: boardId,
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );
    _indexDirty = true;
    _scheduleSave();
  }

  Future<void> deleteBoard(String boardId) async {
    if (state.boardIds.length <= 1) return;

    final strokes = state.boards[boardId] ?? const [];
    if (strokes.isNotEmpty) {
      await _snapshotService.capture(
        state.toJson(),
        reason: SnapshotReason.beforeBoardDelete,
      );
    }

    final updatedBoardIds = List<String>.from(state.boardIds)..remove(boardId);
    final updatedBoards = Map<String, List<Stroke>>.from(state.boards)
      ..remove(boardId);

    String nextActiveId = state.activeBoardId;
    if (state.activeBoardId == boardId) {
      nextActiveId = updatedBoardIds.first;
    }

    emit(
      state.copyWith(
        boards: updatedBoards,
        boardIds: updatedBoardIds,
        activeBoardId: nextActiveId,
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );

    await _boardStore.deleteBoard(boardId);
    _indexDirty = true;
    _scheduleSave();
  }

  Future<void> renameBoard(String oldId, String newId) async {
    if (oldId == newId || newId.trim().isEmpty) return;
    if (state.boardIds.contains(newId)) return;

    final updatedBoardIds = state.boardIds
        .map((id) => id == oldId ? newId : id)
        .toList();

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    final strokes = updatedBoards.remove(oldId);
    if (strokes != null) {
      updatedBoards[newId] = strokes;
    }

    final updatedBoardProblems = Map<String, String?>.from(state.boardProblems);
    final problemId = updatedBoardProblems.remove(oldId);
    updatedBoardProblems[newId] = problemId;

    String nextActiveId = state.activeBoardId;
    if (state.activeBoardId == oldId) {
      nextActiveId = newId;
    }

    emit(
      state.copyWith(
        boardIds: updatedBoardIds,
        boards: updatedBoards,
        boardProblems: updatedBoardProblems,
        activeBoardId: nextActiveId,
      ),
    );

    await _boardStore.renameBoard(oldId, newId);
    _markDirty(boardId: newId, index: true);
  }

  // ---------------------------------------------------------- drawing actions

  List<Stroke> get activeStrokes => state.boards[state.activeBoardId] ?? [];

  void setDrawing(bool isDrawing) {
    emit(state.copyWith(isDrawing: isDrawing));
  }

  void addStroke(Stroke stroke) {
    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = List.from(activeStrokes)..add(stroke);

    emit(
      state.copyWith(
        boards: updatedBoards,
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );
    _markDirty();
  }

  /// Adds [strokes] as one action, so a single undo takes all of them back.
  void addStrokes(List<Stroke> strokes) {
    if (strokes.isEmpty) return;
    if (strokes.length == 1) {
      addStroke(strokes.first);
      return;
    }

    final updated = List<Stroke>.from(activeStrokes)..addAll(strokes);
    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = updated;

    _redoBatches.clear();
    _undoBatches.add(_StrokeBatch(state.activeBoardId, List.of(strokes)));
    if (_undoBatches.length > _maxTrackedBatches) _undoBatches.removeAt(0);

    emit(
      state.copyWith(
        boards: updatedBoards,
        redoStack: const [],
        selectedStrokeIndex: null,
      ),
    );
    _markDirty();
  }

  /// The batch sitting on top of [strokes], if the board still ends with
  /// exactly the strokes that batch added.
  ///
  /// Identity, not position: recognition and shape detection rewrite strokes in
  /// place, and a rewritten stroke is no longer the one the batch added, so the
  /// batch stops counting as a unit rather than swallowing something else.
  _StrokeBatch? _batchOnTopOf(
    List<Stroke> strokes,
    List<_StrokeBatch> batches,
  ) {
    if (batches.isEmpty) return null;
    final batch = batches.last;
    if (batch.boardId != state.activeBoardId) return null;
    if (batch.strokes.length > strokes.length) return null;

    final offset = strokes.length - batch.strokes.length;
    for (var i = 0; i < batch.strokes.length; i++) {
      if (!identical(strokes[offset + i], batch.strokes[i])) return null;
    }
    return batch;
  }

  void selectStroke(int? index) {
    emit(state.copyWith(selectedStrokeIndex: index));
  }

  void updateStrokeTransform({int? index, double? scale, double? rotation}) {
    final idx = index ?? state.selectedStrokeIndex;
    if (idx == null) return;

    final strokes = List<Stroke>.from(activeStrokes);
    if (idx < 0 || idx >= strokes.length) return;

    var stroke = strokes[idx];
    if (scale != null) stroke = stroke.copyWith(scale: scale);
    if (rotation != null) stroke = stroke.copyWith(rotation: rotation);

    strokes[idx] = stroke;

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = strokes;

    emit(state.copyWith(boards: updatedBoards));
  }

  void updateStrokeAt(int index, Stroke stroke) {
    var strokes = List<Stroke>.from(activeStrokes);
    if (index < 0 || index >= strokes.length) return;
    strokes[index] = stroke;

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = strokes;

    emit(state.copyWith(boards: updatedBoards));
  }

  void moveStrokesBy(Set<int> indices, Offset delta) {
    if (indices.isEmpty || delta == Offset.zero) return;

    final strokes = List<Stroke>.from(activeStrokes);
    var didMove = false;

    for (final index in indices) {
      if (index < 0 || index >= strokes.length) continue;

      final stroke = strokes[index];
      strokes[index] = stroke.copyWith(
        points: stroke.points.map((point) => point + delta).toList(),
      );
      didMove = true;
    }

    if (!didMove) return;

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = strokes;

    emit(
      state.copyWith(
        boards: updatedBoards,
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );
  }

  void removeStrokeAt(int index) {
    final strokes = List<Stroke>.from(activeStrokes);
    if (index < 0 || index >= strokes.length) return;

    strokes.removeAt(index);
    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = strokes;

    emit(
      state.copyWith(
        boards: updatedBoards,
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );
    _markDirty();
  }

  void startStroke() {
    if (state.isDrawing) return;
    _recognitionTimer?.cancel();
    // Deliberately does NOT clear the redo stack. This fires on pointer-down,
    // so clearing here threw redo away the moment the canvas was touched at
    // all — including a pan, a stray finger, or a tap that never became a
    // stroke. Redo is only invalidated once a new stroke is actually
    // committed, which is handled in endStroke and addStroke.
    emit(state.copyWith(isDrawing: true, selectedStrokeIndex: null));
  }

  Future<void> endStroke(
    Stroke? stroke,
    bool enableShapeDetection, {
    bool enableHandwriting = false,
  }) async {
    if (!state.isDrawing) return;

    if (stroke == null) {
      emit(state.copyWith(isDrawing: false));
      return;
    }

    final updatedStrokes = List<Stroke>.from(activeStrokes);
    final lastIdx = updatedStrokes.length;
    updatedStrokes.add(stroke);

    if (enableHandwriting && !stroke.isEraser) {
      _pendingStrokeIndices.add(lastIdx);

      final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
      updatedBoards[state.activeBoardId] = updatedStrokes;
      // A new stroke invalidates anything that was undone.
      emit(
        state.copyWith(
          boards: updatedBoards,
          isDrawing: false,
          redoStack: const [],
        ),
      );
      _markDirty();

      _recognitionTimer?.cancel();
      _pendingRecognitionBoardId = state.activeBoardId;
      _recognitionTimer = Timer(const Duration(milliseconds: 800), () async {
        await _processHandwriting();
      });
      return;
    }

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = updatedStrokes;
    emit(
      state.copyWith(
        boards: updatedBoards,
        isDrawing: false,
        redoStack: const [],
      ),
    );
    _markDirty();

    if (enableShapeDetection && !stroke.isEraser && stroke.points.length > 10) {
      unawaited(_processShapeDetection(lastIdx, stroke));
    }
  }

  Future<void> _processShapeDetection(int strokeIndex, Stroke stroke) async {
    final detectedType = await _mlShapeService.detectShape(stroke.points);
    if (detectedType == StrokeType.pen || isClosed) return;

    final strokes = List<Stroke>.from(activeStrokes);
    if (strokeIndex < 0 || strokeIndex >= strokes.length) return;
    if (!identical(strokes[strokeIndex], stroke) &&
        strokes[strokeIndex] != stroke) {
      return;
    }

    strokes[strokeIndex] = stroke.copyWith(type: detectedType);
    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = strokes;
    emit(state.copyWith(boards: updatedBoards));
    _markDirty();
  }

  Future<void> _processHandwriting() async {
    if (_pendingStrokeIndices.isEmpty) return;
    if (_pendingRecognitionBoardId != state.activeBoardId) {
      _cancelPendingRecognition();
      return;
    }

    final List<List<Offset>> multiStrokes = [];
    final List<Stroke> strokesToConvert = [];
    final currentStrokes = activeStrokes;

    _pendingStrokeIndices.sort();
    for (final idx in _pendingStrokeIndices) {
      if (idx < currentStrokes.length) {
        final s = currentStrokes[idx];
        multiStrokes.add(s.points);
        strokesToConvert.add(s);
      }
    }

    if (multiStrokes.isNotEmpty) {
      final text = await _handwritingService.recognize(multiStrokes);
      // recognize() is slow, so the user may have undone or switched boards
      // while it ran. Applying the result now would fight their action.
      final stillValid =
          _pendingStrokeIndices.isNotEmpty &&
          _pendingRecognitionBoardId == state.activeBoardId;
      if (text != null && text.trim().isNotEmpty && !isClosed && stillValid) {
        final updatedStrokes = List<Stroke>.from(activeStrokes);
        final insertionIndex = _pendingStrokeIndices.reduce(math.min);
        final sortedIndices = List<int>.from(_pendingStrokeIndices)
          ..sort((a, b) => b.compareTo(a));
        for (final idx in sortedIndices) {
          if (idx < updatedStrokes.length) updatedStrokes.removeAt(idx);
        }

        final allPoints = multiStrokes.expand((e) => e).toList();
        final textStroke = Stroke(
          points: allPoints,
          color: strokesToConvert.first.color,
          strokeWidth: strokesToConvert.first.strokeWidth,
          type: StrokeType.text,
          text: text,
        );

        updatedStrokes.insert(
          insertionIndex.clamp(0, updatedStrokes.length),
          textStroke,
        );
        final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
        updatedBoards[state.activeBoardId] = updatedStrokes;
        emit(state.copyWith(boards: updatedBoards));
        _markDirty();
      }
    }
    _pendingStrokeIndices.clear();
  }

  /// Drops any handwriting recognition that has been scheduled but not yet run.
  ///
  /// Recognition fires 800ms after the pen lifts and rewrites strokes by index.
  /// If the board changed in the meantime — an undo, a redo, a clear, a board
  /// switch — those indices no longer mean what they meant, and letting it run
  /// rewrites the board *after* the user's action. When writing, that looked
  /// exactly like undo silently not working: the strokes came back as
  /// recognised text a moment later.
  void _cancelPendingRecognition() {
    _recognitionTimer?.cancel();
    _recognitionTimer = null;
    _pendingStrokeIndices.clear();
    _pendingRecognitionBoardId = null;
  }

  void undo() {
    _cancelPendingRecognition();
    final strokes = List<Stroke>.from(activeStrokes);
    if (strokes.isEmpty) return;

    // One action, one undo: a batch added together comes off together.
    final batch = _batchOnTopOf(strokes, _undoBatches);
    final count = batch?.strokes.length ?? 1;
    final undone = strokes.sublist(strokes.length - count);
    strokes.removeRange(strokes.length - count, strokes.length);

    if (batch != null) {
      _undoBatches.removeLast();
      _redoBatches.add(_StrokeBatch(batch.boardId, undone));
      if (_redoBatches.length > _maxTrackedBatches) _redoBatches.removeAt(0);
    }

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = strokes;

    emit(
      state.copyWith(
        boards: updatedBoards,
        redoStack: [...state.redoStack, ...undone],
        selectedStrokeIndex: null,
      ),
    );
    _markDirty();
  }

  void redo() {
    _cancelPendingRecognition();
    if (state.redoStack.isEmpty) return;

    final updatedRedoStack = List<Stroke>.from(state.redoStack);
    final batch = _batchOnTopOf(updatedRedoStack, _redoBatches);
    final count = batch?.strokes.length ?? 1;
    final restored = updatedRedoStack.sublist(updatedRedoStack.length - count);
    updatedRedoStack.removeRange(
      updatedRedoStack.length - count,
      updatedRedoStack.length,
    );

    if (batch != null) {
      _redoBatches.removeLast();
      _undoBatches.add(_StrokeBatch(batch.boardId, restored));
      if (_undoBatches.length > _maxTrackedBatches) _undoBatches.removeAt(0);
    }

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = List.from(activeStrokes)
      ..addAll(restored);
    emit(
      state.copyWith(
        boards: updatedBoards,
        redoStack: updatedRedoStack,
        selectedStrokeIndex: null,
      ),
    );
    _markDirty();
  }

  /// Wipes the active board. Snapshots first — this used to be unrecoverable.
  Future<void> clear() async {
    _cancelPendingRecognition();
    _undoBatches.clear();
    _redoBatches.clear();
    if (activeStrokes.isNotEmpty) {
      await _snapshotService.capture(
        state.toJson(),
        reason: SnapshotReason.beforeClear,
      );
    }

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = [];
    emit(
      state.copyWith(
        boards: updatedBoards,
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );
    _markDirty();
  }

  /// Clears the "one of your boards was damaged" warning once seen.
  void acknowledgeDamagedBoards() {
    if (state.damagedBoardIds.isEmpty) return;
    emit(state.copyWith(damagedBoardIds: const []));
  }

  @override
  Future<void> close() async {
    _recognitionTimer?.cancel();
    _saveTimer?.cancel();
    try {
      await _launchSnapshot;
    } catch (e) {
      debugPrint('DrawingCubit: launch snapshot failed ($e)');
    }
    return super.close();
  }
}
