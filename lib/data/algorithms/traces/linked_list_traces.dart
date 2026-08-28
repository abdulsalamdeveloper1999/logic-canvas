import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// Animated walkthroughs for the Linked List problems (23–27).
class LinkedListTraces {
  const LinkedListTraces._();

  static List<AlgorithmTrace> get all => [
    mergeTwoSortedLists(),
    reorderList(),
    removeNthFromEnd(),
    linkedListCycle(),
    lruCache(),
  ];

  /// A straight chain: node i points at i + 1, and the last points at null.
  static List<int?> _chain(int length) => [
    for (var i = 0; i < length; i++) i + 1 < length ? i + 1 : null,
  ];

  // ----------------------------------------------------------------- 23

  static AlgorithmTrace mergeTwoSortedLists() {
    const a = [1, 2, 4];
    const b = [1, 3, 4];
    final steps = <VizStep>[];
    final merged = <String>[];

    var i = 0;
    var j = 0;

    steps.add(
      VizStep(
        caption:
            'Both lists are already sorted, so the smallest remaining value '
            'is always at the front of one of them. Compare the two heads and '
            'take the smaller — repeatedly.',
        codeLine: 0,
        scenes: [
          LinkedListScene(
            values: a.map((n) => '$n').toList(),
            next: _chain(a.length),
            pointers: {'a': 0},
            title: 'list 1',
          ),
          LinkedListScene(
            values: b.map((n) => '$n').toList(),
            next: _chain(b.length),
            pointers: {'b': 0},
            title: 'list 2',
          ),
        ],
      ),
    );

    while (i < a.length && j < b.length) {
      final takeA = a[i] <= b[j];
      merged.add('${takeA ? a[i] : b[j]}');

      steps.add(
        VizStep(
          caption:
              'Compare ${a[i]} and ${b[j]}. '
              '${takeA ? "List 1's head is not larger, so take ${a[i]}." : "List 2's head is smaller, so take ${b[j]}."} '
              'Ties go to list 1, which keeps the merge stable.',
          codeLine: takeA ? 2 : 3,
          scenes: [
            LinkedListScene(
              values: a.map((n) => '$n').toList(),
              next: _chain(a.length),
              states: {
                for (var x = 0; x < i; x++) x: VizState.done,
                i: takeA ? VizState.success : VizState.compare,
              },
              pointers: {'a': i},
              title: 'list 1',
            ),
            LinkedListScene(
              values: b.map((n) => '$n').toList(),
              next: _chain(b.length),
              states: {
                for (var x = 0; x < j; x++) x: VizState.done,
                j: takeA ? VizState.compare : VizState.success,
              },
              pointers: {'b': j},
              title: 'list 2',
            ),
            ArrayScene(values: merged, title: 'merged so far'),
          ],
        ),
      );

      if (takeA) {
        i++;
      } else {
        j++;
      }
    }

    final leftover = i < a.length ? 'list 1' : 'list 2';
    while (i < a.length) {
      merged.add('${a[i++]}');
    }
    while (j < b.length) {
      merged.add('${b[j++]}');
    }

    steps.add(
      VizStep(
        caption:
            'One list ran out. Everything still in $leftover is already '
            'sorted and larger than what we have taken, so append it whole '
            'rather than node by node.',
        codeLine: 6,
        scenes: [ArrayScene(values: merged, title: 'merged so far')],
      ),
    );

    steps.add(
      VizStep(
        caption: 'The merged list is ${merged.join(" → ")}.',
        codeLine: 7,
        insight:
            'The dummy head node is the real trick here. Without it you need a '
            'special case for the very first append, and that is where most '
            'linked-list bugs live.',
        scenes: [
          LinkedListScene(
            values: merged,
            next: _chain(merged.length),
            states: {
              for (var x = 0; x < merged.length; x++) x: VizState.success,
            },
            title: 'merged',
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'merge-two-sorted-lists',
      title: 'Merge Two Sorted Lists',
      pattern: 'Linked List',
      patternIdea:
          'When both inputs are sorted, the next output is always one of the '
          'two current heads.',
      pseudocode: const [
        'ListNode dummy = new ListNode(0), tail = dummy;',
        'while (l1 != null && l2 != null) {',
        '    if (l1.val <= l2.val) { tail.next = l1;  l1 = l1.next; }',
        '    else                  { tail.next = l2;  l2 = l2.next; }',
        '    tail = tail.next;',
        '}',
        'tail.next = (l1 != null) ? l1 : l2;   // attach the leftovers',
        'return dummy.next;',
      ],
      steps: steps,
      timeComplexity: 'O(n + m) — every node is visited once',
      spaceComplexity: 'O(1) — nodes are relinked, not copied',
      takeaway:
          'Use a dummy head so appending never needs a null check, and attach '
          'the leftover list in one move at the end.',
      problemIds: const ['23'],
    );
  }

  // ----------------------------------------------------------------- 24

  static AlgorithmTrace reorderList() {
    final values = ['1', '2', '3', '4'];
    final steps = <VizStep>[];

    steps.add(
      VizStep(
        caption:
            'Reorder 1→2→3→4 into 1→4→2→3: first node, last node, second, '
            'second-to-last, and so on. Doing that directly needs backwards '
            'traversal, which a singly linked list cannot do.',
        codeLine: 0,
        scenes: [
          LinkedListScene(
            values: values,
            next: _chain(values.length),
            title: 'list',
          ),
        ],
      ),
    );

    steps.add(
      VizStep(
        caption:
            'Step 1: find the middle with slow and fast pointers. Fast moves '
            'two nodes for every one that slow moves, so when fast reaches the '
            'end, slow is halfway.',
        codeLine: 1,
        scenes: [
          LinkedListScene(
            values: values,
            next: _chain(values.length),
            states: {1: VizState.active},
            pointers: {'slow': 1, 'fast': 3},
            title: 'list',
          ),
        ],
      ),
    );

    steps.add(
      VizStep(
        caption:
            'Step 2: split into 1→2 and 3→4, then reverse the second half so '
            'it becomes 4→3. Now the nodes we need to interleave are both at '
            'the front of a list.',
        codeLine: 3,
        scenes: [
          const LinkedListScene(
            values: ['1', '2'],
            next: [1, null],
            title: 'first half',
          ),
          const LinkedListScene(
            values: ['4', '3'],
            next: [1, null],
            states: {0: VizState.active, 1: VizState.active},
            title: 'second half, reversed',
          ),
        ],
      ),
    );

    steps.add(
      const VizStep(
        caption:
            'Step 3: weave them together, taking one node from each in turn. '
            'Take 1 from the first half, then 4 from the second.',
        codeLine: 5,
        scenes: [
          LinkedListScene(
            values: ['1', '4'],
            next: [1, null],
            states: {0: VizState.success, 1: VizState.success},
            title: 'result so far',
          ),
        ],
      ),
    );

    steps.add(
      const VizStep(
        caption: 'Then 2 from the first half and 3 from the second.',
        codeLine: 5,
        scenes: [
          LinkedListScene(
            values: ['1', '4', '2', '3'],
            next: [1, 2, 3, null],
            states: {2: VizState.success, 3: VizState.success},
            title: 'result so far',
          ),
        ],
      ),
    );

    steps.add(
      const VizStep(
        caption: 'The list is now 1→4→2→3, exactly as required.',
        codeLine: 6,
        insight:
            'This problem is three easier problems stacked: find the middle, '
            'reverse a list, merge two lists. Recognising that decomposition '
            'is the whole skill being tested.',
        scenes: [
          LinkedListScene(
            values: ['1', '4', '2', '3'],
            next: [1, 2, 3, null],
            states: {
              0: VizState.success,
              1: VizState.success,
              2: VizState.success,
              3: VizState.success,
            },
            title: 'final list',
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'reorder-list',
      title: 'Reorder List',
      pattern: 'Linked List',
      patternIdea:
          'Hard list problems usually decompose into find-the-middle, reverse, '
          'and merge.',
      pseudocode: const [
        '// 1. find middle with slow / fast pointers',
        'ListNode slow = head, fast = head;',
        'while (fast.next != null && fast.next.next != null) {',
        '    slow = slow.next;  fast = fast.next.next;  }',
        '// 2. reverse the second half',
        'ListNode second = reverse(slow.next);  slow.next = null;',
        '// 3. weave the two halves together',
        'while (second != null) { ... alternate nodes ... }',
      ],
      steps: steps,
      timeComplexity: 'O(n) — three linear passes',
      spaceComplexity: 'O(1) — all pointer rewiring, no copies',
      takeaway:
          'Cut the list at the middle before reversing, or the halves stay '
          'connected and the weave loops forever.',
      problemIds: const ['24'],
    );
  }

  // ----------------------------------------------------------------- 25

  static AlgorithmTrace removeNthFromEnd() {
    final values = ['1', '2', '3', '4', '5'];
    const n = 2;
    final steps = <VizStep>[];

    steps.add(
      VizStep(
        caption:
            'Remove the ${n}nd node from the end. Counting the length first '
            'means two passes; a gap between two pointers does it in one.',
        codeLine: 0,
        scenes: [
          LinkedListScene(
            values: values,
            next: _chain(values.length),
            title: 'list',
          ),
        ],
      ),
    );

    steps.add(
      VizStep(
        caption:
            'Move fast $n nodes ahead of slow. That fixed gap of $n is the '
            'entire idea.',
        codeLine: 2,
        scenes: [
          LinkedListScene(
            values: values,
            next: _chain(values.length),
            states: {0: VizState.active, n: VizState.active},
            pointers: {'slow': 0, 'fast': n},
            title: 'list',
          ),
        ],
      ),
    );

    var slow = 0;
    var fast = n;
    while (fast < values.length - 1) {
      slow++;
      fast++;
      steps.add(
        VizStep(
          caption:
              'Advance both together, keeping the gap at $n. slow is now at '
              '${values[slow]} and fast at ${values[fast]}.',
          codeLine: 4,
          scenes: [
            LinkedListScene(
              values: values,
              next: _chain(values.length),
              states: {slow: VizState.active, fast: VizState.active},
              pointers: {'slow': slow, 'fast': fast},
              title: 'list',
            ),
          ],
        ),
      );
    }

    final removeIndex = slow + 1;
    steps.add(
      VizStep(
        caption:
            'fast has reached the last node, so slow sits exactly one before '
            'the node to remove — ${values[removeIndex]}. Skip over it by '
            'pointing slow.next at the node after.',
        codeLine: 5,
        scenes: [
          LinkedListScene(
            values: values,
            next: [
              for (var i = 0; i < values.length; i++)
                if (i == slow)
                  (removeIndex + 1 < values.length ? removeIndex + 1 : null)
                else if (i + 1 < values.length)
                  i + 1
                else
                  null,
            ],
            states: {removeIndex: VizState.fail, slow: VizState.success},
            pointers: {'slow': slow},
            title: 'list',
          ),
        ],
      ),
    );

    final remaining = [
      for (var i = 0; i < values.length; i++)
        if (i != removeIndex) values[i],
    ];

    steps.add(
      VizStep(
        caption:
            'The list is now ${remaining.join(" → ")}, done in a single pass.',
        codeLine: 6,
        insight:
            'Start fast from a dummy node placed before the head. Otherwise '
            'removing the very first node has no "previous" to rewire, and '
            'that is the edge case this problem is really testing.',
        scenes: [
          LinkedListScene(
            values: remaining,
            next: _chain(remaining.length),
            states: {
              for (var i = 0; i < remaining.length; i++) i: VizState.success,
            },
            title: 'result',
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'remove-nth-from-end',
      title: 'Remove Nth Node From End of List',
      pattern: 'Linked List',
      patternIdea:
          'A fixed gap between two pointers converts "distance from the end" '
          'into "distance from here".',
      pseudocode: const [
        'ListNode dummy = new ListNode(0, head);',
        'ListNode slow = dummy, fast = dummy;',
        'for (int i = 0; i < n; i++) fast = fast.next;',
        'while (fast.next != null) {',
        '    slow = slow.next;  fast = fast.next;',
        '}',
        'slow.next = slow.next.next;',
        'return dummy.next;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — one pass',
      spaceComplexity: 'O(1)',
      takeaway:
          'Anchor both pointers on a dummy node so removing the head needs no '
          'special case.',
      problemIds: const ['25'],
    );
  }

  // ----------------------------------------------------------------- 26

  static AlgorithmTrace linkedListCycle() {
    final values = ['3', '2', '0', '-4'];
    // The last node links back to index 1, forming a cycle.
    const next = <int?>[1, 2, 3, 1];
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'Does this list loop back on itself? Storing every visited node '
            'costs O(n) memory. Two pointers at different speeds cost nothing '
            'and settle it just as well.',
        codeLine: 0,
        scenes: [
          LinkedListScene(
            values: ['3', '2', '0', '-4'],
            next: next,
            title: 'list (the last node links back)',
          ),
        ],
      ),
    );

    var slow = 0;
    var fast = 0;
    var met = false;

    for (var round = 0; round < 6; round++) {
      final nextSlow = next[slow];
      final oneStep = next[fast];
      final twoStep = oneStep == null ? null : next[oneStep];
      if (nextSlow == null || twoStep == null) break;

      slow = nextSlow;
      fast = twoStep;

      met = slow == fast;
      steps.add(
        VizStep(
          caption: met
              ? 'slow and fast have landed on the same node (${values[slow]}). '
                    'On a straight list fast would have run off the end, so '
                    'meeting proves there is a cycle.'
              : 'slow moves one node to ${values[slow]}; fast moves two to '
                    '${values[fast]}. They have not met yet.',
          codeLine: met ? 4 : 3,
          scenes: [
            LinkedListScene(
              values: values,
              next: next,
              states: {
                slow: met ? VizState.success : VizState.active,
                fast: met ? VizState.success : VizState.compare,
              },
              pointers: {'slow': slow, 'fast': fast},
              title: 'list',
            ),
          ],
        ),
      );

      if (met) break;
    }

    steps.add(
      VizStep(
        caption: met
            ? 'The pointers met, so the answer is true — this list has a '
                  'cycle.'
            : 'fast reached the end, so there is no cycle.',
        codeLine: 6,
        insight:
            'Inside a cycle, fast gains exactly one node on slow per round, so '
            'it can never jump over slow — it must eventually land on it. That '
            'is why a gap of one step per round guarantees they meet.',
        scenes: [
          ValueScene(
            readings: [
              (
                label: 'result',
                value: '$met',
                state: met ? VizState.success : VizState.fail,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'linked-list-cycle',
      title: 'Linked List Cycle',
      pattern: 'Linked List',
      patternIdea:
          'Two pointers at different speeds detect a loop without storing '
          'anything.',
      pseudocode: const [
        'ListNode slow = head, fast = head;',
        'while (fast != null && fast.next != null) {',
        '    slow = slow.next;',
        '    fast = fast.next.next;',
        '    if (slow == fast) return true;',
        '}',
        'return false;',
      ],
      steps: steps,
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(1) — the whole point versus a HashSet',
      takeaway:
          'Check fast and fast.next before stepping, or a straight list of '
          'even length throws a null pointer exception.',
      problemIds: const ['26'],
    );
  }

  // ----------------------------------------------------------------- 27

  static AlgorithmTrace lruCache() {
    final steps = <VizStep>[];
    const capacity = 2;
    final order = <int>[]; // least recent first
    final store = <int, int>{};

    List<({String key, String value, VizState state})> mapPanel({int? hit}) {
      return store.entries
          .map(
            (e) => (
              key: '${e.key}',
              value: '${e.value}',
              state: e.key == hit ? VizState.success : VizState.idle,
            ),
          )
          .toList();
    }

    steps.add(
      const VizStep(
        caption:
            'An LRU cache needs get and put in O(1), and must evict the least '
            'recently used entry when full. A hash map gives O(1) lookup; a '
            'doubly linked list gives O(1) reordering. You need both.',
        codeLine: 0,
        scenes: [
          MapScene(entries: [], title: 'map', emptyLabel: 'empty'),
          LinkedListScene(
            values: [],
            next: [],
            title: 'usage order (oldest → newest)',
          ),
        ],
      ),
    );

    void put(int k, int v) {
      final evicting = !store.containsKey(k) && store.length >= capacity;
      int? evicted;
      if (evicting) {
        evicted = order.removeAt(0);
        store.remove(evicted);
      }
      order.remove(k);
      order.add(k);
      store[k] = v;

      steps.add(
        VizStep(
          caption: evicting
              ? 'put($k, $v). The cache is full, so evict the oldest key '
                    '($evicted) from both the list and the map, then insert '
                    '$k as the newest.'
              : 'put($k, $v). There is room, so add $k and mark it the most '
                    'recently used.',
          codeLine: evicting ? 5 : 4,
          scenes: [
            MapScene(
              entries: mapPanel(hit: k),
              title: 'map',
            ),
            LinkedListScene(
              values: order.map((x) => '$x').toList(),
              next: [
                for (var i = 0; i < order.length; i++)
                  i + 1 < order.length ? i + 1 : null,
              ],
              states: {order.length - 1: VizState.success},
              pointers: {'oldest': 0, 'newest': order.length - 1},
              title: 'usage order (oldest → newest)',
            ),
          ],
        ),
      );
    }

    put(1, 1);
    put(2, 2);

    // get(1) makes 1 the most recently used.
    order.remove(1);
    order.add(1);
    steps.add(
      VizStep(
        caption:
            'get(1) returns ${store[1]}. Reading counts as using, so 1 moves '
            'to the newest end. This move is why the list must be doubly '
            'linked — we have to unhook a node from the middle in O(1).',
        codeLine: 2,
        scenes: [
          MapScene(entries: mapPanel(hit: 1), title: 'map'),
          LinkedListScene(
            values: order.map((x) => '$x').toList(),
            next: [
              for (var i = 0; i < order.length; i++)
                i + 1 < order.length ? i + 1 : null,
            ],
            states: {order.length - 1: VizState.success},
            pointers: {'oldest': 0, 'newest': order.length - 1},
            title: 'usage order (oldest → newest)',
          ),
        ],
      ),
    );

    put(3, 3);

    steps.add(
      VizStep(
        caption:
            'Key 2 was evicted rather than key 1, because the get(1) call had '
            'refreshed 1. The cache now holds '
            '${store.keys.map((k) => "$k=${store[k]}").join(", ")}.',
        codeLine: 6,
        insight:
            'The map stores key → node, not key → value. That indirection is '
            'what lets you find a node and unlink it in constant time instead '
            'of walking the list to locate it.',
        scenes: [
          MapScene(entries: mapPanel(), title: 'map'),
          LinkedListScene(
            values: order.map((x) => '$x').toList(),
            next: [
              for (var i = 0; i < order.length; i++)
                i + 1 < order.length ? i + 1 : null,
            ],
            states: {
              for (var i = 0; i < order.length; i++) i: VizState.success,
            },
            title: 'usage order (oldest → newest)',
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'lru-cache',
      title: 'LRU Cache',
      pattern: 'Linked List',
      patternIdea:
          'Combine two structures when neither alone is fast enough: a map for '
          'lookup, a doubly linked list for ordering.',
      pseudocode: const [
        'Map<Integer, Node> map;  // key -> node in the list',
        'Node head, tail;         // head = oldest, tail = newest',
        'int get(int key) {',
        '    if (!map.containsKey(key)) return -1;',
        '    moveToTail(map.get(key));  return map.get(key).value;  }',
        'void put(int key, int value) {',
        '    if (map.size() == capacity) removeHeadAndEvictFromMap();',
        '    addToTail(new Node(key, value));  }',
      ],
      steps: steps,
      timeComplexity: 'O(1) for both get and put',
      spaceComplexity: 'O(capacity)',
      takeaway:
          'get must also refresh recency. Treating a read as "not a use" is '
          'the most common way this implementation goes wrong.',
      problemIds: const ['27'],
    );
  }
}
