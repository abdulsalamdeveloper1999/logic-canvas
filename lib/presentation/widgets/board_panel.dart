import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logic_canvas/domain/entities/problem.dart';
import 'package:logic_canvas/data/datasources/static_problem_data.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_state.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_state.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_cubit.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_state.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/domain/entities/viz_scene.dart';
import 'package:logic_canvas/presentation/widgets/backup_panel.dart';
import 'package:logic_canvas/presentation/widgets/viz/pattern_library_view.dart';

enum _LibraryLens { patterns, problems }

/// The drawer's home: switch boards, browse what to start a board from, and
/// reach settings.
///
/// Two tabs, not four. Boards and Library are things a person browses while
/// working; Settings is visited once and forgotten, so it lives behind the
/// gear icon in a sheet instead of permanently occupying a quarter of the tab
/// bar. Learn and Templates used to be separate tabs for the same underlying
/// idea — something to start a board from — so they are now one tab with a
/// single search across both.
class BoardPanel extends StatefulWidget {
  const BoardPanel({super.key});

  @override
  State<BoardPanel> createState() => _BoardPanelState();
}

class _BoardPanelState extends State<BoardPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _LibraryLens _libraryLens = _LibraryLens.patterns;
  final Set<String> _expandedPacks = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrawingCubit, DrawingState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Boards'),
                  Tab(text: 'Library'),
                ],
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: Theme.of(context).colorScheme.onSurface,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBoardsTab(context, state),
                    _buildLibraryTab(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------- typography
  //
  // Three styles, not eight. The previous panel emphasised nearly everything
  // — w900 letterspaced caps for section labels, tab labels, and category
  // headers alike — which reads as nothing being more important than
  // anything else. Primary color is reserved for the active board, the tab
  // indicator, and real actions; everywhere else stays neutral.

  TextStyle _rowTitleStyle(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  TextStyle _metaStyle(BuildContext context) => TextStyle(
    fontSize: 12,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // ------------------------------------------------------------------ header

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'Settings',
            onPressed: () => _openSettings(context),
            visualDensity: VisualDensity.compact,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- boards tab

  Widget _buildBoardsTab(BuildContext context, DrawingState state) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      itemCount: state.boardIds.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              _buildNewBoardRow(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 17,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                ),
              ),
            ],
          );
        }
        final boardId = state.boardIds[index - 1];
        return _buildBoardTile(
          context,
          boardId,
          boardId == state.activeBoardId,
        );
      },
    );
  }

  Widget _buildNewBoardRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCreateBoardDialog(context),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              Text(
                'New board',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardTile(BuildContext context, String boardId, bool isActive) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Dismissible(
        key: Key('board_$boardId'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) => _confirmDeleteBoard(context, boardId),
        onDismissed: (direction) {
          context.read<DrawingCubit>().deleteBoard(boardId);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
        ),
        child: Material(
          color: isActive
              ? scheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<DrawingCubit>().switchToBoard(boardId);
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    isActive
                        ? Icons.description_rounded
                        : Icons.description_outlined,
                    size: 18,
                    color: isActive
                        ? scheme.primary
                        : scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      boardId,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive
                            ? scheme.onSurface
                            : scheme.onSurface.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    padding: EdgeInsets.zero,
                    tooltip: 'Board options',
                    onSelected: (value) {
                      if (value == 'rename') {
                        _showRenameBoardDialog(context, boardId);
                      } else if (value == 'delete') {
                        _deleteBoardWithConfirm(context, boardId);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBoardWithConfirm(
    BuildContext context,
    String boardId,
  ) async {
    final confirmed = await _confirmDeleteBoard(context, boardId);
    if (confirmed == true && context.mounted) {
      context.read<DrawingCubit>().deleteBoard(boardId);
    }
  }

  // ------------------------------------------------------------ library tab

  Widget _buildLibraryTab(BuildContext context) {
    final query = _searchQuery;

    final starterPack = _filterProblems(ProblemData.starterPack);
    final blind75 = _filterProblems(ProblemData.blind75);
    final pareto = _filterProblems(ProblemData.paretoProblems);
    final problemMatchCount =
        starterPack.length + blind75.length + pareto.length;

    final patternMatchCount = query.isEmpty
        ? null
        : PatternLibraryView.grouped()
              .expand((g) => g.traces)
              .where((t) => PatternLibraryView.matches(t, query))
              .length;

    final showPatternsHint =
        query.isNotEmpty &&
        _libraryLens == _LibraryLens.patterns &&
        (patternMatchCount ?? 0) == 0 &&
        problemMatchCount > 0;
    final showProblemsHint =
        query.isNotEmpty &&
        _libraryLens == _LibraryLens.problems &&
        problemMatchCount == 0 &&
        (patternMatchCount ?? 0) > 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: _buildSearchField(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SegmentedButton<_LibraryLens>(
            segments: const [
              ButtonSegment(
                value: _LibraryLens.patterns,
                label: Text('Patterns'),
                icon: Icon(Icons.play_circle_outline_rounded, size: 16),
              ),
              ButtonSegment(
                value: _LibraryLens.problems,
                label: Text('Problems'),
                icon: Icon(Icons.extension_outlined, size: 16),
              ),
            ],
            selected: {_libraryLens},
            onSelectionChanged: (selection) {
              setState(() => _libraryLens = selection.first);
            },
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        ),
        if (showProblemsHint)
          _buildCrossLensHint(
            context,
            problemMatchCount,
            _LibraryLens.problems,
            'Problems',
          ),
        if (showPatternsHint)
          _buildCrossLensHint(
            context,
            patternMatchCount!,
            _LibraryLens.patterns,
            'Patterns',
          ),
        Expanded(
          child: _libraryLens == _LibraryLens.patterns
              ? PatternLibraryView(
                  onCopyToBoard: _writeTraceToBoard,
                  searchQuery: query,
                )
              : _buildProblemsBrowser(
                  context,
                  starterPack,
                  blind75,
                  pareto,
                  isSearching: query.isNotEmpty,
                ),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: (val) =>
            setState(() => _searchQuery = val.trim().toLowerCase()),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search patterns and problems',
          hintStyle: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  visualDensity: VisualDensity.compact,
                )
              : null,
          filled: true,
          fillColor: scheme.onSurface.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  /// Shown when the active lens has nothing for the query but the other one
  /// does — a tappable way out instead of a dead end that looks like "no
  /// results" when the answer was simply in the other lens.
  Widget _buildCrossLensHint(
    BuildContext context,
    int otherCount,
    _LibraryLens switchTo,
    String label,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _libraryLens = switchTo),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.swap_horiz_rounded, size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$otherCount ${otherCount == 1 ? "match" : "matches"} in $label',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Puts a pattern's summary on a fresh board, so the learner leaves the
  /// animation with something to build on rather than a blank canvas.
  void _writeTraceToBoard(AlgorithmTrace trace) {
    final cubit = context.read<DrawingCubit>();
    final textColor = context.read<SettingsCubit>().state.strokeColor;

    cubit.createNewBoard(_uniqueBoardName(cubit, trace.pattern));
    cubit.addStroke(
      Stroke(
        points: const [Offset(100, 100)],
        color: textColor,
        strokeWidth: 2.0,
        type: StrokeType.text,
        text:
            '${trace.title} — ${trace.pattern}\n\n'
            '${trace.patternIdea}\n\n'
            '${trace.pseudocode.join('\n')}\n\n'
            'Time: ${trace.timeComplexity}\n'
            'Space: ${trace.spaceComplexity}\n\n'
            'Remember: ${trace.takeaway}',
      ),
    );
  }

  String _uniqueBoardName(DrawingCubit cubit, String base) {
    var name = base;
    var counter = 1;
    while (cubit.state.boardIds.contains(name)) {
      name = '$base ($counter)';
      counter++;
    }
    return name;
  }

  List<Problem> _filterProblems(List<Problem> problems) {
    if (_searchQuery.isEmpty) return problems;
    return problems.where((p) {
      return p.title.toLowerCase().contains(_searchQuery) ||
          p.category.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No problems found',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Try a different keyword',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemsBrowser(
    BuildContext context,
    List<Problem> starterPack,
    List<Problem> blind75,
    List<Problem> pareto, {
    required bool isSearching,
  }) {
    if (isSearching &&
        starterPack.isEmpty &&
        blind75.isEmpty &&
        pareto.isEmpty) {
      return _buildNoResultsState(context);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
      children: [
        if (starterPack.isNotEmpty)
          _buildPackSection(
            context,
            'Starter pack',
            starterPack,
            isSearching || _expandedPacks.contains('Starter pack'),
          ),
        if (blind75.isNotEmpty)
          _buildPackSection(
            context,
            'Blind 75',
            blind75,
            isSearching || _expandedPacks.contains('Blind 75'),
          ),
        if (pareto.isNotEmpty)
          _buildPackSection(
            context,
            'Pareto LeetCode',
            pareto,
            isSearching || _expandedPacks.contains('Pareto LeetCode'),
            groupByCategory: true,
          ),
      ],
    );
  }

  /// One expandable pack of problems. A single level of disclosure — the
  /// previous panel nested a second `ExpansionTile` per category inside this
  /// one, which meant two chevrons and two indents to reach a problem.
  /// [groupByCategory] draws the same grouping as a plain, non-collapsible
  /// label instead.
  Widget _buildPackSection(
    BuildContext context,
    String title,
    List<Problem> problems,
    bool initiallyExpanded, {
    bool groupByCategory = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    final children = <Widget>[];
    if (groupByCategory) {
      final grouped = <String, List<Problem>>{};
      for (final p in problems) {
        grouped.update(p.category, (list) => list..add(p), ifAbsent: () => [p]);
      }
      for (final entry in grouped.entries) {
        children.add(_buildCategoryLabel(context, entry.key));
        children.addAll(entry.value.map((p) => _buildProblemTile(context, p)));
      }
    } else {
      children.addAll(problems.map((p) => _buildProblemTile(context, p)));
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey('pack_$title'),
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedPacks.add(title);
            } else {
              _expandedPacks.remove(title);
            }
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${problems.length}',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        children: children,
      ),
    );
  }

  Widget _buildCategoryLabel(BuildContext context, String category) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildProblemTile(BuildContext context, Problem problem) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          final color = context.read<SettingsCubit>().state.strokeColor;
          context.read<DrawingCubit>().createNewBoardFromTemplate(
            problem,
            color,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _difficultyColor(problem.difficulty),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  problem.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.add_rounded,
                size: 16,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _difficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.greenAccent;
      case Difficulty.medium:
        return Colors.orangeAccent;
      case Difficulty.hard:
        return Colors.redAccent;
    }
  }

  // -------------------------------------------------------------- settings
  //
  // A sheet, not a tab. iCloud sync, the AI model, and appearance are visited
  // once and then forgotten — they do not deserve a permanent quarter of the
  // navigation next to boards a person switches between constantly.

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            _buildSettingsSheetContent(context, scrollController),
      ),
    );
  }

  Widget _buildSettingsSheetContent(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _settingsSection(context, 'Synchronization', [
                    SwitchListTile(
                      title: Text(
                        'iCloud sync',
                        style: _rowTitleStyle(context),
                      ),
                      subtitle: Text(
                        'Backup & sync boards across devices',
                        style: _metaStyle(context),
                      ),
                      value: state.isICloudSyncEnabled,
                      onChanged: (val) {
                        context.read<SettingsCubit>().toggleICloudSync();
                        context.read<DrawingCubit>().setSyncEnabled(val);
                      },
                      secondary: Icon(
                        Icons.cloud_sync_rounded,
                        color: scheme.primary,
                      ),
                      activeThumbColor: scheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    const BackupRecoverySection(),
                  ]),
                  const SizedBox(height: 20),
                  _buildAiModelSection(context),
                  const SizedBox(height: 20),
                  _settingsSection(context, 'Appearance', [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text('Theme', style: _rowTitleStyle(context)),
                          const Spacer(),
                          SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('Light'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('Dark'),
                              ),
                            ],
                            selected: {state.themeMode},
                            onSelectionChanged: (selection) {
                              if (selection.first != state.themeMode) {
                                context.read<SettingsCubit>().toggleTheme();
                              }
                            },
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text('Grid', style: _rowTitleStyle(context)),
                          const Spacer(),
                          SegmentedButton<BackgroundPattern>(
                            segments: const [
                              ButtonSegment(
                                value: BackgroundPattern.none,
                                label: Text('None'),
                              ),
                              ButtonSegment(
                                value: BackgroundPattern.grid,
                                label: Text('Grid'),
                              ),
                              ButtonSegment(
                                value: BackgroundPattern.lines,
                                label: Text('Lines'),
                              ),
                            ],
                            selected: {state.pattern},
                            onSelectionChanged: (selection) {
                              context.read<SettingsCubit>().setPattern(
                                selection.first,
                              );
                            },
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _settingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildAiModelSection(BuildContext context) {
    return BlocBuilder<GemmaCubit, GemmaState>(
      builder: (context, state) {
        return _settingsSection(context, 'AI model', [
          switch (state.status) {
            GemmaStatus.idle => _buildIdleState(context),
            GemmaStatus.downloading => _buildDownloadingState(context, state),
            GemmaStatus.ready => _buildReadyState(context),
            GemmaStatus.error => _buildErrorState(context, state),
          },
        ]);
      },
    );
  }

  /// Deleting throws away a 1.7 GB download that has to be fetched again in
  /// full, so it asks first.
  Future<void> _confirmDeleteModel(BuildContext context) async {
    final cubit = context.read<GemmaCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete the AI model?'),
        content: const Text(
          'This frees about 1.7 GB on your device. The AI Assistant will stop '
          'working until you download it again, and the download starts from '
          'the beginning.\n\nYour boards are not affected.',
          style: TextStyle(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await cubit.deleteModel();
  }

  Widget _buildIdleState(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('On-device AI model', style: _rowTitleStyle(context)),
          subtitle: Text(
            'Enhance your whiteboard with AI-powered code explanations & diagram insights (1.7 GB)',
            style: _metaStyle(context),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.read<GemmaCubit>().checkAndDownload(),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text(
                  'Download model',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadingState(BuildContext context, GemmaState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text('Downloading AI model…', style: _rowTitleStyle(context)),
              const Spacer(),
              Text(
                '${(state.downloadProgress * 100).toInt()}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.downloadProgress,
              minHeight: 6,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          // There is no resume: closing the app restarts the 1.7 GB fetch from
          // zero, so say that before the user walks away from it.
          Text(
            '1.7 GB. Keep the app open — closing it starts the download over.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyState(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text('AI model ready', style: _rowTitleStyle(context)),
          const SizedBox(width: 8),
          Icon(Icons.check_circle_rounded, size: 18, color: Colors.greenAccent),
        ],
      ),
      subtitle: Text(
        'Model is installed and ready for offline use',
        style: _metaStyle(context),
      ),
      trailing: TextButton(
        onPressed: () => _confirmDeleteModel(context),
        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
        child: const Text('Delete', style: TextStyle(fontSize: 11)),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildErrorState(BuildContext context, GemmaState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Download failed',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              state.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.read<GemmaCubit>().checkAndDownload(),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Retry', style: TextStyle(fontSize: 10)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- dialogs

  void _showRenameBoardDialog(BuildContext context, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Rename board'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Enter new board name',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                context.read<DrawingCubit>().renameBoard(oldName, newName);
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showCreateBoardDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('New board'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Enter board name (e.g., System Design)',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              context.read<DrawingCubit>().createNewBoard(val.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<DrawingCubit>().createNewBoard(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteBoard(
    BuildContext context,
    String boardId,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete board?'),
        content: Text(
          'Are you sure you want to delete "$boardId"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
