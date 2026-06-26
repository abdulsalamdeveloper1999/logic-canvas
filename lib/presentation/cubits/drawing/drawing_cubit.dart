import 'package:logic_canvas/domain/entities/problem.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_state.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logic_canvas/data/services/handwriting_service.dart';
import 'package:logic_canvas/data/services/ml_shape_service.dart';
import 'package:logic_canvas/data/services/icloud_sync_service.dart';

@injectable
class DrawingCubit extends Cubit<DrawingState> {
  static const String boxName = 'drawing_v3';
  static const String _stateKey = 'drawing_state_v2';
  final HandwritingRecognitionService _handwritingService;
  final MLShapeService _mlShapeService;
  Timer? _recognitionTimer;
  Timer? _saveTimer;
  final List<int> _pendingStrokeIndices = [];
  final ICloudSyncService _icloudSyncService;
  bool _isSyncEnabled = false;

  DrawingCubit(
    this._handwritingService,
    this._mlShapeService,
    this._icloudSyncService,
  ) : super(DrawingState.initial()) {
    _loadState();
  }

  Future<void> _loadState() async {
    // Determine sync status from settings box
    final settingsBox = await Hive.openBox('settings');
    final settingsMap = settingsBox.get('user_settings');
    if (settingsMap != null) {
      _isSyncEnabled = settingsMap['isICloudSyncEnabled'] as bool? ?? false;
    }

    final box = await Hive.openBox(boxName);
    final storedData = box.get(_stateKey);
    if (storedData != null) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(storedData);

      final Map<String, List<Stroke>> boards = {};
      final storedBoards = Map<String, dynamic>.from(data['boards'] ?? {});
      storedBoards.forEach((key, value) {
        boards[key] = (value as List)
            .map((s) => Stroke.fromJson(Map<String, dynamic>.from(s)))
            .toList();
      });

      final boardIds = List<String>.from(
        data['boardIds'] ?? [DrawingState.initial().activeBoardId],
      );
      final activeBoardId = data['activeBoardId'] as String? ?? boardIds.first;
      final boardProblems = Map<String, String?>.from(
        data['boardProblems'] ?? {},
      );

      emit(
        state.copyWith(
          boards: boards,
          activeBoardId: activeBoardId,
          boardIds: boardIds,
          boardProblems: boardProblems,
          redoStack: [],
          isLoaded: true,
        ),
      );
    } else {
      emit(state.copyWith(isLoaded: true));
    }

