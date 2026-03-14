abstract class IProgressRepository {
  Future<void> markAsCompleted(String problemId);
  Future<void> markAsIncomplete(String problemId);
  Future<Set<String>> getCompletedProblemIds();
  Future<void> toggleCompletion(String problemId);
}
