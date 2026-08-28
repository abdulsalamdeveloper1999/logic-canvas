import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:logic_canvas/core/injection.dart';
import 'package:logic_canvas/data/algorithms/algorithm_traces.dart';
import 'package:logic_canvas/data/datasources/static_problem_data.dart';
import 'package:logic_canvas/data/services/board_serializer.dart';
import 'package:logic_canvas/data/services/export_service.dart';
import 'package:logic_canvas/presentation/widgets/viz/algorithm_player.dart';
import 'package:logic_canvas/domain/entities/problem.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/domain/entities/viz_scene.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_state.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_cubit.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_state.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';
import 'package:logic_canvas/presentation/widgets/app_toast.dart';
import 'package:logic_canvas/presentation/widgets/upgrade_dialog.dart';

enum AiMode { ask, coach, dryRun }

class AiAssistantPanel extends StatefulWidget {
  final VoidCallback onClose;
  final GestureDragUpdateCallback onPanUpdate;

  const AiAssistantPanel({
    super.key,
    required this.onClose,
    required this.onPanUpdate,
  });

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _lastError;
  AiMode _mode = AiMode.ask;
  String _preferredLanguage = 'Python';
  String? _problemTitle;
  String? _problemDescription;
  List<String> _problemHints = const [];
  List<ProblemExample> _problemExamples = const [];
  List<String> _coachingNotes = const [];
  String? _problemId;
  List<Stroke>? _cachedBoardStrokes;
  BoardDescription? _cachedBoard;

  @override
  void initState() {
    super.initState();
    _loadProblemContext();
  }

  void _loadProblemContext() {
    final drawState = context.read<DrawingCubit>().state;
    final problemId = drawState.boardProblems[drawState.activeBoardId];
    final Problem? problem = ProblemData.findById(problemId);

    if (problem == null) {
      _problemId = null;
      _problemTitle = null;
      _problemDescription = null;
      _problemHints = const [];
      _problemExamples = const [];
      _coachingNotes = const [];
      return;
    }

    _problemId = problem.id;
    _problemTitle = problem.title;
    _problemDescription = problem.description;
    _problemHints = problem.hints;
    _problemExamples = problem.examples;
    _coachingNotes = problem.coachingNotes;
  }

  /// Reads the current board into text. This is the single biggest AI fix:
  /// Ask mode used to send only a screenshot, so a small on-device model was
  /// left guessing at handwriting it could not read — even though the app had
  /// already recognised that handwriting into text.
  BoardDescription _readBoard() {
    final strokes = context.read<DrawingCubit>().state.activeStrokes;

    // The panel rebuilds on every streamed token, and this is now read during
    // build for the unread-board banner. The cubit hands out a new list on
    // every board change, so list identity is an exact invalidation signal.
    final cached = _cachedBoard;
    if (cached != null && identical(strokes, _cachedBoardStrokes)) {
      return cached;
    }

    final described = BoardSerializer.describe(strokes);
    _cachedBoardStrokes = strokes;
    _cachedBoard = described;
    return described;
  }

