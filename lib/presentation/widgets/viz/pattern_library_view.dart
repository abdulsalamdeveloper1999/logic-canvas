import 'package:flutter/material.dart';
import 'package:logic_canvas/data/algorithms/algorithm_traces.dart';
import 'package:logic_canvas/domain/entities/viz_scene.dart';
import 'package:logic_canvas/presentation/widgets/viz/algorithm_player.dart';

/// Browsable catalogue of the animated walkthroughs, grouped into the same
/// categories as the problem list and ordered as a study plan.
///
/// A beginner opening a blank whiteboard has no idea what to draw. This is the
/// "show me how this works first" entry point, reachable without picking a
/// problem — and the numbered sections tell them where to start.
class PatternLibraryView extends StatelessWidget {
  /// Called when the learner asks to copy a pattern's summary onto the board.
  final void Function(AlgorithmTrace trace)? onCopyToBoard;

  /// Filters the catalogue to traces whose title or pattern matches. Empty
  /// shows everything. Kept as a widget-level filter rather than folding it
  /// into [grouped] so the full-catalogue completeness test keeps checking
  /// the real data, not whatever happens to be typed into a search box.
  final String searchQuery;

  const PatternLibraryView({
    super.key,
    this.onCopyToBoard,
    this.searchQuery = '',
  });

  /// True when [trace] is a hit for [query] — case-insensitive, title or
  /// pattern name. An empty query matches everything.
  static bool matches(AlgorithmTrace trace, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return trace.title.toLowerCase().contains(q) ||
        trace.pattern.toLowerCase().contains(q);
  }

  /// Section title → the trace patterns it contains. Order is the recommended
  /// learning path: each category builds on the ones above it.
  static const List<(String, Set<String>)> sections = [
    ('Arrays & Hashing', {'Hash Map', 'Prefix Sum'}),
    ('Two Pointers', {'Two Pointers'}),
    ('Sliding Window', {'Sliding Window'}),
    ('Stack', {'Stack'}),
    ('Binary Search', {'Binary Search'}),
    ('Linked List', {'Linked List'}),
    ('Trees', {'Trees', 'BFS'}),
    ('Heap / Priority Queue', {'Heap'}),
    ('Graphs', {'Graphs'}),
  ];

  /// Groups the master list into display sections, preserving order. A trace
  /// whose pattern matches no section still gets shown, in a trailing group,
  /// so nothing can silently vanish from the catalogue.
  static List<({String title, List<AlgorithmTrace> traces})> grouped() {
    final all = AlgorithmTraces.all;
    final placed = <AlgorithmTrace>{};
    final result = <({String title, List<AlgorithmTrace> traces})>[];

    for (final (title, patterns) in sections) {
      final members = all.where((t) => patterns.contains(t.pattern)).toList();
      if (members.isEmpty) continue;
      placed.addAll(members);
      result.add((title: title, traces: members));
    }

    final orphans = all.where((t) => !placed.contains(t)).toList();
    if (orphans.isNotEmpty) {
      result.add((title: 'More', traces: orphans));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = searchQuery.trim();

    final groups = grouped()
        .map(
          (g) => (
            title: g.title,
            traces: g.traces.where((t) => matches(t, query)).toList(),
          ),
        )
        .where((g) => g.traces.isNotEmpty)
        .toList();

    if (groups.isEmpty && query.isNotEmpty) {
      return _buildNoResults(context, scheme);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (query.isEmpty) ...[
          Text(
            'Watch each algorithm run, one step at a time, on a real example. '
            'The sections are ordered — if you are new to this, start at the '
            'top and work down.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
        ],
        for (final (index, group) in groups.indexed) ...[
          _SectionHeader(
            number: index + 1,
            title: group.title,
            count: group.traces.length,
          ),
          const SizedBox(height: 8),
          for (final trace in group.traces) ...[
            _PatternCard(
              trace: trace,
              onOpen: () => AlgorithmPlayerPage.open(
                context,
                trace,
                onCopyToBoard: onCopyToBoard,
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildNoResults(BuildContext context, ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 12),
            Text(
              'No patterns match "$searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final int number;
  final String title;
  final int count;

  const _SectionHeader({
    required this.number,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PatternCard extends StatelessWidget {
  final AlgorithmTrace trace;
  final VoidCallback onOpen;

  const _PatternCard({required this.trace, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trace.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trace.patternIdea,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${trace.stepCount} steps · ${trace.pattern}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.play_circle_fill_rounded,
                size: 28,
                color: scheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
