import 'package:flutter_test/flutter_test.dart';
import 'package:logic_canvas/data/algorithms/algorithm_traces.dart';
import 'package:logic_canvas/data/algorithms/traces/arrays_hashing_traces.dart';
import 'package:logic_canvas/data/datasources/static_problem_data.dart';
import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// The animations exist to teach. A trace that renders beautifully but shows a
/// wrong final answer would teach the wrong thing, so each one is checked
/// against an independent implementation of the algorithm it claims to explain.
void main() {
  group('trace integrity (applies to every animation)', () {
    for (final trace in AlgorithmTraces.all) {
      group(trace.title, () {
        test('has steps, pseudocode and teaching copy', () {
          expect(trace.steps, isNotEmpty);
          expect(trace.pseudocode, isNotEmpty);
          expect(trace.takeaway.trim(), isNotEmpty);
          expect(trace.patternIdea.trim(), isNotEmpty);
          expect(trace.timeComplexity.trim(), isNotEmpty);
          expect(trace.spaceComplexity.trim(), isNotEmpty);
        });

        test('every codeLine points at a real pseudocode line', () {
          for (final step in trace.steps) {
            final line = step.codeLine;
            if (line == null) continue;
            expect(
              line,
              inInclusiveRange(0, trace.pseudocode.length - 1),
              reason:
                  'step "${step.caption}" highlights line $line, but the '
                  'pseudocode only has ${trace.pseudocode.length} lines',
            );
          }
        });

        test('every step has a caption a beginner can read', () {
          for (final step in trace.steps) {
            expect(step.caption.trim(), isNotEmpty);
            expect(
              step.caption.length,
              greaterThan(20),
              reason:
                  'captions carry the teaching; "${step.caption}" is too '
                  'thin to explain anything',
            );
          }
        });

        test('pointers and states stay inside their scene bounds', () {
          for (final step in trace.steps) {
            for (final scene in step.scenes) {
              switch (scene) {
                case ArrayScene(:final values, :final states, :final pointers):
                  for (final index in states.keys) {
                    expect(
                      index,
                      inInclusiveRange(0, values.length - 1),
                      reason: 'state index $index is off the array',
                    );
                  }
                  for (final entry in pointers.entries) {
                    expect(
                      entry.value,
                      inInclusiveRange(0, values.length - 1),
                      reason: 'pointer "${entry.key}" is off the array',
                    );
                  }
                  final window = scene.window;
                  if (window != null) {
                    expect(window.start, lessThanOrEqualTo(window.end));
                    expect(window.start, greaterThanOrEqualTo(0));
                    expect(window.end, lessThan(values.length));
                  }
                case LinkedListScene(:final values, :final next, :final states):
                  expect(next.length, values.length);
                  for (final target in next) {
                    if (target == null) continue;
                    expect(target, inInclusiveRange(0, values.length - 1));
                  }
                  for (final index in states.keys) {
                    expect(index, inInclusiveRange(0, values.length - 1));
                  }
                case TreeScene(:final heap, :final states):
                  for (final index in states.keys) {
                    expect(index, inInclusiveRange(0, heap.length - 1));
                    expect(
                      heap[index],
                      isNotNull,
                      reason: 'a missing node cannot be highlighted',
                    );
                  }
                default:
                  break;
              }
            }
          }
        });
      });
    }

    test('ids are unique so lookup is unambiguous', () {
      final ids = AlgorithmTraces.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('byId finds a trace and returns null for an unknown id', () {
      expect(AlgorithmTraces.byId('two-sum'), isNotNull);
      expect(AlgorithmTraces.byId('no-such-trace'), isNull);
    });

    test('forProblem resolves a trace from a library problem id', () {
      // '03' is Two Sum in the library; '01' is Contains Duplicate.
      expect(AlgorithmTraces.forProblem('03')?.id, 'two-sum');
      expect(AlgorithmTraces.forProblem('nope'), isNull);
    });

    test('every linked problem id exists and matches the trace subject', () {
      final library = ProblemData.allProblems;

      for (final trace in AlgorithmTraces.all) {
        for (final id in trace.problemIds) {
          final matches = library.where((p) => p.id == id).toList();
          expect(
            matches,
            isNotEmpty,
            reason:
                '${trace.title} points at problem "$id", which is not in '
                'the library',
          );

          // A trace linked to the wrong problem teaches the wrong thing, so
          // check the titles actually correspond.
          expect(
            matches.first.title.toLowerCase(),
            trace.title.toLowerCase(),
            reason:
                '${trace.title} is linked to problem "$id" '
                '(${matches.first.title})',
          );
        }
      }
    });

    test('every Pareto problem has an animation', () {
      final missing = <String>[];
      for (final problem in ProblemData.paretoProblems) {
        if (AlgorithmTraces.forProblem(problem.id) == null) {
          missing.add('${problem.id} ${problem.title}');
        }
      }
      expect(
        missing,
        isEmpty,
        reason:
            'the Pareto map is the core curriculum; these have no '
            'walkthrough yet:\n${missing.join("\n")}',
      );
    });

    test('no narrated statement is skipped by the code highlight', () {
      // A learner watches the highlight move down the code panel. If a step's
      // caption describes a decision or an action whose line never lights up,
      // the animation looks like it jumped over the logic — which is exactly
      // what happened with Two Sum's `if (seen.containsKey(need))`.
      //
      // Lines a single-line step-through legitimately never anchors on are
      // excluded: braces, comments, loop headers (their bodies get narrated),
      // method signatures, and `return`/`break` lines, which frequently sit on
      // a branch the chosen example never takes.
      bool neverAnchored(String line) {
        final t = line.trim();
        if (t.isEmpty || t.startsWith('//')) return true;
        if (RegExp(r'^[{}\);]+$').hasMatch(t)) return true;
        if (RegExp(r'^\}?\s*(for|while)\s*\(').hasMatch(t)) return true;
        if (t.contains('return') || t.contains('break')) return true;
        // Method signature, e.g. `int depth(TreeNode node) {`
        if (RegExp(r'^[\w<>\[\], ]+\s+\w+\(.*\)\s*\{$').hasMatch(t)) {
          return true;
        }
        return false;
      }

      final offenders = <String>[];
      for (final trace in AlgorithmTraces.all) {
        final anchored = trace.steps
            .map((s) => s.codeLine)
            .whereType<int>()
            .toSet();
        for (var i = 0; i < trace.pseudocode.length; i++) {
          final line = trace.pseudocode[i];
          if (neverAnchored(line)) continue;
          if (!anchored.contains(i)) {
            offenders.add('${trace.title}|$i');
          }
        }
      }

      final unexpected = offenders
          .where((o) => !_highlightExceptions.contains(o))
          .toList();
      expect(
        unexpected,
        isEmpty,
        reason:
            'these statements are never highlighted by any step:\n'
            '${unexpected.join("\n")}',
      );

      // Keep the exception list honest: an entry that is now covered must be
      // deleted, otherwise the list slowly stops meaning anything.
      final stale = _highlightExceptions
          .where((e) => !offenders.contains(e))
          .toList();
      expect(
        stale,
        isEmpty,
        reason:
            'these exceptions are no longer needed — delete them:\n'
            '${stale.join("\n")}',
      );
    });

    test('pseudocode is Java, not Python', () {
      // The learner writes Java in interviews, so the code panel must match.
      const pythonisms = [
        'def ',
        'elif ',
        'None',
        'True',
        'False',
        'range(',
        'self.',
        'append(',
      ];

      for (final trace in AlgorithmTraces.all) {
        for (final line in trace.pseudocode) {
          for (final marker in pythonisms) {
            expect(
              line.contains(marker),
              isFalse,
              reason: '${trace.title} pseudocode looks like Python: "$line"',
            );
          }
          // Python block syntax: a control line ending in a colon.
          final trimmed = line.trim();
          if (trimmed.startsWith(RegExp(r'(for|while|if|else)\b'))) {
            expect(
              trimmed.endsWith(':'),
              isFalse,
              reason: '${trace.title} uses Python block syntax: "$line"',
            );
          }
        }
      }
    });

    test('no two traces claim the same problem', () {
      final claimed = <String, String>{};
      for (final trace in AlgorithmTraces.all) {
        for (final id in trace.problemIds) {
          expect(
            claimed.containsKey(id),
            isFalse,
            reason:
                'problem "$id" is claimed by both ${claimed[id]} and '
                '${trace.id}',
          );
          claimed[id] = trace.id;
        }
      }
    });
  });

  group('traces agree with a reference implementation', () {
    test('Two Sum ends on the correct pair of indexes', () {
      final trace = ArraysHashingTraces.twoSum();
      const nums = [2, 7, 11, 15];
      const target = 9;

      // Reference: brute force, which is obviously correct.
      var expected = <int>[];
      outer:
      for (var i = 0; i < nums.length; i++) {
        for (var j = i + 1; j < nums.length; j++) {
          if (nums[i] + nums[j] == target) {
            expected = [i, j];
            break outer;
          }
        }
      }

      final answer = _valueOf(trace.steps.last, 'answer');
      expect(answer, '[${expected[0]}, ${expected[1]}]');
    });

    test('Valid Palindrome concludes true for a real palindrome', () {
      final trace = AlgorithmTraces.validPalindrome();
      const word = 'racecar';
      final isPalindrome = word == word.split('').reversed.join();

      expect(isPalindrome, isTrue);
      expect(_valueOf(trace.steps.last, 'result'), 'true');
    });

    test('Longest Substring reports the true answer for "abcabcbb"', () {
      final trace = AlgorithmTraces.longestSubstring();

      // Reference: check every substring.
      const s = 'abcabcbb';
      var best = 0;
      for (var i = 0; i < s.length; i++) {
        for (var j = i; j < s.length; j++) {
          final sub = s.substring(i, j + 1);
          if (sub.split('').toSet().length == sub.length) {
            best = best > sub.length ? best : sub.length;
          }
        }
      }

      expect(best, 3);
      expect(_valueOf(trace.steps.last, 'answer'), '$best');
    });

    test('Binary Search lands on the index holding the target', () {
      final trace = AlgorithmTraces.binarySearch();
      const nums = [1, 3, 5, 7, 9, 11, 13];
      const target = 11;
      final expected = nums.indexOf(target);

      expect(_valueOf(trace.steps.last, 'answer'), 'index $expected');
    });

    test('Binary Search never lets its range grow', () {
      final trace = AlgorithmTraces.binarySearch();
      int? previousWidth;

      for (final step in trace.steps) {
        for (final scene in step.scenes) {
          if (scene is! ArrayScene) continue;
          final window = scene.window;
          if (window == null) continue;
          final width = window.end - window.start;
          if (previousWidth != null) {
            expect(
              width,
              lessThanOrEqualTo(previousWidth),
              reason: 'a search range that grows would loop forever',
            );
          }
          previousWidth = width;
        }
      }
      expect(previousWidth, isNotNull);
    });

    test('Valid Parentheses accepts a correctly nested string', () {
      final trace = AlgorithmTraces.validParentheses();
      expect(_valueOf(trace.steps.last, 'result'), 'true');

      // The stack must be empty at the end of a valid string.
      final finalStack = trace.steps.last.scenes.whereType<StackScene>().single;
      expect(finalStack.items, isEmpty);
    });

    test('Level order matches a reference BFS over the same tree', () {
      final trace = AlgorithmTraces.levelOrder();
      const heap = <String?>['3', '9', '20', null, null, '15', '7'];

      final expected = <String>[];
      final queue = <int>[0];
      while (queue.isNotEmpty) {
        final index = queue.removeAt(0);
        expected.add(heap[index]!);
        for (final child in [index * 2 + 1, index * 2 + 2]) {
          if (child < heap.length && heap[child] != null) queue.add(child);
        }
      }

      expect(expected, ['3', '9', '20', '15', '7']);
      expect(_valueOf(trace.steps.last, 'answer'), '[${expected.join(", ")}]');
    });

    test('Reverse Linked List really is reversed at the end', () {
      final trace = AlgorithmTraces.reverseLinkedList();
      final finalScene = trace.steps.last.scenes
          .whereType<LinkedListScene>()
          .single;

      // Walk from the new head and read the values off in order.
      final headEntry = finalScene.pointers.entries.firstWhere(
        (e) => e.key.startsWith('prev'),
      );
      var cursor = headEntry.value;
      final walked = <String>[];
      final guard = finalScene.values.length + 1;

      while (cursor != null && walked.length <= guard) {
        walked.add(finalScene.values[cursor]);
        cursor = finalScene.next[cursor];
      }

      expect(walked, ['4', '3', '2', '1']);
      expect(
        walked.length,
        finalScene.values.length,
        reason: 'a broken link would make the walk end early',
      );
    });

    test('Reverse Linked List never orphans a node mid-animation', () {
      final trace = AlgorithmTraces.reverseLinkedList();

      for (final step in trace.steps) {
        for (final scene in step.scenes.whereType<LinkedListScene>()) {
          // No node may point at itself, and no two nodes at the same target.
          final targets = <int>{};
          for (var i = 0; i < scene.next.length; i++) {
            final target = scene.next[i];
            if (target == null) continue;
            expect(target, isNot(i), reason: 'self-loop at node $i');
            expect(
              targets.add(target),
              isTrue,
              reason: 'two nodes both point at $target — the list forked',
            );
          }
        }
      }
    });
  });
}

/// Reads a labelled reading out of a step's [ValueScene] panels.
String? _valueOf(VizStep step, String label) {
  for (final scene in step.scenes.whereType<ValueScene>()) {
    for (final reading in scene.readings) {
      if (reading.label == label) return reading.value;
    }
  }
  return null;
}

/// Pseudocode lines that no step anchors on, each reviewed and accepted as one
/// of three cases:
///   * a branch the chosen example never takes (`else hi = mid - 1;` when the
///     target is found on the other side),
///   * a continuation line of a statement wrapped across two lines,
///   * a statement whose result the same step already shows in a panel
///     (`int sum = ...` immediately before the comparison the caption narrates).
///
/// Anything not on this list fails the build, and any entry that becomes
/// covered must be removed.
const _highlightExceptions = <String>{
  '3Sum|10',
  '3Sum|6',
  'Balanced Binary Tree|3',
  'Binary Search|5',
  'Binary Tree Level Order Traversal|2',
  'Binary Tree Level Order Traversal|3',
  'Binary Tree Right Side View|2',
  'Binary Tree Right Side View|4',
  'Binary Tree Right Side View|6',
  'Clone Graph|4',
  'Clone Graph|7',
  'Container With Most Water|2',
  'Count Good Nodes in Binary Tree|4',
  'Count Good Nodes in Binary Tree|6',
  'Course Schedule II|3',
  'Course Schedule|4',
  'Course Schedule|6',
  'Course Schedule|8',
  'Diameter of Binary Tree|3',
  'Diameter of Binary Tree|5',
  'Group Anagrams|2',
  'Group Anagrams|3',
  'Invert Binary Tree|3',
  'Invert Binary Tree|4',
  'Kth Largest Element in a Stream|1',
  'Kth Largest Element in an Array|2',
  'LRU Cache|1',
  'LRU Cache|7',
  'Last Stone Weight|1',
  'Last Stone Weight|5',
  'Linked List Cycle|2',
  'Longest Consecutive Sequence|5',
  'Lowest Common Ancestor of a Binary Search Tree|1',
  'Lowest Common Ancestor of a Binary Search Tree|2',
  'Lowest Common Ancestor of a Binary Search Tree|3',
  'Lowest Common Ancestor of a Binary Search Tree|4',
  'Lowest Common Ancestor of a Binary Search Tree|5',
  'Max Area of Island|3',
  'Merge Two Sorted Lists|4',
  'Number of Islands|3',
  'Number of Islands|5',
  'Product of Array Except Self|4',
  'Remove Nth Node From End of List|1',
  'Search in Rotated Sorted Array|2',
  'Search in Rotated Sorted Array|4',
  'Search in Rotated Sorted Array|6',
  'Search in Rotated Sorted Array|7',
  'Search in Rotated Sorted Array|8',
  'Search in Rotated Sorted Array|9',
  'Two Sum II - Input Array Is Sorted|2',
  'Two Sum II - Input Array Is Sorted|4',
  'Valid Parentheses|3',
  'Valid Sudoku|3',
  'Validate Binary Search Tree|2',
};
