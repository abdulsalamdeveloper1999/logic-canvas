import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// A binary min-heap kept in an array, exactly as `PriorityQueue` stores one.
/// Index i has children 2i+1 and 2i+2, which is why the array renders directly
/// as a tree.
class _MinHeap {
  final List<int> items = [];
  final bool max;

  _MinHeap({this.max = false});

  bool _higher(int a, int b) => max ? a > b : a < b;

  int get length => items.length;
  int get peek => items.first;

  void push(int v) {
    items.add(v);
    var i = items.length - 1;
    while (i > 0) {
      final parent = (i - 1) ~/ 2;
      if (!_higher(items[i], items[parent])) break;
      final t = items[i];
      items[i] = items[parent];
      items[parent] = t;
      i = parent;
    }
  }

  int pop() {
    final top = items.first;
    final last = items.removeLast();
    if (items.isNotEmpty) {
      items[0] = last;
      var i = 0;
      while (true) {
        final l = i * 2 + 1;
        final r = i * 2 + 2;
        var best = i;
        if (l < items.length && _higher(items[l], items[best])) best = l;
        if (r < items.length && _higher(items[r], items[best])) best = r;
        if (best == i) break;
        final t = items[i];
        items[i] = items[best];
        items[best] = t;
        i = best;
      }
    }
    return top;
  }

  List<String?> get heap => items.map((v) => '$v').toList();
}

/// Animated walkthroughs for the Heap / Priority Queue problems (40–42).
class HeapTraces {
  const HeapTraces._();

  static List<AlgorithmTrace> get all => [
    kthLargestStream(),
    lastStoneWeight(),
    kthLargestArray(),
  ];

  // ----------------------------------------------------------------- 40

