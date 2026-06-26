import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:logic_canvas/core/injection.dart';
import 'package:logic_canvas/data/datasources/static_problem_data.dart';
import 'package:logic_canvas/data/services/export_service.dart';
import 'package:logic_canvas/domain/entities/problem.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_cubit.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_state.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/widgets/app_toast.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProblemContext();
  }

  void _loadProblemContext() {
    final drawState = context.read<DrawingCubit>().state;
    final problemId = drawState.boardProblems[drawState.activeBoardId];
    if (problemId == null) return;

    Problem? problem;
    try {
      problem = ProblemData.paretoProblems.firstWhere((p) => p.id == problemId);
    } catch (_) {
      try {
        problem = ProblemData.starterPack.firstWhere((p) => p.id == problemId);
      } catch (_) {}
    }

    if (problem != null) {
      _problemTitle = problem.title;
      _problemDescription = problem.description;
      _problemHints = problem.hints;
      _problemExamples = problem.examples;
    }
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

  Future<String> _buildAskPrompt() async {
    return '''You are an expert LeetCode tutor helping a user learn Data Structures and Algorithms.
${_problemTitle != null ? 'The current problem is: $_problemTitle' : ''}
${_problemDescription != null ? 'Description: $_problemDescription' : ''}

I have provided an image of my whiteboard. Please analyze it carefully.

CRITICAL RULES:
- Use the Socratic Method: NEVER give away the full solution code or the direct answer.
- Always ask leading questions to guide the user to the correct approach.
- Prioritize correctness over sounding confident. If the board/text is unclear, ask one clarifying question and suggest the user tap "Next hint" again after updating the board.
- If the user says your advice is wrong or confusing, acknowledge uncertainty, ask what invariant they are using, and give a smaller next hint instead of doubling down.
- For Longest Repeating Character Replacement / sliding-window with max frequency: the valid-window check is usually windowLength - maxFrequency <= k. Do NOT tell the user to decrease/recompute maxFrequency inside the shrink loop unless explicitly discussing a slower exact variant; a stale non-decreasing maxFrequency is acceptable for the standard O(n) solution.
- EXCEPTION: If the user asks you to read, clean, or rewrite their notes from the board, DO SO IMMEDIATELY. Output EXACTLY AND ONLY the transcribed text formatted beautifully in Markdown. Do NOT add any conversational filler like "Here is the cleaned version" or "Here are your notes". If the board is empty or illegible, say EXACTLY: "Please zoom to the proper section so I can see it clearly."
- If asked for time complexity, explain how to calculate it rather than just giving the answer.
- Keep responses extremely concise (under 150 words).
- OUT OF BOUNDS TOPICS: If the user asks ANY question completely unrelated to Data Structures, Algorithms, LeetCode, programming, or the whiteboard, you MUST refuse to answer and reply with EXACTLY: "I am only your teacher for DSA and LeetCode topics. I cannot assist with other subjects."
- Use Markdown formatting and bullet points for readability. DO NOT use LaTeX math formatting; write comparisons like >= and avoid dollar-delimited math.
- Whenever you write or suggest code snippets, use $_preferredLanguage.
- Be encouraging and supportive.''';
  }

  Future<String> _buildDryRunPrompt() async {
    return '''You are a friendly DSA tutor reviewing a student's whiteboard sketch for a coding problem.

Problem: ${_problemTitle ?? 'Unknown'}
Description: ${_problemDescription ?? 'Not available'}

I have provided an image of my whiteboard. Please analyze the structural elements, logic, diagrams, and text.

Your job is to act as a mock interviewer providing Socratic guidance:
- Analyze their shapes, text, and connections to understand their mental model.
- Do NOT criticize pen coordinates; focus on the logical structures (e.g., nodes, arrays, trees) represented.
- Prioritize correctness over sounding confident. If the board/text is unclear, ask one clarifying question and suggest the user update the board, then ask for the next hint again.
- If their approach looks correct, confirm it and ask them about edge cases or time complexity.
- If it looks flawed or incomplete, ask a guiding question (e.g., "I see you have a tree structure, but how will you keep track of visited nodes?").
- For Longest Repeating Character Replacement / sliding-window with max frequency: do not recommend decreasing/recomputing maxFrequency inside the shrink loop for the standard O(n) approach. The usual invariant is windowLength - maxFrequency <= k, with maxFrequency allowed to be stale/non-decreasing.
- Whenever you write or suggest code snippets, use $_preferredLanguage.
- OUT OF BOUNDS TOPICS: If the user asks ANY question completely unrelated to Data Structures, Algorithms, LeetCode, programming, or the whiteboard, you MUST refuse to answer and reply with EXACTLY: "I am only your teacher for DSA and LeetCode topics. I cannot assist with other subjects."
- Keep it concise, engaging, and under 150 words.
- DO NOT use LaTeX math formatting; write comparisons like >= and avoid dollar-delimited math.''';
  }

  String _buildBoardContext({bool includeProblem = true}) {
    final drawState = context.read<DrawingCubit>().state;
    final strokes = drawState.activeStrokes;
    final counts = <StrokeType, int>{};
    final textNotes = <String>[];

    for (final stroke in strokes) {
      counts[stroke.type] = (counts[stroke.type] ?? 0) + 1;
      final text = stroke.text?.trim();
      if (stroke.type == StrokeType.text && text != null && text.isNotEmpty) {
        textNotes.add(text);
      }
    }

    final typeSummary = counts.entries
        .map((entry) => '${entry.key.name}: ${entry.value}')
        .join(', ');
    final examples = _problemExamples
        .take(2)
        .map((e) {
          final explanation = e.explanation == null
              ? ''
              : ' Explanation: ${e.explanation}';
          return 'Input: ${e.input}; Output: ${e.output}.$explanation';
        })
        .join('\n');

    final boardContext =
        '''
Current board:
- Board id: ${drawState.activeBoardId}
- Stroke count: ${strokes.length}
- Stroke types: ${typeSummary.isEmpty ? 'none' : typeSummary}
- Text notes on board:
${textNotes.isEmpty ? '  none' : textNotes.take(8).map((note) => '  - $note').join('\n')}''';

    if (!includeProblem) return boardContext;

    return '''
$boardContext

Problem context:
- Title: ${_problemTitle ?? 'Unknown'}
- Description: ${_problemDescription ?? 'Not available'}
- Examples:
${examples.isEmpty ? '  none' : examples}
- Built-in hints for reference only:
${_problemHints.isEmpty ? '  none' : _problemHints.take(3).map((hint) => '  - $hint').join('\n')}''';
  }

  Future<String> _buildCoachPrompt(String action) async {
    final boardContext = _buildBoardContext();
    return '''You are Logic Canvas Coach, an on-device LeetCode interviewer.

$boardContext

Coach action: $action

Rules:
- Use the screenshot and board context together.
- Do not give full solution code unless the user explicitly asks for code.
- Prioritize correctness over sounding confident.
- If you are unsure what the user wrote or what invariant they are using, ask one clarifying question and tell them to update the board, then ask for the next hint again.
- If the user's current logic seems wrong, name the exact invariant that fails before suggesting a change.
- For Longest Repeating Character Replacement: do NOT tell the user to update/decrease/recompute maxFrequency inside the shrink loop for the standard O(n) sliding-window solution. The standard check is windowLength - maxFrequency <= k, and maxFrequency can remain stale/non-decreasing.
- Prefer one focused next step over a full explanation.
- If the board is empty, help from the problem statement and say what the user should draw/write next.
- Mention at most one likely issue in the current approach.
- Include a tiny "Try next" task the user can do on the board.
- If discussing complexity, explain the reasoning briefly.
- Use $_preferredLanguage for any tiny snippet or variable names.
- Keep the response under 120 words.
- Use Markdown bullets. Do not use LaTeX.''';
  }

  Future<String> _buildCleanNotesPrompt() async {
    final boardContext = _buildBoardContext(includeProblem: false);
    return '''You are a whiteboard transcription and cleanup tool.

$boardContext

Task: Clean Notes.

STRICT RULES:
- Only rewrite what is visible or explicitly written on the current board.
- Do NOT solve the problem.
- Do NOT add missing algorithm steps, code, hints, edge cases, complexity, or corrections from your own knowledge.
- Do NOT use the problem statement to complete the user's notes.
- If text is unclear, preserve it as "[unclear]" instead of guessing.
- If the board has no readable notes, reply exactly: "Please zoom to the proper section so I can see it clearly."
- Output clean Markdown notes only.
- Do not say "Here are your notes", "Cleaned notes", or any conversational intro.
- Keep the user's intent and wording, but fix spelling, spacing, and formatting.
- Use normal programming symbols like <=, >=, !=. Do not use LaTeX.''';
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
                      'Dry Run',
                    ),
                    _languagePicker(context),
                  ],
                ),
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
                              imageBytes: imageBytes,
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
                          label: const Text('Run Dry Run'),
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

    const startX = 200.0;
    var currentY = 200.0;
    const gap = 20.0;

    final cubit = context.read<DrawingCubit>();
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
      cubit.addStroke(stroke);

      // Increment by the actual rendered height + a gap between paragraphs
      currentY += textPainter.height + gap;
    }

    // Auto-pan to the new text
    context.read<SettingsCubit>().setTransformTransient(
      zoomLevel: 1.0,
      panOffset: const Offset(-100.0, -100.0),
    );
    context.read<SettingsCubit>().persistTransform();

    if (context.mounted) {
      AppToast.show(
        context,
        message: 'Added to board — tap Undo to remove',
        actionLabel: 'Undo',
        onAction: () => cubit.undo(),
        duration: const Duration(seconds: 2), // 2 seconds per user request
      );
    }
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
          imageBytes: imageBytes,
          includeHistory: !isCleanNotes,
        );
        _controller.clear();
      },
    );
  }
}
