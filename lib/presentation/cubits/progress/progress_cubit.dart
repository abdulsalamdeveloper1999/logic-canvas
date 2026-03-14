import 'package:logic_canvas/domain/repositories/i_progress_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logic_canvas/presentation/cubits/progress/progress_state.dart';

@injectable
class ProgressCubit extends Cubit<ProgressState> {
  final IProgressRepository _repository;

  ProgressCubit(this._repository) : super(ProgressState.initial()) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final completedIds = await _repository.getCompletedProblemIds();
    emit(state.copyWith(completedProblemIds: completedIds));
  }

  Future<void> markAsCompleted(String problemId) async {
    await _repository.markAsCompleted(problemId);
    final updatedIds = Set<String>.from(state.completedProblemIds)
      ..add(problemId);
    emit(state.copyWith(completedProblemIds: updatedIds));
  }

  Future<void> toggleCompletion(String problemId) async {
    await _repository.toggleCompletion(problemId);
    final completedIds = await _repository.getCompletedProblemIds();
    emit(state.copyWith(completedProblemIds: completedIds));
  }
}
