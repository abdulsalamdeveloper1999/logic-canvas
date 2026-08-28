import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// A binary tree node used only to build the animations.
class _N {
  final String val;
  _N? left;
  _N? right;
  _N(this.val, [this.left, this.right]);
}

/// Level-order layout of a tree, plus the index of each node, so steps can
/// highlight a node without tracking positions by hand.
class _Layout {
  final List<String?> heap;
  final Map<_N, int> index;
  const _Layout(this.heap, this.index);
}

_Layout _layout(_N? root) {
  final values = <int, String>{};
  final index = <_N, int>{};
  var maxIndex = -1;

  void walk(_N? node, int i) {
    if (node == null) return;
    values[i] = node.val;
    index[node] = i;
    if (i > maxIndex) maxIndex = i;
    walk(node.left, i * 2 + 1);
    walk(node.right, i * 2 + 2);
  }

  walk(root, 0);
  return _Layout([for (var i = 0; i <= maxIndex; i++) values[i]], index);
}

_N? _build(List<String?> heap, [int i = 0]) {
  if (i >= heap.length || heap[i] == null) return null;
  return _N(heap[i]!, _build(heap, i * 2 + 1), _build(heap, i * 2 + 2));
}

/// Animated walkthroughs for the Trees problems (28–34, 36–39).
class TreeTraces {
  const TreeTraces._();

  static List<AlgorithmTrace> get all => [
    invertTree(),
    maxDepth(),
    diameter(),
    balanced(),
    sameTree(),
    subtree(),
    lowestCommonAncestor(),
    rightSideView(),
    countGoodNodes(),
    validateBst(),
    kthSmallestBst(),
  ];

  // ----------------------------------------------------------------- 28

