import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// Animated walkthroughs for the Binary Search problems (20, 21).
class BinarySearchTraces {
  const BinarySearchTraces._();

  static List<AlgorithmTrace> get all => [findMinRotated(), searchRotated()];

  // ----------------------------------------------------------------- 20

  static AlgorithmTrace findMinRotated() {
    const nums = [4, 5, 6, 7, 0, 1, 2];
    final values = nums.map((n) => '$n').toList();
    final steps = <VizStep>[];

    var lo = 0;
    var hi = nums.length - 1;

    steps.add(
      VizStep(
        caption:
            'This array was sorted, then rotated. The smallest value is the '
            'single point where the order breaks. We can still binary search, '
            'because one half is always properly sorted.',
        codeLine: 0,
        scenes: [
          ArrayScene(
            values: values,
            title: 'nums (rotated)',
            pointers: {'lo': lo, 'hi': hi},
          ),
        ],
      ),
    );

    while (lo < hi) {
      final mid = lo + (hi - lo) ~/ 2;
      final rightIsSmaller = nums[mid] > nums[hi];

      steps.add(
        VizStep(
          caption: rightIsSmaller
              ? 'nums[$mid] = ${nums[mid]} is greater than nums[$hi] = '
                    '${nums[hi]}. A sorted run can never end lower than it '
                    'starts, so the break — and the minimum — must be to the '
                    'right of $mid.'
              : 'nums[$mid] = ${nums[mid]} is not greater than nums[$hi] = '
                    '${nums[hi]}, so from $mid to $hi is properly sorted. The '
                    'minimum is at $mid or to its left.',
          codeLine: 2,
          scenes: [
            ArrayScene(
              values: values,
              title: 'nums (rotated)',
              states: {
                for (var j = 0; j < values.length; j++) j: VizState.dim,
                for (var j = lo; j <= hi; j++) j: VizState.idle,
                mid: VizState.active,
                hi: VizState.compare,
              },
              window: (start: lo, end: hi),
              windowLabel: 'still possible',
              pointers: {'lo': lo, 'mid': mid, 'hi': hi},
            ),
          ],
        ),
      );

      if (rightIsSmaller) {
        lo = mid + 1;
      } else {
        hi = mid;
      }

      steps.add(
        VizStep(
          caption: rightIsSmaller
              ? 'Discard everything up to and including $mid. The range is '
                    'now $lo to $hi.'
              : 'Discard everything after $mid, but keep $mid itself — it '
                    'might be the minimum. The range is now $lo to $hi.',
          codeLine: rightIsSmaller ? 3 : 4,
          scenes: [
            ArrayScene(
              values: values,
              title: 'nums (rotated)',
              states: {
                for (var j = 0; j < values.length; j++) j: VizState.dim,
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

    steps.add(
      VizStep(
        caption:
            'lo and hi have met at index $lo, so the minimum is ${nums[lo]}.',
        codeLine: 6,
        insight:
            'The loop is "while lo < hi", not "lo <= hi", and hi moves to mid '
            'rather than mid − 1. Both choices exist because the answer is a '
            'position we must keep, not a value we can discard.',
        scenes: [
          ArrayScene(
            values: values,
            title: 'nums (rotated)',
            states: {
              for (var j = 0; j < values.length; j++) j: VizState.dim,
              lo: VizState.success,
            },
            pointers: {'min': lo},
          ),
          ValueScene(
            readings: [
              (label: 'answer', value: '${nums[lo]}', state: VizState.success),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'find-min-rotated',
      title: 'Find Minimum in Rotated Sorted Array',
      pattern: 'Binary Search',
      patternIdea:
          'Comparing the middle to an end reveals which half is sorted, which '
          'is enough to halve the search even without full order.',
      pseudocode: const [
        'int lo = 0, hi = nums.length - 1;',
        'while (lo < hi) {',
        '    int mid = lo + (hi - lo) / 2;',
        '    if (nums[mid] > nums[hi]) lo = mid + 1;  // break is right',
        '    else hi = mid;               // mid may itself be the minimum',
        '}',
        'return nums[lo];',
      ],
      steps: steps,
      timeComplexity: 'O(log n)',
      spaceComplexity: 'O(1)',
      takeaway:
          'Compare mid against hi, not lo. Comparing against lo cannot '
          'distinguish a rotated array from an already-sorted one.',
      problemIds: const ['20', 'b7'],
    );
  }

  // ----------------------------------------------------------------- 21

  static AlgorithmTrace searchRotated() {
    const nums = [4, 5, 6, 7, 0, 1, 2];
    const target = 0;
    final values = nums.map((n) => '$n').toList();
    final steps = <VizStep>[];

    var lo = 0;
    var hi = nums.length - 1;
    var found = -1;

    steps.add(
      VizStep(
        caption:
            'Find $target in a rotated sorted array. At every step, at least '
            'one half is still properly sorted — so we can check whether the '
            'target lies inside that half and discard accordingly.',
        codeLine: 0,
        scenes: [
          ArrayScene(
            values: values,
            title: 'nums (rotated)',
            pointers: {'lo': lo, 'hi': hi},
          ),
        ],
      ),
    );

    while (lo <= hi) {
      final mid = lo + (hi - lo) ~/ 2;

      if (nums[mid] == target) {
        found = mid;
        steps.add(
          VizStep(
            caption: 'nums[$mid] is $target. Found it at index $mid.',
            codeLine: 3,
            insight:
                'The only new idea versus plain binary search is deciding '
                'which half is sorted. Everything else is unchanged.',
            scenes: [
              ArrayScene(
                values: values,
                title: 'nums (rotated)',
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

      final leftSorted = nums[lo] <= nums[mid];
      final inLeft = leftSorted && target >= nums[lo] && target < nums[mid];
      final inRight = !leftSorted && target > nums[mid] && target <= nums[hi];

      steps.add(
        VizStep(
          caption: leftSorted
              ? 'nums[$lo] = ${nums[lo]} is at most nums[$mid] = ${nums[mid]}, '
                    'so the left half is sorted. Is $target inside '
                    '[${nums[lo]}, ${nums[mid]})? ${inLeft ? "Yes — search there." : "No — so it must be on the right."}'
              : 'The left half is not sorted, so the right half must be. Is '
                    '$target inside (${nums[mid]}, ${nums[hi]}]? '
                    '${inRight ? "Yes — search there." : "No — so it must be on the left."}',
          codeLine: leftSorted ? 5 : 8,
          scenes: [
            ArrayScene(
              values: values,
              title: 'nums (rotated)',
              states: {
                for (var j = 0; j < values.length; j++) j: VizState.dim,
                for (var j = lo; j <= hi; j++)
                  j: (leftSorted && j <= mid) || (!leftSorted && j >= mid)
                      ? VizState.compare
                      : VizState.idle,
                mid: VizState.active,
              },
              window: (start: lo, end: hi),
              windowLabel: 'still possible',
              pointers: {'lo': lo, 'mid': mid, 'hi': hi},
            ),
          ],
        ),
      );

      if (leftSorted) {
        if (inLeft) {
          hi = mid - 1;
        } else {
          lo = mid + 1;
        }
      } else {
        if (inRight) {
          lo = mid + 1;
        } else {
          hi = mid - 1;
        }
      }
    }

    if (found < 0) {
      steps.add(
        const VizStep(
          caption: 'The range is empty, so the target is not in the array.',
          codeLine: 11,
          scenes: [],
        ),
      );
    }

    return AlgorithmTrace(
      id: 'search-rotated',
      title: 'Search in Rotated Sorted Array',
      pattern: 'Binary Search',
      patternIdea:
          'Identify the sorted half first; only then can you decide which side '
          'the target can possibly be on.',
      pseudocode: const [
        'int lo = 0, hi = nums.length - 1;',
        'while (lo <= hi) {',
        '    int mid = lo + (hi - lo) / 2;',
        '    if (nums[mid] == target) return mid;',
        '    if (nums[lo] <= nums[mid]) {          // left half sorted',
        '        if (target >= nums[lo] && target < nums[mid]) hi = mid - 1;',
        '        else lo = mid + 1;',
        '    } else {                              // right half sorted',
        '        if (target > nums[mid] && target <= nums[hi]) lo = mid + 1;',
        '        else hi = mid - 1;',
        '    }',
        '}',
        'return -1;',
      ],
      steps: steps,
      timeComplexity: 'O(log n)',
      spaceComplexity: 'O(1)',
      takeaway:
          'Use <= when testing which half is sorted. With a two-element range '
          'a strict < sends you down the wrong branch.',
      problemIds: const ['21', 'b8'],
    );
  }
}
