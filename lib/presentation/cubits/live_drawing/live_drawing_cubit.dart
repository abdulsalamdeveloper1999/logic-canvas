import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'live_drawing_state.dart';

class LiveDrawingCubit extends Cubit<LiveDrawingState> {
  LiveDrawingCubit() : super(LiveDrawingState.initial());

  void startStroke(Stroke stroke, Offset hover) {
    emit(state.copyWith(
      activeStroke: stroke,
      hoverPosition: hover,
      revision: state.revision + 1,
    ));
  }

  void notifyChange() {
    emit(state.copyWith(revision: state.revision + 1));
  }

  void updateHover(Offset hover) {
    emit(state.copyWith(hoverPosition: hover));
  }

  void endStroke() {
    emit(state.copyWith(
      activeStroke: null,
      revision: state.revision + 1,
    ));
  }

  void cancel() {
    emit(LiveDrawingState.initial());
  }
}
