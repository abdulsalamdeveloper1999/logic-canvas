import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';

part 'drawing_state.freezed.dart';

@Freezed(equal: false)
class DrawingState with _$DrawingState {
  const DrawingState._();
  const factory DrawingState({
    required Map<String, List<Stroke>> boards,
    required String activeBoardId,
    required List<String> boardIds,
    required List<Stroke> redoStack,
    @Default({}) Map<String, String?> boardProblems,
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

  // We explicitly want reference equality for the massive collections to prevent UI freeze.
  // Freezed's default equality and Equatable both use DeepCollectionEquality for Maps/Lists,
  // which causes O(N) freezing on the main thread when adding rapidly (like dots).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrawingState &&
        identical(boards, other.boards) &&
        activeBoardId == other.activeBoardId &&
        identical(boardIds, other.boardIds) &&
        identical(redoStack, other.redoStack) &&
        identical(boardProblems, other.boardProblems) &&
        isDrawing == other.isDrawing &&
        isLoaded == other.isLoaded &&
        selectedStrokeIndex == other.selectedStrokeIndex;
  }

  @override
  int get hashCode =>
      identityHashCode(boards) ^
      activeBoardId.hashCode ^
      identityHashCode(boardIds) ^
      identityHashCode(redoStack) ^
      identityHashCode(boardProblems) ^
      isDrawing.hashCode ^
      isLoaded.hashCode ^
      selectedStrokeIndex.hashCode;
}
