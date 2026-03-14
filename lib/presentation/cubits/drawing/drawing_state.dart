import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';

part 'drawing_state.freezed.dart';

@freezed
class DrawingState with _$DrawingState {
  const factory DrawingState({
    required List<Stroke> strokes,
    required List<Stroke> redoStack,
    @Default(false) bool isDrawing,
  }) = _DrawingState;

  factory DrawingState.initial() => const DrawingState(
        strokes: [],
        redoStack: [],
      );
}
