import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_state.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logic_canvas/data/services/handwriting_service.dart';
import 'package:logic_canvas/data/services/ml_shape_service.dart';

@injectable
class DrawingCubit extends Cubit<DrawingState> {
  static const String _boxName = 'drawing';
  String _currentBoardKey = 'global_board';
  final HandwritingRecognitionService _handwritingService;
  final MLShapeService _mlShapeService;
  Timer? _recognitionTimer;
  final List<int> _pendingStrokeIndices = [];

  DrawingCubit(this._handwritingService, this._mlShapeService)
    : super(DrawingState.initial()) {
    _loadStrokes();
  }

  Future<void> loadProblemBoard(String? problemId) async {
    final newKey = problemId != null ? 'problem_$problemId' : 'global_board';
    if (_currentBoardKey == newKey) return;

    // Save current board before switching
    await _saveStrokes();

    _currentBoardKey = newKey;
    await _loadStrokes();
  }

  Future<void> _loadStrokes() async {
    final box = await Hive.openBox(_boxName);
    final List? storedStrokes = box.get(_currentBoardKey);
    if (storedStrokes != null) {
      final strokes = storedStrokes
          .map((s) => Stroke.fromJson(Map<String, dynamic>.from(s)))
          .toList();
      emit(state.copyWith(strokes: strokes, redoStack: []));
    } else {
      emit(state.copyWith(strokes: [], redoStack: []));
    }
  }

  Future<void> _saveStrokes() async {
    final box = await Hive.openBox(_boxName);
    final strokesJson = state.strokes.map((s) => s.toJson()).toList();
    await box.put(_currentBoardKey, strokesJson);
  }

  void setDrawing(bool isDrawing) {
    emit(state.copyWith(isDrawing: isDrawing));
  }

  void addStroke(Stroke stroke) {
    emit(
      state.copyWith(
        strokes: List.from(state.strokes)..add(stroke),
        redoStack: [],
      ),
    );
    _saveStrokes();
  }

  void startStroke() {
    if (state.isDrawing) return;

    // Cancel pending recognition when a new stroke starts
    _recognitionTimer?.cancel();

    emit(state.copyWith(redoStack: [], isDrawing: true));
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
    final updatedStrokes = List<Stroke>.from(state.strokes);
    final lastIdx = updatedStrokes.length; // Index where new stroke will go
    updatedStrokes.add(finalStroke);

    if (enableHandwriting && !finalStroke.isEraser) {
      _pendingStrokeIndices.add(lastIdx);
      emit(state.copyWith(strokes: updatedStrokes, isDrawing: false));

      _recognitionTimer?.cancel();
      _recognitionTimer = Timer(const Duration(milliseconds: 800), () async {
        await _processHandwriting();
      });
      return;
    }

    // 2. Shape Detection (immediate if handwriting off)
    if (enableShapeDetection &&
        !finalStroke.isEraser &&
        finalStroke.points.length > 10) {
      final detectedType = await _mlShapeService.detectShape(
        finalStroke.points,
      );

      if (detectedType != StrokeType.pen) {
        finalStroke = finalStroke.copyWith(type: detectedType);
        updatedStrokes[lastIdx] = finalStroke;
        emit(state.copyWith(strokes: updatedStrokes, isDrawing: false));
        await _saveStrokes();
        return;
      }
    }

    emit(state.copyWith(strokes: updatedStrokes, isDrawing: false));
    await _saveStrokes();
  }

  Future<void> _processHandwriting() async {
    if (_pendingStrokeIndices.isEmpty) return;

    final List<List<Offset>> multiStrokes = [];
    final List<Stroke> strokesToConvert = [];

    // Sort indices just in case
    _pendingStrokeIndices.sort();

    for (final idx in _pendingStrokeIndices) {
      if (idx < state.strokes.length) {
        final s = state.strokes[idx];
        multiStrokes.add(s.points);
        strokesToConvert.add(s);
      }
    }

    if (multiStrokes.isNotEmpty) {
      debugPrint('HANDWRITING: Processing ${multiStrokes.length} strokes...');
      final text = await _handwritingService.recognize(multiStrokes);
      debugPrint('HANDWRITING: Recognized text: "$text"');

      if (text != null && text.trim().isNotEmpty) {
        final updatedStrokes = List<Stroke>.from(state.strokes);

        // Remove processed strokes (from highest index to lowest to maintain order)
        final sortedIndices = List<int>.from(_pendingStrokeIndices)
          ..sort((a, b) => b.compareTo(a));
        for (final idx in sortedIndices) {
          if (idx < updatedStrokes.length) {
            updatedStrokes.removeAt(idx);
          }
        }

        // Add the new text stroke
        // Construct points for bounding box from all converted strokes
        final allPoints = multiStrokes.expand((e) => e).toList();
        final textStroke = Stroke(
          points: allPoints,
          color: strokesToConvert.first.color,
          strokeWidth: strokesToConvert.first.strokeWidth,
          type: StrokeType.text,
          text: text,
        );

        updatedStrokes.add(textStroke);
        emit(state.copyWith(strokes: updatedStrokes));
        await _saveStrokes();
      }
    }
    _pendingStrokeIndices.clear();
  }

  void undo() {
    if (state.strokes.isEmpty) return;

    final updatedStrokes = List<Stroke>.from(state.strokes);
    final lastStroke = updatedStrokes.removeLast();

    emit(
      state.copyWith(
        strokes: updatedStrokes,
        redoStack: List.from(state.redoStack)..add(lastStroke),
      ),
    );
    _saveStrokes();
  }

  void redo() {
    if (state.redoStack.isEmpty) return;

    final updatedRedoStack = List<Stroke>.from(state.redoStack);
    final lastStroke = updatedRedoStack.removeLast();

    emit(
      state.copyWith(
        strokes: List.from(state.strokes)..add(lastStroke),
        redoStack: updatedRedoStack,
      ),
    );
    _saveStrokes();
  }

  void clear() {
    emit(state.copyWith(strokes: [], redoStack: []));
    _saveStrokes();
  }

  @override
  Future<void> close() {
    _recognitionTimer?.cancel();
    return super.close();
  }
}
