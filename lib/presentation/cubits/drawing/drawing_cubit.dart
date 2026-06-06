import 'package:logic_canvas/domain/entities/problem.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  static const String _boxName = 'drawing';
  static const String _stateKey = 'drawing_state_v2';
  final HandwritingRecognitionService _handwritingService;
  final MLShapeService _mlShapeService;
  Timer? _recognitionTimer;
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

    final box = await Hive.openBox(_boxName);
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

    // Auto-download from cloud on launch if enabled
    if (_isSyncEnabled) {
      syncFromCloud();
    }
  }

  Future<void> _saveState() async {
    final box = await Hive.openBox(_boxName);
    final Map<String, dynamic> boardsJson = {};
    state.boards.forEach((key, value) {
      boardsJson[key] = value.map((s) => s.toJson()).toList();
    });

    await box.put(_stateKey, {
      'boards': boardsJson,
      'activeBoardId': state.activeBoardId,
      'boardIds': state.boardIds,
      'boardProblems': state.boardProblems,
    });

    // Auto-sync to cloud if enabled
    syncToCloud();
  }

  void setSyncEnabled(bool enabled) {
    _isSyncEnabled = enabled;
  }

  Future<void> syncToCloud() async {
    if (!_isSyncEnabled) return;
    await _icloudSyncService.syncToCloud(state.toJson());
  }

  Future<void> syncFromCloud() async {
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
      await _saveState();
    }
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
    _saveState();
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
    _saveState();
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
    _saveState();
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
    _saveState();
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
    _saveState();
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
    _saveState();
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
    _saveState();
  }

  void updateStrokeAt(int index, Stroke stroke) {
    var strokes = List<Stroke>.from(activeStrokes);
    if (index < 0 || index >= strokes.length) return;
    strokes[index] = stroke;

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = strokes;

    emit(state.copyWith(boards: updatedBoards));
    _saveState();
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
    _saveState();
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
    if (!state.isDrawing) return;

    if (stroke == null) {
      emit(state.copyWith(isDrawing: false));
      return;
    }

    var finalStroke = stroke;
    final updatedStrokes = List<Stroke>.from(activeStrokes);
    final lastIdx = updatedStrokes.length;
    updatedStrokes.add(finalStroke);

    if (enableHandwriting && !finalStroke.isEraser) {
      _pendingStrokeIndices.add(lastIdx);

      final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
      updatedBoards[state.activeBoardId] = updatedStrokes;
      emit(state.copyWith(boards: updatedBoards, isDrawing: false));

      _recognitionTimer?.cancel();
      _recognitionTimer = Timer(const Duration(milliseconds: 800), () async {
        await _processHandwriting();
      });
      return;
    }

    if (enableShapeDetection &&
        !finalStroke.isEraser &&
        finalStroke.points.length > 10) {
      final detectedType = await _mlShapeService.detectShape(
        finalStroke.points,
      );
      if (detectedType != StrokeType.pen) {
        finalStroke = finalStroke.copyWith(type: detectedType);
        updatedStrokes[lastIdx] = finalStroke;
      }
    }

    final updatedBoards = Map<String, List<Stroke>>.from(state.boards);
    updatedBoards[state.activeBoardId] = updatedStrokes;
    emit(state.copyWith(boards: updatedBoards, isDrawing: false));
    await _saveState();
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
        await _saveState();
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
    _saveState();
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
    _saveState();
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
    _saveState();
  }

  @override
  Future<void> close() {
    _recognitionTimer?.cancel();
    return super.close();
  }
}
