import 'package:logic_canvas/domain/repositories/i_progress_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IProgressRepository)
class ProgressRepositoryImpl implements IProgressRepository {
  final Box<bool> _progressBox;

  ProgressRepositoryImpl() : _progressBox = Hive.box<bool>('progress');

  @override
  Future<Set<String>> getCompletedProblemIds() async {
    return _progressBox.keys
        .cast<String>()
        .where((key) => _progressBox.get(key) == true)
        .toSet();
  }

  @override
  Future<void> markAsCompleted(String problemId) async {
    await _progressBox.put(problemId, true);
  }

  @override
  Future<void> markAsIncomplete(String problemId) async {
    await _progressBox.delete(problemId);
  }

  @override
  Future<void> toggleCompletion(String problemId) async {
    final isCompleted = _progressBox.get(problemId) ?? false;
    if (isCompleted) {
      await markAsIncomplete(problemId);
    } else {
      await markAsCompleted(problemId);
    }
  }
}
