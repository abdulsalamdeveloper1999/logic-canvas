import 'package:flutter_test/flutter_test.dart';
import 'package:logic_canvas/data/datasources/static_problem_data.dart';

void main() {
  test(
    'ProblemData should have descriptions and examples for first few problems',
    () {
      final problems = ProblemData.paretoProblems;

      // Check Problem 01
      final p01 = problems.firstWhere((p) => p.id == '01');
      expect(p01.description, isNotNull);
      expect(p01.examples, isNotEmpty);
      expect(p01.examples[0].input, contains('nums = [1,2,3,1]'));

      // Check Problem 02
      final p02 = problems.firstWhere((p) => p.id == '02');
      expect(p02.description, isNotNull);
      expect(p02.examples, isNotEmpty);
      expect(p02.examples[0].input, contains('s = "anagram"'));

      // Check Problem 03
      final p03 = problems.firstWhere((p) => p.id == '03');
      expect(p03.description, isNotNull);
      expect(p03.examples, isNotEmpty);
      expect(p03.examples[0].explanation, isNotNull);
    },
  );
}
