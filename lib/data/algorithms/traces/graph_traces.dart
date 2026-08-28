import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// Animated walkthroughs for the Graphs problems (43–49).
class GraphTraces {
  const GraphTraces._();

  static List<AlgorithmTrace> get all => [
    numberOfIslands(),
    maxAreaOfIsland(),
    cloneGraph(),
    pacificAtlantic(),
    surroundedRegions(),
    courseSchedule(),
    courseScheduleII(),
  ];

  static List<List<String>> _grid(List<String> rows) =>
      rows.map((r) => r.split('')).toList();

  // ----------------------------------------------------------------- 43

  static AlgorithmTrace numberOfIslands() {
    final cells = _grid(['1100', '1100', '0010', '0001']);
    final rows = cells.length;
    final cols = cells[0].length;
    final steps = <VizStep>[];
    final visited = <int>{};
    var islands = 0;

    steps.add(
      VizStep(
        caption:
            'Count the islands: groups of 1s joined horizontally or '
            'vertically. Walk every cell; each time we meet unvisited land, '
            'that is a new island — then flood the whole thing so it is never '
            'counted twice.',
        codeLine: 0,
        scenes: [GridScene(cells: cells, title: 'grid')],
      ),
    );

    void flood(int r, int c) {
      if (r < 0 || r >= rows || c < 0 || c >= cols) return;
      final idx = r * cols + c;
      if (cells[r][c] != '1' || visited.contains(idx)) return;
      visited.add(idx);
      flood(r + 1, c);
      flood(r - 1, c);
      flood(r, c + 1);
      flood(r, c - 1);
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final idx = r * cols + c;
        if (cells[r][c] != '1' || visited.contains(idx)) continue;

        islands++;
        final before = Set<int>.from(visited);
        flood(r, c);
        final justFlooded = visited.difference(before);

        steps.add(
          VizStep(
            caption:
                'Cell ($r,$c) is land we have not seen, so island number '
                '$islands starts here. Flood outward and mark all '
                '${justFlooded.length} of its cells as visited.',
            codeLine: 4,
            scenes: [
              GridScene(
                cells: cells,
                title: 'grid',
                states: {
                  for (final v in before) v: VizState.done,
                  for (final v in justFlooded) v: VizState.success,
                  idx: VizState.active,
                },
              ),
              ValueScene(
                readings: [
                  (
                    label: 'islands',
                    value: '$islands',
                    state: VizState.success,
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }

    steps.add(
      VizStep(
        caption: 'Every cell has been examined. There are $islands islands.',
        codeLine: 6,
        insight:
            'Marking cells visited as you enter them, not as you leave, is '
            'what stops the flood from revisiting a cell and recursing '
            'forever.',
        scenes: [
          GridScene(
            cells: cells,
            title: 'grid',
            states: {for (final v in visited) v: VizState.success},
          ),
          ValueScene(
            readings: [
              (label: 'answer', value: '$islands', state: VizState.success),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'number-of-islands',
      title: 'Number of Islands',
      pattern: 'Graphs',
      patternIdea:
          'A grid is a graph in disguise: each cell is a node, and its '
          'neighbours are the four cells around it.',
      pseudocode: const [
        'int count = 0;',
        'for (int r = 0; r < rows; r++)',
        '    for (int c = 0; c < cols; c++)',
        '        if (grid[r][c] == \'1\') {',
        '            count++;',
        '            flood(grid, r, c);   // DFS or BFS',
        '        }',
        'return count;',
      ],
      steps: steps,
      timeComplexity: 'O(rows × cols) — each cell is flooded once',
      spaceComplexity: 'O(rows × cols) worst case for the stack',
      takeaway:
          'Sink each island as you count it, either with a visited set or by '
          'overwriting the 1s with 0s.',
      problemIds: const ['43'],
    );
  }

  // ----------------------------------------------------------------- 44

  static AlgorithmTrace maxAreaOfIsland() {
    final cells = _grid(['1100', '1100', '0010', '0001']);
    final rows = cells.length;
    final cols = cells[0].length;
    final steps = <VizStep>[];
    final visited = <int>{};
    var best = 0;
    var bestCells = <int>{};

    steps.add(
      VizStep(
        caption:
            'Same flood fill as counting islands, but instead of adding one '
            'per island we measure how big each one is and keep the largest.',
        codeLine: 0,
        scenes: [GridScene(cells: cells, title: 'grid')],
      ),
    );

    int flood(int r, int c) {
      if (r < 0 || r >= rows || c < 0 || c >= cols) return 0;
      final idx = r * cols + c;
      if (cells[r][c] != '1' || visited.contains(idx)) return 0;
      visited.add(idx);
      return 1 +
          flood(r + 1, c) +
          flood(r - 1, c) +
          flood(r, c + 1) +
          flood(r, c - 1);
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final idx = r * cols + c;
        if (cells[r][c] != '1' || visited.contains(idx)) continue;

        final before = Set<int>.from(visited);
        final area = flood(r, c);
        final region = visited.difference(before);
        final improved = area > best;
        if (improved) {
          best = area;
          bestCells = region;
        }

        steps.add(
          VizStep(
            caption:
                'The island starting at ($r,$c) covers $area cells. '
                '${improved ? "That is the biggest so far." : "The best is still $best."}',
            codeLine: 4,
            scenes: [
              GridScene(
                cells: cells,
                title: 'grid',
                states: {
                  for (final v in before) v: VizState.done,
                  for (final v in region)
                    v: improved ? VizState.success : VizState.compare,
                },
              ),
              ValueScene(
                readings: [
                  (label: 'this island', value: '$area', state: VizState.idle),
                  (label: 'best', value: '$best', state: VizState.success),
                ],
              ),
            ],
          ),
        );
      }
    }

    steps.add(
      VizStep(
        caption: 'The largest island covers $best cells.',
        codeLine: 6,
        insight:
            'The flood returns 1 + the four recursive calls. Returning a count '
            'instead of void is the only change from Number of Islands.',
        scenes: [
          GridScene(
            cells: cells,
            title: 'grid',
            states: {
              for (final v in visited) v: VizState.dim,
              for (final v in bestCells) v: VizState.success,
            },
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
      id: 'max-area-of-island',
      title: 'Max Area of Island',
      pattern: 'Graphs',
      patternIdea:
          'Let the flood fill return a value, and the same traversal answers a '
          'different question.',
      pseudocode: const [
        'int best = 0;',
        'for (int r = 0; r < rows; r++)',
        '    for (int c = 0; c < cols; c++)',
        '        if (grid[r][c] == 1)',
        '            best = Math.max(best, flood(grid, r, c));',
        'return best;',
        '// flood returns 1 + flood(up) + flood(down) + flood(left) + flood(right)',
      ],
      steps: steps,
      timeComplexity: 'O(rows × cols)',
      spaceComplexity: 'O(rows × cols)',
      takeaway:
          'Return 0 for out-of-bounds, water, or already-visited cells. Those '
          'three guards are the entire base case.',
      problemIds: const ['44'],
    );
  }

  // ----------------------------------------------------------------- 45

  static AlgorithmTrace cloneGraph() {
    const labels = ['1', '2', '3', '4'];
    const edges = [
      (from: 0, to: 1),
      (from: 0, to: 3),
      (from: 1, to: 2),
      (from: 2, to: 3),
    ];
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'Make a deep copy of this graph. The danger is cycles: following '
            'edges blindly would copy the same node again and again forever. '
            'A map from original to copy prevents that.',
        codeLine: 0,
        scenes: [
          GraphScene(nodes: labels, edges: edges, title: 'original'),
          MapScene(
            entries: [],
            title: 'original → copy',
            emptyLabel: 'nothing cloned yet',
          ),
        ],
      ),
    );

    final cloned = <int>[];
    final order = [0, 1, 2, 3];

    for (final n in order) {
      cloned.add(n);
      steps.add(
        VizStep(
          caption:
              'Visit node ${labels[n]}. It is not in the map, so create its '
              'copy, record it immediately, then walk its neighbours.',
          codeLine: 3,
          scenes: [
            GraphScene(
              nodes: labels,
              edges: edges,
              states: {
                for (final c in cloned) c: VizState.done,
                n: VizState.active,
              },
              activeEdges: {
                for (var i = 0; i < edges.length; i++)
                  if (edges[i].from == n || edges[i].to == n) i,
              },
              title: 'original',
            ),
            MapScene(
              entries: cloned
                  .map(
                    (c) => (
                      key: labels[c],
                      value: "copy of ${labels[c]}",
                      state: c == n ? VizState.success : VizState.idle,
                    ),
                  )
                  .toList(),
              title: 'original → copy',
            ),
          ],
        ),
      );
    }

    steps.add(
      VizStep(
        caption:
            'Every node has been visited exactly once, and each edge was '
            'rebuilt against the copies rather than the originals.',
        codeLine: 5,
        insight:
            'Put the copy in the map *before* recursing into neighbours. Doing '
            'it afterwards lets a cycle re-enter the same node and recurse '
            'until the stack overflows.',
        scenes: [
          GraphScene(
            nodes: labels,
            edges: edges,
            states: {for (final c in cloned) c: VizState.success},
            title: 'cloned graph',
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'clone-graph',
      title: 'Clone Graph',
      pattern: 'Graphs',
      patternIdea:
          'A visited map doubles as the copy table, which is what makes cyclic '
          'graphs safe to traverse.',
      pseudocode: const [
        'Map<Node, Node> copies = new HashMap<>();',
        'Node clone(Node node) {',
        '    if (node == null) return null;',
        '    if (copies.containsKey(node)) return copies.get(node);',
        '    Node copy = new Node(node.val);',
        '    copies.put(node, copy);          // BEFORE recursing',
        '    for (Node nb : node.neighbors)',
        '        copy.neighbors.add(clone(nb));',
        '    return copy;',
        '}',
      ],
      steps: steps,
      timeComplexity: 'O(V + E)',
      spaceComplexity: 'O(V) — the map plus the recursion stack',
      takeaway:
          'Register the copy in the map before you follow any neighbour. That '
          'single ordering is what makes cycles terminate.',
      problemIds: const ['45'],
    );
  }

  // ----------------------------------------------------------------- 46

  static AlgorithmTrace pacificAtlantic() {
    final cells = _grid(['123', '234', '345']);
    final steps = <VizStep>[];
    const cols = 3;

    steps.add(
      VizStep(
        caption:
            'Water flows from a cell to any neighbour of equal or lower '
            'height. Which cells can reach both the Pacific (top and left) and '
            'the Atlantic (bottom and right)?',
        codeLine: 0,
        scenes: [GridScene(cells: cells, title: 'heights')],
      ),
    );

    steps.add(
      const VizStep(
        caption:
            'Testing every cell separately would be far too slow. Instead '
            'reverse the question: start at each ocean edge and climb '
            '*upward* to find everything that can drain into it.',
        codeLine: 1,
        scenes: [
          GridScene(
            cells: [
              ['1', '2', '3'],
              ['2', '3', '4'],
              ['3', '4', '5'],
            ],
            title: 'heights',
            states: {
              0: VizState.compare,
              1: VizState.compare,
              2: VizState.compare,
              3: VizState.compare,
              6: VizState.compare,
            },
          ),
        ],
      ),
    );

    // Reverse flood from each ocean: move to a neighbour only if it is higher.
    Set<int> reachable(List<({int r, int c})> starts) {
      final seen = <int>{};
      void climb(int r, int c, int from) {
        if (r < 0 || r > 2 || c < 0 || c > 2) return;
        final h = int.parse(cells[r][c]);
        if (h < from) return;
        final idx = r * cols + c;
        if (!seen.add(idx)) return;
        climb(r + 1, c, h);
        climb(r - 1, c, h);
        climb(r, c + 1, h);
        climb(r, c - 1, h);
      }

      for (final s in starts) {
        climb(s.r, s.c, -1 << 30);
      }
      return seen;
    }

    final pacific = reachable([
      for (var c = 0; c < 3; c++) (r: 0, c: c),
      for (var r = 0; r < 3; r++) (r: r, c: 0),
    ]);
    final atlantic = reachable([
      for (var c = 0; c < 3; c++) (r: 2, c: c),
      for (var r = 0; r < 3; r++) (r: r, c: 2),
    ]);

    steps.add(
      VizStep(
        caption:
            'Climbing inward from the top and left edges reaches '
            '${pacific.length} cells — everything that can drain to the '
            'Pacific.',
        codeLine: 2,
        scenes: [
          GridScene(
            cells: cells,
            title: 'reaches Pacific',
            states: {for (final i in pacific) i: VizState.active},
          ),
        ],
      ),
    );

    steps.add(
      VizStep(
        caption:
            'Doing the same from the bottom and right edges reaches '
            '${atlantic.length} cells for the Atlantic.',
        codeLine: 3,
        scenes: [
          GridScene(
            cells: cells,
            title: 'reaches Atlantic',
            states: {for (final i in atlantic) i: VizState.compare},
          ),
        ],
      ),
    );

    final both = pacific.intersection(atlantic);
    steps.add(
      VizStep(
        caption:
            'The answer is the overlap of the two sets: ${both.length} cells '
            'can reach both oceans.',
        codeLine: 4,
        insight:
            'Reversing the flow is the whole trick. Searching forward from '
            'every cell is O((rc)²); searching backward from the edges is '
            'O(rc).',
        scenes: [
          GridScene(
            cells: cells,
            title: 'reaches both',
            states: {
              for (var i = 0; i < 9; i++) i: VizState.dim,
              for (final i in both) i: VizState.success,
            },
          ),
          ValueScene(
            readings: [
              (
                label: 'answer',
                value: '${both.length} cells',
                state: VizState.success,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'pacific-atlantic',
      title: 'Pacific Atlantic Water Flow',
      pattern: 'Graphs',
      patternIdea:
          'When "can X reach the edge?" is expensive, ask "what can the edge '
          'reach?" and reverse the condition.',
      pseudocode: const [
        'Set<Cell> pacific = new HashSet<>(), atlantic = new HashSet<>();',
        '// climb inward: move only to neighbours that are >= current height',
        'for (int c = 0; c < cols; c++) { climb(0, c, pacific); ... }',
        'for (int c = 0; c < cols; c++) { climb(rows-1, c, atlantic); ... }',
        'return intersection(pacific, atlantic);',
      ],
      steps: steps,
      timeComplexity: 'O(rows × cols) — each cell entered once per ocean',
      spaceComplexity: 'O(rows × cols)',
      takeaway:
          'Flip the comparison when you flip the direction: draining downhill '
          'forward becomes climbing uphill backward.',
      problemIds: const ['46'],
    );
  }

  // ----------------------------------------------------------------- 47

  static AlgorithmTrace surroundedRegions() {
    final cells = _grid(['XXXX', 'XOOX', 'XXOX', 'XOXX']);
    const cols = 4;
    final steps = <VizStep>[];

    steps.add(
      VizStep(
        caption:
            'Flip every O that is fully surrounded by X. The catch is that an '
            'O touching the border is safe — and so is anything connected to '
            'it.',
        codeLine: 0,
        scenes: [GridScene(cells: cells, title: 'board')],
      ),
    );

    final safe = <int>{};
    void mark(int r, int c) {
      if (r < 0 || r > 3 || c < 0 || c > 3) return;
      if (cells[r][c] != 'O') return;
      final idx = r * cols + c;
      if (!safe.add(idx)) return;
      mark(r + 1, c);
      mark(r - 1, c);
      mark(r, c + 1);
      mark(r, c - 1);
    }

    for (var r = 0; r < 4; r++) {
      mark(r, 0);
      mark(r, 3);
    }
    for (var c = 0; c < 4; c++) {
      mark(0, c);
      mark(3, c);
    }

    steps.add(
      VizStep(
        caption:
            'Rather than testing each region for enclosure, start from the '
            'border and mark every O reachable from it as safe. That found '
            '${safe.length}.',
        codeLine: 2,
        scenes: [
          GridScene(
            cells: cells,
            title: 'board',
            states: {for (final i in safe) i: VizState.success},
          ),
        ],
      ),
    );

    final flipped = <int>{};
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final idx = r * cols + c;
        if (cells[r][c] == 'O' && !safe.contains(idx)) flipped.add(idx);
      }
    }

    final result = cells.map((row) => row.toList()).toList();
    for (final idx in flipped) {
      result[idx ~/ cols][idx % cols] = 'X';
    }

    steps.add(
      VizStep(
        caption:
            'Every remaining O is unreachable from the border, so it is '
            'surrounded. Flip those ${flipped.length} to X.',
        codeLine: 4,
        insight:
            'This is the complement trick: instead of finding what to change, '
            'find what to protect, then change everything else.',
        scenes: [
          GridScene(
            cells: result,
            title: 'result',
            states: {
              for (final i in flipped) i: VizState.success,
              for (final i in safe) i: VizState.dim,
            },
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'surrounded-regions',
      title: 'Surrounded Regions',
      pattern: 'Graphs',
      patternIdea:
          'It is often easier to identify the exceptions from the boundary '
          'than to test each region for enclosure.',
      pseudocode: const [
        '// 1. mark every O connected to the border as safe',
        'for (int r = 0; r < rows; r++) { mark(r, 0); mark(r, cols-1); }',
        'for (int c = 0; c < cols; c++) { mark(0, c); mark(rows-1, c); }',
        '// 2. flip every unmarked O',
        'for (each cell) if (board[r][c] == \'O\' && !safe) board[r][c] = \'X\';',
      ],
      steps: steps,
      timeComplexity: 'O(rows × cols)',
      spaceComplexity: 'O(rows × cols)',
      takeaway:
          'Do the border pass first. Flipping as you scan would destroy the '
          'evidence the border pass depends on.',
      problemIds: const ['47'],
    );
  }

  // ----------------------------------------------------------------- 48

  static AlgorithmTrace courseSchedule() {
    const labels = ['0', '1', '2', '3'];
    // edge from -> to means "from must be taken before to"
    const edges = [
      (from: 0, to: 1),
      (from: 0, to: 2),
      (from: 1, to: 3),
      (from: 2, to: 3),
    ];
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'Can every course be finished? Only if the prerequisite graph has '
            'no cycle — a course that ultimately requires itself can never be '
            'started.',
        codeLine: 0,
        scenes: [
          GraphScene(
            nodes: labels,
            edges: edges,
            directed: true,
            title: 'prerequisites (arrow = must come first)',
          ),
        ],
      ),
    );

    final indegree = List<int>.filled(labels.length, 0);
    for (final e in edges) {
      indegree[e.to]++;
    }

    steps.add(
      VizStep(
        caption:
            'Count each course\'s prerequisites: '
            '${[for (var i = 0; i < labels.length; i++) '${labels[i]}→${indegree[i]}'].join(', ')}. '
            'Anything at zero can be taken right now.',
        codeLine: 2,
        scenes: [
          GraphScene(
            nodes: labels,
            edges: edges,
            directed: true,
            states: {
              for (var i = 0; i < labels.length; i++)
                i: indegree[i] == 0 ? VizState.success : VizState.idle,
            },
            title: 'prerequisites',
          ),
          ValueScene(
            readings: [
              for (var i = 0; i < labels.length; i++)
                (
                  label: 'course ${labels[i]}',
                  value: '${indegree[i]} left',
                  state: indegree[i] == 0 ? VizState.success : VizState.idle,
                ),
            ],
          ),
        ],
      ),
    );

    final queue = <int>[
      for (var i = 0; i < labels.length; i++)
        if (indegree[i] == 0) i,
    ];
    final taken = <int>[];

    while (queue.isNotEmpty) {
      final n = queue.removeAt(0);
      taken.add(n);
      final freed = <int>[];
      for (final e in edges) {
        if (e.from != n) continue;
        indegree[e.to]--;
        if (indegree[e.to] == 0) {
          queue.add(e.to);
          freed.add(e.to);
        }
      }

      steps.add(
        VizStep(
          caption: freed.isEmpty
              ? 'Take course ${labels[n]}. Nothing new becomes available yet.'
              : 'Take course ${labels[n]}. That clears the last prerequisite '
                    'for ${freed.map((f) => labels[f]).join(" and ")}, so '
                    'they join the queue.',
          codeLine: 5,
          scenes: [
            GraphScene(
              nodes: labels,
              edges: edges,
              directed: true,
              states: {
                for (final t in taken) t: VizState.done,
                n: VizState.active,
                for (final f in freed) f: VizState.success,
              },
              title: 'prerequisites',
            ),
            ValueScene(
              readings: [
                (
                  label: 'taken',
                  value: taken.map((t) => labels[t]).join(', '),
                  state: VizState.idle,
                ),
              ],
            ),
          ],
        ),
      );
    }

    final ok = taken.length == labels.length;
    steps.add(
      VizStep(
        caption: ok
            ? 'All ${labels.length} courses were taken, so no cycle exists '
                  'and the answer is true.'
            : 'Only ${taken.length} of ${labels.length} courses could be '
                  'taken; the rest form a cycle.',
        codeLine: 7,
        insight:
            'Counting how many nodes came out of the queue is the cycle test. '
            'Anything stuck in a cycle never reaches indegree zero, so it '
            'never enters the queue.',
        scenes: [
          ValueScene(
            readings: [
              (
                label: 'result',
                value: '$ok',
                state: ok ? VizState.success : VizState.fail,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'course-schedule',
      title: 'Course Schedule',
      pattern: 'Graphs',
      patternIdea:
          'Repeatedly removing nodes with no remaining prerequisites detects '
          'cycles and produces a valid order at the same time.',
      pseudocode: const [
        'int[] indegree = new int[numCourses];',
        'for (int[] p : prerequisites) indegree[p[0]]++;',
        'Queue<Integer> q = new LinkedList<>();',
        'for (int i = 0; i < numCourses; i++) if (indegree[i] == 0) q.add(i);',
        'int taken = 0;',
        'while (!q.isEmpty()) {',
        '    int course = q.poll();  taken++;',
        '    for (int next : graph.get(course))',
        '        if (--indegree[next] == 0) q.add(next);',
        '}',
        'return taken == numCourses;',
      ],
      steps: steps,
      timeComplexity: 'O(V + E)',
      spaceComplexity: 'O(V + E)',
      takeaway:
          'If fewer courses come out than went in, the leftovers form a cycle. '
          'That count is the entire answer.',
      problemIds: const ['48'],
    );
  }

  // ----------------------------------------------------------------- 49

  static AlgorithmTrace courseScheduleII() {
    const labels = ['0', '1', '2', '3'];
    const edges = [
      (from: 0, to: 1),
      (from: 0, to: 2),
      (from: 1, to: 3),
      (from: 2, to: 3),
    ];
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'Same graph as Course Schedule, but now we must return an actual '
            'order to take the courses in — not just whether one exists.',
        codeLine: 0,
        scenes: [
          GraphScene(
            nodes: labels,
            edges: edges,
            directed: true,
            title: 'prerequisites',
          ),
        ],
      ),
    );

    final indegree = List<int>.filled(labels.length, 0);
    for (final e in edges) {
      indegree[e.to]++;
    }
    final queue = <int>[
      for (var i = 0; i < labels.length; i++)
        if (indegree[i] == 0) i,
    ];
    final order = <int>[];

    while (queue.isNotEmpty) {
      final n = queue.removeAt(0);
      order.add(n);
      for (final e in edges) {
        if (e.from != n) continue;
        indegree[e.to]--;
        if (indegree[e.to] == 0) queue.add(e.to);
      }

      steps.add(
        VizStep(
          caption:
              'Course ${labels[n]} has no prerequisites left, so append it to '
              'the order. So far: ${order.map((o) => labels[o]).join(" → ")}.',
          codeLine: 4,
          scenes: [
            GraphScene(
              nodes: labels,
              edges: edges,
              directed: true,
              states: {
                for (final o in order) o: VizState.done,
                n: VizState.success,
              },
              title: 'prerequisites',
            ),
            ArrayScene(
              values: order.map((o) => labels[o]).toList(),
              title: 'course order',
              states: {order.length - 1: VizState.success},
            ),
          ],
        ),
      );
    }

    final valid = order.length == labels.length;
    steps.add(
      VizStep(
        caption: valid
            ? 'A valid order is ${order.map((o) => labels[o]).join(" → ")}. '
                  'Other orders are also valid; any topological order works.'
            : 'A cycle blocked some courses, so no valid order exists and we '
                  'return an empty array.',
        codeLine: 6,
        insight:
            'This is Course Schedule with one line changed: record the course '
            'instead of only counting it. Recognising that two problems are '
            'the same algorithm saves real time in an interview.',
        scenes: [
          ArrayScene(
            values: order.map((o) => labels[o]).toList(),
            title: 'answer',
            states: {
              for (var i = 0; i < order.length; i++) i: VizState.success,
            },
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'course-schedule-ii',
      title: 'Course Schedule II',
      pattern: 'Graphs',
      patternIdea:
          'A topological sort is the order in which prerequisites clear.',
      pseudocode: const [
        'int[] order = new int[numCourses];  int idx = 0;',
        '// build indegree and queue exactly as in Course Schedule',
        'while (!q.isEmpty()) {',
        '    int course = q.poll();',
        '    order[idx++] = course;',
        '    for (int next : graph.get(course))',
        '        if (--indegree[next] == 0) q.add(next);',
        '}',
        'return idx == numCourses ? order : new int[0];',
      ],
      steps: steps,
      timeComplexity: 'O(V + E)',
      spaceComplexity: 'O(V + E)',
      takeaway:
          'Return an empty array when the order is short — a partial order is '
          'not an answer.',
      problemIds: const ['49'],
    );
  }
}
