/// Visual emphasis for a single element in an animated algorithm step.
enum VizState {
  /// Not currently involved.
  idle,

  /// The element the algorithm is looking at right now.
  active,

  /// Being compared against the active element.
  compare,

  /// Confirmed part of the answer.
  success,

  /// Ruled out / discarded.
  fail,

  /// Already processed, no longer in play.
  done,

  /// Outside the current region of interest.
  dim,
}

/// One panel inside an animation frame. A step may stack several panels — an
/// array above the hash map it is filling in, for example.
sealed class VizScene {
  const VizScene();

  /// Shown above the panel, e.g. "nums" or "seen".
  String? get title;
}

/// A row of boxed values with optional pointers and a highlighted window.
/// Covers arrays, strings, and any index-walked sequence.
class ArrayScene extends VizScene {
  final List<String> values;
  final Map<int, VizState> states;

  /// Label -> index, drawn as a marker under the cell ("i", "left", "mid").
  final Map<String, int> pointers;

  /// Inclusive range drawn as a bracket above the cells.
  final ({int start, int end})? window;

  final String? windowLabel;
  @override
  final String? title;

  const ArrayScene({
    required this.values,
    this.states = const {},
    this.pointers = const {},
    this.window,
    this.windowLabel,
    this.title,
  });
}

/// Key/value rows, for hash maps, frequency counts and "seen" sets.
class MapScene extends VizScene {
  final List<({String key, String value, VizState state})> entries;
  @override
  final String? title;

  /// Shown when [entries] is empty, e.g. "empty".
  final String emptyLabel;

  const MapScene({
    required this.entries,
    this.title,
    this.emptyLabel = 'empty',
  });
}

/// A vertical stack that grows upward, for stack-based algorithms.
class StackScene extends VizScene {
  final List<({String value, VizState state})> items;
  @override
  final String? title;
  final String emptyLabel;

  const StackScene({
    required this.items,
    this.title,
    this.emptyLabel = 'empty',
  });
}

/// A binary tree in level order. `null` marks a missing child, exactly like
/// LeetCode's own tree input format.
class TreeScene extends VizScene {
  final List<String?> heap;
  final Map<int, VizState> states;
  @override
  final String? title;

  const TreeScene({required this.heap, this.states = const {}, this.title});

  /// Depth of the tree, used by the renderer to size itself.
  int get depth {
    var levels = 0;
    var capacity = 1;
    var index = 0;
    while (index < heap.length) {
      levels++;
      index += capacity;
      capacity *= 2;
    }
    return levels;
  }
}

/// A singly linked list. [next] holds each node's successor index, so a
/// reversal animation can show links flipping one at a time.
class LinkedListScene extends VizScene {
  final List<String> values;
  final List<int?> next;
  final Map<int, VizState> states;

  /// Label -> node index, or null for a pointer parked at null.
  final Map<String, int?> pointers;

  @override
  final String? title;

  const LinkedListScene({
    required this.values,
    required this.next,
    this.states = const {},
    this.pointers = const {},
    this.title,
  });
}

/// A horizontal queue, drawn front-to-back. Used alongside a tree for BFS.
class QueueScene extends VizScene {
  final List<({String value, VizState state})> items;
  @override
  final String? title;
  final String emptyLabel;

  const QueueScene({
    required this.items,
    this.title,
    this.emptyLabel = 'empty',
  });
}

/// A 2-D grid, for matrix problems: islands, Sudoku boards, flood fill.
/// States are keyed by `row * columns + column`, matching [ArrayScene]'s
/// index-based convention.
class GridScene extends VizScene {
  final List<List<String>> cells;
  final Map<int, VizState> states;
  @override
  final String? title;

  const GridScene({required this.cells, this.states = const {}, this.title});

  int get rows => cells.length;
  int get columns => cells.isEmpty ? 0 : cells.first.length;

  int indexOf(int row, int column) => row * columns + column;
}

/// A node-and-edge graph laid out on a circle by the renderer. Used for
/// traversal, cloning and topological-sort problems.
class GraphScene extends VizScene {
  final List<String> nodes;
  final List<({int from, int to})> edges;
  final bool directed;
  final Map<int, VizState> states;

  /// Edges to draw emphasised, as indices into [edges].
  final Set<int> activeEdges;

  @override
  final String? title;

  const GraphScene({
    required this.nodes,
    required this.edges,
    this.directed = false,
    this.states = const {},
    this.activeEdges = const {},
    this.title,
  });
}

/// A plain read-out, for running totals and answers ("maxLength = 3").
class ValueScene extends VizScene {
  final List<({String label, String value, VizState state})> readings;
  @override
  final String? title;

  const ValueScene({required this.readings, this.title});
}

/// A single frame of an animation.
class VizStep {
  /// Plain-English narration of what is happening, written for someone who has
  /// never seen the pattern before.
  final String caption;

  final List<VizScene> scenes;

  /// Index into [AlgorithmTrace.pseudocode] to highlight, if any.
  final int? codeLine;

  /// Optional "why this works" aside, surfaced more prominently than caption.
  final String? insight;

  const VizStep({
    required this.caption,
    required this.scenes,
    this.codeLine,
    this.insight,
  });
}

/// A complete, replayable walkthrough of one algorithm on one concrete input.
class AlgorithmTrace {
  final String id;
  final String title;

  /// The pattern this teaches, e.g. "Sliding Window".
  final String pattern;

  /// One line on why this pattern exists at all.
  final String patternIdea;

  final List<String> pseudocode;
  final List<VizStep> steps;
  final String timeComplexity;
  final String spaceComplexity;

  /// The one sentence worth remembering after the animation ends.
  final String takeaway;

  /// Problem ids in the library this trace explains.
  final List<String> problemIds;

  const AlgorithmTrace({
    required this.id,
    required this.title,
    required this.pattern,
    required this.patternIdea,
    required this.pseudocode,
    required this.steps,
    required this.timeComplexity,
    required this.spaceComplexity,
    required this.takeaway,
    this.problemIds = const [],
  });

  int get stepCount => steps.length;
}
