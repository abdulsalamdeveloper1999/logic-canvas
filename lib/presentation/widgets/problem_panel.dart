import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logic_canvas/presentation/cubits/progress/progress_cubit.dart';
import 'package:logic_canvas/presentation/cubits/progress/progress_state.dart';
import 'package:logic_canvas/domain/entities/problem.dart';
import 'package:logic_canvas/data/datasources/static_problem_data.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';
import 'package:logic_canvas/presentation/widgets/upgrade_dialog.dart';

import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/selection/selection_cubit.dart';
import 'package:logic_canvas/presentation/cubits/selection/selection_state.dart';

class ProblemPanel extends StatelessWidget {
  const ProblemPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isPro = context.select((EntitlementsCubit c) => c.state.isPro);
    return BlocBuilder<ProgressCubit, ProgressState>(
      builder: (context, progress) {
        return BlocBuilder<SelectionCubit, SelectionState>(
          builder: (context, selection) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.3),
                border: Border(
                  right: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child:
                  selection.isViewingDetail && selection.selectedProblem != null
                  ? _buildDetailView(
                      context,
                      selection.selectedProblem!,
                      progress.completedProblemIds,
                    )
                  : _buildListView(
                      context,
                      selection.currentList,
                      progress.completedProblemIds,
                      isPro,
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(
    BuildContext context,
    String currentList,
    Set<String> completedIds,
    bool isPro,
  ) {
    final allProblems = currentList == 'Pareto 49'
        ? ProblemData.paretoProblems
        : ProblemData.blind75;
    final problems = isPro ? allProblems : ProblemData.starterPack;

    final grouped = <String, List<Problem>>{};
    for (var p in problems) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    return Column(
      children: [
        _buildHeader(context, currentList, isPro),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: grouped.entries
                .map(
                  (entry) => _buildCategory(
                    context,
                    entry.key,
                    entry.value,
                    completedIds,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(
    BuildContext context,
    Problem p,
    Set<String> completedIds,
  ) {
    final isDone = completedIds.contains(p.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.read<SelectionCubit>().exitDetail();
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const Text(
                'Back to List',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                p.category.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                p.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDifficultyBadge(p.difficulty),
              const SizedBox(height: 24),
              if (p.description != null) ...[
                const Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  p.description!,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 32),
              ],
              if (p.examples.isNotEmpty) ...[
                const Text(
                  'EXAMPLES',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 12),
                ...p.examples.asMap().entries.map((entry) {
                  final index = entry.key;
                  final example = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Example ${index + 1}:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Input: ',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    TextSpan(
                                      text: example.input,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Output: ',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    TextSpan(
                                      text: example.output,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (example.explanation != null) ...[
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Explanation: ',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: example.explanation!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
              const Text(
                'HINTS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              if (p.hints.isEmpty)
                const Text(
                  'No hints available for this problem yet.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.white38,
                  ),
                )
              else
                ...p.hints.map(
                  (hint) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blueAccent,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            hint,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _confirmToggleCompletion(context, p, isDone);
                },
                icon: Icon(isDone ? Icons.close : Icons.check),
                label: Text(
                  isDone ? 'Mark as Incomplete' : 'Mark as Completed',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  foregroundColor: isDone ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (isDone) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Text(
                        'Solved!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _confirmToggleCompletion(
    BuildContext context,
    Problem problem,
    bool isCurrentlyDone,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isCurrentlyDone ? 'Mark as Incomplete' : 'Confirm Completion',
        ),
        content: Text(
          isCurrentlyDone
              ? 'Are you sure you want to mark "${problem.title}" as incomplete?'
              : 'Are you sure you want to mark "${problem.title}" as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.read<ProgressCubit>().toggleCompletion(problem.id);
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(
              foregroundColor: isCurrentlyDone ? Colors.red : Colors.green,
            ),
            child: Text(
              isCurrentlyDone ? 'Yes, Unmark it' : 'Yes, Mark it Complete',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(Difficulty diff) {
    final color = _getDifficultyColor(diff);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        diff.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String currentList, bool isPro) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPro)
            Row(
              children: [
                _buildTabButton(
                  context,
                  'Pareto 49',
                  currentList == 'Pareto 49',
                ),
                const SizedBox(width: 8),
                _buildTabButton(context, 'Blind 75', currentList == 'Blind 75'),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        'STARTER PACK',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => UpgradeDialog.show(context),
                  icon: const Icon(Icons.lock_rounded, size: 16),
                  label: const Text('Pro'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.read<SelectionCubit>().setCurrentList(title);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context,
    String category,
    List<Problem> problems,
    Set<String> completedIds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            category.toUpperCase(),
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...problems.map((p) => _buildProblemTile(context, p, completedIds)),
      ],
    );
  }

  Widget _buildProblemTile(
    BuildContext context,
    Problem problem,
    Set<String> completedIds,
  ) {
    final isDone = completedIds.contains(problem.id);
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.read<SelectionCubit>().selectProblem(problem);
        context.read<DrawingCubit>().loadProblemBoard(problem.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone
                      ? Colors.green
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                  width: 2,
                ),
                color: isDone ? Colors.green : Colors.transparent,
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    problem.title,
                    style: TextStyle(
                      color: isDone
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.4)
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    problem.difficulty.name.toUpperCase(),
                    style: TextStyle(
                      color: _getDifficultyColor(problem.difficulty),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(Difficulty diff) {
    switch (diff) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
    }
  }
}
