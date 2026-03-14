import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logic_canvas/domain/entities/problem.dart';

part 'selection_state.freezed.dart';

@freezed
class SelectionState with _$SelectionState {
  const factory SelectionState({
    Problem? selectedProblem,
    @Default('Pareto 49') String currentList,
    @Default(false) bool isViewingDetail,
  }) = _SelectionState;

  factory SelectionState.initial() => const SelectionState();
}
