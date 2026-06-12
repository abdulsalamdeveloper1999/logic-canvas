import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_state.freezed.dart';

@freezed
class ProgressState with _$ProgressState {
  const factory ProgressState({@Default({}) Set<String> completedProblemIds}) =
      _ProgressState;

  factory ProgressState.initial() => const ProgressState();
}