    // Cloud sync is manual-only. Avoid doing iCloud work during app launch or
    // drawing; users can pull from iCloud with the Download button.
  }

  static Map<String, dynamic> _encodeStateToMap(DrawingState state) {
    return state.toJson();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      _performSave();
    });
  }

  Future<void> _performSave() async {
    final box = await Hive.openBox(boxName);

    // Offload heavy JSON serialization to a background thread to prevent UI freezing
    final Map<String, dynamic> data = await compute(_encodeStateToMap, state);

    await box.put(_stateKey, data);
  }

  void setSyncEnabled(bool enabled) {
    _isSyncEnabled = enabled;
  }

  void persistState() {
    _scheduleSave();
  }

  Future<void> syncToCloud() async {
    if (!_isSyncEnabled) return;
    await _icloudSyncService.syncToCloud(state.toJson());
  }

  Future<bool> syncFromCloud() async {
    final cloudData = await _icloudSyncService.downloadFromCloud();
    if (cloudData != null) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(cloudData);

      final Map<String, List<Stroke>> boards = {};
      final storedBoards = Map<String, dynamic>.from(data['boards'] ?? {});
      storedBoards.forEach((key, value) {
        boards[key] = (value as List)
            .map((s) => Stroke.fromJson(Map<String, dynamic>.from(s)))
            .toList();
      });

      final boardIds = List<String>.from(
        data['boardIds'] ?? [DrawingState.initial().activeBoardId],
      );
      final activeBoardId = data['activeBoardId'] as String? ?? boardIds.first;
      final boardProblems = Map<String, String?>.from(
        data['boardProblems'] ?? {},
      );

      emit(
        state.copyWith(
          boards: boards,
          activeBoardId: activeBoardId,
          boardIds: boardIds,
          boardProblems: boardProblems,
          redoStack: [],
          selectedStrokeIndex: null,
        ),
      );
      _scheduleSave();
      return true;
    }
    return false;
  }

  // --- Board Management ---

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
    _scheduleSave();
  }

  void createNewBoardFromTemplate(Problem problem, Color textColor) {
    // Check if a board for this problem already exists
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
    // Handle duplicate names (unlikely if we only allow one per problem, but good for safety)
    int count = 1;
    String baseName = name;
    while (state.boardIds.contains(name)) {
      name = '$baseName ($count)';
      count++;
    }

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);

    // Create initial stroke for problem description
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
    _scheduleSave();
  }

  void switchToBoard(String boardId) {
    if (boardId == state.activeBoardId) return;
    emit(
      state.copyWith(
        activeBoardId: boardId,
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );
    _scheduleSave();
  }

  void deleteBoard(String boardId) {
    if (state.boardIds.length <= 1) return; // Keep at least one board

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
    _scheduleSave();
  }

  void renameBoard(String oldId, String newId) {
    if (oldId == newId || newId.trim().isEmpty) return;
    if (state.boardIds.contains(newId)) return; // Prevent duplicates

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
    _scheduleSave();
  }

  // --- Drawing Actions ---

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
    _scheduleSave();
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
    _scheduleSave();
  }

  void startStroke() {
    if (state.isDrawing) return;
    _recognitionTimer?.cancel();
    emit(
      state.copyWith(redoStack: [], isDrawing: true, selectedStrokeIndex: null),
    );
  }

  Future<void> endStroke(
    Stroke? stroke,
    bool enableShapeDetection, {
    bool enableHandwriting = false,
  }) async {
    final startMicros = DateTime.now().microsecondsSinceEpoch;
    if (!state.isDrawing) return;

    if (stroke == null) {
      emit(state.copyWith(isDrawing: false));
      return;
    }

    final updatedStrokes = List<Stroke>.from(activeStrokes);
    final lastIdx = updatedStrokes.length;
    updatedStrokes.add(stroke);
    // debugPrint(
    //   'INK CUBIT: endStroke begin idx=$lastIdx type=${stroke.type.name} points=${stroke.points.length} shape=$enableShapeDetection handwriting=$enableHandwriting',
    // );

    if (enableHandwriting && !stroke.isEraser) {
      _pendingStrokeIndices.add(lastIdx);

      final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
      updatedBoards[state.activeBoardId] = updatedStrokes;
      emit(state.copyWith(boards: updatedBoards, isDrawing: false));
      final emitMs =
          ((DateTime.now().microsecondsSinceEpoch - startMicros) / 1000)
              .toStringAsFixed(1);
      // debugPrint('INK CUBIT: emitted handwriting stroke after ${emitMs}ms');
      _scheduleSave();

      _recognitionTimer?.cancel();
      _recognitionTimer = Timer(const Duration(milliseconds: 800), () async {
        await _processHandwriting();
      });
      return;
    }

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = updatedStrokes;
    emit(state.copyWith(boards: updatedBoards, isDrawing: false));
    final emitMs =
        ((DateTime.now().microsecondsSinceEpoch - startMicros) / 1000)
            .toStringAsFixed(1);
    // debugPrint('INK CUBIT: emitted stroke after ${emitMs}ms');
    _scheduleSave();

    if (enableShapeDetection && !stroke.isEraser && stroke.points.length > 10) {
      // debugPrint('INK CUBIT: shape detection scheduled idx=$lastIdx');
      unawaited(_processShapeDetection(lastIdx, stroke));
    }
  }

  Future<void> _processShapeDetection(int strokeIndex, Stroke stroke) async {
    final startMicros = DateTime.now().microsecondsSinceEpoch;
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
    _scheduleSave();
    final totalMs =
        ((DateTime.now().microsecondsSinceEpoch - startMicros) / 1000)
            .toStringAsFixed(1);
    // debugPrint(
    //   'INK CUBIT: shape converted idx=$strokeIndex type=${detectedType.name} after ${totalMs}ms',
    // );
  }

  Future<void> _processHandwriting() async {
    if (_pendingStrokeIndices.isEmpty) return;

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
      if (text != null && text.trim().isNotEmpty) {
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
        _scheduleSave();
      }
    }
    _pendingStrokeIndices.clear();
  }

  void undo() {
    final strokes = List<Stroke>.from(activeStrokes);
    if (strokes.isEmpty) return;

    final lastStroke = strokes.removeLast();
    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = strokes;

    emit(
      state.copyWith(
        boards: updatedBoards,
        redoStack: List.from(state.redoStack)..add(lastStroke),
        selectedStrokeIndex: null,
      ),
    );
    _scheduleSave();
  }

  void redo() {
    if (state.redoStack.isEmpty) return;

    final updatedRedoStack = List<Stroke>.from(state.redoStack);
    final lastStroke = updatedRedoStack.removeLast();

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = List.from(activeStrokes)
      ..add(lastStroke);

    emit(
      state.copyWith(
        boards: updatedBoards,
        redoStack: updatedRedoStack,
        selectedStrokeIndex: null,
      ),
    );
    _scheduleSave();
  }

  void clear() {
    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = [];
    emit(
      state.copyWith(
        boards: updatedBoards,
        redoStack: [],
        selectedStrokeIndex: null,
      ),
    );
    _scheduleSave();
  }

  @override
  Future<void> close() {
    _recognitionTimer?.cancel();
    _saveTimer?.cancel();
    return super.close();
  }
}
