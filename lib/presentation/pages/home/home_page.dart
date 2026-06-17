import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_state.dart';
import 'package:logic_canvas/presentation/widgets/ai_hint_dialog.dart';
import 'package:logic_canvas/presentation/widgets/app_toast.dart';
import 'package:logic_canvas/presentation/widgets/board_panel.dart';
import 'package:logic_canvas/presentation/widgets/whiteboard_view.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_state.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:logic_canvas/presentation/widgets/icon_picker_sheet.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';
import 'package:logic_canvas/core/injection.dart';
import 'package:logic_canvas/data/services/export_service.dart';
import 'package:logic_canvas/presentation/widgets/upgrade_dialog.dart';
import 'package:logic_canvas/data/datasources/static_problem_data.dart';
import 'package:logic_canvas/domain/entities/problem.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_cubit.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_state.dart';

void _llmLog(String message) {
  debugPrintSynchronously(message);
  developer.log(message, name: 'LogicCanvasLLM');
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isDescriptionExpanded = true;
  bool _isAiPanelOpen = false;
  Offset _aiPanelPosition = const Offset(20, 90);

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final sidebarWidth = orientation == Orientation.landscape ? 350.0 : 280.0;
    final isSubscribed = context.select(
      (EntitlementsCubit c) => c.state.isSubscribed,
    );

    return Scaffold(
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return Stack(
            children: [
              Positioned.fill(child: const WhiteboardView()),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(context, isSubscribed),
              ),

              _buildSidebar(context, settings, sidebarWidth),

              _buildComprehensiveToolbar(context, settings, orientation),

              Positioned(
                top: 90,
                right: 20,
                child: _buildProblemDescriptionPanel(context),
              ),

              if (_isAiPanelOpen)
                Positioned(
                  left: _aiPanelPosition.dx,
                  top: _aiPanelPosition.dy,
                  child: AiAssistantPanel(
                    onClose: () => setState(() => _isAiPanelOpen = false),
                    onPanUpdate: (details) {
                      setState(() {
                        _aiPanelPosition += details.delta;
                      });
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProblemDescriptionPanel(BuildContext context) {
    return BlocBuilder<DrawingCubit, DrawingState>(
      builder: (context, state) {
        final problemId = state.boardProblems[state.activeBoardId];
        if (problemId == null) return const SizedBox.shrink();

        final problem = ProblemData.paretoProblems.firstWhere(
          (p) => p.id == problemId,
          orElse: () =>
              ProblemData.starterPack.firstWhere((p) => p.id == problemId),
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutQuart,
          width: _isDescriptionExpanded ? 320 : 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => setState(
                  () => _isDescriptionExpanded = !_isDescriptionExpanded,
                ),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isDescriptionExpanded
                        ? Icons.close_rounded
                        : Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              if (_isDescriptionExpanded) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(
                                      problem.difficulty,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    problem.difficulty.name.toUpperCase(),
                                    style: TextStyle(
                                      color: _getDifficultyColor(
                                        problem.difficulty,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  problem.category,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              problem.title,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              problem.description ??
                                  'No description available.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            if (problem.examples.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                "EXAMPLES",
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...problem.examples.map(
                                (ex) => _buildExampleItem(ex),
                              ),
                            ],
                            if (problem.hints.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                "HINTS",
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...problem.hints.asMap().entries.map(
                                (entry) =>
                                    _buildHintItem(entry.key + 1, entry.value),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildExampleItem(ProblemExample ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExampleRow("Input", ex.input),
          const SizedBox(height: 8),
          _buildExampleRow("Output", ex.output),
          if (ex.explanation != null) ...[
            const SizedBox(height: 8),
            _buildExampleRow("Explanation", ex.explanation!),
          ],
        ],
      ),
    );
  }

  Widget _buildExampleRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            "$label:",
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 11,
              fontFamily: 'Courier',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHintItem(int index, String hint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "H$index",
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.greenAccent;
      case Difficulty.medium:
        return Colors.orangeAccent;
      case Difficulty.hard:
        return Colors.redAccent;
    }
  }

  Widget _buildComprehensiveToolbar(
    BuildContext context,
    SettingsState settings,
    Orientation orientation,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Intelligence & View Row (Upper Row)
              _buildIntelligenceRow(context, settings),
              const SizedBox(height: 8),

              // Icon Picker Trigger (Contextual)
              if (settings.toolMode == ToolMode.diagram)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSelectedIconPreview(context, settings),
                ),

              // Main Drawing & Styling Bar (Lower Row)
              _buildMainIntegratedBar(context, settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntelligenceRow(BuildContext context, SettingsState settings) {
    final isSubscribed = context.select(
      (EntitlementsCubit c) => c.state.isSubscribed,
    );
    // final selectedProblem = null; // We are moving away from problem-locked boards
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI Intelligence
              _smallToggleButton(
                context,
                Icons.draw_rounded,
                () => isSubscribed
                    ? context.read<SettingsCubit>().toggleShapeDetection()
                    : UpgradeDialog.show(context),
                isSubscribed && settings.enableShapeDetection,
                tooltip: "Shape Detector",
              ),
              _smallToggleButton(
                context,
                Icons.text_fields_rounded,
                () => isSubscribed
                    ? context
                          .read<SettingsCubit>()
                          .toggleHandwritingRecognition()
                    : UpgradeDialog.show(context),
                isSubscribed && settings.enableHandwritingRecognition,
                tooltip: "Paint to Text (Handwriting)",
              ),

              _divider(),

              // Zoom Controls
              _smallIconButton(
                context,
                Icons.zoom_out_rounded,
                () => context.read<SettingsCubit>().setZoom(
                  settings.zoomLevel - 0.2,
                ),
                tooltip: "Zoom Out",
              ),
              _smallIconButton(
                context,
                Icons.zoom_in_rounded,
                () => context.read<SettingsCubit>().setZoom(
                  settings.zoomLevel + 0.2,
                ),
                tooltip: "Zoom In",
              ),
              _smallIconButton(
                context,
                Icons.center_focus_strong_outlined,
                () => context.read<SettingsCubit>().resetTransform(),
                color:
                    (settings.panOffset != Offset.zero ||
                        settings.zoomLevel != 1.0)
                    ? Colors.blueAccent
                    : null,
                tooltip: "Reset View",
              ),

              _divider(),

              // Global Actions
              _smallIconButton(
                context,
                Icons.delete_sweep_rounded,
                () => _confirmClearBoard(context),
                color: Colors.redAccent.withValues(alpha: 0.8),
                tooltip: "Clear Board",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearBoard(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Clear board'),
        content: const Text(
          'Are you sure you want to clear the board?\n\n'
          'This will remove all strokes and icons from the current board.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (shouldClear == true && context.mounted) {
      HapticFeedback.heavyImpact();
      context.read<DrawingCubit>().clear(); // Fixed method call
    }
  }

  void _showAiDialog(BuildContext context) {
    final gemmaState = context.read<GemmaCubit>().state;
    _llmLog(
      '🧠 HomePage._showAiDialog: status=${gemmaState.status}, '
      'aiLoading=${gemmaState.aiLoading}, hasError=${gemmaState.aiError != null}',
    );
    if (gemmaState.status != GemmaStatus.ready) {
      _llmLog('🧠 HomePage._showAiDialog: blocked because model is not ready');
      AppToast.show(
        context,
        message: 'AI model not downloaded. Go to Settings → AI Model to download.',
        actionLabel: 'Settings',
        onAction: () {
          context.read<SettingsCubit>().toggleSidebar();
        },
      );
      return;
    }

    _llmLog('🧠 HomePage._showAiDialog: toggling AiAssistantPanel');
    setState(() {
      _isAiPanelOpen = !_isAiPanelOpen;
    });
  }

  Widget _buildMainIntegratedBar(BuildContext context, SettingsState settings) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.shadow.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Core Tools
              _toolbarButton(
                context,
                Icons.edit_rounded,
                () => context.read<SettingsCubit>().setToolMode(ToolMode.pen),
                settings.toolMode == ToolMode.pen,
                tooltip: "Pen",
              ),
              _toolbarButton(
                context,
                Icons.pan_tool_rounded,
                () => context.read<SettingsCubit>().setToolMode(ToolMode.hand),
                settings.toolMode == ToolMode.hand,
                tooltip: "Hand (Pan)",
              ),
              _toolbarButton(
                context,
                Icons.device_hub_rounded,
                () => context.read<SettingsCubit>().setToolMode(
                  ToolMode.connector,
                ),
                settings.toolMode == ToolMode.connector,
                tooltip: "Connector",
              ),
              _toolbarButton(
                context,
                Icons.category_rounded,
                () =>
                    context.read<SettingsCubit>().setToolMode(ToolMode.diagram),
                settings.toolMode == ToolMode.diagram,
                tooltip: "Diagram Icons",
              ),
              _toolbarButton(
                context,
                Icons.auto_fix_high_rounded,
                () =>
                    context.read<SettingsCubit>().setToolMode(ToolMode.eraser),
                settings.toolMode == ToolMode.eraser,
                tooltip: "Eraser",
              ),

              _divider(),

              _buildToolSpecificControls(context, settings),

              // Styled Preview (Empty space or divider could go here)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedIconPreview(
    BuildContext context,
    SettingsState settings,
  ) {
    final iconPath = settings.selectedIconPath;
    return GestureDetector(
      onTap: () => _showIconPicker(context, settings),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reduce preview icon size (~1.2x smaller).
                if (iconPath != null)
                  SvgPicture.asset(iconPath, width: 20, height: 20)
                else
                  const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                const SizedBox(width: 8),
                Text(
                  iconPath
                          ?.split('/')
                          .last
                          .split('.')
                          .first
                          .replaceAll('-', ' ')
                          .toUpperCase() ??
                      "SEARCH CLOUD ICONS",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueAccent,
                    letterSpacing: 1.0,
                  ),
                ),
                const Icon(
                  Icons.arrow_right_rounded,
                  size: 20,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIconPicker(BuildContext context, SettingsState settings) {
    final isSubscribed = context.read<EntitlementsCubit>().state.isSubscribed;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Asset Library',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        final size = MediaQuery.of(context).size;
        return Material(
          color: Colors.transparent,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: size.height * 0.8,
                ),
                child: IconPickerSheet(
                  isSubscribed: isSubscribed,
                  selectedIconPath: settings.selectedIconPath,
                  onIconSelected: (path) {
                    context.read<SettingsCubit>().setSelectedIconPath(path);
                  },
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    SettingsState settings,
    double width,
  ) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart,
      left: settings.showSidebar ? 0 : -width,
      top: 0,
      bottom: 0,
      width: width + 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: width,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.9),
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: const BoardPanel(),
                ),
              ),
            ),
          ),
          Positioned(
            left: width + 10,
            top: 100,
            child: GestureDetector(
              onTap: () => context.read<SettingsCubit>().toggleSidebar(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  settings.showSidebar
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isSubscribed) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Text(
                  "LogicCanvas",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withValues(alpha: 0.2),
                        Colors.blueAccent.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Text(
                    "PREMIUM",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                // History (Undo/Redo)
                _topBarIconButton(
                  context,
                  Icons.undo_rounded,
                  () => context.read<DrawingCubit>().undo(),
                  tooltip: "Undo",
                ),
                const SizedBox(width: 4),
                _topBarIconButton(
                  context,
                  Icons.redo_rounded,
                  () => context.read<DrawingCubit>().redo(),
                  tooltip: "Redo",
                ),
                const SizedBox(width: 8),
                _topBarIconButton(
                  context,
                  Icons.auto_awesome_rounded,
                  () => _showAiDialog(context),
                  color: Colors.blueAccent.withValues(alpha: 0.9),
                  tooltip: "AI Assistant",
                ),
                const SizedBox(width: 16),

                // Export Button
                _buildExportButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBarIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback? onPressed, {
    String? tooltip,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        icon: Icon(
          icon,
          color:
              color ??
              (onPressed == null
                  ? Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8)),
          size: 22,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
        hoverColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context) {
    final exportService = getIt<ExportService>();
    final activeBoardId = context.read<DrawingCubit>().state.activeBoardId;

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'png') {
          await exportService.exportToPng(activeBoardId);
        } else if (value == 'pdf') {
          await exportService.exportToPdf(activeBoardId);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.ios_share_rounded,
              size: 18,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            SizedBox(width: 10),
            Text(
              "EXPORT",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'png',
          child: Row(
            children: [
              Icon(Icons.image_rounded, color: Colors.blueAccent),
              SizedBox(width: 12),
              Text('Export as PNG'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: Colors.orangeAccent),
              SizedBox(width: 12),
              Text('Export as PDF'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorButton(BuildContext context, Color currentColor) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: const Text('Brush Color'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: currentColor,
                onColorChanged: (color) =>
                    context.read<SettingsCubit>().setStrokeColor(color),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Done'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: currentColor.withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidthSlider(
    BuildContext context,
    double currentWidth, {
    double minWidth = 1.0,
    double maxWidth = 50.0,
  }) {
    final safeWidth = currentWidth.clamp(minWidth, maxWidth);
    return SizedBox(
      width: 80,
      child: Slider(
        value: safeWidth,
        min: minWidth,
        max: maxWidth,
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.1),
        onChanged: (value) =>
            context.read<SettingsCubit>().setStrokeWidth(value),
      ),
    );
  }

  Widget _buildToolSpecificControls(
    BuildContext context,
    SettingsState settings,
  ) {
    if (settings.isEraser) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _presetButton(
            context,
            Icons.circle,
            20.0,
            settings.strokeWidth,
            "Small Eraser",
          ),
          _presetButton(
            context,
            Icons.circle,
            40.0,
            settings.strokeWidth,
            "Medium Eraser",
          ),
          _presetButton(
            context,
            Icons.circle,
            60.0,
            settings.strokeWidth,
            "Large Eraser",
          ),
          _presetButton(
            context,
            Icons.circle,
            80.0,
            settings.strokeWidth,
            "Huge Eraser",
          ),
          _divider(),
          _buildBrushSizePreview(
            settings.strokeWidth,
            settings.strokeColor,
            true,
          ),
          _buildWidthSlider(context, settings.strokeWidth, maxWidth: 100.0),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _presetButton(
            context,
            Icons.edit_note,
            2.0,
            settings.strokeWidth,
            "Pencil",
          ),
          _presetButton(context, Icons.edit, 5.0, settings.strokeWidth, "Pen"),
          _presetButton(
            context,
            Icons.brush_rounded,
            12.0,
            settings.strokeWidth,
            "Brush",
          ),
          _presetButton(
            context,
            Icons.format_paint_rounded,
            24.0,
            settings.strokeWidth,
            "Paint",
          ),
          _divider(),
          _buildColorButton(context, settings.strokeColor),
          _buildBrushSizePreview(
            settings.strokeWidth,
            settings.strokeColor,
            false,
          ),
          _buildWidthSlider(context, settings.strokeWidth, maxWidth: 50.0),
        ],
      );
    }
  }

  Widget _buildBrushSizePreview(
    double strokeWidth,
    Color strokeColor,
    bool isEraser,
  ) {
    final maxRange = isEraser ? 100.0 : 50.0;
    final safe = strokeWidth.clamp(1.0, maxRange);
    final diameter = (6.0 + (safe - 1.0) * (14.0 / (maxRange - 1.0))).clamp(
      6.0,
      20.0,
    );

    final fill = isEraser
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
        : strokeColor.withValues(alpha: 0.85);
    final border = isEraser
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.04),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(
      width: 1,
      height: 30,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
    ),
  );

  Widget _toolbarButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
    bool active, {
    Color? color,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? "",
      child: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        icon: Icon(icon),
        color: active
            ? Theme.of(context).colorScheme.primary
            : (color ??
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6)),
        iconSize: 28,
      ),
    );
  }

  Widget _presetButton(
    BuildContext context,
    IconData icon,
    double size,
    double currentSize,
    String tooltip,
  ) {
    final isActive = (size - currentSize).abs() < 0.1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 18 + (size / 10).clamp(0, 10),
          color: isActive
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onPressed: () => context.read<SettingsCubit>().setStrokeWidth(size),
        tooltip: tooltip,
        splashRadius: 20,
      ),
    );
  }

  Widget _smallIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? "",
      child: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        icon: Icon(icon),
        color:
            color ??
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        iconSize: 20,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _smallToggleButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
    bool active, {
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? "",
      child: IconButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        icon: Icon(icon),
        color: active
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        iconSize: 20,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}
