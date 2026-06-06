import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';

part 'drawing_state.freezed.dart';

@freezed
class DrawingState with _$DrawingState {
  const DrawingState._();
  const factory DrawingState({
    required Map<String, List<Stroke>> boards,
    required String activeBoardId,
    required List<String> boardIds,
    required List<Stroke> redoStack,
    @Default({}) Map<String, String?> boardProblems, // boardId -> problemId
    @Default(false) bool isDrawing,
    @Default(false) bool isLoaded,
    int? selectedStrokeIndex,
  }) = _DrawingState;

  factory DrawingState.initial() {
    const initialBoardId = 'Board 1';
    return const DrawingState(
      boards: {initialBoardId: []},
      activeBoardId: initialBoardId,
      boardIds: [initialBoardId],
      redoStack: [],
      isLoaded: false,
    );
  }

  List<Stroke> get activeStrokes => boards[activeBoardId] ?? [];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> boardsJson = {};
    boards.forEach((key, value) {
      boardsJson[key] = value.map((s) => s.toJson()).toList();
    });

    return {
      'boards': boardsJson,
      'activeBoardId': activeBoardId,
      'boardIds': boardIds,
      'boardProblems': boardProblems,
    };
  }
}
