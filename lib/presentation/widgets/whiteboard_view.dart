import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_state.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/widgets/grid_painter.dart';
import 'package:logic_canvas/presentation/widgets/whiteboard_painter.dart';

import '../cubits/settings/settings_state.dart';

class WhiteboardView extends StatefulWidget {
  const WhiteboardView({super.key});

  @override
  State<WhiteboardView> createState() => _WhiteboardViewState();
}

class _WhiteboardViewState extends State<WhiteboardView> {
  Offset? _pendingPoint;
  bool _hasInitiatedWithMovement = false;
  int? _activePointerId;
  final ValueNotifier<Stroke?> _activeStrokeNotifier = ValueNotifier<Stroke?>(
    null,
  );
  final ValueNotifier<Offset?> _hoverPositionNotifier = ValueNotifier<Offset?>(
    null,
  );
  final Map<String, ui.Picture> _svgCache = {};

  @override
  void dispose() {
    _activeStrokeNotifier.dispose();
    _hoverPositionNotifier.dispose();
    for (final picture in _svgCache.values) {
      picture.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSvg(String path) async {
    if (_svgCache.containsKey(path)) return;

    try {
      final loader = SvgAssetLoader(path);
      // Load with a consistent target size
      final pictureInfo = await vg.loadPicture(
        loader,
        null, // No override color
        onError: (e, stack) => debugPrint('SVG Error: $e'),
      );

      if (mounted) {
        setState(() {
          _svgCache[path] = pictureInfo.picture;
        });
      }
    } catch (e) {
      debugPrint('Error loading SVG $path: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final drawingCubit = context.read<DrawingCubit>();

    return SizedBox.expand(
      child: Listener(
        onPointerHover: (event) {
          final settings = settingsCubit.state;
          if (settings.toolMode != ToolMode.hand) {
            final canvasPoint =
                (event.localPosition - settings.panOffset) / settings.zoomLevel;
            _hoverPositionNotifier.value = canvasPoint;
          }
        },
        onPointerDown: (event) {
          final settings = settingsCubit.state;
          final drawingState = drawingCubit.state;

          if (settings.toolMode != ToolMode.hand && !drawingState.isDrawing) {
            // Priority Check: If we have an active pointer and this is a stylus, Stylus wins
            if (event.kind == PointerDeviceKind.stylus ||
                _activePointerId == null) {
              _activePointerId = event.pointer;
              _pendingPoint = event.localPosition;
              _hasInitiatedWithMovement = false;

              _handleDrawingStart(
                context,
                _pendingPoint!,
                settings,
                drawingCubit,
                settingsCubit,
              );
            }
          }
        },
        onPointerMove: (event) {
          if (event.pointer != _activePointerId) return;

          final settings = settingsCubit.state;
          if (settings.toolMode == ToolMode.hand) return;

          final currentPoint = event.localPosition;
          final canvasPoint =
              (currentPoint - settings.panOffset) / settings.zoomLevel;
          _hoverPositionNotifier.value = canvasPoint;

          if (_activeStrokeNotifier.value != null) {
            final currentStroke = _activeStrokeNotifier.value!;

            final List<Offset> updatedPoints = List<Offset>.from(
              currentStroke.points,
            )..add(canvasPoint);

            _activeStrokeNotifier.value = currentStroke.copyWith(
              points: updatedPoints,
            );
          }
        },
        onPointerUp: (event) async {
          if (event.pointer != _activePointerId) return;
          _activePointerId = null;

          final settings = settingsCubit.state;
          await _cleanupDrawing(
            drawingCubit,
            settings.enableShapeDetection,
            settings.enableHandwritingRecognition,
          );
        },
        onPointerCancel: (event) async {
          if (event.pointer != _activePointerId) return;
          _activePointerId = null;

          final settings = settingsCubit.state;
          await _cleanupDrawing(
            drawingCubit,
            settings.enableShapeDetection,
            settings.enableHandwritingRecognition,
          );
        },
        child: GestureDetector(
          onTapDown: (details) {
            // Handled by onPointerDown
          },
          onScaleStart: (details) {
            final settings = settingsCubit.state;
            final drawingState = drawingCubit.state;
            if (settings.toolMode != ToolMode.hand && !drawingState.isDrawing) {
              _pendingPoint = details.localFocalPoint;
              _hasInitiatedWithMovement = false;
            }
          },
          onScaleUpdate: (details) {
            final settings = settingsCubit.state;
            if (settings.toolMode == ToolMode.hand) {
              if (details.scale != 1.0) {
                settingsCubit.setZoom(settings.zoomLevel * details.scale);
              } else {
                settingsCubit.updatePan(details.focalPointDelta);
              }
              return;
            }
          },
          onLongPress: () async {
            final settings = settingsCubit.state;
            final drawingState = drawingCubit.state;
            if (_pendingPoint != null &&
                !drawingState.isDrawing &&
                !_hasInitiatedWithMovement) {
              _handleDrawingStart(
                context,
                _pendingPoint!,
                settings,
                drawingCubit,
                settingsCubit,
              );
              await _cleanupDrawing(
                drawingCubit,
                settings.enableShapeDetection,
                settings.enableHandwritingRecognition,
              );
              _pendingPoint = null;
            }
          },
          child: BlocListener<DrawingCubit, DrawingState>(
            listenWhen: (prev, curr) => prev.strokes != curr.strokes,
            listener: (context, state) {
              // Load SVGs for any new icon strokes
              for (final stroke in state.strokes) {
                if (stroke.type == StrokeType.icon && stroke.iconPath != null) {
                  _loadSvg(stroke.iconPath!);
                }
              }
            },
            child: Stack(
              children: [
                // 1. Static Layer: Infinite Background Grid
                BlocBuilder<SettingsCubit, SettingsState>(
                  buildWhen: (prev, curr) =>
                      prev.pattern != curr.pattern ||
                      prev.panOffset != curr.panOffset ||
                      prev.zoomLevel != curr.zoomLevel ||
                      prev.themeMode != curr.themeMode,
                  builder: (context, settings) {
                    return RepaintBoundary(
                      child: CustomPaint(
                        painter: GridPainter(
                          pattern: settings.pattern,
                          panOffset: settings.panOffset,
                          zoomLevel: settings.zoomLevel,
                          themeMode: settings.themeMode,
                        ),
                        size: Size.infinite,
                      ),
                    );
                  },
                ),

                // 2. History Layer: Completed Strokes
                BlocBuilder<SettingsCubit, SettingsState>(
                  buildWhen: (prev, curr) =>
                      prev.panOffset != curr.panOffset ||
                      prev.zoomLevel != curr.zoomLevel ||
                      prev.themeMode != curr.themeMode,
                  builder: (context, settings) {
                    return BlocBuilder<DrawingCubit, DrawingState>(
                      buildWhen: (prev, curr) => prev.strokes != curr.strokes,
                      builder: (context, drawingState) {
                        return RepaintBoundary(
                          child: SizedBox.expand(
                            child: CustomPaint(
                              painter: WhiteboardPainter(
                                strokes: drawingState.strokes,
                                pattern: BackgroundPattern.none,
                                themeMode: settings.themeMode,
                                panOffset: settings.panOffset,
                                zoomLevel: settings.zoomLevel,
                                svgPictures: _svgCache,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // 3. Dynamic Layer: Active Stroke & Hover Cursor
                BlocBuilder<SettingsCubit, SettingsState>(
                  buildWhen: (prev, curr) =>
                      prev.panOffset != curr.panOffset ||
                      prev.zoomLevel != curr.zoomLevel ||
                      prev.strokeWidth != curr.strokeWidth ||
                      prev.strokeColor != curr.strokeColor ||
                      prev.isEraser != curr.isEraser ||
                      prev.themeMode != curr.themeMode,
                  builder: (context, settings) {
                    return ValueListenableBuilder<Offset?>(
                      valueListenable: _hoverPositionNotifier,
                      builder: (context, hoverPos, _) {
                        return ValueListenableBuilder<Stroke?>(
                          valueListenable: _activeStrokeNotifier,
                          builder: (context, activeStroke, _) {
                            return SizedBox.expand(
                              child: CustomPaint(
                                painter: WhiteboardPainter(
                                  strokes: const [],
                                  activeStroke: activeStroke,
                                  pattern: BackgroundPattern.none,
                                  themeMode: settings.themeMode,
                                  hoverPosition: hoverPos,
                                  brushSize: settings.strokeWidth,
                                  brushColor: settings.strokeColor,
                                  isEraser: settings.isEraser,
                                  panOffset: settings.panOffset,
                                  zoomLevel: settings.zoomLevel,
                                ),
                                size: Size.infinite,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cleanupDrawing(
    DrawingCubit drawingCubit,
    bool enableShapeDetection,
    bool enableHandwriting,
  ) async {
    // ATOMIC CLEANUP: Capture and clear immediately to prevent race conditions
    final finalStroke = _activeStrokeNotifier.value;
    if (finalStroke == null) return; // Already cleaned up

    _activeStrokeNotifier.value = null;
    _pendingPoint = null;
    _hasInitiatedWithMovement = false;

    debugPrint(
      'TOUCH: Finalizing Stroke (Points: ${finalStroke.points.length})',
    );

    // Commit the completed stroke to the Cubit
    await drawingCubit.endStroke(
      finalStroke,
      enableShapeDetection,
      enableHandwriting: enableHandwriting,
    );

    if (finalStroke.type == StrokeType.icon && finalStroke.iconPath != null) {
      _loadSvg(finalStroke.iconPath!);
    }
  }

  void _handleDrawingStart(
    BuildContext context,
    Offset localPosition,
    SettingsState settings,
    DrawingCubit drawingCubit,
    SettingsCubit settingsCubit,
  ) {
    if (settings.autoHideSidebar && settings.showSidebar) {
      settingsCubit.hideSidebar();
    }
    final canvasPoint =
        (localPosition - settings.panOffset) / settings.zoomLevel;

    // Handle Diagram Mode (One-tap icon placement)
    if (settings.toolMode == ToolMode.diagram &&
        settings.selectedIconPath != null) {
      final iconStroke = Stroke(
        points: [canvasPoint],
        color: settings.strokeColor,
        strokeWidth: settings.strokeWidth,
        type: StrokeType.icon,
        iconPath: settings.selectedIconPath,
      );
      drawingCubit.addStroke(iconStroke);
      _loadSvg(settings.selectedIconPath!);
      return; // No need to start a 'drawing' session
    }

    // Create new active stroke
    final newStroke = Stroke(
      points: [canvasPoint],
      color: settings.isEraser ? Colors.transparent : settings.strokeColor,
      strokeWidth: settings.strokeWidth,
      isEraser: settings.isEraser,
      type: settings.toolMode == ToolMode.connector
          ? StrokeType.connector
          : StrokeType.pen,
    );

    debugPrint(
      'TOUCH: Start Stroke (Color: ${settings.strokeColor}, Width: ${settings.strokeWidth}, Mode: ${settings.toolMode})',
    );
    _activeStrokeNotifier.value = newStroke;
    drawingCubit.startStroke();
    _hoverPositionNotifier.value = canvasPoint;
  }
}
