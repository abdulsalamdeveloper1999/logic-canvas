import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// Animated walkthroughs for the Two Pointers problems (10–12).
class TwoPointersTraces {
  const TwoPointersTraces._();

  static List<AlgorithmTrace> get all => [
    twoSumSorted(),
    threeSum(),
    containerWithMostWater(),
  ];

  // ----------------------------------------------------------------- 10

  static AlgorithmTrace twoSumSorted() {
    const nums = [2, 7, 11, 15];
    const target = 9;
    final values = nums.map((n) => '$n').toList();
    final steps = <VizStep>[];

    var left = 0;
    var right = nums.length - 1;

    steps.add(
      VizStep(
        caption:
            'Same goal as Two Sum, but the array is sorted — and sorted means '
            'we can steer. Start with the widest possible pair and let the sum '
            'tell us which end to move.',
        codeLine: 0,
        scenes: [
          ArrayScene(
            values: values,
            title: 'numbers (sorted)',
            pointers: {'left': left, 'right': right},
          ),
        ],
      ),
    );

    var answer = <int>[];
    while (left < right) {
      final sum = nums[left] + nums[right];

      if (sum == target) {
        answer = [left + 1, right + 1];
        steps.add(
          VizStep(
            caption:
                '${nums[left]} + ${nums[right]} = $sum, exactly the target. '
                'The problem wants 1-based indexes, so the answer is '
                '[${answer[0]}, ${answer[1]}].',
            codeLine: 3,
            insight:
                'No hash map was needed. Sorted input replaced O(n) extra '
                'memory with two integers — that is the whole advantage of '
                'two pointers over hashing here.',
            scenes: [
              ArrayScene(
                values: values,
                title: 'numbers (sorted)',
                states: {left: VizState.success, right: VizState.success},
                pointers: {'left': left, 'right': right},
              ),
              ValueScene(
                readings: [
                  (
                    label: 'answer',
                    value: '[${answer[0]}, ${answer[1]}]',
                    state: VizState.success,
                  ),
                ],
              ),
            ],
          ),
        );
        break;
      }

      final tooSmall = sum < target;
      steps.add(
        VizStep(
          caption: tooSmall
              ? '${nums[left]} + ${nums[right]} = $sum, which is below '
                    '$target. The right end is already the biggest value '
                    'available, so the only way to grow the sum is to move '
                    'left inward.'
              : '${nums[left]} + ${nums[right]} = $sum, which is above '
                    '$target. The left end is already the smallest value '
                    'available, so shrink the sum by moving right inward.',
          codeLine: tooSmall ? 4 : 5,
          scenes: [
            ArrayScene(
              values: values,
              title: 'numbers (sorted)',
              states: {left: VizState.compare, right: VizState.compare},
              window: (start: left, end: right),
              windowLabel: 'still in play',
              pointers: {'left': left, 'right': right},
            ),
            ValueScene(
              readings: [
                (
                  label: 'sum',
                  value: '$sum ${tooSmall ? "<" : ">"} $target',
                  state: tooSmall ? VizState.fail : VizState.fail,
                ),
              ],
            ),
          ],
        ),
      );

      if (tooSmall) {
        left++;
      } else {
        right--;
      }
    }

    return AlgorithmTrace(
      id: 'two-sum-sorted',
      title: 'Two Sum II - Input Array Is Sorted',
      pattern: 'Two Pointers',
      patternIdea:
          'Sorted order tells you which direction changes the sum, so you '
          'never have to guess which element to move.',
      pseudocode: const [
        'int left = 0, right = numbers.length - 1;',
        'while (left < right) {',
        '    int sum = numbers[left] + numbers[right];',
        '    if (sum == target) return new int[]{left + 1, right + 1};',
        '    else if (sum < target) left++;   // need a bigger sum',
        '    else right--;                    // need a smaller sum',
        '}',
        'return new int[]{};',
      ],
      steps: steps,
      timeComplexity: 'O(n) — the two pointers only ever move inward',
      spaceComplexity: 'O(1) — no hash map needed',
      takeaway:
          'Sum too small means move left up; too big means move right down. '
          'Each comparison eliminates a whole column of pairs.',
      problemIds: const ['10'],
    );
  }

  // ----------------------------------------------------------------- 11

  static AlgorithmTrace threeSum() {
    const raw = [-1, 0, 1, 2, -1, -4];
    final nums = List<int>.from(raw)..sort();
    final values = nums.map((n) => '$n').toList();
    final steps = <VizStep>[];
    final results = <List<int>>[];

    steps.add(
      VizStep(
        caption:
            'Find every unique triple that sums to zero. Sorting first turns '
            'this into "pick one number, then run Two Sum on the rest" — and '
            'sorting is also what makes duplicates easy to skip.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: raw.map((n) => '$n').toList(), title: 'input'),
          ArrayScene(values: values, title: 'after sorting'),
        ],
      ),
    );