  /// Problem statement, examples and any per-problem corrections. Kept out of
  /// the system prompt's rule list so the rules stay short.
  String _problemBlock() {
    if (_problemTitle == null) {
      return 'No LeetCode problem is attached to this board.';
    }

    final buffer = StringBuffer()
      ..writeln('PROBLEM: $_problemTitle')
      ..writeln(_problemDescription ?? '');

    if (_problemExamples.isNotEmpty) {
      buffer.writeln('Examples:');
      for (final e in _problemExamples.take(2)) {
        buffer.writeln(
          '  Input: ${e.input} → Output: ${e.output}'
          '${e.explanation == null ? '' : ' (${e.explanation})'}',
        );
      }
    }

    if (_problemHints.isNotEmpty) {
      buffer.writeln('Nudges you may draw one hint from, never all at once:');
      for (final hint in _problemHints.take(3)) {
        buffer.writeln('  - $hint');
      }
    }

    if (_coachingNotes.isNotEmpty) {
      buffer.writeln('Facts you must not contradict for this problem:');
      for (final note in _coachingNotes) {
        buffer.writeln('  - $note');
      }
    }

    return buffer.toString().trimRight();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildChatMessage(BuildContext context, UiChatMessage msg) {
    if (msg.isUser) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              16,
            ).copyWith(bottomRight: const Radius.circular(4)),
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 14,
            ),
          ),
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(
                12,
              ).copyWith(bottomLeft: const Radius.circular(4)),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: MarkdownBody(
              data: msg.text,
              selectable: true,
              extensionSet: md.ExtensionSet.gitHubFlavored,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  height: 1.6,
                ),
                code: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                ),
                codeblockDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                h3: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _writeResponseToBoard(msg.text),
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Write to Board', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Shared preamble for every mode. Short on purpose — the previous prompts
  /// carried fifteen-plus rules each, including a hardcoded note about one
  /// specific problem, and small models follow five rules far better.
  String _basePrompt(String role) {
    return '''$role

${_problemBlock()}

${_readBoard().text}

Rules:
- Answer only about the board and the problem above. For anything else reply exactly: "I am only your teacher for DSA and LeetCode topics. I cannot assist with other subjects."
- The board transcription above is authoritative. If it does not contain what you need, say so and ask one clarifying question instead of guessing from the image.
- Use $_preferredLanguage for any code.
- Plain Markdown, no LaTeX. Write >= and <= directly.''';
  }

  Future<String> _buildAskPrompt() async {
    return _basePrompt('''You are a LeetCode tutor.

Guide with questions; do not hand over the full solution unless asked outright.
Keep it under 150 words.''');
  }

  Future<String> _buildDryRunPrompt() async {
    return _basePrompt(
      '''You are a mock interviewer reviewing the student's whiteboard.

Judge the logic, not the handwriting. If the approach works, confirm it and ask about an edge case or the complexity. If it is flawed, name the exact step that breaks before suggesting anything.
Keep it under 150 words.''',
    );
  }

  Future<String> _buildCoachPrompt(String action) async {
    return _basePrompt('''You are a LeetCode coach giving one focused next step.

Requested: $action

Give at most one issue and one small "Try next" task the student can do on the board. If the board is empty, say what to draw first.
Keep it under 120 words.''');
  }

  /// Transcription only. Given the board text, this no longer depends on the
  /// model reading handwriting out of an image.
  Future<String> _buildCleanNotesPrompt() async {
    final board = _readBoard();
    return '''You are a transcription tool. You do not solve problems.

${board.text}

Rules:
- Rewrite ONLY what is transcribed above, fixing spelling, spacing and formatting.
- Add nothing: no algorithm steps, no code, no hints, no complexity, no corrections.
- Keep anything unclear as "[unclear]".
- If there are no readable notes, reply exactly: "There is nothing readable on this board yet. Turn on handwriting recognition in the toolbar, or type your notes, so I can read them."
- Output the cleaned Markdown notes only, with no introduction.''';
  }

  Future<Uint8List?> _captureCanvas() async {
    try {
      final exportService = getIt<ExportService>();
      final imageBytes = await exportService.screenshotController.capture();
      return imageBytes;
    } catch (e) {
      debugPrint('Error capturing canvas screenshot: $e');
      return null;
    }
  }

  Future<void> _runDryRun() async {
    final prompt = await _buildDryRunPrompt();
    final imageBytes = await _captureCanvas();
    if (!mounted) return;
    context.read<GemmaCubit>().generateAiResponse(
      systemPrompt: prompt,
      userMessage: 'Please review my whiteboard progress on this problem.',
      imageBytes: imageBytes,
    );
  }

  Future<void> _runCoachAction(String action) async {
    final prompt = await _buildCoachPrompt(action);
    final imageBytes = await _captureCanvas();
    if (!mounted) return;
    context.read<GemmaCubit>().generateAiResponse(
      systemPrompt: prompt,
      userMessage: action,
      imageBytes: imageBytes,
    );
  }

  bool _isCleanNotesRequest(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('clean note') ||
        normalized.contains('clean my note') ||
        normalized.contains('rewrite note') ||
        normalized.contains('read my board') ||
        normalized.contains('transcribe');
  }

  @override
  Widget build(BuildContext context) {
    // Switching boards switches problems. The panel used to read the problem
    // once in initState and never again, so it kept coaching the old one — and
    // the model's own history carried that conversation across with it.
    return BlocListener<DrawingCubit, DrawingState>(
      listenWhen: (prev, curr) => prev.activeBoardId != curr.activeBoardId,
      listener: (context, _) {
        setState(_loadProblemContext);
        context.read<GemmaCubit>().resetConversationContext();
      },
      child: _buildPanel(context),
    );
  }

  Widget _buildPanel(BuildContext context) {
    return BlocConsumer<GemmaCubit, GemmaState>(
      listenWhen: (prev, curr) =>
          prev.aiThinking != curr.aiThinking ||
          prev.aiResponse != curr.aiResponse ||
          prev.chatHistory.length != curr.chatHistory.length ||
          prev.aiError != curr.aiError,
      listener: (context, state) {
        if (state.aiError != null && _lastError != state.aiError) {
          _lastError = state.aiError;
          AppToast.show(
            context,
            message: state.aiError!,
            duration: const Duration(seconds: 4),
          );
        } else if (state.aiError == null) {
          _lastError = null;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      },
      buildWhen: (prev, curr) =>
          prev.aiLoading != curr.aiLoading ||
          prev.aiThinking != curr.aiThinking ||
          prev.aiResponse != curr.aiResponse ||
          prev.aiError != curr.aiError ||
          prev.chatHistory != curr.chatHistory,
      builder: (context, state) {
        return Container(
          width: 380,
          height: 600,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Drag Handle
              GestureDetector(
                onPanUpdate: widget.onPanUpdate,
                child: Container(
                  color:
                      Colors.transparent, // Ensures the whole area is draggable
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (!state.aiLoading &&
                          (state.chatHistory.isNotEmpty ||
                              state.aiResponse != null ||
                              state.aiThinking != null))
                        IconButton(
                          tooltip: 'Clear chat',
                          icon: const Icon(
                            Icons.delete_sweep_rounded,
                            size: 20,
                          ),
                          onPressed: () =>
                              context.read<GemmaCubit>().clearAiResponse(),
                        ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 12),

              // Mode toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _modeChip(AiMode.ask, Icons.chat_rounded, 'Ask'),
                    _modeChip(
                      AiMode.coach,
                      Icons.psychology_alt_rounded,
                      'Coach',
                    ),
                    _modeChip(
                      AiMode.dryRun,
                      Icons.rate_review_rounded,
                      'Review',
                    ),
                    _languagePicker(context),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildVisionRow(context),
              ),
              const SizedBox(height: 12),

              // Content area (Scrollable)
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.chatHistory.isEmpty &&
                          (_mode == AiMode.ask || _mode == AiMode.coach) &&
                          !state.aiLoading &&
                          state.aiResponse == null &&
                          state.aiThinking == null) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _mode == AiMode.coach
                                    ? 'Get a focused next step for this board.'
                                    : 'Ask me anything about your whiteboard!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (_problemTitle != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _problemTitle!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      Builder(
                        builder: (context) {
                          final board = _readBoard();
                          final handwritingOn =
                              context.select(
                                (SettingsCubit c) =>
                                    c.state.enableHandwritingRecognition,
                              ) &&
                              context.select(
                                (EntitlementsCubit c) => c.state.isSubscribed,
                              );
                          if (!board.isUnrecognised || handwritingOn) {
                            return const SizedBox.shrink();
                          }
                          return _buildUnreadBoardBanner(
                            context,
                            board.freehandCount,
                          );
                        },
                      ),

                      if (_mode == AiMode.dryRun && !state.aiLoading)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.teal.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.rate_review_rounded,
                                size: 18,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Reviews your whiteboard — checks if your approach is correct and suggests fixes.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.teal.shade700,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_mode == AiMode.coach && !state.aiLoading)
                        _buildCoachActions(context),

                      if (state.chatHistory.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: state.chatHistory
                              .map((msg) => _buildChatMessage(context, msg))
                              .toList(),
                        ),

                      if (state.aiLoading)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                              Text(
                                switch (_mode) {
                                  AiMode.coach => 'Coaching your next step...',
                                  AiMode.dryRun =>
                                    'Reviewing your whiteboard...',
                                  AiMode.ask => 'Generating...',
                                },
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (state.aiThinking != null &&
                          state.aiThinking!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.psychology_rounded,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    state.aiLoading
                                        ? 'AI is thinking...'
                                        : 'AI thought process',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              children: [
                                MarkdownBody(
                                  data: state.aiThinking!,
                                  extensionSet: md.ExtensionSet.gitHubFlavored,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      height: 1.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (state.aiResponse != null &&
                          state.aiResponse!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                ),
                              ),
                              child: MarkdownBody(
                                data: state.aiResponse!,
                                selectable: true,
                                extensionSet: md.ExtensionSet.gitHubFlavored,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                  code: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontSize: 12,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                  ),
                                  codeblockDecoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  h3: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  listBullet: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _writeResponseToBoard(state.aiResponse!),
                              icon: const Icon(
                                Icons.edit_note_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Write to Board',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (state.aiError != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            state.aiError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      if (_mode == AiMode.ask && !state.aiLoading) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _quickActionChip(
                              '⏱️ Complexity',
                              'What is the time and space complexity of the optimal solution?',
                            ),
                            _quickActionChip(
                              '⚠️ Edge Cases',
                              'What are some tricky edge cases I should consider for this problem?',
                            ),
                            _quickActionChip(
                              '💡 Optimal',
                              'Can you give me a hint towards the most optimal approach?',
                            ),
                            _quickActionChip(
                              '🐛 Find Bugs',
                              'What are common bugs or pitfalls when solving this?',
                            ),
                            _quickActionChip(
                              '🧹 Clean Notes',
                              'Read my messy whiteboard and rewrite it into clean, structured notes.',
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(
                        height: 24,
                      ), // Give some bottom padding so scrolling feels natural
                    ],
                  ),
                ),
              ),

              if (_mode == AiMode.ask)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: TextField(
                    controller: _controller,
                    maxLines: 2,
                    enabled: !state.aiLoading,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: _problemTitle != null
                          ? 'Ask about $_problemTitle...'
                          : 'Ask about this problem...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, child) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _controller.clear();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onClose,
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    if (!state.aiLoading)
                      switch (_mode) {
                        AiMode.ask => FilledButton.icon(
                          onPressed: () async {
                            final text = _controller.text.trim();
                            if (text.isEmpty) return;
                            final gemmaCubit = context.read<GemmaCubit>();
                            final isCleanNotes = _isCleanNotesRequest(text);
                            final prompt = isCleanNotes
                                ? await _buildCleanNotesPrompt()
                                : await _buildAskPrompt();
                            final imageBytes = await _captureCanvas();
                            if (!mounted) return;
                            gemmaCubit.generateAiResponse(
                              systemPrompt: prompt,
                              userMessage: isCleanNotes
                                  ? 'Clean only the current board notes. Do not solve or add new information.'
                                  : text,
                              imageBytes: isCleanNotes ? null : imageBytes,
                              includeHistory: !isCleanNotes,
                            );
                            _controller.clear();
                          },
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                          ),
                          label: const Text('Generate'),
                        ),
                        AiMode.coach => FilledButton.icon(
                          onPressed: () => _runCoachAction(
                            'Give me one Socratic next hint based on my current board.',
                          ),
                          icon: const Icon(
                            Icons.psychology_alt_rounded,
                            size: 16,
                          ),
                          label: const Text('Next Hint'),
                        ),
                        AiMode.dryRun => FilledButton.icon(
                          onPressed: _runDryRun,
                          icon: const Icon(Icons.rate_review_rounded, size: 16),
                          label: const Text('Review my board'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                        ),
                      },
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _writeResponseToBoard(String text) {
    var clean = text
        // Remove common conversational fillers at the start of the response
        .replaceAll(
          RegExp(
            r'^(Here is|Here are|Certainly|Sure|I can|Okay|Based on the image|The image contains).*?:?\s*\n+',
            caseSensitive: false,
          ),
          '',
        )
        // Sanitize LaTeX math formats
        .replaceAllMapped(
          RegExp(r'\$([^\$]+)\$'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll(r'\ge', '>=')
        .replaceAll(r'\le', '<=')
        .replaceAll(r'\neq', '!=')
        // Remove code block markers but keep the content!
        .replaceAllMapped(
          RegExp(r'```[a-zA-Z]*\s*\n([\s\S]*?)```'),
          (match) => match.group(1) ?? '',
        )
        // Remove inline code markers but keep content
        .replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1) ?? '')
        // Remove headers
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        // Remove bold
        .replaceAllMapped(
          RegExp(r'\*\*(.+?)\*\*'),
          (match) => match.group(1) ?? '',
        )
        // Remove italic
        .replaceAllMapped(RegExp(r'\*(.+?)\*'), (match) => match.group(1) ?? '')
        // Remove strikethrough
        .replaceAllMapped(RegExp(r'~~(.+?)~~'), (match) => match.group(1) ?? '')
        // Remove links, keep text
        .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\([^)]+\)'),
          (match) => match.group(1) ?? '',
        )
        // Remove images
        .replaceAllMapped(
          RegExp(r'!\[([^\]]*)\]\([^)]+\)'),
          (match) => match.group(1) ?? '',
        )
        // Remove blockquote markers
        .replaceAll(RegExp(r'^>\s?', multiLine: true), '')
        // Remove horizontal rules
        .replaceAll(RegExp(r'^[-*_]{3,}\s*$', multiLine: true), '')
        // Remove list markers (-, *, 1.)
        .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '• ')
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '')
        .trim();

    final paragraphs = clean
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (paragraphs.isEmpty) return;

    const gap = 20.0;

    final cubit = context.read<DrawingCubit>();

    // Below whatever is already on the board. This used to be a fixed
    // (200,200), so a second answer was written straight on top of the first.
    final existing = cubit.activeStrokes.where(
      (s) => !s.isEraser && s.points.isNotEmpty,
    );
    var startX = 200.0;
    var currentY = 200.0;
    if (existing.isNotEmpty) {
      var left = double.infinity;
      var bottom = double.negativeInfinity;
      for (final stroke in existing) {
        final bounds = BoardSerializer.boundsOf(stroke);
        left = math.min(left, bounds.left);
        bottom = math.max(bottom, bounds.bottom);
      }
      startX = left;
      currentY = bottom + 60;
    }
    final firstLine = Offset(startX, currentY);

    final written = <Stroke>[];
    for (final para in paragraphs) {
      final textSpan = TextSpan(
        text: para.trim(),
        style: const TextStyle(
          fontSize:
              28.0, // Matches _autoFormattedTextFontSize in WhiteboardPainter
          fontWeight: FontWeight.w500,
          fontFamily: 'Noteworthy',
          fontFamilyFallback: [
            'Chalkboard SE',
            'Marker Felt',
            'Apple SD Gothic Neo',
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      // Calculate max width similarly to how WhiteboardPainter does it
      textPainter.layout(maxWidth: 600.0);

      final stroke = Stroke(
        points: [Offset(startX, currentY)],
        color:
            cubit.state.boards[cubit.state.activeBoardId]?.lastOrNull?.color ??
            Colors.white,
        strokeWidth: 2.0,
        type: StrokeType.text,
        text: para.trim(),
      );
      written.add(stroke);

      // Increment by the actual rendered height + a gap between paragraphs
      currentY += textPainter.height + gap;
    }

    // One action, so one undo takes the whole answer back off the board.
    cubit.addStrokes(written);

    // Scroll the answer into view without touching the zoom the user chose —
    // this used to snap every write back to 100% at a hardcoded offset.
    final settingsCubit = context.read<SettingsCubit>();
    final zoom = settingsCubit.state.zoomLevel;
    settingsCubit.setTransformTransient(
      zoomLevel: zoom,
      panOffset: const Offset(120, 160) - firstLine * zoom,
    );
    settingsCubit.persistTransform();

    if (context.mounted) {
      final count = written.length;
      AppToast.show(
        context,
        message: count == 1
            ? 'Added to board — tap Undo to remove'
            : 'Added $count blocks to the board — Undo removes all of them',
        actionLabel: 'Undo',
        onAction: () => cubit.undo(),
        duration: const Duration(seconds: 2), // 2 seconds per user request
      );
    }
  }

  /// Tells the user what the AI will actually be able to read from the board,
  /// before they ask. When nothing was recognised, this is the difference
  /// between "the AI is stupid" and "turn on handwriting recognition".
  Widget _buildVisionRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trace = _problemId == null
        ? null
        : AlgorithmTraces.forProblem(_problemId!);

    return BlocBuilder<DrawingCubit, DrawingState>(
      buildWhen: (prev, curr) =>
          !identical(prev.boards, curr.boards) ||
          prev.activeBoardId != curr.activeBoardId,
      builder: (context, drawState) {
        final seen = BoardSerializer.describe(drawState.activeStrokes);
        final warn = seen.isEmpty || seen.isUnrecognised;
        final color = warn ? const Color(0xFFE0A11B) : scheme.primary;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Tooltip(
              message: seen.isEmpty
                  ? 'Nothing on this board yet.'
                  : seen.isUnrecognised
                  ? 'Your drawing has not been recognised as text or shapes, '
                        'so the AI is working from the picture alone. Turn on '
                        'handwriting recognition in the toolbar for much '
                        'better answers.'
                  : 'The AI reads these directly, not just from a screenshot.',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      warn
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 13,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI sees: ${seen.chipLabel}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (trace != null)
              ActionChip(
                avatar: const Icon(Icons.play_circle_outline_rounded, size: 16),
                label: const Text(
                  'Watch it step by step',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                onPressed: () => AlgorithmPlayerPage.open(
                  context,
                  trace,
                  onCopyToBoard: _writeTraceToBoard,
                ),
              ),
          ],
        );
      },
    );
  }

  /// Drops the pattern's key idea onto the board as notes the student can
  /// build on, rather than making them retype it.
  void _writeTraceToBoard(AlgorithmTrace trace) {
    final navigator = Navigator.of(context);
    _writeResponseToBoard(
      '${trace.title} — ${trace.pattern}\n\n'
      '${trace.patternIdea}\n\n'
      '${trace.pseudocode.join('\n')}\n\n'
      'Time: ${trace.timeComplexity}\n'
      'Space: ${trace.spaceComplexity}\n\n'
      'Remember: ${trace.takeaway}',
    );
    if (navigator.canPop()) navigator.pop();
  }

  /// Shown when the board has ink on it that nothing recognised.
  ///
  /// Handwriting recognition ships off, and the prompts tell the model the
  /// transcription is authoritative and not to guess from the picture. So the
  /// default path — draw with the pencil, ask a question — was the model
  /// politely refusing every time. Offer the switch instead of leaving the
  /// user to find it in the toolbar.
  Widget _buildUnreadBoardBanner(BuildContext context, int sketchCount) {
    final isSubscribed = context.select(
      (EntitlementsCubit c) => c.state.isSubscribed,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_off_rounded,
                size: 18,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "I can see $sketchCount ${sketchCount == 1 ? "sketch" : "sketches"} "
                  "but none of it has been turned into text yet, so I can only "
                  "guess at what it says.",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () {
                  if (!isSubscribed) {
                    UpgradeDialog.show(context);
                    return;
                  }
                  context.read<SettingsCubit>().toggleHandwritingRecognition();
                  AppToast.show(
                    context,
                    message:
                        'Handwriting recognition is on. Write your next note '
                        'and I will be able to read it.',
                    duration: const Duration(seconds: 3),
                  );
                },
                icon: const Icon(Icons.text_fields_rounded, size: 16),
                label: Text(
                  isSubscribed
                      ? 'Turn on Paint to Text'
                      : 'Unlock Paint to Text',
                  style: const TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'It reads what you write from here on — anything already on the '
            'board stays a sketch.',
            style: TextStyle(
              fontSize: 11,
              height: 1.3,
              color: Colors.orange.shade800.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachActions(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_alt_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Local Coach',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Uses the current board screenshot, problem, and written notes.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _coachActionButton(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Next hint',
                action:
                    'Give me one Socratic next hint based on my current board.',
              ),
              _coachActionButton(
                icon: Icons.fact_check_rounded,
                label: 'Check approach',
                action:
                    'Check whether my current approach and invariant are correct. If unclear, ask one clarifying question instead of guessing.',
              ),
              _coachActionButton(
                icon: Icons.warning_amber_rounded,
                label: 'Edge cases',
                action:
                    'Give me the top edge cases I should test for this problem and my current approach.',
              ),
              _coachActionButton(
                icon: Icons.speed_rounded,
                label: 'Complexity',
                action:
                    'Help me reason about time and space complexity from my current approach.',
              ),
              _coachActionButton(
                icon: Icons.account_tree_rounded,
                label: 'Make plan',
                action:
                    'Turn my current board into a concise implementation plan without full code.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coachActionButton({
    required IconData icon,
    required String label,
    required String action,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _runCoachAction(action),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _modeChip(AiMode mode, IconData icon, String label) {
    final isSelected = _mode == mode;
    final gemmaState = context.read<GemmaCubit>().state;
    return GestureDetector(
      onTap: () {
        if (gemmaState.aiLoading) return;
        setState(() => _mode = mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (mode == AiMode.dryRun
                    ? Colors.teal.withValues(alpha: 0.15)
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (mode == AiMode.dryRun
                      ? Colors.teal.withValues(alpha: 0.4)
                      : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.4))
                : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (mode == AiMode.dryRun
                        ? Colors.teal
                        : Theme.of(context).colorScheme.primary)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (mode == AiMode.dryRun
                          ? Colors.teal
                          : Theme.of(context).colorScheme.primary)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languagePicker(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _preferredLanguage,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          items: ['Python', 'Dart', 'Java', 'C++', 'JS / TS'].map((lang) {
            return DropdownMenuItem(value: lang, child: Text(lang));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _preferredLanguage = val);
            }
          },
        ),
      ),
    );
  }

  Widget _quickActionChip(String label, String prompt) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      side: BorderSide(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
      ),
      onPressed: () async {
        _controller.text = prompt;
        final isCleanNotes = label == '🧹 Clean Notes';
        final sysPrompt = isCleanNotes
            ? await _buildCleanNotesPrompt()
            : await _buildAskPrompt();
        final finalPrompt = isCleanNotes
            ? 'Clean only the current board notes. Do not solve or add new information.'
            : prompt;

        final imageBytes = await _captureCanvas();
        if (!mounted) return;
        context.read<GemmaCubit>().generateAiResponse(
          systemPrompt: sysPrompt,
          userMessage: finalPrompt,
          imageBytes: isCleanNotes ? null : imageBytes,
          includeHistory: !isCleanNotes,
        );
        _controller.clear();
      },
    );
  }
}