  static AlgorithmTrace kthLargestStream() {
    const k = 3;
    const initial = [4, 5, 8, 2];
    const additions = [3, 5, 10, 9, 4];
    final steps = <VizStep>[];
    final heap = _MinHeap();

    steps.add(
      const VizStep(
        caption:
            'Report the 3rd largest value after each new number arrives. '
            'Keeping everything sorted is wasteful — we only ever need the top '
            '3, so hold exactly 3 in a min-heap.',
        codeLine: 0,
        scenes: [TreeScene(heap: [], title: 'min-heap (size ≤ 3)')],
      ),
    );

    for (final v in initial) {
      heap.push(v);
      if (heap.length > k) heap.pop();
    }

    steps.add(
      VizStep(
        caption:
            'After seeding with ${initial.join(", ")}, the heap holds the top '
            '$k values. Its smallest element sits at the root, and that root '
            'is the ${k}rd largest overall: ${heap.peek}.',
        codeLine: 3,
        scenes: [
          TreeScene(
            heap: heap.heap,
            states: {0: VizState.success},
            title: 'min-heap (size ≤ 3)',
          ),
          ValueScene(
            readings: [
              (
                label: 'kth largest',
                value: '${heap.peek}',
                state: VizState.success,
              ),
            ],
          ),
        ],
      ),
    );

    for (final v in additions) {
      heap.push(v);
      final overflowed = heap.length > k;
      final evicted = overflowed ? heap.pop() : null;

      steps.add(
        VizStep(
          caption: overflowed
              ? 'add($v). The heap now holds ${k + 1} values, so drop the '
                    'smallest ($evicted). The root — and the answer — is '
                    '${heap.peek}.'
              : 'add($v). The heap still has room, so nothing is evicted. The '
                    'answer is ${heap.peek}.',
          codeLine: 5,
          scenes: [
            TreeScene(
              heap: heap.heap,
              states: {0: VizState.success},
              title: 'min-heap (size ≤ 3)',
            ),
            ValueScene(
              readings: [
                (
                  label: 'kth largest',
                  value: '${heap.peek}',
                  state: VizState.success,
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
            'Every add cost only O(log k), because the heap never grew past '
            '$k elements.',
        codeLine: 6,
        insight:
            'A min-heap for the k largest feels backwards until you see why: '
            'the cheapest element to discard is the smallest of the ones you '
            'are keeping, and a min-heap puts exactly that on top.',
        scenes: [
          TreeScene(
            heap: heap.heap,
            states: {for (var i = 0; i < heap.length; i++) i: VizState.success},
            title: 'final heap',
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'kth-largest-stream',
      title: 'Kth Largest Element in a Stream',
      pattern: 'Heap',
      patternIdea:
          'To track the k largest, keep a min-heap of size k and evict its '
          'root whenever it overflows.',
      pseudocode: const [
        'PriorityQueue<Integer> heap = new PriorityQueue<>();  // min-heap',
        'KthLargest(int k, int[] nums) {',
        '    for (int n : nums) add(n);',
        '}',
        'int add(int val) {',
        '    heap.offer(val);',
        '    if (heap.size() > k) heap.poll();',
        '    return heap.peek();',
        '}',
      ],
      steps: steps,
      timeComplexity: 'O(log k) per add',
      spaceComplexity: 'O(k)',
      takeaway:
          'Use a min-heap for the k largest, and a max-heap for the k '
          'smallest. The heap type is the opposite of what the question says.',
      problemIds: const ['40'],
    );
  }

  // ----------------------------------------------------------------- 41

  static AlgorithmTrace lastStoneWeight() {
    const stones = [2, 7, 4, 1, 8, 1];
    final steps = <VizStep>[];
    final heap = _MinHeap(max: true);
    for (final s in stones) {
      heap.push(s);
    }

    steps.add(
      VizStep(
        caption:
            'Repeatedly smash the two heaviest stones together. We always '
            'need the current maximum, and the set changes every round — that '
            'is precisely what a max-heap is for.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: stones.map((s) => '$s').toList(), title: 'stones'),
          TreeScene(
            heap: heap.heap,
            states: {0: VizState.active},
            title: 'max-heap',
          ),
        ],
      ),
    );

    while (heap.length > 1) {
      final a = heap.pop();
      final b = heap.pop();
      final diff = a - b;
      if (diff > 0) heap.push(diff);

      steps.add(
        VizStep(
          caption: diff > 0
              ? 'Take the two heaviest, $a and $b. They differ by $diff, so a '
                    'stone of weight $diff goes back into the heap.'
              : 'Take the two heaviest, $a and $b. They are equal, so both are '
                    'destroyed and nothing returns.',
          codeLine: 4,
          scenes: [
            TreeScene(
              heap: heap.heap,
              states: heap.length > 0 ? {0: VizState.active} : const {},
              title: 'max-heap',
            ),
            ValueScene(
              readings: [
                (
                  label: 'smashed',
                  value: '$a vs $b → ${diff > 0 ? diff : "both gone"}',
                  state: VizState.compare,
                ),
              ],
            ),
          ],
        ),
      );
    }

    final answer = heap.length == 1 ? heap.peek : 0;
    steps.add(
      VizStep(
        caption: heap.length == 1
            ? 'One stone is left, weighing $answer.'
            : 'No stones remain, so the answer is 0.',
        codeLine: 6,
        insight:
            'Java has no max-heap, so build one with '
            'PriorityQueue<>(Collections.reverseOrder()). Forgetting the '
            'comparator silently gives you the two lightest stones instead.',
        scenes: [
          ValueScene(
            readings: [
              (label: 'answer', value: '$answer', state: VizState.success),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'last-stone-weight',
      title: 'Last Stone Weight',
      pattern: 'Heap',
      patternIdea:
          'When you repeatedly need the largest item from a changing '
          'collection, a heap beats re-sorting every round.',
      pseudocode: const [
        'PriorityQueue<Integer> heap =',
        '    new PriorityQueue<>(Collections.reverseOrder());',
        'for (int s : stones) heap.offer(s);',
        'while (heap.size() > 1) {',
        '    int a = heap.poll(), b = heap.poll();',
        '    if (a != b) heap.offer(a - b);',
        '}',
        'return heap.isEmpty() ? 0 : heap.peek();',
      ],
      steps: steps,
      timeComplexity: 'O(n log n) — each smash costs O(log n)',
      spaceComplexity: 'O(n)',
      takeaway:
          'Handle the empty-heap case at the end; smashing equal stones can '
          'leave nothing behind.',
      problemIds: const ['41'],
    );
  }

  // ----------------------------------------------------------------- 42

  static AlgorithmTrace kthLargestArray() {
    const nums = [3, 2, 1, 5, 6, 4];
    const k = 2;
    final steps = <VizStep>[];
    final heap = _MinHeap();

    steps.add(
      const VizStep(
        caption:
            'Find the 2nd largest value. Sorting the whole array costs '
            'n log n; a min-heap capped at k costs n log k, which is much less '
            'when k is small.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: ['3', '2', '1', '5', '6', '4'], title: 'nums'),
        ],
      ),
    );

    for (var i = 0; i < nums.length; i++) {
      heap.push(nums[i]);
      final overflowed = heap.length > k;
      final evicted = overflowed ? heap.pop() : null;

      steps.add(
        VizStep(
          caption: overflowed
              ? 'Offer ${nums[i]}, then evict the heap\'s smallest '
                    '($evicted) to stay at size $k. Whatever is left are the '
                    'best $k seen so far.'
              : 'Offer ${nums[i]}. The heap is not full yet, so nothing is '
                    'evicted.',
          codeLine: 3,
          scenes: [
            ArrayScene(
              values: nums.map((n) => '$n').toList(),
              title: 'nums',
              states: {
                for (var j = 0; j < i; j++) j: VizState.done,
                i: VizState.active,
              },
              pointers: {'i': i},
            ),
            TreeScene(
              heap: heap.heap,
              states: {0: VizState.success},
              title: 'min-heap of the top $k',
            ),
          ],
        ),
      );
    }

    steps.add(
      VizStep(
        caption:
            'The heap holds the $k largest values, and its root is the '
            'smallest of them — so the ${k}nd largest is ${heap.peek}.',
        codeLine: 4,
        insight:
            'Quickselect solves this in O(n) average time, but the heap '
            'version is far easier to write correctly under interview '
            'pressure. Say both out loud; implement this one.',
        scenes: [
          TreeScene(
            heap: heap.heap,
            states: {0: VizState.success},
            title: 'min-heap of the top $k',
          ),
          ValueScene(
            readings: [
              (label: 'answer', value: '${heap.peek}', state: VizState.success),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'kth-largest-array',
      title: 'Kth Largest Element in an Array',
      pattern: 'Heap',
      patternIdea:
          'You rarely need full order — only the boundary between kept and '
          'discarded.',
      pseudocode: const [
        'PriorityQueue<Integer> heap = new PriorityQueue<>();  // min-heap',
        'for (int n : nums) {',
        '    heap.offer(n);',
        '    if (heap.size() > k) heap.poll();',
        '}',
        'return heap.peek();',
      ],
      steps: steps,
      timeComplexity: 'O(n log k)',
      spaceComplexity: 'O(k)',
      takeaway:
          'Poll immediately after every offer. Letting the heap grow to n '
          'throws away the whole advantage.',
      problemIds: const ['42'],
    );
  }
}
