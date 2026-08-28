import 'package:logic_canvas/data/algorithms/traces/arrays_hashing_traces.dart';
import 'package:logic_canvas/data/algorithms/traces/binary_search_traces.dart';
import 'package:logic_canvas/data/algorithms/traces/graph_traces.dart';
import 'package:logic_canvas/data/algorithms/traces/heap_traces.dart';
import 'package:logic_canvas/data/algorithms/traces/linked_list_traces.dart';
import 'package:logic_canvas/data/algorithms/traces/sliding_window_traces.dart';
import 'package:logic_canvas/data/algorithms/traces/stack_traces.dart';
import 'package:logic_canvas/data/algorithms/traces/tree_traces.dart';
import 'package:logic_canvas/data/algorithms/traces/two_pointers_traces.dart';
import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// Step-by-step animations for the core interview patterns.
///
/// Every trace is produced by *running* the algorithm and recording what it did
/// at each point, rather than by hand-writing frames. The animation therefore
/// cannot drift away from the logic it claims to teach, and adding a new input
/// is a one-line change.
class AlgorithmTraces {
  const AlgorithmTraces._();

  /// Every walkthrough, in curriculum order — the same order as the Pareto
  /// problem list, so the Learn tab reads top-to-bottom as a study plan.
  static List<AlgorithmTrace> get all => [
    // Arrays & Hashing (01–08)
    ...ArraysHashingTraces.all,
    // Two Pointers (09–12)
    validPalindrome(),
    ...TwoPointersTraces.all,
    // Sliding Window (13–15)
    SlidingWindowTraces.bestTimeToBuyAndSell(),
    longestSubstring(),
    SlidingWindowTraces.longestRepeatingCharacterReplacement(),
    // Stack (16–18)
    validParentheses(),
    ...StackTraces.all,
    // Binary Search (19–21)
    binarySearch(),
    ...BinarySearchTraces.all,
    // Linked List (22–27)
    reverseLinkedList(),
    ...LinkedListTraces.all,
    // Trees (28–39)
    TreeTraces.invertTree(),
    TreeTraces.maxDepth(),
    TreeTraces.diameter(),
    TreeTraces.balanced(),
    TreeTraces.sameTree(),
    TreeTraces.subtree(),
    TreeTraces.lowestCommonAncestor(),
    levelOrder(),
    TreeTraces.rightSideView(),
    TreeTraces.countGoodNodes(),
    TreeTraces.validateBst(),
    TreeTraces.kthSmallestBst(),
    // Heap / Priority Queue (40–42)
    ...HeapTraces.all,
    // Graphs (43–49)
    ...GraphTraces.all,
  ];

  static AlgorithmTrace? byId(String id) {
    for (final trace in all) {
      if (trace.id == id) return trace;
    }
    return null;
  }

  /// The trace that explains a given library problem, if one exists.
  static AlgorithmTrace? forProblem(String problemId) {
    for (final trace in all) {
      if (trace.problemIds.contains(problemId)) return trace;
    }
    return null;
  }

  static List<AlgorithmTrace> forPattern(String pattern) {
    return all
        .where((t) => t.pattern.toLowerCase() == pattern.toLowerCase())
        .toList();
  }

  // ----------------------------------------------------------- two pointers

