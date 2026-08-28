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

    /// Boards whose stored data could not be read at launch. Surfaced to the
    /// user rather than letting a board silently come back empty.
    @Default(<String>[]) List<String> damagedBoardIds,
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
        activeBoardId == other.activeBoardId &&
        isDrawing == other.isDrawing &&
        isLoaded == other.isLoaded &&
        selectedStrokeIndex == other.selectedStrokeIndex &&
        boardIds.length == other.boardIds.length &&
        redoStack.length == other.redoStack.length &&
        damagedBoardIds.length == other.damagedBoardIds.length &&
        boards.length == other.boards.length &&
        (boards[activeBoardId]?.length ==
            other.boards[other.activeBoardId]?.length);
  }

  @override
  int get hashCode =>
      activeBoardId.hashCode ^
      isDrawing.hashCode ^
      isLoaded.hashCode ^
      selectedStrokeIndex.hashCode ^
      boards.length.hashCode ^
      redoStack.length.hashCode;
}
