import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// Animated walkthroughs for the Stack problems (17, 18).
class StackTraces {
  const StackTraces._();

  static List<AlgorithmTrace> get all => [minStack(), dailyTemperatures()];

  // ----------------------------------------------------------------- 17

  static AlgorithmTrace minStack() {
    final steps = <VizStep>[];
    final main = <int>[];
    final mins = <int>[];

    List<({String value, VizState state})> panel(
      List<int> items, {
      VizState? topState,
    }) {
      return [
        for (var i = 0; i < items.length; i++)
          (
            value: '${items[i]}',
            state: (i == items.length - 1 && topState != null)
                ? topState
                : VizState.idle,
          ),
      ];
    }

    steps.add(
      const VizStep(
        caption:
            'Build a stack where getMin() is O(1). Scanning for the minimum '
            'would be O(n), so instead keep a second stack that remembers the '
            'minimum as of each push.',
        codeLine: 0,
        scenes: [
          StackScene(items: [], title: 'stack', emptyLabel: 'empty'),
          StackScene(items: [], title: 'minStack', emptyLabel: 'empty'),
        ],
      ),
    );

    void push(int v) {
      main.add(v);
      final newMin = mins.isEmpty || v < mins.last ? v : mins.last;
      mins.add(newMin);

      steps.add(
        VizStep(
          caption:
              'push($v). Push $v on the main stack, and push the smaller of '
              '$v and the current minimum onto minStack — that is $newMin. '
              'Both stacks always have the same height.',
          codeLine: 1,
          scenes: [
            StackScene(
              items: panel(main, topState: VizState.active),
              title: 'stack',
            ),
            StackScene(
              items: panel(mins, topState: VizState.success),
              title: 'minStack',
            ),
          ],
        ),
      );
    }

    push(-2);
    push(0);
    push(-3);

    steps.add(
      VizStep(
        caption:
            'getMin() just reads the top of minStack, which is ${mins.last}. '
            'No searching, no scanning — one lookup.',
        codeLine: 4,
        scenes: [
          StackScene(items: panel(main), title: 'stack'),
          StackScene(
            items: panel(mins, topState: VizState.success),
            title: 'minStack',
          ),
          ValueScene(
            readings: [
              (
                label: 'getMin()',
                value: '${mins.last}',
                state: VizState.success,
              ),
            ],
          ),
        ],
      ),
    );

    final popped = main.removeLast();
    mins.removeLast();
    steps.add(
      VizStep(
        caption:
            'pop() removes $popped. Crucially, pop minStack too — otherwise '
            'the minimum would still reflect a value that is no longer in the '
            'stack.',
        codeLine: 2,
        scenes: [
          StackScene(
            items: panel(main, topState: VizState.active),
            title: 'stack',
          ),
          StackScene(
            items: panel(mins, topState: VizState.active),
            title: 'minStack',
          ),
        ],
      ),
    );

    steps.add(
      VizStep(
        caption:
            'top() is ${main.last} and getMin() is now ${mins.last}. The '
            'minimum corrected itself automatically because both stacks move '
            'together.',
        codeLine: 3,
        insight:
            'The second stack stores "the minimum at the time of this push". '
            'That is why popping in lockstep restores the previous answer for '
            'free — no recomputation anywhere.',
        scenes: [
          StackScene(
            items: panel(main, topState: VizState.success),
            title: 'stack',
          ),
          StackScene(
            items: panel(mins, topState: VizState.success),
            title: 'minStack',
          ),
          ValueScene(
            readings: [
              (label: 'top()', value: '${main.last}', state: VizState.success),
              (
                label: 'getMin()',
                value: '${mins.last}',
                state: VizState.success,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'min-stack',
      title: 'Min Stack',
      pattern: 'Stack',
      patternIdea:
          'If a query is expensive to compute on demand, store the answer '
          'alongside the data as it changes.',
      pseudocode: const [
        'Deque<Integer> stack = new ArrayDeque<>(),  mins = new ArrayDeque<>();',
        'void push(int v) { stack.push(v);  mins.push(minOf(v, mins)); }',
        'void pop()       { stack.pop();  mins.pop(); }',
        'int  top()       { return stack.peek(); }',
        'int  getMin()    { return mins.peek(); }',
      ],
      steps: steps,
      timeComplexity: 'O(1) for every operation',
      spaceComplexity: 'O(n) — the second stack doubles the memory',
      takeaway:
          'Push to minStack on every push, even when the minimum does not '
          'change. Keeping the heights equal is what makes pop trivial.',
      problemIds: const ['17'],
    );
  }

  // ----------------------------------------------------------------- 18

  static AlgorithmTrace dailyTemperatures() {
    const temps = [73, 74, 75, 71, 69, 72, 76, 73];
    final values = temps.map((n) => '$n').toList();
    final steps = <VizStep>[];
    final answer = List<int>.filled(temps.length, 0);
    final stack = <int>[]; // indexes waiting for a warmer day

    steps.add(
      VizStep(
        caption:
            'For each day, how many days until it gets warmer? Checking every '
            'later day is O(n²). Instead keep a stack of days still waiting — '
            'and note that it stays in decreasing temperature order.',
        codeLine: 0,
        scenes: [
          ArrayScene(values: values, title: 'temperatures'),
          const StackScene(
            items: [],
            title: 'waiting days (indexes)',
            emptyLabel: 'nobody waiting',
          ),
        ],
      ),
    );

    for (var i = 0; i < temps.length; i++) {
      final resolved = <int>[];
      while (stack.isNotEmpty && temps[i] > temps[stack.last]) {
        final day = stack.removeLast();
        answer[day] = i - day;
        resolved.add(day);
      }

      if (resolved.isNotEmpty) {
        steps.add(
          VizStep(
            caption:
                'Day $i is ${temps[i]}, warmer than the days waiting on top '
                'of the stack. That answers ${resolved.map((d) => "day $d").join(", ")} — '
                '${resolved.map((d) => "${i - d} day${i - d == 1 ? "" : "s"}").join(", ")} later.',
            codeLine: 3,
            scenes: [
              ArrayScene(
                values: values,
                title: 'temperatures',
                states: {
                  i: VizState.active,
                  for (final d in resolved) d: VizState.success,
                },
                pointers: {'i': i},
              ),
              ArrayScene(
                values: answer.map((n) => '$n').toList(),
                title: 'answer (days to wait)',
                states: {for (final d in resolved) d: VizState.success},
              ),
              StackScene(
                items: stack
                    .map((d) => (value: '$d', state: VizState.idle))
                    .toList(),
                title: 'waiting days (indexes)',
                emptyLabel: 'nobody waiting',
              ),
            ],
          ),
        );
      }

      stack.add(i);
      steps.add(
        VizStep(
          caption:
              'Day $i (${temps[i]}) has no warmer day yet, so it joins the '
              'waiting stack. The stack stays in decreasing temperature order, '
              'which is why one comparison at the top is enough.',
          codeLine: 5,
          scenes: [
            ArrayScene(
              values: values,
              title: 'temperatures',
              states: {
                for (var j = 0; j < i; j++) j: VizState.done,
                i: VizState.active,
              },
              pointers: {'i': i},
            ),
            StackScene(
              items: stack
                  .map(
                    (d) => (
                      value: '$d (${temps[d]})',
                      state: d == i ? VizState.active : VizState.idle,
                    ),
                  )
                  .toList(),
              title: 'waiting days (indexes)',
            ),
          ],
        ),
      );
    }

    steps.add(
      VizStep(
        caption:
            'Anything still on the stack never got a warmer day, so those '
            'stay 0. The answer is [${answer.join(", ")}].',
        codeLine: 7,
        insight:
            'Each index is pushed once and popped at most once, so despite the '
            'inner while loop this is O(n). That argument — amortised counting '
            '— is what makes monotonic stacks worth recognising.',
        scenes: [
          ArrayScene(
            values: answer.map((n) => '$n').toList(),
            title: 'answer',
            states: {
              for (var j = 0; j < answer.length; j++) j: VizState.success,
            },
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'daily-temperatures',
      title: 'Daily Temperatures',
      pattern: 'Stack',
      patternIdea:
          'A monotonic stack answers "next greater element" for everything in '
          'one pass, because each item waits only until its answer arrives.',
      pseudocode: const [
        'int[] res = new int[temps.length];  Deque<Integer> stack = new ArrayDeque<>();',
        'for (int i = 0; i < temps.length; i++) {',
        '    while (!stack.isEmpty() && temps[i] > temps[stack.peek()]) {',
        '        int day = stack.pop();  res[day] = i - day;',
        '    }',
        '    stack.push(i);',
        '}',
        'return res;',
      ],
      steps: steps,
      timeComplexity: 'O(n) — each index is pushed and popped at most once',
      spaceComplexity: 'O(n) — the stack in the worst case',
      takeaway:
          'Store indexes, not temperatures. You need the index to compute the '
          'distance when the answer finally arrives.',
      problemIds: const ['18'],
    );
  }
}