    for (var i = 0; i < nums.length - 2; i++) {
      if (i > 0 && nums[i] == nums[i - 1]) {
        steps.add(
          VizStep(
            caption:
                'nums[$i] is ${nums[i]}, the same as the previous anchor. '
                'Any triple starting here was already found, so skip it — '
                'this is how duplicates are avoided without a set.',
            codeLine: 3,
            scenes: [
              ArrayScene(
                values: values,
                title: 'after sorting',
                states: {i: VizState.dim, i - 1: VizState.done},
                pointers: {'i': i},
              ),
            ],
          ),
        );
        continue;
      }

      if (nums[i] > 0) {
        steps.add(
          VizStep(
            caption:
                'The anchor ${nums[i]} is positive, and everything after it '
                'is at least as large. Three positives can never sum to zero, '
                'so we can stop entirely.',
            codeLine: 2,
            scenes: [
              ArrayScene(
                values: values,
                title: 'after sorting',
                states: {
                  for (var j = i; j < values.length; j++) j: VizState.fail,
                },
                pointers: {'i': i},
              ),
            ],
          ),
        );
        break;
      }

      var left = i + 1;
      var right = nums.length - 1;

      steps.add(
        VizStep(
          caption:
              'Anchor on nums[$i] = ${nums[i]}. Now we need two numbers from '
              'the right-hand side that sum to ${-nums[i]}.',
          codeLine: 4,
          scenes: [
            ArrayScene(
              values: values,
              title: 'after sorting',
              states: {i: VizState.active},
              window: (start: left, end: right),
              windowLabel: 'search here',
              pointers: {'i': i, 'left': left, 'right': right},
            ),
            ValueScene(
              readings: [
                (label: 'need', value: '${-nums[i]}', state: VizState.active),
              ],
            ),
          ],
        ),
      );

      while (left < right) {
        final sum = nums[i] + nums[left] + nums[right];

        if (sum == 0) {
          results.add([nums[i], nums[left], nums[right]]);
          steps.add(
            VizStep(
              caption:
                  '${nums[i]} + ${nums[left]} + ${nums[right]} = 0. That is a '
                  'triple. Record it, then move both pointers past their '
                  'duplicates so the same triple is not found twice.',
              codeLine: 7,
              scenes: [
                ArrayScene(
                  values: values,
                  title: 'after sorting',
                  states: {
                    i: VizState.success,
                    left: VizState.success,
                    right: VizState.success,
                  },
                  pointers: {'i': i, 'left': left, 'right': right},
                ),
                ValueScene(
                  readings: [
                    (
                      label: 'found',
                      value: results.map((t) => '[${t.join(",")}]').join(' '),
                      state: VizState.success,
                    ),
                  ],
                ),
              ],
            ),
          );

          left++;
          right--;
          while (left < right && nums[left] == nums[left - 1]) {
            left++;
          }
          while (left < right && nums[right] == nums[right + 1]) {
            right--;
          }
        } else {
          final tooSmall = sum < 0;
          steps.add(
            VizStep(
              caption:
                  '${nums[i]} + ${nums[left]} + ${nums[right]} = $sum, which '
                  'is ${tooSmall ? "below" : "above"} zero. '
                  '${tooSmall ? "Move left up to gain." : "Move right down to lose."}',
              codeLine: tooSmall ? 9 : 11,
              scenes: [
                ArrayScene(
                  values: values,
                  title: 'after sorting',
                  states: {
                    i: VizState.active,
                    left: VizState.compare,
                    right: VizState.compare,
                  },
                  pointers: {'i': i, 'left': left, 'right': right},
                ),
                ValueScene(
                  readings: [
                    (label: 'sum', value: '$sum', state: VizState.fail),
                  ],
                ),
              ],
            ),
          );
          if (tooSmall) {
            left++;
          } else {
            right--;
          }
        }
      }
    }

