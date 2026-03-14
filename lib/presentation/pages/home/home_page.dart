import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';

import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_state.dart';
import 'package:logic_canvas/presentation/cubits/selection/selection_cubit.dart';
import 'package:logic_canvas/presentation/cubits/selection/selection_state.dart';
import 'package:logic_canvas/presentation/widgets/whiteboard_view.dart';
import 'package:logic_canvas/presentation/widgets/problem_panel.dart';
import 'package:logic_canvas/domain/entities/problem.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final sidebarWidth = orientation == Orientation.landscape ? 350.0 : 280.0;

    return Scaffold(
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return BlocBuilder<SelectionCubit, SelectionState>(
            builder: (context, selection) {
              final selectedProblem = selection.selectedProblem;

              return Stack(
                children: [
                  // 1. Edge-to-Edge Whiteboard View
                  const Positioned.fill(child: WhiteboardView()),

                  // 2. Floating Glassmorphic Top Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildTopBar(context, selectedProblem),
                  ),

                  // 3. Problem Badge & Toolbar Layer
                  Positioned.fill(
                    child: Stack(
                      children: [
                        if (selectedProblem != null)
                          Positioned(
                            top: 100, // Below the floating top bar
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _buildProblemBadge(
                                context,
                                selectedProblem,
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: orientation == Orientation.landscape
                              ? (settings.showToolbar ? 40 : -100)
                              : null,
                          right: orientation == Orientation.portrait
                              ? (settings.showToolbar ? 20 : -100)
                              : 0,
                          left: orientation == Orientation.landscape ? 0 : null,
                          top: orientation == Orientation.portrait ? 100 : null,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 400),
                            opacity: settings.showToolbar ? 1.0 : 0.0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutQuart,
                              child: orientation == Orientation.landscape
                                  ? Center(
                                      child: _buildFloatingToolbar(
                                        context,
                                        settings,
                                        false,
                                      ),
                                    )
                                  : _buildFloatingToolbar(
                                      context,
                                      settings,
                                      true,
                                    ),
                            ),
                          ),
                        ),

                        // Toolbar Toggle Button (Always visible)
                        Positioned(
                          bottom: orientation == Orientation.landscape
                              ? 10
                              : 20,
                          left: orientation == Orientation.landscape ? 0 : null,
                          right: orientation == Orientation.landscape
                              ? 0
                              : (orientation == Orientation.portrait
                                    ? 20
                                    : null),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildRecenterButton(
                                  context,
                                  settings.panOffset != Offset.zero ||
                                      settings.zoomLevel != 1.0,
                                ),
                                const SizedBox(width: 12),
                                _buildToolbarToggle(
                                  context,
                                  settings.showToolbar,
                                  orientation,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Diagram Asset Bar Overlay
                        BlocBuilder<SettingsCubit, SettingsState>(
                          builder: (context, settings) {
                            if (settings.toolMode != ToolMode.diagram) return const SizedBox.shrink();
                            return Positioned(
                              bottom: MediaQuery.of(context).orientation == Orientation.landscape ? 100 : 160,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _buildAssetBar(context, settings),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Floating Sidebar Overlay
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutQuart,
                    left: settings.showSidebar ? 0 : -sidebarWidth,
                    top: 0,
                    bottom: 0,
                    width:
                        sidebarWidth +
                        60, // Include toggle button in hit-test area
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Blur and Sidebar
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: sidebarWidth,
                          child: ClipRRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withValues(alpha: 0.8),
                                  border: Border(
                                    right: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  boxShadow: [
                                    if (settings.showSidebar)
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 40,
                                        spreadRadius: 5,
                                      ),
                                  ],
                                ),
                                child: const ProblemPanel(),
                              ),
                            ),
                          ),
                        ),

                        // Top-Left Chevron Toggle (Attached to sidebar)
                        if (settings.showSidebar)
                          Positioned(
                            left: sidebarWidth + 20,
                            top: 60,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                context.read<SettingsCubit>().toggleSidebar();
                              },
                              child: _buildChevronToggle(
                                context,
                                settings.showSidebar,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProblemBadge(BuildContext context, Problem problem) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: _getDifficultyColor(problem.difficulty),
              ),
              const SizedBox(width: 8),
              Text(
                problem.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 12),
              Text(
                problem.difficulty.name.toUpperCase(),
                style: TextStyle(
                  color: _getDifficultyColor(problem.difficulty),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Problem? selectedProblem) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, state) {
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.read<SettingsCubit>().toggleSidebar();
                          },
                          child: _buildChevronToggle(
                            context,
                            state.showSidebar,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LOGIC",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            color: Colors.blueAccent,
                          ),
                        ),
                        Text(
                          "Canvas",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Advanced Settings Popup
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: BlocBuilder<SettingsCubit, SettingsState>(
                            builder: (context, state) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Auto-hide Sidebar"),
                                  Switch.adaptive(
                                    value: state.autoHideSidebar,
                                    onChanged: (value) {
                                      HapticFeedback.lightImpact();
                                      context
                                          .read<SettingsCubit>()
                                          .toggleAutoHideSidebar();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    _buildThemeToggle(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final isDark = state.themeMode == ThemeMode.dark;
        return IconButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.read<SettingsCubit>().toggleTheme();
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              key: ValueKey(isDark),
              color: isDark ? Colors.orangeAccent : Colors.indigoAccent,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChevronToggle(BuildContext context, bool isExpanded) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isExpanded ? Icons.chevron_left : Icons.chevron_right,
          color: Colors.blueAccent,
          size: 24,
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

  Widget _buildRecenterButton(BuildContext context, bool canRecenter) {
    return GestureDetector(
      onTap: () {
        if (canRecenter) {
          HapticFeedback.mediumImpact();
          context.read<SettingsCubit>().resetTransform();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: canRecenter
                ? Colors.blueAccent.withValues(alpha: 0.5)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.center_focus_strong,
            color: canRecenter ? Colors.blueAccent : Colors.grey,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarToggle(
    BuildContext context,
    bool isExpanded,
    Orientation orientation,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.mediumImpact();
        context.read<SettingsCubit>().toggleToolbar();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: isExpanded ? 50 : 60,
        height: isExpanded ? 24 : 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(isExpanded ? 12 : 30),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isExpanded
              ? Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.blueAccent.withValues(alpha: 0.8),
                  size: 20,
                )
              : const Icon(
                  Icons.construction,
                  color: Colors.blueAccent,
                  size: 28,
                ),
        ),
      ),
    );
  }

  Widget _buildFloatingToolbar(
    BuildContext context,
    SettingsState settings,
    bool isVertical,
  ) {
    final children = [
      _toolbarButton(
        context,
        Icons.edit,
        () => context.read<SettingsCubit>().setToolMode(ToolMode.pen),
        settings.toolMode == ToolMode.pen,
      ),
      _toolbarButton(
        context,
        Icons.auto_fix_normal,
        () => context.read<SettingsCubit>().setToolMode(ToolMode.eraser),
        settings.toolMode == ToolMode.eraser,
      ),
      _toolbarButton(
        context,
        Icons.pan_tool,
        () => context.read<SettingsCubit>().setToolMode(ToolMode.hand),
        settings.toolMode == ToolMode.hand,
      ),
      isVertical
          ? const Divider(color: Colors.white24, indent: 10, endIndent: 10)
          : const VerticalDivider(
              color: Colors.white24,
              indent: 10,
              endIndent: 10,
            ),
      _toolbarButton(
        context,
        Icons.zoom_in,
        () => context.read<SettingsCubit>().setZoom(settings.zoomLevel + 0.1),
        false,
      ),
      _toolbarButton(
        context,
        Icons.zoom_out,
        () => context.read<SettingsCubit>().setZoom(settings.zoomLevel - 0.1),
        false,
      ),
      _toolbarButton(
        context,
        Icons.center_focus_strong,
        () => context.read<SettingsCubit>().resetTransform(),
        false,
      ),
      isVertical
          ? const Divider(color: Colors.white24, indent: 10, endIndent: 10)
          : const VerticalDivider(
              color: Colors.white24,
              indent: 10,
              endIndent: 10,
            ),
      _toolbarButton(
        context,
        Icons.undo,
        () => context.read<DrawingCubit>().undo(),
        false,
      ),
      _toolbarButton(
        context,
        Icons.redo,
        () => context.read<DrawingCubit>().redo(),
        false,
      ),
      isVertical
          ? const Divider(color: Colors.white24, indent: 10, endIndent: 10)
          : const VerticalDivider(
              color: Colors.white24,
              indent: 10,
              endIndent: 10,
            ),
      _buildBrushPresets(context, settings.strokeWidth, isVertical: isVertical),
      isVertical
          ? const Divider(color: Colors.white24, indent: 10, endIndent: 10)
          : const VerticalDivider(
              color: Colors.white24,
              indent: 10,
              endIndent: 10,
            ),
      _buildColorPickerButton(context, settings.strokeColor),
      _buildWidthSlider(context, settings.strokeWidth, isVertical: isVertical),
      isVertical
          ? const Divider(color: Colors.white24, indent: 10, endIndent: 10)
          : const VerticalDivider(
              color: Colors.white24,
              indent: 10,
              endIndent: 10,
            ),
      _toolbarButton(
        context,
        Icons.grid_4x4,
        () => context.read<SettingsCubit>().setPattern(BackgroundPattern.grid),
        settings.pattern == BackgroundPattern.grid,
      ),
      _toolbarButton(
        context,
        Icons.reorder,
        () => context.read<SettingsCubit>().setPattern(BackgroundPattern.lines),
        settings.pattern == BackgroundPattern.lines,
      ),
      _toolbarButton(
        context,
        Icons.layers_clear,
        () => context.read<SettingsCubit>().setPattern(BackgroundPattern.none),
        settings.pattern == BackgroundPattern.none,
      ),
      isVertical
          ? const Divider(color: Colors.white24, indent: 10, endIndent: 10)
          : const VerticalDivider(
              color: Colors.white24,
              indent: 10,
              endIndent: 10,
            ),
      _toolbarButton(
        context,
        Icons.text_fields,
        () {
          context.read<SettingsCubit>().toggleHandwritingRecognition();
        },
        settings.enableHandwritingRecognition,
        tooltip: 'Writing to Proper Text',
      ),
      isVertical
          ? const Divider(color: Colors.white24, indent: 10, endIndent: 10)
          : const VerticalDivider(
              color: Colors.white24,
              indent: 10,
              endIndent: 10,
            ),
      _toolbarButton(
        context,
        settings.enableShapeDetection
            ? Icons.auto_fix_high
            : Icons.auto_fix_off,
        () {
          context.read<SettingsCubit>().toggleShapeDetection();
        },
        settings.enableShapeDetection,
        tooltip: 'Auto Shape Detection',
      ),
      isVertical
          ? const Divider(color: Colors.white24, indent: 10, endIndent: 10)
          : const VerticalDivider(
              color: Colors.white24,
              indent: 10,
              endIndent: 10,
            ),
      _toolbarButton(
        context,
        Icons.category_outlined,
        () => context.read<SettingsCubit>().setToolMode(ToolMode.diagram),
        settings.toolMode == ToolMode.diagram,
        tooltip: 'Diagram Icons',
      ),
      _toolbarButton(
        context,
        Icons.mediation_outlined,
        () => context.read<SettingsCubit>().setToolMode(ToolMode.connector),
        settings.toolMode == ToolMode.connector,
        tooltip: 'Connector Tool',
      ),
      isVertical
          ? const Divider(color: Colors.white24, indent: 10, endIndent: 10)
          : const VerticalDivider(
              color: Colors.white24,
              indent: 10,
              endIndent: 10,
            ),
      _toolbarButton(
        context,
        Icons.delete_outline,
        () => context.read<DrawingCubit>().clear(),
        false,
        color: Colors.redAccent,
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
          child: isVertical
              ? IntrinsicWidth(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: children,
                    ),
                  ),
                )
              : IntrinsicHeight(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: children,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBrushPresets(
    BuildContext context,
    double currentWidth, {
    bool isVertical = false,
  }) {
    final children = [
      _toolbarButton(
        context,
        Icons.edit_note,
        () => context.read<SettingsCubit>().setBrushPreset(2.0),
        currentWidth == 2.0,
        tooltip: 'Pencil (2px)',
      ),
      _toolbarButton(
        context,
        Icons.edit,
        () => context.read<SettingsCubit>().setBrushPreset(5.0),
        currentWidth == 5.0,
        tooltip: 'Pen (5px)',
      ),
      _toolbarButton(
        context,
        Icons.brush,
        () => context.read<SettingsCubit>().setBrushPreset(12.0),
        currentWidth == 12.0,
        tooltip: 'Brush (12px)',
      ),
      _toolbarButton(
        context,
        Icons.format_paint,
        () => context.read<SettingsCubit>().setBrushPreset(24.0),
        currentWidth == 24.0,
        tooltip: 'Painting (24px)',
      ),
    ];

    return isVertical
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildColorPickerButton(BuildContext context, Color currentColor) {
    return IconButton(
      icon: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pick a color'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: currentColor,
                onColorChanged: (color) =>
                    context.read<SettingsCubit>().setStrokeColor(color),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWidthSlider(
    BuildContext context,
    double currentWidth, {
    bool isVertical = false,
  }) {
    return SizedBox(
      width: isVertical ? 100 : 150,
      child: Slider(
        value: currentWidth,
        min: 1,
        max: 50,
        onChanged: (value) =>
            context.read<SettingsCubit>().setStrokeWidth(value),
      ),
    );
  }

  Widget _toolbarButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
    bool active, {
    Color? color,
    String? tooltip,
  }) {
    return IconButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      icon: Icon(icon),
      tooltip: tooltip,
      color: active
          ? Colors.blueAccent
          : (color ??
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
      iconSize: 26,
    );
  }

  Widget _buildAssetBar(BuildContext context, SettingsState settings) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 600,
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: "AWS"),
                    Tab(text: "Azure"),
                    Tab(text: "GCP"),
                  ],
                  labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  indicatorColor: Colors.blueAccent,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAssetGrid(context, "aws-icons"),
                      _buildAssetGrid(context, "azure-icons"),
                      _buildAssetGrid(context, "gcp-icons"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetGrid(BuildContext context, String category) {
    // This is a simplified list for initial implementation. 
    // In a real app, we'd list the directory or have a predefined map of popular icons.
    final List<String> popularIcons = _getPopularIcons(category);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: popularIcons.length,
      itemBuilder: (context, index) {
        final iconPath = "assets/icons/$category/${popularIcons[index]}";
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.read<SettingsCubit>().setSelectedIconPath(iconPath);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white24,
              ),
            ),
            child: Center(
              child: Text(
                popularIcons[index].split('-').last.split('.').first.toUpperCase(),
                style: const TextStyle(fontSize: 8, color: Colors.white70),
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _getPopularIcons(String category) {
    if (category == "aws-icons") {
      return ["aws-lambda.svg", "aws-ec2.svg", "aws-simple-storage-service.svg", "aws-dynamodb.svg"];
    } else if (category == "azure-icons") {
      return ["azure-virtual-machine.svg", "azure-function-apps.svg", "azure-cosmos-db.svg", "azure-active-directory.svg"];
    } else {
      return ["gcp-compute-engine.svg", "gcp-cloud-functions.svg", "gcp-cloud-storage.svg", "gcp-bigquery.svg"];
    }
  }
}
