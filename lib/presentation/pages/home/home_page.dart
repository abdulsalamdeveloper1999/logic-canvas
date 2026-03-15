import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:logic_canvas/presentation/widgets/icon_picker_sheet.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';
import 'package:logic_canvas/presentation/widgets/upgrade_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final sidebarWidth = orientation == Orientation.landscape ? 350.0 : 280.0;
    final isPro = context.select((EntitlementsCubit c) => c.state.isPro);

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return BlocBuilder<SelectionCubit, SelectionState>(
            builder: (context, selection) {
              final selectedProblem = selection.selectedProblem;

              return Stack(
                children: [
                   const Positioned.fill(child: WhiteboardView()),

                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildTopBar(context, selectedProblem, isPro),
                  ),

                  if (selectedProblem != null)
                    Positioned(
                      top: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildProblemBadge(context, selectedProblem),
                      ),
                    ),

                  _buildSidebar(context, settings, sidebarWidth),

                  _buildComprehensiveToolbar(context, settings, orientation),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildComprehensiveToolbar(BuildContext context, SettingsState settings, Orientation orientation) {
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
    final isPro = context.select((EntitlementsCubit c) => c.state.isPro);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI Intelligence
              _smallToggleButton(
                context, 
                Icons.draw_rounded, 
                () => isPro
                    ? context.read<SettingsCubit>().toggleShapeDetection()
                    : UpgradeDialog.show(context),
                isPro && settings.enableShapeDetection, 
                tooltip: "Shape Detector",
              ),
              _smallToggleButton(
                context, 
                Icons.text_fields_rounded, 
                () => isPro
                    ? context.read<SettingsCubit>().toggleHandwritingRecognition()
                    : UpgradeDialog.show(context),
                isPro && settings.enableHandwritingRecognition, 
                tooltip: "Paint to Text (Handwriting)",
              ),

              _divider(),

              // Zoom Controls
              _smallIconButton(context, Icons.zoom_out_rounded, () => context.read<SettingsCubit>().setZoom(settings.zoomLevel - 0.2), tooltip: "Zoom Out"),
              _smallIconButton(context, Icons.zoom_in_rounded, () => context.read<SettingsCubit>().setZoom(settings.zoomLevel + 0.2), tooltip: "Zoom In"),
              _smallIconButton(
                context, 
                Icons.center_focus_strong_outlined, 
                () => context.read<SettingsCubit>().resetTransform(), 
                color: (settings.panOffset != Offset.zero || settings.zoomLevel != 1.0) ? Colors.blueAccent : null,
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
      context.read<DrawingCubit>().clear();
    }
  }

  Widget _buildMainIntegratedBar(BuildContext context, SettingsState settings) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Core Tools
              _toolbarButton(context, Icons.edit_rounded, () => context.read<SettingsCubit>().setToolMode(ToolMode.pen), settings.toolMode == ToolMode.pen, tooltip: "Pen"),
              _toolbarButton(context, Icons.pan_tool_rounded, () => context.read<SettingsCubit>().setToolMode(ToolMode.hand), settings.toolMode == ToolMode.hand, tooltip: "Hand (Pan)"),
              _toolbarButton(context, Icons.device_hub_rounded, () => context.read<SettingsCubit>().setToolMode(ToolMode.connector), settings.toolMode == ToolMode.connector, tooltip: "Connector"),
              _toolbarButton(context, Icons.category_rounded, () => context.read<SettingsCubit>().setToolMode(ToolMode.diagram), settings.toolMode == ToolMode.diagram, tooltip: "Diagram Icons"),
              _toolbarButton(context, Icons.auto_fix_high_rounded, () => context.read<SettingsCubit>().setToolMode(ToolMode.eraser), settings.toolMode == ToolMode.eraser, tooltip: "Eraser"),
              
              _divider(),

              // Quick Presets
              _presetButton(context, Icons.edit_note, 2.0, settings.strokeWidth, "Pencil"),
              _presetButton(context, Icons.edit, 5.0, settings.strokeWidth, "Pen"),
              _presetButton(context, Icons.brush_rounded, 12.0, settings.strokeWidth, "Brush"),
              _presetButton(context, Icons.format_paint_rounded, 24.0, settings.strokeWidth, "Paint"),

              _divider(),

              // Styling Controls
              _buildColorButton(context, settings.strokeColor),
              _buildBrushSizePreview(settings.strokeWidth, settings.strokeColor, settings.isEraser),
              _buildWidthSlider(context, settings.strokeWidth),

              _divider(),

              // History
              _toolbarButton(context, Icons.undo_rounded, () => context.read<DrawingCubit>().undo(), false, tooltip: "Undo"),
              _toolbarButton(context, Icons.redo_rounded, () => context.read<DrawingCubit>().redo(), false, tooltip: "Redo"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedIconPreview(BuildContext context, SettingsState settings) {
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
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reduce preview icon size (~1.2x smaller).
                if (iconPath != null) SvgPicture.asset(iconPath, width: 20, height: 20)
                else const Icon(Icons.search_rounded, size: 20, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  iconPath?.split('/').last.split('.').first.replaceAll('-', ' ').toUpperCase() ?? "SEARCH CLOUD ICONS",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1.0),
                ),
                const Icon(Icons.arrow_right_rounded, size: 20, color: Colors.blueAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIconPicker(BuildContext context, SettingsState settings) {
    final isPro = context.read<EntitlementsCubit>().state.isPro;
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
                  isPro: isPro,
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
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
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

  Widget _buildSidebar(BuildContext context, SettingsState settings, double width) {
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
            left: 0, top: 0, bottom: 0, width: width,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                    border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: const ProblemPanel(),
                ),
              ),
            ),
          ),
          Positioned(
            left: width + 10, top: 100,
            child: GestureDetector(
              onTap: () => context.read<SettingsCubit>().toggleSidebar(),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: Icon(settings.showSidebar ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: Colors.blueAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Problem? selectedProblem, bool isPro) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4), border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
          child: SafeArea(
            bottom: false,
              child: Row(
              children: [
                const Text("LogicCanvas", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                const Spacer(),
                Text(
                  isPro ? "Pro" : "Free",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProblemBadge(BuildContext context, Problem problem) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_rounded, size: 18, color: _getDifficultyColor(problem.difficulty)),
              const SizedBox(width: 10),
              Text(problem.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 15),
              Container(width: 1, height: 16, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(width: 15),
              Text(problem.difficulty.name.toUpperCase(), style: TextStyle(color: _getDifficultyColor(problem.difficulty), fontSize: 13, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(BuildContext context, Color currentColor) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Brush Color'),
            content: SingleChildScrollView(child: ColorPicker(pickerColor: currentColor, onColorChanged: (color) => context.read<SettingsCubit>().setStrokeColor(color))),
            actions: [TextButton(child: const Text('Done'), onPressed: () => Navigator.of(context).pop())],
          ),
        );
      },
      child: Container(
        width: 32, height: 32, margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: currentColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: currentColor.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 2)]),
      ),
    );
  }

  Widget _buildWidthSlider(BuildContext context, double currentWidth) {
    const minWidth = 1.0;
    const maxWidth = 50.0; // Must cover preset values (e.g. 24.0) and persisted settings.
    final safeWidth = currentWidth.clamp(minWidth, maxWidth);
    return SizedBox(
      width: 80,
      child: Slider(
        value: safeWidth,
        min: minWidth,
        max: maxWidth,
        onChanged: (value) => context.read<SettingsCubit>().setStrokeWidth(value),
      ),
    );
  }

  Widget _buildBrushSizePreview(double strokeWidth, Color strokeColor, bool isEraser) {
    final safe = strokeWidth.clamp(1.0, 50.0);
    // Toolbar preview should stay compact; map to 6..20 px diameter.
    final diameter = (6.0 + (safe - 1.0) * (14.0 / 49.0)).clamp(6.0, 20.0);

    final fill = isEraser
        ? Colors.white.withValues(alpha: 0.12)
        : strokeColor.withValues(alpha: 0.85);
    final border = isEraser ? Colors.white54 : Colors.white24;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
    child: Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
  );

  Widget _toolbarButton(BuildContext context, IconData icon, VoidCallback onPressed, bool active, {Color? color, String? tooltip}) {
    return Tooltip(
      message: tooltip ?? "",
      child: IconButton(
        onPressed: () { HapticFeedback.lightImpact(); onPressed(); },
        icon: Icon(icon), color: active ? Colors.blueAccent : (color ?? Colors.white.withValues(alpha: 0.6)), iconSize: 28,
      ),
    );
  }

  Widget _presetButton(BuildContext context, IconData icon, double width, double currentWidth, String label) {
    final bool active = (currentWidth - width).abs() < 0.1;
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: () { HapticFeedback.mediumImpact(); context.read<SettingsCubit>().setBrushPreset(width); },
        icon: Icon(icon), color: active ? Colors.blueAccent : Colors.white.withValues(alpha: 0.4), iconSize: 22,
      ),
    );
  }

  Widget _smallIconButton(BuildContext context, IconData icon, VoidCallback onPressed, {Color? color, String? tooltip}) {
    return Tooltip(
      message: tooltip ?? "",
      child: IconButton(
        onPressed: () { HapticFeedback.lightImpact(); onPressed(); },
        icon: Icon(icon), color: color ?? Colors.white.withValues(alpha: 0.6), iconSize: 20, constraints: const BoxConstraints(), padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _smallToggleButton(BuildContext context, IconData icon, VoidCallback onPressed, bool active, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? "",
      child: IconButton(
        onPressed: () { HapticFeedback.mediumImpact(); onPressed(); },
        icon: Icon(icon), color: active ? Colors.blueAccent : Colors.white.withValues(alpha: 0.4), iconSize: 20, constraints: const BoxConstraints(), padding: const EdgeInsets.all(8),
      ),
    );
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy: return Colors.greenAccent;
      case Difficulty.medium: return Colors.orangeAccent;
      case Difficulty.hard: return Colors.redAccent;
    }
  }
}
