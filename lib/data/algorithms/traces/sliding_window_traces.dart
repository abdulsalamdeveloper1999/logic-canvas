import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// Animated walkthroughs for the Sliding Window problems (13, 15).
class SlidingWindowTraces {
  const SlidingWindowTraces._();

  static List<AlgorithmTrace> get all => [
    bestTimeToBuyAndSell(),
    longestRepeatingCharacterReplacement(),
  ];

  // ----------------------------------------------------------------- 13

  static AlgorithmTrace bestTimeToBuyAndSell() {
    const prices = [7, 1, 5, 3, 6, 4];
    final values = prices.map((n) => '$n').toList();
    final steps = <VizStep>[];

    var cheapest = prices[0];
    var cheapestAt = 0;
    var best = 0;
    var bestBuy = 0;
    var bestSell = 0;

    steps.add(
      VizStep(
        caption:
            'Buy on one day and sell on a later day for the largest profit. '
            'You only need to remember the cheapest price seen so far — the '
            'best sale today is always against that.',
        codeLine: 0,
        scenes: [ArrayScene(values: values, title: 'prices')],
      ),
    );

    for (var i = 1; i < prices.length; i++) {
      final profit = prices[i] - cheapest;
      final improved = profit > best;
      if (improved) {
        best = profit;
        bestBuy = cheapestAt;
        bestSell = i;
      }

      steps.add(
        VizStep(
          caption:
              'On day $i the price is ${prices[i]}. The cheapest so far was '
              '$cheapest on day $cheapestAt, so selling today makes '
              '${prices[i]} − $cheapest = $profit. '
              '${improved ? "New best." : "Best stays $best."}',
          codeLine: 2,
          scenes: [
            ArrayScene(
              values: values,
              title: 'prices',
              states: {
                cheapestAt: VizState.compare,
                i: improved ? VizState.success : VizState.active,
              },
              pointers: {'buy': cheapestAt, 'today': i},
            ),
            ValueScene(
              readings: [
                (
                  label: 'best profit',
                  value: '$best',
                  state: improved ? VizState.success : VizState.idle,
                ),
              ],
            ),
          ],
        ),
      );

      if (prices[i] < cheapest) {
        cheapest = prices[i];
        cheapestAt = i;
        steps.add(
          VizStep(
            caption:
                '${prices[i]} is cheaper than anything before it, so it '
                'becomes the new buy day. Any future sale should be measured '
                'against this price.',
            codeLine: 3,
            scenes: [
              ArrayScene(
                values: values,
                title: 'prices',
                states: {i: VizState.active},
                pointers: {'buy': i},
              ),
            ],
          ),
        );
      }
    }

    steps.add(
      VizStep(
        caption:
            'One pass, done. Buy on day $bestBuy at ${prices[bestBuy]} and '
            'sell on day $bestSell at ${prices[bestSell]} for a profit of '
            '$best.',
        codeLine: 5,
        insight:
            'Notice we never went back to compare pairs. Tracking the running '
            'minimum turns an O(n²) pair search into a single sweep — the same '
            'idea behind most "best so far" problems.',
        scenes: [
          ArrayScene(
            values: values,
            title: 'prices',
            states: {
              for (var j = 0; j < values.length; j++) j: VizState.dim,
              bestBuy: VizState.success,
              bestSell: VizState.success,
            },
            pointers: {'buy': bestBuy, 'sell': bestSell},
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
      id: 'best-time-to-buy-sell-stock',
      title: 'Best Time to Buy and Sell Stock',
      pattern: 'Sliding Window',
      patternIdea:
          'Carry the best "left edge" seen so far instead of re-examining '
          'every earlier element.',
      pseudocode: const [
        'int cheapest = prices[0], best = 0;',
        'for (int i = 1; i < prices.length; i++) {',
        '    int profit = prices[i] - cheapest;  if (profit > best) best = profit;',
        '    if (prices[i] < cheapest) cheapest = prices[i];',
        '}',
        'return best;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — a single pass',
      spaceComplexity: 'O(1) — two running values',
      takeaway:
          'Compute the profit before updating the minimum. Swap those two '
          'lines and you allow buying and selling on the same day.',
      problemIds: const ['13', 'b2'],
    );
  }

  // ----------------------------------------------------------------- 15

  static AlgorithmTrace longestRepeatingCharacterReplacement() {
    const text = 'AABABBA';
    const k = 1;
    final values = text.split('');
    final steps = <VizStep>[];

    final count = <String, int>{};
    var left = 0;
    var maxFreq = 0;
    var best = 0;
    var bestRange = (start: 0, end: 0);

    List<({String key, String value, VizState state})> countPanel() {
      return count.entries
          .where((e) => e.value > 0)
          .map((e) => (key: e.key, value: '${e.value}', state: VizState.idle))
          .toList();
    }

    steps.add(
      VizStep(
        caption:
            'With at most $k replacement, how long a run of one letter can we '
            'make in "$text"? A window is valid when the letters we would '
            'need to replace — its length minus its most common letter — is '
            'at most $k.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: values, title: 's'),
          const MapScene(
            entries: [],
            title: 'counts in window',
            emptyLabel: 'window empty',
          ),
        ],
      ),
    );

    for (var right = 0; right < values.length; right++) {
      final ch = values[right];
      count[ch] = (count[ch] ?? 0) + 1;
      if (count[ch]! > maxFreq) maxFreq = count[ch]!;

      steps.add(
        VizStep(
          caption:
              'Extend the window to include "$ch". The most common letter in '
              'the window now appears $maxFreq times.',
          codeLine: 2,
          scenes: [
            ArrayScene(
              values: values,
              title: 's',
              states: {right: VizState.active},
              window: (start: left, end: right),
              windowLabel: 'window',
              pointers: {'left': left, 'right': right},
            ),
            MapScene(entries: countPanel(), title: 'counts in window'),
            ValueScene(
              readings: [
                (label: 'maxFreq', value: '$maxFreq', state: VizState.active),
              ],
            ),
          ],
        ),
      );

      final windowLength = right - left + 1;
      final toReplace = windowLength - maxFreq;

      if (toReplace > k) {
        final removed = values[left];
        count[removed] = count[removed]! - 1;
        left++;

        steps.add(
          VizStep(
            caption:
                'The window is $windowLength long with $maxFreq of its most '
                'common letter, so $windowLength − $maxFreq = $toReplace '
                'letters would need replacing — more than $k. Drop "$removed" '
                'from the left to restore the rule.',
            codeLine: 4,
            scenes: [
              ArrayScene(
                values: values,
                title: 's',
                states: {left - 1: VizState.fail},
                window: (start: left, end: right),
                windowLabel: 'window',
                pointers: {'left': left, 'right': right},
              ),
              MapScene(entries: countPanel(), title: 'counts in window'),
            ],
          ),
        );
      }

      final length = right - left + 1;
      if (length > best) {
        best = length;
        bestRange = (start: left, end: right);
      }

      steps.add(
        VizStep(
          caption:
              'The window is valid and $length long. Best so far is $best.',
          codeLine: 5,
          scenes: [
            ArrayScene(
              values: values,
              title: 's',
              states: {for (var j = left; j <= right; j++) j: VizState.success},
              window: (start: left, end: right),
              windowLabel: 'valid window (length $length)',
              pointers: {'left': left, 'right': right},
            ),
            ValueScene(
              readings: [(label: 'best', value: '$best', state: VizState.idle)],
            ),
          ],
        ),
      );
    }

    steps.add(
      VizStep(
        caption:
            'The longest achievable run is $best characters, using at most '
            '$k replacement.',
        codeLine: 7,
        insight:
            'maxFreq is never decreased, even when the window shrinks. That '
            'looks like a bug and is not: a stale maxFreq can only make the '
            'window look valid when it is not, and the window never grows '
            'beyond the true best, so the answer stays correct — and the '
            'algorithm stays O(n).',
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
            windowLabel: 'best window',
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
      id: 'longest-repeating-char-replacement',
      title: 'Longest Repeating Character Replacement',
      pattern: 'Sliding Window',
      patternIdea:
          'Define what makes a window valid as a single arithmetic test, then '
          'grow right and shrink left to keep that test true.',
      pseudocode: const [
        'int[] count = new int[26];  int left = 0, maxFreq = 0, best = 0;',
        'for (int right = 0; right < s.length(); right++) {',
        '    maxFreq = Math.max(maxFreq, ++count[s.charAt(right) - \'A\']);',
        '    // valid while windowLength - maxFreq <= k',
        '    if ((right-left+1) - maxFreq > k) count[s.charAt(left++)-\'A\']--;',
        '    best = Math.max(best, right - left + 1);',
        '}',
        'return best;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — left and right each cross the string once',
      spaceComplexity: 'O(1) — 26 counters',
      takeaway:
          'The valid-window test is windowLength − maxFreq <= k. Do not '
          'recompute or decrease maxFreq when shrinking; leaving it stale is '
          'correct and is what keeps this linear.',
      problemIds: const ['15'],
    );
  }
}
