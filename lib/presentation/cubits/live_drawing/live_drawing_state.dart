import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';

part 'live_drawing_state.freezed.dart';

@freezed
class LiveDrawingState with _$LiveDrawingState {
  const factory LiveDrawingState({
    Stroke? activeStroke,
    Offset? hoverPosition,
    @Default(0) int revision,
  }) = _LiveDrawingState;

  factory LiveDrawingState.initial() => const LiveDrawingState();
}