  static AlgorithmTrace validPalindrome() {
    const word = 'racecar';
    final values = word.split('');
    final steps = <VizStep>[];

    var left = 0;
    var right = values.length - 1;

    steps.add(
      VizStep(
        caption:
            'Is "$word" the same forwards and backwards? Rather than building '
            'a reversed copy, put one finger at each end and walk them toward '
            'each other.',
        codeLine: 0,
        scenes: [
          ArrayScene(
            values: values,
            title: 's',
            pointers: {'left': left, 'right': right},
          ),
        ],
      ),
    );

    var ok = true;
    while (left < right) {
      final match = values[left] == values[right];
      steps.add(
        VizStep(
          caption: match
              ? 'Compare "${values[left]}" and "${values[right]}" — they '
                    'match, so the outside of the word is still symmetric.'
              : 'Compare "${values[left]}" and "${values[right]}" — they '
                    'differ, so it cannot be a palindrome. Stop immediately.',
          codeLine: 2,
          scenes: [
            ArrayScene(
              values: values,
              title: 's',
              states: {
                for (var j = 0; j < left; j++) j: VizState.done,
                for (var j = right + 1; j < values.length; j++)
                  j: VizState.done,
                left: match ? VizState.compare : VizState.fail,
                right: match ? VizState.compare : VizState.fail,
              },
              pointers: {'left': left, 'right': right},
            ),
          ],
        ),
      );

      if (!match) {
        ok = false;
        break;
      }

      left++;
      right--;

      if (left < right) {
        steps.add(
          VizStep(
            caption:
                'Those two are settled. Step both fingers inward and check '
                'the next pair. The untested part of the word shrinks by two '
                'every round.',
            codeLine: 3,
            scenes: [
              ArrayScene(
                values: values,
                title: 's',
                states: {
                  for (var j = 0; j < left; j++) j: VizState.done,
                  for (var j = right + 1; j < values.length; j++)
                    j: VizState.done,
                },
                window: (start: left, end: right),
                windowLabel: 'still to check',
                pointers: {'left': left, 'right': right},
              ),
            ],
          ),
        );
      }
    }

    if (ok) {
      steps.add(
        VizStep(
          caption:
              'The fingers have met in the middle, so every pair matched. '
              '"$word" is a palindrome.',
          codeLine: 5,
          insight:
              'Two pointers replaced a reversed copy of the string. Same '
              'answer, no extra memory — and it can quit early the moment it '
              'finds a mismatch.',
          scenes: [
            ArrayScene(
              values: values,
              title: 's',
              states: {
                for (var j = 0; j < values.length; j++) j: VizState.success,
              },
            ),
            const ValueScene(
              readings: [
                (label: 'result', value: 'true', state: VizState.success),
              ],
            ),
          ],
        ),
      );
    }

    return AlgorithmTrace(
      id: 'valid-palindrome',
      title: 'Valid Palindrome',
      pattern: 'Two Pointers',
      patternIdea:
          'When a question is about both ends of a sequence at once, walk in '
          'from both ends instead of scanning left to right.',
      pseudocode: const [
        'int left = 0, right = s.length() - 1;',
        'while (left < right) {',
        '    if (s.charAt(left) != s.charAt(right)) return false;',
        '    left++; right--;',
        '}',
        'return true;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — each character is visited at most once',
      spaceComplexity: 'O(1) — just two integers',
      takeaway:
          'Two pointers turn "compare the sequence with its reverse" into a '
          'single pass using no extra memory.',
      problemIds: const ['09'],
    );
  }

  // ---------------------------------------------------------- sliding window

  static AlgorithmTrace longestSubstring() {
    const text = 'abcabcbb';
    final values = text.split('');
    final steps = <VizStep>[];

    final seen = <String>{};
    var left = 0;
    var best = 0;
    var bestRange = (start: 0, end: 0);

    List<({String key, String value, VizState state})> setPanel() {
      return seen
          .map((c) => (key: c, value: '✓', state: VizState.idle))
          .toList();
    }

    steps.add(
      VizStep(
        caption:
            'We want the longest stretch of "$text" with no repeated letter. '
            'Keep a window that is always valid: extend it on the right, and '
            'whenever a duplicate appears, pull the left edge in until it is '
            'gone.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: values, title: 's'),
          const MapScene(
            entries: [],
            title: 'letters in the window',
            emptyLabel: 'window is empty',
          ),
        ],
      ),
    );

    for (var right = 0; right < values.length; right++) {
      final ch = values[right];

      steps.add(
        VizStep(
          caption: 'Try to extend the window to include "$ch" at index $right.',
          codeLine: 2,
          scenes: [
            ArrayScene(
              values: values,
              title: 's',
              states: {right: VizState.active},
              window: (start: left, end: right - 1 < left ? left : right - 1),
              windowLabel: 'window',
              pointers: {'left': left, 'right': right},
            ),
            MapScene(
              entries: setPanel(),
              title: 'letters in the window',
              emptyLabel: 'window is empty',
            ),
          ],
        ),
      );

      while (seen.contains(ch)) {
        final removed = values[left];
        seen.remove(removed);
        left++;
        steps.add(
          VizStep(
            caption:
                '"$ch" is already inside the window, so the window is no '
                'longer valid. Drop "$removed" from the left edge and try '
                'again.',
            codeLine: 3,
            scenes: [
              ArrayScene(
                values: values,
                title: 's',
                states: {right: VizState.fail, left - 1: VizState.done},
                window: (start: left, end: right - 1 < left ? left : right - 1),
                windowLabel: 'window',
                pointers: {'left': left, 'right': right},
              ),
              MapScene(
                entries: setPanel(),
                title: 'letters in the window',
                emptyLabel: 'window is empty',
              ),
            ],
          ),
        );
      }

      seen.add(ch);
      final length = right - left + 1;
      final isBest = length > best;
      if (isBest) {
        best = length;
        bestRange = (start: left, end: right);
      }

      steps.add(
        VizStep(
          caption: isBest
              ? 'The window is valid again and now $length letters long — '
                    'that is the best so far.'
              : 'The window is valid again, $length letters long. The best is '
                    'still $best.',
          codeLine: 4,
          scenes: [
            ArrayScene(
              values: values,
              title: 's',
              states: {
                for (var j = left; j <= right; j++)
                  j: isBest ? VizState.success : VizState.active,
              },
              window: (start: left, end: right),
              windowLabel: 'window (length $length)',
              pointers: {'left': left, 'right': right},
            ),
            MapScene(
              entries: setPanel(),
              title: 'letters in the window',
              emptyLabel: 'window is empty',
            ),
            ValueScene(
              readings: [
                (
                  label: 'best',
                  value: '$best',
                  state: isBest ? VizState.success : VizState.idle,
                ),
              ],
            ),
          ],
        ),
      );
    }

    steps.add(
      VizStep(
        caption:
            'Every position has been tried. The longest stretch without a '
            'repeat is $best letters.',
        codeLine: 6,
        insight:
            'Notice that left never moves backwards. Each pointer crosses the '
            'string at most once, so this is O(n) even though there is a loop '
            'inside a loop.',
        scenes: [
          ArrayScene(
            values: values,
            title: 's',
            states: {
              for (var j = 0; j < values.length; j++) j: VizState.dim,
              for (var j = bestRange.start; j <= bestRange.end; j++)
                j: VizState.success,
            },
            window: bestRange,
            windowLabel: 'longest valid window',
          ),
          ValueScene(
            readings: [
              (label: 'answer', value: '$best', state: VizState.success),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'longest-substring',
      title: 'Longest Substring Without Repeating Characters',
      pattern: 'Sliding Window',
      patternIdea:
          'For "longest / shortest run that satisfies a rule", keep one window '
          'that is always valid instead of testing every possible substring.',
      pseudocode: const [
        'Set<Character> seen = new HashSet<>();  int left = 0, best = 0;',
        'for (int right = 0; right < s.length(); right++) {',
        '    while (seen.contains(s.charAt(right)))',
        '        seen.remove(s.charAt(left++));',
        '    seen.add(s.charAt(right));  best = Math.max(best, right-left+1);',
        '}',
        'return best;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — left and right each move forward at most n times',
      spaceComplexity: 'O(k) — k distinct characters in the window',
      takeaway:
          'Grow the window on the right; shrink it from the left only until it '
          'is valid again. Never move the left edge backwards.',
      problemIds: const ['14'],
    );
  }

  // ----------------------------------------------------------- binary search

  static AlgorithmTrace binarySearch() {
    const nums = [1, 3, 5, 7, 9, 11, 13];
    const target = 11;
    final values = nums.map((n) => '$n').toList();
    final steps = <VizStep>[];

    var lo = 0;
    var hi = nums.length - 1;

    steps.add(
      VizStep(
        caption:
            'Find $target in a sorted list. Because it is sorted, we can throw '
            'away half the list with a single comparison — like finding a word '
            'in a dictionary.',
        codeLine: 0,
        scenes: [
          ArrayScene(
            values: values,
            title: 'nums (sorted)',
            pointers: {'lo': lo, 'hi': hi},
          ),
        ],
      ),
    );

    var found = -1;
    while (lo <= hi) {
      final mid = lo + (hi - lo) ~/ 2;

      steps.add(
        VizStep(
          caption:
              'The search range is indexes $lo to $hi. Check the middle one, '
              'index $mid, which holds ${nums[mid]}.',
          codeLine: 2,
          scenes: [
            ArrayScene(
              values: values,
              title: 'nums (sorted)',
              states: {
                for (var j = 0; j < values.length; j++) j: VizState.dim,
                for (var j = lo; j <= hi; j++) j: VizState.idle,
                mid: VizState.active,
              },
              window: (start: lo, end: hi),
              windowLabel: 'still possible',
              pointers: {'lo': lo, 'mid': mid, 'hi': hi},
            ),
          ],
        ),
      );

      if (nums[mid] == target) {
        found = mid;
        steps.add(
          VizStep(
            caption:
                '${nums[mid]} is exactly what we wanted. Found it at index '
                '$mid.',
            codeLine: 3,
            insight:
                'Seven elements took three checks. A million would take about '
                'twenty. Every comparison halves what is left, which is what '
                'O(log n) means in practice.',
            scenes: [
              ArrayScene(
                values: values,
                title: 'nums (sorted)',
                states: {
                  for (var j = 0; j < values.length; j++) j: VizState.dim,
                  mid: VizState.success,
                },
                pointers: {'mid': mid},
              ),
              ValueScene(
                readings: [
                  (
                    label: 'answer',
                    value: 'index $mid',
                    state: VizState.success,
                  ),
                ],
              ),
            ],
          ),
        );
        break;
      }

      if (nums[mid] < target) {
        final oldLo = lo;
        lo = mid + 1;
        steps.add(
          VizStep(
            caption:
                '${nums[mid]} is smaller than $target, and the list is '
                'sorted, so everything from index $oldLo to $mid is too '
                'small. Discard that whole half.',
            codeLine: 4,
            scenes: [
              ArrayScene(
                values: values,
                title: 'nums (sorted)',
                states: {
                  for (var j = 0; j < lo; j++) j: VizState.fail,
                  for (var j = lo; j <= hi; j++) j: VizState.idle,
                },
                window: (start: lo, end: hi),
                windowLabel: 'still possible',
                pointers: {'lo': lo, 'hi': hi},
              ),
            ],
          ),
        );
      } else {
        final oldHi = hi;
        hi = mid - 1;
        steps.add(
          VizStep(
            caption:
                '${nums[mid]} is bigger than $target, so everything from '
                'index $mid to $oldHi is too big. Discard that half.',
            codeLine: 5,
            scenes: [
              ArrayScene(
                values: values,
                title: 'nums (sorted)',
                states: {
                  for (var j = hi + 1; j < values.length; j++) j: VizState.fail,
                  for (var j = lo; j <= hi; j++) j: VizState.idle,
                },
                window: (start: lo, end: hi),
                windowLabel: 'still possible',
                pointers: {'lo': lo, 'hi': hi},
              ),
            ],
          ),
        );
      }
    }

    if (found < 0) {
      steps.add(
        const VizStep(
          caption: 'The range is now empty, so the target is not in the list.',
          codeLine: 7,
          scenes: [],
        ),
      );
    }

    return AlgorithmTrace(
      id: 'binary-search',
      title: 'Binary Search',
      pattern: 'Binary Search',
      patternIdea:
          'Sorted input is a gift: one comparison in the middle tells you '
          'which half the answer cannot be in.',
      pseudocode: const [
        'int lo = 0, hi = nums.length - 1;',
        'while (lo <= hi) {',
        '    int mid = lo + (hi - lo) / 2;',
        '    if (nums[mid] == target) return mid;',
        '    else if (nums[mid] < target) lo = mid + 1;',
        '    else hi = mid - 1;',
        '}',
        'return -1;',
      ],
      steps: steps,
      timeComplexity: 'O(log n) — the range halves every step',
      spaceComplexity: 'O(1)',
      takeaway:
          'Write mid as lo + (hi - lo) // 2, and make sure every branch shrinks '
          'the range, or the loop never ends.',
      problemIds: const ['19'],
    );
  }

  // ------------------------------------------------------------------ stack

  static AlgorithmTrace validParentheses() {
    const text = '([{}])';
    final values = text.split('');
    const pairs = {')': '(', ']': '[', '}': '{'};
    final steps = <VizStep>[];
    final stack = <String>[];

    List<({String value, VizState state})> stackPanel({VizState? topState}) {
      return [
        for (var i = 0; i < stack.length; i++)
          (
            value: stack[i],
            state: (i == stack.length - 1 && topState != null)
                ? topState
                : VizState.idle,
          ),
      ];
    }

    steps.add(
      const VizStep(
        caption:
            'Brackets must close in the reverse order they opened. That is '
            'exactly what a stack does: the last thing you put in is the first '
            'thing you take out.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: ['(', '[', '{', '}', ']', ')'], title: 's'),
          StackScene(items: [], title: 'stack', emptyLabel: 'empty'),
        ],
      ),
    );

    var ok = true;
    for (var i = 0; i < values.length; i++) {
      final ch = values[i];

      if (!pairs.containsKey(ch)) {
        stack.add(ch);
        steps.add(
          VizStep(
            caption:
                '"$ch" is an opening bracket. Push it on the stack — it is now '
                'the one that must be closed next.',
            codeLine: 2,
            scenes: [
              ArrayScene(
                values: values,
                title: 's',
                states: {
                  for (var j = 0; j < i; j++) j: VizState.done,
                  i: VizState.active,
                },
                pointers: {'i': i},
              ),
              StackScene(
                items: stackPanel(topState: VizState.active),
                title: 'stack',
              ),
            ],
          ),
        );
        continue;
      }

      final expected = pairs[ch]!;
      final top = stack.isEmpty ? null : stack.last;
      final matches = top == expected;

      steps.add(
        VizStep(
          caption: matches
              ? '"$ch" is a closing bracket. The top of the stack is "$top", '
                    'which is its partner — so this pair is correct. Pop it '
                    'off.'
              : '"$ch" is a closing bracket, but the top of the stack is '
                    '${top == null ? "nothing" : "\"$top\""}. That is the '
                    'wrong partner, so the string is invalid.',
          codeLine: matches ? 5 : 3,
          scenes: [
            ArrayScene(
              values: values,
              title: 's',
              states: {
                for (var j = 0; j < i; j++) j: VizState.done,
                i: matches ? VizState.compare : VizState.fail,
              },
              pointers: {'i': i},
            ),
            StackScene(
              items: stackPanel(
                topState: matches ? VizState.compare : VizState.fail,
              ),
              title: 'stack',
            ),
          ],
        ),
      );

      if (!matches) {
        ok = false;
        break;
      }
      stack.removeLast();
    }

    if (ok) {
      steps.add(
        VizStep(
          caption: stack.isEmpty
              ? 'Every bracket found its partner and the stack is empty, so '
                    'the string is valid.'
              : 'The string ended but the stack still holds unclosed '
                    'brackets, so it is invalid.',
          codeLine: 7,
          insight:
              'The stack is really a to-do list of promises: every opening '
              'bracket is a promise to close it, and popping is keeping that '
              'promise in the right order.',
          scenes: [
            ArrayScene(
              values: values,
              title: 's',
              states: {
                for (var j = 0; j < values.length; j++) j: VizState.success,
              },
            ),
            StackScene(items: stackPanel(), title: 'stack'),
            ValueScene(
              readings: [
                (
                  label: 'result',
                  value: stack.isEmpty ? 'true' : 'false',
                  state: stack.isEmpty ? VizState.success : VizState.fail,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AlgorithmTrace(
      id: 'valid-parentheses',
      title: 'Valid Parentheses',
      pattern: 'Stack',
      patternIdea:
          'When the most recent unfinished thing is the one you must handle '
          'next, that is a stack.',
      pseudocode: const [
        'Deque<Character> stack = new ArrayDeque<>();',
        'for (char ch : s.toCharArray()) {',
        '    if (isOpening(ch)) stack.push(ch);',
        '    else if (stack.isEmpty() || stack.peek() != partner(ch))',
        '        return false;',
        '    else stack.pop();',
        '}',
        'return stack.isEmpty();',
      ],
      steps: steps,
      timeComplexity: 'O(n) — each character is pushed and popped at most once',
      spaceComplexity: 'O(n) — worst case every character is an opener',
      takeaway:
          'Do not forget the final check: leftovers on the stack mean unclosed '
          'brackets, which is still invalid.',
      problemIds: const ['16'],
    );
  }

  // ------------------------------------------------------------------- tree

  static AlgorithmTrace levelOrder() {
    const heap = <String?>['3', '9', '20', null, null, '15', '7'];
    final steps = <VizStep>[];

    final queue = <int>[];
    final visited = <int>[];
    final output = <String>[];

    List<({String value, VizState state})> queuePanel() {
      return queue
          .map((i) => (value: heap[i]!, state: VizState.active))
          .toList();
    }

    Map<int, VizState> treeStates({int? current}) {
      return {
        for (final v in visited) v: VizState.done,
        for (final q in queue) q: VizState.compare,
        ?current: VizState.active,
      };
    }

    steps.add(
      const VizStep(
        caption:
            'Visit the tree level by level, top to bottom. A queue makes this '
            'natural: whatever went in first comes out first, so a whole level '
            'is handled before the next one begins.',
        codeLine: 0,
        scenes: [
          TreeScene(heap: heap, title: 'tree'),
          QueueScene(items: [], title: 'queue', emptyLabel: 'empty'),
        ],
      ),
    );

    queue.add(0);
    steps.add(
      VizStep(
        caption: 'Start by putting the root, ${heap[0]}, into the queue.',
        codeLine: 0,
        scenes: [
          TreeScene(heap: heap, states: treeStates(), title: 'tree'),
          QueueScene(items: queuePanel(), title: 'queue'),
        ],
      ),
    );

    while (queue.isNotEmpty) {
      final levelSize = queue.length;
      final level = <String>[];

      for (var n = 0; n < levelSize; n++) {
        final index = queue.removeAt(0);
        visited.add(index);
        level.add(heap[index]!);
        output.add(heap[index]!);

        final left = index * 2 + 1;
        final right = index * 2 + 2;
        final children = <int>[];
        if (left < heap.length && heap[left] != null) children.add(left);
        if (right < heap.length && heap[right] != null) children.add(right);
        queue.addAll(children);

        steps.add(
          VizStep(
            caption: children.isEmpty
                ? 'Take ${heap[index]} out of the queue and record it. It has '
                      'no children, so nothing new goes in.'
                : 'Take ${heap[index]} out of the queue and record it, then '
                      'add its ${children.length == 1 ? "child" : "children"} '
                      '${children.map((c) => heap[c]).join(" and ")} to the '
                      'back of the queue.',
            codeLine: 5,
            scenes: [
              TreeScene(
                heap: heap,
                states: treeStates(current: index),
                title: 'tree',
              ),
              QueueScene(items: queuePanel(), title: 'queue'),
              ValueScene(
                readings: [
                  (
                    label: 'visited so far',
                    value: output.join(', '),
                    state: VizState.idle,
                  ),
                ],
              ),
            ],
          ),
        );
      }

      steps.add(
        VizStep(
          caption:
              'That completes a level: [${level.join(", ")}]. Everything now '
              'in the queue belongs to the next level down.',
          codeLine: 8,
          scenes: [
            TreeScene(heap: heap, states: treeStates(), title: 'tree'),
            QueueScene(items: queuePanel(), title: 'queue'),
          ],
        ),
      );
    }

    steps.add(
      VizStep(
        caption:
            'The queue is empty, so every node has been visited. Level order: '
            '[${output.join(", ")}].',
        codeLine: 10,
        insight:
            'Reading the queue length once at the start of each round is what '
            'separates the levels. Swap the queue for a stack and the very '
            'same code becomes depth-first search.',
        scenes: [
          TreeScene(
            heap: heap,
            states: {for (final v in visited) v: VizState.success},
            title: 'tree',
          ),
          ValueScene(
            readings: [
              (
                label: 'answer',
                value: '[${output.join(", ")}]',
                state: VizState.success,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'level-order',
      title: 'Binary Tree Level Order Traversal',
      pattern: 'BFS',
      patternIdea:
          'A queue explores outward in rings — everything one step away, then '
          'everything two steps away. That is why BFS finds shortest paths.',
      pseudocode: const [
        'Queue<TreeNode> q = new LinkedList<>();  q.add(root);',
        'while (!q.isEmpty()) {',
        '    int size = q.size();   // freeze this level width',
        '    List<Integer> level = new ArrayList<>();',
        '    for (int i = 0; i < size; i++) {',
        '        TreeNode node = q.poll();  level.add(node.val);',
        '        for (TreeNode c : node.kids()) if (c != null) q.add(c);',
        '    }',
        '    result.add(level);',
        '}',
        'return result;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — every node enters and leaves the queue once',
      spaceComplexity: 'O(w) — w is the widest level',
      takeaway:
          'Capture len(queue) before the inner loop. That single line is what '
          'keeps the levels apart.',
      problemIds: const ['35'],
    );
  }

  // ------------------------------------------------------------ linked list

  static AlgorithmTrace reverseLinkedList() {
    final values = ['1', '2', '3', '4'];
    final steps = <VizStep>[];

    final next = <int?>[1, 2, 3, null];
    int? prev;
    int? curr = 0;

    steps.add(
      VizStep(
        caption:
            'Reverse the list. We cannot walk backwards, so instead we walk '
            'forwards once and flip each arrow as we pass it. Three pointers '
            'are enough.',
        codeLine: 0,
        scenes: [
          LinkedListScene(
            values: values,
            next: List<int?>.from(next),
            pointers: {'prev': prev, 'curr': curr},
            title: 'list',
          ),
        ],
      ),
    );

    while (curr != null) {
      final following = next[curr];

      steps.add(
        VizStep(
          caption: following == null
              ? 'Before touching anything, remember what comes after '
                    '${values[curr]} — nothing, this is the last node.'
              : 'Before touching anything, remember what comes after '
                    '${values[curr]}: it is ${values[following]}. If we flip '
                    'the arrow first we lose the rest of the list forever.',
          codeLine: 2,
          scenes: [
            LinkedListScene(
              values: values,
              next: List<int?>.from(next),
              states: {curr: VizState.active},
              pointers: {'prev': prev, 'curr': curr, 'next': following},
              title: 'list',
            ),
          ],
        ),
      );

      next[curr] = prev;

      steps.add(
        VizStep(
          caption: prev == null
              ? 'Now point ${values[curr]} at null. It was the first node; it '
                    'will end up last.'
              : 'Now flip the arrow: ${values[curr]} points back at '
                    '${values[prev]}.',
          codeLine: 3,
          scenes: [
            LinkedListScene(
              values: values,
              next: List<int?>.from(next),
              states: {curr: VizState.success, ?prev: VizState.done},
              pointers: {'prev': prev, 'curr': curr, 'next': following},
              title: 'list',
            ),
          ],
        ),
      );

      prev = curr;
      curr = following;

      if (curr != null) {
        steps.add(
          VizStep(
            caption:
                'Shuffle the pointers forward and repeat on ${values[curr]}.',
            codeLine: 4,
            scenes: [
              LinkedListScene(
                values: values,
                next: List<int?>.from(next),
                states: {prev: VizState.done},
                pointers: {'prev': prev, 'curr': curr},
                title: 'list',
              ),
            ],
          ),
        );
      }
    }

    steps.add(
      VizStep(
        caption:
            'curr has run off the end, so every arrow has been flipped. prev '
            'is now sitting on the new head, ${values.last}.',
        codeLine: 6,
        insight:
            'The order of the three assignments is the whole problem. Save '
            'next, flip the arrow, then move prev and curr — any other order '
            'loses the list.',
        scenes: [
          LinkedListScene(
            values: values,
            next: List<int?>.from(next),
            states: {
              for (var i = 0; i < values.length; i++) i: VizState.success,
            },
            pointers: {'prev (new head)': prev},
            title: 'list',
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'reverse-linked-list',
      title: 'Reverse Linked List',
      pattern: 'Linked List',
      patternIdea:
          'Linked list problems are pointer choreography. Draw the arrows '
          'before writing a single line of code.',
      pseudocode: const [
        'ListNode prev = null, curr = head;',
        'while (curr != null) {',
        '    ListNode following = curr.next;',
        '    curr.next = prev;',
        '    prev = curr;  curr = following;',
        '}',
        'return prev;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — one pass',
      spaceComplexity: 'O(1) — three pointers, no copy of the list',
      takeaway:
          'Save the next node before you overwrite the arrow, or the remainder '
          'of the list becomes unreachable.',
      problemIds: const ['22'],
    );
  }
}