  static AlgorithmTrace invertTree() {
    final root = _build(['4', '2', '7', '1', '3', '6', '9']);
    final steps = <VizStep>[];

    steps.add(
      VizStep(
        caption:
            'Mirror the tree so every left child becomes a right child. The '
            'whole job is one swap repeated at every node.',
        codeLine: 0,
        scenes: [TreeScene(heap: _layout(root).heap, title: 'tree')],
      ),
    );

    void invert(_N? node) {
      if (node == null) return;
      final tmp = node.left;
      node.left = node.right;
      node.right = tmp;

      final layout = _layout(root);
      steps.add(
        VizStep(
          caption:
              'Swap the children of ${node.val}. Its subtrees have traded '
              'sides; everything below them still needs the same treatment.',
          codeLine: 2,
          scenes: [
            TreeScene(
              heap: layout.heap,
              states: {layout.index[node]!: VizState.active},
              title: 'tree',
            ),
          ],
        ),
      );

      invert(node.left);
      invert(node.right);
    }

    invert(root);

    final finalLayout = _layout(root);
    steps.add(
      VizStep(
        caption:
            'Every node has been swapped, so the tree is a full mirror of the '
            'original.',
        codeLine: 5,
        insight:
            'Swap first, then recurse — or recurse first, then swap. Both work. '
            'What does not work is swapping in the middle of using the old '
            'pointers.',
        scenes: [
          TreeScene(
            heap: finalLayout.heap,
            states: {
              for (final i in finalLayout.index.values) i: VizState.success,
            },
            title: 'inverted tree',
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'invert-binary-tree',
      title: 'Invert Binary Tree',
      pattern: 'Trees',
      patternIdea:
          'Most tree problems are "do something here, then ask both children '
          'to do the same".',
      pseudocode: const [
        'TreeNode invert(TreeNode root) {',
        '    if (root == null) return null;',
        '    TreeNode tmp = root.left;',
        '    root.left = root.right;  root.right = tmp;',
        '    invert(root.left);  invert(root.right);',
        '    return root;',
        '}',
      ],
      steps: steps,
      timeComplexity: 'O(n) — every node is visited once',
      spaceComplexity: 'O(h) — the recursion stack, h = height',
      takeaway:
          'Save one child in a temporary before overwriting, exactly like '
          'swapping two variables.',
      problemIds: const ['28'],
    );
  }

  // ----------------------------------------------------------------- 29

  static AlgorithmTrace maxDepth() {
    const heap = <String?>['3', '9', '20', null, null, '15', '7'];
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'How many levels does the tree have? A node\'s depth is one more '
            'than the deeper of its two children — which is the definition '
            'and the algorithm at the same time.',
        codeLine: 0,
        scenes: [TreeScene(heap: heap, title: 'tree')],
      ),
    );

    final depths = <int, int>{};
    int depthOf(int i) {
      if (i >= heap.length || heap[i] == null) return 0;
      final left = depthOf(i * 2 + 1);
      final right = depthOf(i * 2 + 2);
      final d = 1 + (left > right ? left : right);
      depths[i] = d;

      steps.add(
        VizStep(
          caption: (left == 0 && right == 0)
              ? '${heap[i]} is a leaf, so its depth is 1.'
              : '${heap[i]} has children of depth $left and $right, so its '
                    'own depth is 1 + ${left > right ? left : right} = $d.',
          codeLine: 2,
          scenes: [
            TreeScene(
              heap: heap,
              states: {
                for (final k in depths.keys) k: VizState.done,
                i: VizState.active,
              },
              title: 'tree',
            ),
            ValueScene(
              readings: [
                for (final e in depths.entries)
                  (
                    label: 'depth(${heap[e.key]})',
                    value: '${e.value}',
                    state: e.key == i ? VizState.success : VizState.idle,
                  ),
              ],
            ),
          ],
        ),
      );
      return d;
    }

    final answer = depthOf(0);

    steps.add(
      VizStep(
        caption: 'The root reports $answer, so the maximum depth is $answer.',
        codeLine: 3,
        insight:
            'Answers flow upward from the leaves. Recognising that a problem '
            'is solved "on the way back up" is what separates post-order '
            'recursion from pre-order.',
        scenes: [
          TreeScene(
            heap: heap,
            states: {for (final k in depths.keys) k: VizState.success},
            title: 'tree',
          ),
          ValueScene(
            readings: [
              (label: 'answer', value: '$answer', state: VizState.success),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'max-depth-binary-tree',
      title: 'Maximum Depth of Binary Tree',
      pattern: 'Trees',
      patternIdea:
          'Define the answer for a node in terms of its children, and the '
          'recursion writes itself.',
      pseudocode: const [
        'int maxDepth(TreeNode root) {',
        '    if (root == null) return 0;',
        '    return 1 + Math.max(maxDepth(root.left),',
        '                        maxDepth(root.right));',
        '}',
      ],
      steps: steps,
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(h) — recursion depth',
      takeaway:
          'A null node has depth 0, not 1. Getting that base case wrong shifts '
          'every answer by one.',
      problemIds: const ['29'],
    );
  }

  // ----------------------------------------------------------------- 30

  static AlgorithmTrace diameter() {
    const heap = <String?>['1', '2', '3', '4', '5'];
    final steps = <VizStep>[];
    var best = 0;

    steps.add(
      const VizStep(
        caption:
            'The diameter is the longest path between any two nodes, and that '
            'path need not pass through the root. At each node, the best path '
            'through it is leftDepth + rightDepth.',
        codeLine: 0,
        scenes: [TreeScene(heap: heap, title: 'tree')],
      ),
    );

    final noted = <int>{};
    int depth(int i) {
      if (i >= heap.length || heap[i] == null) return 0;
      final left = depth(i * 2 + 1);
      final right = depth(i * 2 + 2);
      final through = left + right;
      final improved = through > best;
      if (improved) best = through;
      noted.add(i);

      steps.add(
        VizStep(
          caption:
              'At ${heap[i]}: the left side reaches down $left and the right '
              '$right, so a path through ${heap[i]} spans $through edges. '
              '${improved ? "That is the longest so far." : "Best stays $best."}',
          codeLine: 4,
          scenes: [
            TreeScene(
              heap: heap,
              states: {
                for (final k in noted) k: VizState.done,
                i: improved ? VizState.success : VizState.active,
              },
              title: 'tree',
            ),
            ValueScene(
              readings: [
                (
                  label: 'through ${heap[i]}',
                  value: '$through',
                  state: improved ? VizState.success : VizState.idle,
                ),
                (label: 'best', value: '$best', state: VizState.idle),
              ],
            ),
          ],
        ),
      );

      return 1 + (left > right ? left : right);
    }

    depth(0);

    steps.add(
      VizStep(
        caption: 'The longest path anywhere in the tree spans $best edges.',
        codeLine: 6,
        insight:
            'The function returns a depth but records a diameter. Mixing those '
            'two up — returning left + right — is the classic bug here.',
        scenes: [
          ValueScene(
            readings: [
              (label: 'answer', value: '$best', state: VizState.success),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'diameter-binary-tree',
      title: 'Diameter of Binary Tree',
      pattern: 'Trees',
      patternIdea:
          'Return one value up the recursion while recording a different one '
          'in a field.',
      pseudocode: const [
        'int best = 0;',
        'int depth(TreeNode node) {',
        '    if (node == null) return 0;',
        '    int left = depth(node.left);',
        '    int right = depth(node.right);',
        '    best = Math.max(best, left + right);',
        '    return 1 + Math.max(left, right);',
        '}',
      ],
      steps: steps,
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(h)',
      takeaway:
          'Return 1 + max(left, right) to the parent, but score left + right '
          'into the answer.',
      problemIds: const ['30'],
    );
  }

  // ----------------------------------------------------------------- 31

  static AlgorithmTrace balanced() {
    const heap = <String?>['3', '9', '20', null, null, '15', '7'];
    final steps = <VizStep>[];
    var ok = true;

    steps.add(
      const VizStep(
        caption:
            'A tree is balanced when every node\'s two subtrees differ in '
            'height by at most 1. Checking height separately at each node '
            'would be O(n²), so compute height and balance together.',
        codeLine: 0,
        scenes: [TreeScene(heap: heap, title: 'tree')],
      ),
    );

    final noted = <int>{};
    int height(int i) {
      if (i >= heap.length || heap[i] == null) return 0;
      final left = height(i * 2 + 1);
      final right = height(i * 2 + 2);
      final diff = (left - right).abs();
      if (diff > 1) ok = false;
      noted.add(i);

      steps.add(
        VizStep(
          caption:
              'At ${heap[i]}: subtree heights are $left and $right, a '
              'difference of $diff. '
              '${diff > 1 ? "That breaks the rule, so the tree is unbalanced." : "Within 1, so this node is fine."}',
          codeLine: 4,
          scenes: [
            TreeScene(
              heap: heap,
              states: {
                for (final k in noted) k: VizState.done,
                i: diff > 1 ? VizState.fail : VizState.active,
              },
              title: 'tree',
            ),
            ValueScene(
              readings: [
                (
                  label: 'heights at ${heap[i]}',
                  value: '$left vs $right',
                  state: diff > 1 ? VizState.fail : VizState.idle,
                ),
              ],
            ),
          ],
        ),
      );

      return 1 + (left > right ? left : right);
    }

    height(0);

    steps.add(
      VizStep(
        caption: ok
            ? 'Every node passed, so the tree is balanced.'
            : 'At least one node broke the rule, so the tree is not balanced.',
        codeLine: 6,
        insight:
            'Returning a sentinel like −1 for "already unbalanced" lets the '
            'recursion stop early instead of finishing a walk whose answer is '
            'already decided.',
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
      id: 'balanced-binary-tree',
      title: 'Balanced Binary Tree',
      pattern: 'Trees',
      patternIdea:
          'Compute the expensive value once on the way up rather than '
          'recomputing it at every node.',
      pseudocode: const [
        'boolean balanced = true;',
        'int height(TreeNode node) {',
        '    if (node == null) return 0;',
        '    int l = height(node.left), r = height(node.right);',
        '    if (Math.abs(l - r) > 1) balanced = false;',
        '    return 1 + Math.max(l, r);',
        '}',
        '// call height(root), then return balanced',
      ],
      steps: steps,
      timeComplexity: 'O(n) — one pass, versus O(n²) if height is recomputed',
      spaceComplexity: 'O(h)',
      takeaway:
          'Calling a separate height() inside isBalanced() is the O(n²) trap. '
          'Fuse the two into one traversal.',
      problemIds: const ['31'],
    );
  }

  // ----------------------------------------------------------------- 32

  static AlgorithmTrace sameTree() {
    const p = <String?>['1', '2', '3'];
    const q = <String?>['1', '2', '3'];
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'Two trees are the same when their roots match and both pairs of '
            'subtrees match. That sentence is the entire recursion.',
        codeLine: 0,
        scenes: [
          TreeScene(heap: p, title: 'tree p'),
          TreeScene(heap: q, title: 'tree q'),
        ],
      ),
    );

    var same = true;
    final visited = <int>{};

    void compare(int i) {
      final a = i < p.length ? p[i] : null;
      final b = i < q.length ? q[i] : null;

      if (a == null && b == null) return;
      if (a == null || b == null || a != b) {
        same = false;
        steps.add(
          VizStep(
            caption:
                'At this position the trees differ (${a ?? "null"} versus '
                '${b ?? "null"}), so they are not the same tree.',
            codeLine: 3,
            scenes: [
              TreeScene(
                heap: p,
                states: {if (a != null) i: VizState.fail},
                title: 'tree p',
              ),
              TreeScene(
                heap: q,
                states: {if (b != null) i: VizState.fail},
                title: 'tree q',
              ),
            ],
          ),
        );
        return;
      }

      visited.add(i);
      steps.add(
        VizStep(
          caption:
              'Both trees hold $a here, so this node matches. Now ask the '
              'same question of the left pair and the right pair.',
          codeLine: 4,
          scenes: [
            TreeScene(
              heap: p,
              states: {
                for (final k in visited) k: VizState.done,
                i: VizState.active,
              },
              title: 'tree p',
            ),
            TreeScene(
              heap: q,
              states: {
                for (final k in visited) k: VizState.done,
                i: VizState.active,
              },
              title: 'tree q',
            ),
          ],
        ),
      );

      compare(i * 2 + 1);
      compare(i * 2 + 2);
    }

    compare(0);

    steps.add(
      VizStep(
        caption: same
            ? 'Every corresponding node matched, so the trees are identical.'
            : 'A mismatch was found, so the trees differ.',
        codeLine: 5,
        insight:
            'Handle the null cases first: both null is a match, exactly one '
            'null is a mismatch. Skipping that ordering causes a null pointer '
            'exception on the value comparison.',
        scenes: [
          ValueScene(
            readings: [
              (
                label: 'result',
                value: '$same',
                state: same ? VizState.success : VizState.fail,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'same-tree',
      title: 'Same Tree',
      pattern: 'Trees',
      patternIdea:
          'Structural equality is defined recursively, so the code mirrors the '
          'definition exactly.',
      pseudocode: const [
        'boolean isSameTree(TreeNode p, TreeNode q) {',
        '    if (p == null && q == null) return true;',
        '    if (p == null || q == null) return false;',
        '    if (p.val != q.val) return false;',
        '    return isSameTree(p.left, q.left)',
        '        && isSameTree(p.right, q.right);',
        '}',
      ],
      steps: steps,
      timeComplexity: 'O(n) — n is the smaller tree',
      spaceComplexity: 'O(h)',
      takeaway:
          'Check both-null before either-null, and both before comparing '
          'values.',
      problemIds: const ['32'],
    );
  }

  // ----------------------------------------------------------------- 33

  static AlgorithmTrace subtree() {
    const root = <String?>['3', '4', '5', '1', '2'];
    const sub = <String?>['4', '1', '2'];
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'Does the big tree contain the small one as a subtree? Try every '
            'node of the big tree as a candidate root, and run a Same Tree '
            'check from there.',
        codeLine: 0,
        scenes: [
          TreeScene(heap: root, title: 'root'),
          TreeScene(heap: sub, title: 'subRoot'),
        ],
      ),
    );

    steps.add(
      const VizStep(
        caption:
            'Start at 3. Its value does not match the subtree root 4, so 3 '
            'cannot be the match. Move down to its children.',
        codeLine: 2,
        scenes: [
          TreeScene(heap: root, states: {0: VizState.fail}, title: 'root'),
          TreeScene(heap: sub, states: {0: VizState.compare}, title: 'subRoot'),
        ],
      ),
    );

    steps.add(
      const VizStep(
        caption:
            'Try 4. The values match, so run the full Same Tree comparison '
            'from here — not just this node, but everything beneath it.',
        codeLine: 3,
        scenes: [
          TreeScene(
            heap: root,
            states: {
              1: VizState.active,
              3: VizState.compare,
              4: VizState.compare,
            },
            title: 'root',
          ),
          TreeScene(
            heap: sub,
            states: {
              0: VizState.active,
              1: VizState.compare,
              2: VizState.compare,
            },
            title: 'subRoot',
          ),
        ],
      ),
    );

    steps.add(
      const VizStep(
        caption:
            '4 matches 4, its left child 1 matches 1, and its right child 2 '
            'matches 2. Every node lines up, so the answer is true.',
        codeLine: 4,
        insight:
            'A match must be exact all the way down. A subtree is a node plus '
            '*all* of its descendants — stopping early would wrongly accept a '
            'partial match.',
        scenes: [
          TreeScene(
            heap: root,
            states: {
              1: VizState.success,
              3: VizState.success,
              4: VizState.success,
            },
            title: 'root',
          ),
          TreeScene(
            heap: sub,
            states: {
              0: VizState.success,
              1: VizState.success,
              2: VizState.success,
            },
            title: 'subRoot',
          ),
          ValueScene(
            readings: [
              (label: 'result', value: 'true', state: VizState.success),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'subtree-of-another-tree',
      title: 'Subtree of Another Tree',
      pattern: 'Trees',
      patternIdea:
          'Reuse a solved problem: this is Same Tree, attempted from every '
          'possible starting node.',
      pseudocode: const [
        'boolean isSubtree(TreeNode root, TreeNode sub) {',
        '    if (root == null) return false;',
        '    if (isSameTree(root, sub)) return true;',
        '    return isSubtree(root.left, sub)',
        '        || isSubtree(root.right, sub);',
        '}',
      ],
      steps: steps,
      timeComplexity: 'O(n · m) — a Same Tree check at every node',
      spaceComplexity: 'O(h)',
      takeaway:
          'An empty subRoot is a subtree of anything. Decide that base case '
          'deliberately rather than by accident.',
      problemIds: const ['33'],
    );
  }

  // ----------------------------------------------------------------- 34

  static AlgorithmTrace lowestCommonAncestor() {
    const heap = <String?>['6', '2', '8', '0', '4', '7', '9'];
    const p = 2;
    const q = 8;
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'Find the lowest node that has both 2 and 8 beneath it. In a '
            'binary search tree we never need to explore — the values '
            'themselves say which way to go.',
        codeLine: 0,
        scenes: [TreeScene(heap: heap, title: 'BST')],
      ),
    );

    var i = 0;
    while (true) {
      final v = int.parse(heap[i]!);
      if (p < v && q < v) {
        steps.add(
          VizStep(
            caption:
                'Both $p and $q are less than $v, so both live in the left '
                'subtree. The answer must be further left.',
            codeLine: 2,
            scenes: [
              TreeScene(heap: heap, states: {i: VizState.fail}, title: 'BST'),
            ],
          ),
        );
        i = i * 2 + 1;
      } else if (p > v && q > v) {
        steps.add(
          VizStep(
            caption:
                'Both $p and $q are greater than $v, so both live to the '
                'right. Move right.',
            codeLine: 4,
            scenes: [
              TreeScene(heap: heap, states: {i: VizState.fail}, title: 'BST'),
            ],
          ),
        );
        i = i * 2 + 2;
      } else {
        steps.add(
          VizStep(
            caption:
                'At $v the two targets split: one is not greater and the '
                'other is not smaller. This is the first node where their '
                'paths diverge, so $v is the lowest common ancestor.',
            codeLine: 6,
            insight:
                'No traversal of the subtrees was needed. The BST ordering '
                'turned a search problem into a single walk down one path.',
            scenes: [
              TreeScene(
                heap: heap,
                states: {i: VizState.success},
                title: 'BST',
              ),
              ValueScene(
                readings: [
                  (label: 'answer', value: '$v', state: VizState.success),
                ],
              ),
            ],
          ),
        );
        break;
      }
    }

    return AlgorithmTrace(
      id: 'lca-bst',
      title: 'Lowest Common Ancestor of a Binary Search Tree',
      pattern: 'Trees',
      patternIdea:
          'In a BST, comparing both targets to the current value tells you '
          'which single direction to walk.',
      pseudocode: const [
        'while (node != null) {',
        '    if (p.val < node.val && q.val < node.val)',
        '        node = node.left;',
        '    else if (p.val > node.val && q.val > node.val)',
        '        node = node.right;',
        '    else',
        '        return node;   // they split here',
        '}',
      ],
      steps: steps,
      timeComplexity: 'O(h) — one path down, not a full traversal',
      spaceComplexity: 'O(1) iteratively',
      takeaway:
          'The split point is the answer. A node counts as its own descendant, '
          'so equality falls into the split case.',
      problemIds: const ['34'],
    );
  }

  // ----------------------------------------------------------------- 36

  static AlgorithmTrace rightSideView() {
    const heap = <String?>['1', '2', '3', null, '5', null, '4'];
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'Standing to the right of the tree, which nodes can you see? Only '
            'the last node of each level — so walk level by level and keep '
            'the final one.',
        codeLine: 0,
        scenes: [
          TreeScene(heap: heap, title: 'tree'),
          QueueScene(items: [], title: 'queue', emptyLabel: 'empty'),
        ],
      ),
    );

    final view = <String>[];
    var level = <int>[0];
    var levelNumber = 0;

    while (level.isNotEmpty) {
      final visible = level.last;
      view.add(heap[visible]!);

      steps.add(
        VizStep(
          caption:
              'Level $levelNumber holds '
              '${level.map((i) => heap[i]).join(", ")}. The rightmost is '
              '${heap[visible]}, so that is what is visible.',
          codeLine: 5,
          scenes: [
            TreeScene(
              heap: heap,
              states: {
                for (final i in level) i: VizState.compare,
                visible: VizState.success,
              },
              title: 'tree',
            ),
            QueueScene(
              items: level
                  .map(
                    (i) => (
                      value: heap[i]!,
                      state: i == visible ? VizState.success : VizState.idle,
                    ),
                  )
                  .toList(),
              title: 'current level',
            ),
            ValueScene(
              readings: [
                (
                  label: 'visible so far',
                  value: view.join(', '),
                  state: VizState.active,
                ),
              ],
            ),
          ],
        ),
      );

      final next = <int>[];
      for (final i in level) {
        for (final c in [i * 2 + 1, i * 2 + 2]) {
          if (c < heap.length && heap[c] != null) next.add(c);
        }
      }
      level = next;
      levelNumber++;
    }

    steps.add(
      VizStep(
        caption: 'The right side view is [${view.join(", ")}].',
        codeLine: 7,
        insight:
            'This is level-order traversal with one extra line. Many tree '
            'problems are exactly BFS plus a small twist on what you record '
            'per level.',
        scenes: [
          ValueScene(
            readings: [
              (
                label: 'answer',
                value: '[${view.join(", ")}]',
                state: VizState.success,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'right-side-view',
      title: 'Binary Tree Right Side View',
      pattern: 'BFS',
      patternIdea:
          'Once you can walk a tree level by level, "per level" questions '
          'become one extra line.',
      pseudocode: const [
        'Queue<TreeNode> q = new LinkedList<>();  q.add(root);',
        'while (!q.isEmpty()) {',
        '    int size = q.size();',
        '    for (int i = 0; i < size; i++) {',
        '        TreeNode node = q.poll();',
        '        if (i == size - 1) res.add(node.val);   // rightmost',
        '        if (node.left != null) q.add(node.left);',
        '        if (node.right != null) q.add(node.right);',
        '    }',
        '}',
        'return res;',
      ],
      steps: steps,
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(w) — the widest level',
      takeaway:
          'Capture the level size before the inner loop, then record the node '
          'at index size − 1.',
      problemIds: const ['36'],
    );
  }

  // ----------------------------------------------------------------- 37

  static AlgorithmTrace countGoodNodes() {
    const heap = <String?>['3', '1', '4', '3', null, '1', '5'];
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'A node is "good" when nothing on the path from the root to it is '
            'larger. So carry the largest value seen so far down the tree as '
            'you go.',
        codeLine: 0,
        scenes: [TreeScene(heap: heap, title: 'tree')],
      ),
    );

    var count = 0;
    final good = <int>{};
    final bad = <int>{};

    void walk(int i, int maxSoFar) {
      if (i >= heap.length || heap[i] == null) return;
      final v = int.parse(heap[i]!);
      final isGood = v >= maxSoFar;
      if (isGood) {
        count++;
        good.add(i);
      } else {
        bad.add(i);
      }
      final newMax = v > maxSoFar ? v : maxSoFar;

      steps.add(
        VizStep(
          caption: isGood
              ? '$v is at least the largest value on the path so far '
                    '($maxSoFar), so it is good. Running total: $count.'
              : '$v is smaller than $maxSoFar, which sits above it on the '
                    'path, so it is not good.',
          codeLine: 3,
          scenes: [
            TreeScene(
              heap: heap,
              states: {
                for (final k in good) k: VizState.success,
                for (final k in bad) k: VizState.fail,
                i: isGood ? VizState.success : VizState.fail,
              },
              title: 'tree',
            ),
            ValueScene(
              readings: [
                (
                  label: 'max on path',
                  value: '$newMax',
                  state: VizState.active,
                ),
                (label: 'good count', value: '$count', state: VizState.idle),
              ],
            ),
          ],
        ),
      );

      walk(i * 2 + 1, newMax);
      walk(i * 2 + 2, newMax);
    }

    walk(0, -1 << 30);

    steps.add(
      VizStep(
        caption: 'There are $count good nodes.',
        codeLine: 5,
        insight:
            'The maximum is passed *down* as a parameter, unlike depth or '
            'diameter which are returned *up*. Deciding which direction '
            'information flows is the core design choice in tree recursion.',
        scenes: [
          TreeScene(
            heap: heap,
            states: {
              for (final k in good) k: VizState.success,
              for (final k in bad) k: VizState.dim,
            },
            title: 'good nodes highlighted',
          ),
          ValueScene(
            readings: [
              (label: 'answer', value: '$count', state: VizState.success),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'count-good-nodes',
      title: 'Count Good Nodes in Binary Tree',
      pattern: 'Trees',
      patternIdea:
          'When a node\'s answer depends on its ancestors, pass that context '
          'down as an argument.',
      pseudocode: const [
        'int count = 0;',
        'void walk(TreeNode node, int maxSoFar) {',
        '    if (node == null) return;',
        '    if (node.val >= maxSoFar) count++;',
        '    int newMax = Math.max(maxSoFar, node.val);',
        '    walk(node.left, newMax);',
        '    walk(node.right, newMax);',
        '}',
      ],
      steps: steps,
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(h)',
      takeaway:
          'Use >= so equal values still count, and seed the walk with the '
          'root value (or negative infinity).',
      problemIds: const ['37'],
    );
  }

  // ----------------------------------------------------------------- 38

  static AlgorithmTrace validateBst() {
    const heap = <String?>['2', '1', '3'];
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'A BST needs more than "left child smaller, right child larger". '
            'Every node must fall inside a range fixed by all of its '
            'ancestors, so carry that range down.',
        codeLine: 0,
        scenes: [TreeScene(heap: heap, title: 'tree')],
      ),
    );

    var valid = true;
    final checked = <int>{};

    void walk(int i, int? low, int? high) {
      if (i >= heap.length || heap[i] == null) return;
      final v = int.parse(heap[i]!);
      final ok = (low == null || v > low) && (high == null || v < high);
      if (!ok) valid = false;
      checked.add(i);

      final range = '${low ?? "−∞"} < $v < ${high ?? "+∞"}';

      steps.add(
        VizStep(
          caption: ok
              ? 'Node $v must satisfy $range. It does, so the subtree rooted '
                    'here is still valid.'
              : 'Node $v must satisfy $range, and it does not. The tree is '
                    'not a valid BST.',
          codeLine: 3,
          scenes: [
            TreeScene(
              heap: heap,
              states: {
                for (final k in checked) k: VizState.done,
                i: ok ? VizState.active : VizState.fail,
              },
              title: 'tree',
            ),
            ValueScene(
              readings: [
                (
                  label: 'allowed range',
                  value: range,
                  state: ok ? VizState.idle : VizState.fail,
                ),
              ],
            ),
          ],
        ),
      );

      walk(i * 2 + 1, low, v);
      walk(i * 2 + 2, v, high);
    }

    walk(0, null, null);

    steps.add(
      VizStep(
        caption: valid
            ? 'Every node stayed inside its allowed range, so this is a valid '
                  'BST.'
            : 'A node fell outside its range, so this is not a valid BST.',
        codeLine: 5,
        insight:
            'Going left tightens the upper bound; going right tightens the '
            'lower bound. Comparing only against the parent misses violations '
            'from a grandparent.',
        scenes: [
          ValueScene(
            readings: [
              (
                label: 'result',
                value: '$valid',
                state: valid ? VizState.success : VizState.fail,
              ),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'validate-bst',
      title: 'Validate Binary Search Tree',
      pattern: 'Trees',
      patternIdea:
          'Local checks are not enough — push the full constraint down as a '
          'range.',
      pseudocode: const [
        'boolean valid(TreeNode node, Integer low, Integer high) {',
        '    if (node == null) return true;',
        '    if ((low != null && node.val <= low)',
        '        || (high != null && node.val >= high)) return false;',
        '    return valid(node.left, low, node.val)',
        '        && valid(node.right, node.val, high);',
        '}',
      ],
      steps: steps,
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(h)',
      takeaway:
          'Use Integer, not int, so null can stand for "no bound" — and mind '
          'the strict inequalities, since duplicates are invalid.',
      problemIds: const ['38'],
    );
  }

  // ----------------------------------------------------------------- 39

  static AlgorithmTrace kthSmallestBst() {
    const heap = <String?>['3', '1', '4', null, '2'];
    const k = 1;
    final steps = <VizStep>[];

    steps.add(
      const VizStep(
        caption:
            'Find the 1st smallest value in this BST. An in-order traversal '
            'of a BST visits values in sorted order, so we just need to stop '
            'at the kth one.',
        codeLine: 0,
        scenes: [TreeScene(heap: heap, title: 'BST')],
      ),
    );

    final order = <int>[];
    void inOrder(int i) {
      if (i >= heap.length || heap[i] == null) return;
      inOrder(i * 2 + 1);
      order.add(i);
      inOrder(i * 2 + 2);
    }

    inOrder(0);

    final visited = <int>[];
    var answer = '';
    for (var n = 0; n < order.length; n++) {
      final i = order[n];
      visited.add(i);
      final isTarget = n + 1 == k;
      if (isTarget) answer = heap[i]!;

      steps.add(
        VizStep(
          caption: isTarget
              ? 'In-order visit number ${n + 1} lands on ${heap[i]}. That is '
                    'the ${k}st smallest, so we can stop here.'
              : 'In-order visit number ${n + 1} is ${heap[i]}. Not yet the '
                    'kth, so keep going.',
          codeLine: 3,
          scenes: [
            TreeScene(
              heap: heap,
              states: {
                for (final v in visited) v: VizState.done,
                i: isTarget ? VizState.success : VizState.active,
              },
              title: 'BST',
            ),
            ValueScene(
              readings: [
                (
                  label: 'visited in order',
                  value: visited.map((v) => heap[v]).join(', '),
                  state: VizState.idle,
                ),
              ],
            ),
          ],
        ),
      );

      if (isTarget) break;
    }

    steps.add(
      VizStep(
        caption: 'The ${k}st smallest element is $answer.',
        codeLine: 5,
        insight:
            'In-order on a BST is sorted order. That single fact turns half '
            'the BST problems on this list into "traverse and count".',
        scenes: [
          ValueScene(
            readings: [
              (label: 'answer', value: answer, state: VizState.success),
            ],
          ),
        ],
      ),
    );

    return AlgorithmTrace(
      id: 'kth-smallest-bst',
      title: 'Kth Smallest Element in a BST',
      pattern: 'Trees',
      patternIdea:
          'In-order traversal of a BST produces sorted output, so ranking '
          'questions become counting questions.',
      pseudocode: const [
        'int count = 0, answer = -1;',
        'void inOrder(TreeNode node, int k) {',
        '    if (node == null) return;',
        '    inOrder(node.left, k);',
        '    if (++count == k) { answer = node.val; return; }',
        '    inOrder(node.right, k);',
        '}',
      ],
      steps: steps,
      timeComplexity: 'O(h + k) — only the first k values are visited',
      spaceComplexity: 'O(h)',
      takeaway:
          'Return as soon as the counter hits k. Finishing the traversal wastes '
          'the advantage the BST just gave you.',
      problemIds: const ['39'],
    );
  }
}