    steps.add(
      VizStep(
        caption:
            'Every anchor has been tried. The unique triples are '
            '${results.map((t) => '[${t.join(", ")}]').join(' and ')}.',
        codeLine: 13,
        insight:
            'The three duplicate-skips are the whole difficulty of this '
            'problem. Sorting is what makes them possible: identical values '
            'always sit next to each other.',
        scenes: [
          ValueScene(
            readings: [
              (
                label: 'answer',
                value: results.map((t) => '[${t.join(",")}]').join(' '),
                state: VizState.success,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'three-sum',
      title: '3Sum',
      pattern: 'Two Pointers',
      patternIdea:
          'Fix one element, then the remaining problem is Two Sum on a sorted '
          'array — which two pointers solve in linear time.',
      pseudocode: const [
        'Arrays.sort(nums);',
        'for (int i = 0; i < nums.length - 2; i++) {',
        '    if (nums[i] > 0) break;',
        '    if (i > 0 && nums[i] == nums[i - 1]) continue;',
        '    int left = i + 1, right = nums.length - 1;',
        '    while (left < right) {',
        '        int sum = nums[i] + nums[left] + nums[right];',
        '        if (sum == 0) {  res.add(...);  left++; right--;',
        '            while (left < right && nums[left] == nums[left-1]) left++;',
        '        } else if (sum < 0) left++;',
        '        else right--;',
        '    }',
        '}',
        'return res;',
      ],
      steps: steps,
      timeComplexity: 'O(n²) — one pass per anchor',
      spaceComplexity: 'O(1) beyond the sort and the output',
      takeaway:
          'Skip a duplicate anchor with continue, and skip duplicate pointers '
          'only after recording a hit.',
      problemIds: const ['11', 'b9'],
    );
  }

  // ----------------------------------------------------------------- 12

  static AlgorithmTrace containerWithMostWater() {
    const height = [1, 8, 6, 2, 5, 4, 8, 3, 7];
    final values = height.map((n) => '$n').toList();
    final steps = <VizStep>[];

    var left = 0;
    var right = height.length - 1;
    var best = 0;
    var bestPair = (l: 0, r: 0);

    steps.add(
      VizStep(
        caption:
            'Pick two lines to form a container. Its area is the width '
            'between them times the shorter of the two. Trying every pair is '
            'n squared, so start at the widest and work inward.',
        codeLine: 0,
        scenes: [
          ArrayScene(
            values: values,
            title: 'height',
            pointers: {'left': left, 'right': right},
          ),
        ],
      ),
    );

    while (left < right) {
      final h = height[left] < height[right] ? height[left] : height[right];
      final area = (right - left) * h;
      final improved = area > best;
      if (improved) {
        best = area;
        bestPair = (l: left, r: right);
      }

      steps.add(
        VizStep(
          caption:
              'Width is ${right - left}, and the shorter wall is $h, so the '
              'area is ${right - left} × $h = $area. '
              '${improved ? "That is the best so far." : "The best is still $best."}',
          codeLine: 3,
          scenes: [
            ArrayScene(
              values: values,
              title: 'height',
              states: {
                left: improved ? VizState.success : VizState.compare,
                right: improved ? VizState.success : VizState.compare,
              },
              window: (start: left, end: right),
              windowLabel: 'area $area',
              pointers: {'left': left, 'right': right},
            ),
            ValueScene(
              readings: [(label: 'best', value: '$best', state: VizState.idle)],
            ),
          ],
        ),
      );

      final moveLeft = height[left] < height[right];
      steps.add(
        VizStep(
          caption: moveLeft
              ? 'The left wall (${height[left]}) is the shorter one. Moving '
                    'the taller right wall could only lose width without '
                    'gaining height, so move left inward instead.'
              : 'The right wall (${height[right]}) is the shorter one, so it '
                    'is the limiting factor. Move it inward and hope for a '
                    'taller wall.',
          codeLine: moveLeft ? 4 : 5,
          scenes: [
            ArrayScene(
              values: values,
              title: 'height',
              states: {(moveLeft ? left : right): VizState.fail},
              pointers: {'left': left, 'right': right},
            ),
          ],
        ),
      );

      if (moveLeft) {
        left++;
      } else {
        right--;
      }
    }

    steps.add(
      VizStep(
        caption:
            'The pointers have met. The largest container holds $best, formed '
            'by the walls at index ${bestPair.l} and ${bestPair.r}.',
        codeLine: 7,
        insight:
            'Moving the shorter wall is safe because the area is capped by it. '
            'Keeping it and shrinking the width can never beat what we just '
            'measured, so that whole set of pairs can be discarded.',
        scenes: [
          ArrayScene(
            values: values,
            title: 'height',
            states: {
              for (var j = 0; j < values.length; j++) j: VizState.dim,
              bestPair.l: VizState.success,
              bestPair.r: VizState.success,
            },
            window: (start: bestPair.l, end: bestPair.r),
            windowLabel: 'largest container',
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
      id: 'container-with-most-water',
      title: 'Container With Most Water',
      pattern: 'Two Pointers',
      patternIdea:
          'When one side clearly limits the result, moving that side is the '
          'only move that can possibly improve it.',
      pseudocode: const [
        'int left = 0, right = height.length - 1, best = 0;',
        'while (left < right) {',
        '    int h = Math.min(height[left], height[right]);  // limiting wall',
        '    best = Math.max(best, (right - left) * h);',
        '    if (height[left] < height[right]) left++;',
        '    else right--;',
        '}',
        'return best;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — each pointer moves at most n times',
      spaceComplexity: 'O(1)',
      takeaway:
          'Always move the shorter wall. Moving the taller one loses width '
          'without any chance of gaining height.',
      problemIds: const ['12', 'b10'],
    );
  }
}
