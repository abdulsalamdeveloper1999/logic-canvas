import 'package:freezed_annotation/freezed_annotation.dart';

part 'problem.freezed.dart';

enum Difficulty { easy, medium, hard }

@freezed
class ProblemExample with _$ProblemExample {
  const factory ProblemExample({
    required String input,
    required String output,
    String? explanation,
  }) = _ProblemExample;
}

@freezed
class Problem with _$Problem {
  const factory Problem({
    required String id,
    required String title,
    required String url,
    required Difficulty difficulty,
    required String category,
    @Default([]) List<String> hints,
    String? description,
    @Default([]) List<ProblemExample> examples,
  }) = _Problem;
}
