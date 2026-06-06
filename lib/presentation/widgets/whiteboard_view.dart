import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_state.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';
import 'package:logic_canvas/presentation/widgets/grid_painter.dart';
import 'package:logic_canvas/presentation/widgets/whiteboard_painter.dart';

import 'package:screenshot/screenshot.dart';
import 'package:logic_canvas/data/services/export_service.dart';
import 'package:logic_canvas/core/injection.dart';

import '../cubits/settings/settings_state.dart';

enum _TransformHandle { none, topLeft, topRight, bottomLeft, bottomRight, rotate, delete }

class WhiteboardView extends StatefulWidget {
  const WhiteboardView({super.key});

  @override
  State<WhiteboardView> createState() => _WhiteboardViewState();
}

class _WhiteboardViewState extends State<WhiteboardView> {
  final ExportService _exportService = getIt<ExportService>();
  Offset? _pendingPoint;
  bool _hasInitiatedWithMovement = false;
  int? _activePointerId;
  PointerDeviceKind? _activePointerKind;
  final Set<int> _activeTouchPointers = <int>{};
  int? _draggingIconIndex;
  _TransformHandle _activeHandle = _TransformHandle.none;
  Offset _draggingIconDelta = Offset.zero;
  double _initialScale = 1.0;
  double _initialRotation = 0.0;
  double _initialAngle = 0.0;
  Offset _initialHandleOffset = Offset.zero;
  bool _draggingIconIsNewlyPlaced = false;
  Size? _lastBoardSize;
  double? _scaleBaseZoom;
  Offset? _scaleBasePan;
  Offset? _scaleBaseCanvasFocal;
  final ValueNotifier<Stroke?> _activeStrokeNotifier = ValueNotifier<Stroke?>(
    null,
  );
  final ValueNotifier<Offset?> _hoverPositionNotifier = ValueNotifier<Offset?>(
    null,
  );
  final Map<String, PictureInfo> _svgCache = {};

  @override
  void dispose() {
    _activeStrokeNotifier.dispose();
    _hoverPositionNotifier.dispose();
    for (final info in _svgCache.values) {
      info.picture.dispose();
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
          _svgCache[path] = pictureInfo;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        _lastBoardSize = Size(constraints.maxWidth, constraints.maxHeight);

        return SizedBox.expand(
          child: Listener(
            onPointerHover: (event) {
              final settings = settingsCubit.state;
              if (settings.toolMode != ToolMode.hand) {
                final canvasPoint = _toCanvasPoint(
                  settings,
                  event.localPosition,
                );
                _hoverPositionNotifier.value = canvasPoint;
              }
            },
            onPointerDown: (event) {
              final settings = settingsCubit.state;
              final drawingState = drawingCubit.state;

              if (event.kind == PointerDeviceKind.touch) {
                _activeTouchPointers.add(event.pointer);
                // If a second touch finger comes in, stop any touch-draw stroke.
                if (_activeTouchPointers.length >= 2 &&
                    _activePointerKind == PointerDeviceKind.touch) {
                  _cancelActiveStroke(drawingCubit);
                  // If we just placed an icon and started dragging it, cancel that too
                  // so pinch/zoom can take over without leaving stray icons.
                  _cancelIconDrag(drawingCubit, removeIfNew: true);
                  // Let the scale gesture handle pinch zoom/pan.
                  return;
                }
              }

              if (settings.toolMode != ToolMode.hand &&
                  !drawingState.isDrawing) {
                // Priority Check: If we have an active pointer and this is a stylus, Stylus wins
                if (event.kind == PointerDeviceKind.stylus ||
                    _activePointerId == null) {
                  _activePointerId = event.pointer;
                  _activePointerKind = event.kind;
                  _pendingPoint = event.localPosition;
                  _hasInitiatedWithMovement = false;

                  if (settings.toolMode == ToolMode.diagram) {
                    final canvasPoint = _toCanvasPoint(settings, event.localPosition);
                    
                    // 1. Check if we hit a handle of already selected icon
                    if (drawingState.selectedStrokeIndex != null &&
                        drawingState.selectedStrokeIndex! <
                            drawingState.activeStrokes.length) {
                      final stroke = drawingState.activeStrokes[
                          drawingState.selectedStrokeIndex!];
                      if (stroke.type == StrokeType.icon) {
                        final handle = _hitTestHandles(canvasPoint, stroke);
                        if (handle == _TransformHandle.delete) {
                          drawingCubit.removeStrokeAt(drawingState.selectedStrokeIndex!);
                          _activePointerId = null;
                          _activePointerKind = null;
                          return;
                        }
                        if (handle != _TransformHandle.none) {
                          _activeHandle = handle;
                          _draggingIconIndex = drawingState.selectedStrokeIndex;
                          _initialScale = stroke.scale;
                          _initialRotation = stroke.rotation;
                          _initialHandleOffset = canvasPoint - stroke.points.first;
                          _initialAngle = (canvasPoint - stroke.points.first).direction;
                          _pendingPoint = null;
                          return;
                        }
                      }
                    }

                    // 2. Check if we hit another icon to select/drag
                    final hitIndex = _hitTestIconStrokeIndex(
                      strokes: drawingState.activeStrokes,
                      canvasPoint: canvasPoint,
                    );
                    
                    if (hitIndex != null) {
                      drawingCubit.selectStroke(hitIndex);
                      final hitStroke = drawingState.activeStrokes[hitIndex];
                      _draggingIconIndex = hitIndex;
                      _draggingIconDelta = canvasPoint - hitStroke.points.first;
                      _activeHandle = _TransformHandle.none;
                      _pendingPoint = null;
                      return;
                    } else {
                      // Tapped empty space in diagram mode -> deselect
                      drawingCubit.selectStroke(null);
                    }

                    // 3. Fallback to diagram placement logic
                    _handleDiagramPointerDown(
                      localPosition: event.localPosition,
                      settings: settings,
                      drawingCubit: drawingCubit,
                    );
                    _pendingPoint = null;
                    return;
                  }

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

              final canvasPoint = _toCanvasPoint(settings, event.localPosition);
              _hoverPositionNotifier.value = canvasPoint;

              if (_draggingIconIndex != null) {
                if (_activeTouchPointers.length >= 2) return;
                final idx = _draggingIconIndex!;
                if (idx < 0 || idx >= drawingCubit.activeStrokes.length) return;
                final s = drawingCubit.activeStrokes[idx];

                if (_activeHandle == _TransformHandle.none) {
                  // Standard Drag
                  final updated = s.copyWith(
                    points: [canvasPoint - _draggingIconDelta],
                  );
                  drawingCubit.updateStrokeAt(idx, updated);
                } else if (_activeHandle == _TransformHandle.rotate) {
                  // Rotation logic
                  final currentAngle = (canvasPoint - s.points.first).direction;
                  final angleDelta = currentAngle - _initialAngle;
                  drawingCubit.updateStrokeTransform(
                    index: idx,
                    rotation: _initialRotation + angleDelta,
                  );
                } else {
                  // Resizing logic (corners)
                  final currentDist = (canvasPoint - s.points.first).distance;
                  final initialDist = _initialHandleOffset.distance;
                  if (initialDist > 0) {
                    final scaleFactor = currentDist / initialDist;
                    drawingCubit.updateStrokeTransform(
                      index: idx,
                      scale: _initialScale * scaleFactor,
                    );
                  }
                }
                return;
              }

              if (_activeStrokeNotifier.value != null) {
                final currentStroke = _activeStrokeNotifier.value!;

                if (currentStroke.type == StrokeType.connector &&
                    currentStroke.points.isNotEmpty) {
                  final start = currentStroke.points.first;
                  Offset snappedPoint = canvasPoint;

                  // Snap to horizontal or vertical if close enough (20.0 units)
                  const double snapThreshold = 20.0;
                  final dx = (canvasPoint.dx - start.dx).abs();
                  final dy = (canvasPoint.dy - start.dy).abs();

                  if (dy < snapThreshold) {
                    snappedPoint = Offset(canvasPoint.dx, start.dy);
                  } else if (dx < snapThreshold) {
                    snappedPoint = Offset(start.dx, canvasPoint.dy);
                  }

                  _activeStrokeNotifier.value = currentStroke.copyWith(
                    points: [start, snappedPoint],
                  );
                } else {
                  final List<Offset> updatedPoints = List<Offset>.from(
                    currentStroke.points,
                  )..add(canvasPoint);

                  _activeStrokeNotifier.value = currentStroke.copyWith(
                    points: updatedPoints,
                  );
                }
              }
            },
            onPointerUp: (event) async {
              if (event.kind == PointerDeviceKind.touch) {
                _activeTouchPointers.remove(event.pointer);
              }
              if (event.pointer != _activePointerId) return;
              _activePointerId = null;
              _activePointerKind = null;

              if (_draggingIconIndex != null) {
                _draggingIconIndex = null;
                _draggingIconDelta = Offset.zero;
                return;
              }

              final settings = settingsCubit.state;
              final isSubscribed = context.read<EntitlementsCubit>().state.isSubscribed;
              await _cleanupDrawing(
                drawingCubit,
                isSubscribed && settings.enableShapeDetection,
                isSubscribed && settings.enableHandwritingRecognition,
              );
            },
            onPointerCancel: (event) async {
              if (event.kind == PointerDeviceKind.touch) {
                _activeTouchPointers.remove(event.pointer);
              }
              if (event.pointer != _activePointerId) return;
              _activePointerId = null;
              _activePointerKind = null;

              if (_draggingIconIndex != null) {
                _draggingIconIndex = null;
                _draggingIconDelta = Offset.zero;
                return;
              }

              final settings = settingsCubit.state;
              final isSubscribed = context.read<EntitlementsCubit>().state.isSubscribed;
              await _cleanupDrawing(
                drawingCubit,
                isSubscribed && settings.enableShapeDetection,
                isSubscribed && settings.enableHandwritingRecognition,
              );
            },
            child: GestureDetector(
              onTapDown: (details) {
                // Handled by onPointerDown
              },
              onScaleStart: (details) {
                final settings = settingsCubit.state;
                final drawingState = drawingCubit.state;
                if (drawingState.isDrawing ||
                    _activeStrokeNotifier.value != null) {
                  return;
                }

                // If a pinch starts while we were dragging an icon, cancel icon drag
                // so the gesture can control the viewport transform.
                if (_draggingIconIndex != null &&
                    _activeTouchPointers.length >= 2) {
                  _cancelIconDrag(drawingCubit, removeIfNew: true);
                }

                _scaleBaseZoom = settings.zoomLevel;
                _scaleBasePan = settings.panOffset;
                _scaleBaseCanvasFocal =
                    (details.localFocalPoint - settings.panOffset) /
                    settings.zoomLevel;
              },
              onScaleUpdate: (details) {
                final settings = settingsCubit.state;
                final drawingState = drawingCubit.state;
                if (drawingState.isDrawing ||
                    _activeStrokeNotifier.value != null) {
                  return;
                }

                const eps = 0.001;
                final isPinch = (details.scale - 1.0).abs() > eps;

                final twoFingerGesture = _activeTouchPointers.length >= 2;

                // If the user starts pinching while dragging an icon, cancel drag and
                // let transform win.
                if (isPinch && _draggingIconIndex != null) {
                  _cancelIconDrag(drawingCubit, removeIfNew: true);
                }

                // Hand tool: 1-finger pan, 2-finger pinch (and 2-finger pan if no scale change).
                // Diagram tool: allow 2-finger pan/pinch so user can navigate while icons are active.
                final allowOneFingerPan = settings.toolMode == ToolMode.hand;
                final allowTransform = allowOneFingerPan || twoFingerGesture;
                if (!allowTransform) return;

                if (isPinch) {
                  final baseZoom = _scaleBaseZoom ?? settings.zoomLevel;
                  final baseCanvasFocal =
                      _scaleBaseCanvasFocal ??
                      ((details.localFocalPoint - settings.panOffset) /
                          settings.zoomLevel);

                  final newZoom = (baseZoom * details.scale).clamp(0.1, 5.0);
                  final newPan =
                      details.localFocalPoint - (baseCanvasFocal * newZoom);

                  settingsCubit.setTransformTransient(
                    zoomLevel: newZoom,
                    panOffset: newPan,
                  );
                } else {
                  // Only allow non-scaling pan with two fingers (or when hand tool is active).
                  if (allowOneFingerPan || twoFingerGesture) {
                    settingsCubit.updatePan(details.focalPointDelta);
                  }
                }
              },
              onScaleEnd: (details) async {
                final didTransform =
                    _scaleBaseZoom != null ||
                    _scaleBasePan != null ||
                    _scaleBaseCanvasFocal != null;
                _scaleBaseZoom = null;
                _scaleBasePan = null;
                _scaleBaseCanvasFocal = null;

                if (didTransform) {
                  await settingsCubit.persistTransform();
                }
              },
              onLongPress: () async {
                final settings = settingsCubit.state;
                final drawingState = drawingCubit.state;
                if (settings.toolMode == ToolMode.diagram) return;
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
                  final isSubscribed = context.read<EntitlementsCubit>().state.isSubscribed;
                  await _cleanupDrawing(
                    drawingCubit,
                    isSubscribed && settings.enableShapeDetection,
                    isSubscribed && settings.enableHandwritingRecognition,
                  );
                  _pendingPoint = null;
                }
              },
              child: MultiBlocListener(
                listeners: [
                  BlocListener<SettingsCubit, SettingsState>(
                    listenWhen: (prev, curr) =>
                        prev.iconSelectionNonce != curr.iconSelectionNonce,
                    listener: (context, settings) {
                      final path = settings.selectedIconPath;
                      if (settings.toolMode != ToolMode.diagram ||
                          path == null) {
                        return;
                      }
                      _autoDropSelectedIcon(
                        settings: settings,
                        drawingCubit: drawingCubit,
                        iconPath: path,
                      );
                    },
                  ),
                  BlocListener<DrawingCubit, DrawingState>(
                    listenWhen: (prev, curr) => prev.activeStrokes != curr.activeStrokes,
                    listener: (context, state) {
                      // Load SVGs for any new icon strokes
                      for (final stroke in state.activeStrokes) {
                        if (stroke.type == StrokeType.icon &&
                            stroke.iconPath != null) {
                          _loadSvg(stroke.iconPath!);
                        }
                      }
                    },
                  ),
                ],
                child: Screenshot(
                  controller: _exportService.screenshotController,
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
                            prev.strokeWidth != curr.strokeWidth ||
                            prev.strokeColor != curr.strokeColor ||
                            prev.isEraser != curr.isEraser ||
                            prev.themeMode != curr.themeMode,
                        builder: (context, settings) {
                          return BlocBuilder<DrawingCubit, DrawingState>(
                            buildWhen: (prev, curr) =>
                                prev.activeStrokes != curr.activeStrokes ||
                                prev.isDrawing != curr.isDrawing,
                            builder: (context, drawingState) {
                              return ValueListenableBuilder<Offset?>(
                                valueListenable: _hoverPositionNotifier,
                                builder: (context, hoverPos, _) {
                                  return ValueListenableBuilder<Stroke?>(
                                    valueListenable: _activeStrokeNotifier,
                                    builder: (context, activeStroke, _) {
                                      return RepaintBoundary(
                                        child: SizedBox.expand(
                                          child: CustomPaint(
                                            painter: WhiteboardPainter(
                                              strokes: drawingState.activeStrokes,
                                              activeStroke: activeStroke,
                                              pattern: BackgroundPattern.none,
                                              themeMode: settings.themeMode,
                                              hoverPosition: hoverPos,
                                              brushSize: settings.strokeWidth,
                                              brushColor: settings.strokeColor,
                                              isEraser: settings.isEraser,
                                              panOffset: settings.panOffset,
                                              zoomLevel: settings.zoomLevel,
                                              selectedStrokeIndex: drawingState.selectedStrokeIndex,
                                              svgPictures: _svgCache,
                                            ),
                                            size: Size.infinite,
                                          ),
                                        ),
                                      );
                                    },
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
          ),
        );
      },
    );
  }

  Offset _toCanvasPoint(SettingsState settings, Offset localPosition) {
    return (localPosition - settings.panOffset) / settings.zoomLevel;
  }

  void _cancelActiveStroke(DrawingCubit drawingCubit) {
    _activePointerId = null;
    _activePointerKind = null;
    _pendingPoint = null;
    _hasInitiatedWithMovement = false;
    _activeStrokeNotifier.value = null;
    drawingCubit.setDrawing(false);
  }

  void _cancelIconDrag(DrawingCubit drawingCubit, {required bool removeIfNew}) {
    final idx = _draggingIconIndex;
    if (idx == null) return;
    if (removeIfNew && _draggingIconIsNewlyPlaced) {
      drawingCubit.removeStrokeAt(idx);
    }
    _draggingIconIndex = null;
    _draggingIconDelta = Offset.zero;
    _draggingIconIsNewlyPlaced = false;
  }

  int? _hitTestIconStrokeIndex({
    required List<Stroke> strokes,
    required Offset canvasPoint,
  }) {
    // Keep in sync with icon size in WhiteboardPainter.
    const iconBaseSize = 48.0;
    for (int i = strokes.length - 1; i >= 0; i--) {
      final s = strokes[i];
      if (s.type != StrokeType.icon || s.points.isEmpty) continue;
      final c = s.points.first;
      final size = iconBaseSize * s.scale;
      final half = size / 2;
      final rect = Rect.fromLTWH(c.dx - half, c.dy - half, size, size).inflate(8);
      if (rect.contains(canvasPoint)) return i;
    }
    return null;
  }

  void _handleDiagramPointerDown({
    required Offset localPosition,
    required SettingsState settings,
    required DrawingCubit drawingCubit,
  }) {
    final canvasPoint = _toCanvasPoint(settings, localPosition);
    _hoverPositionNotifier.value = canvasPoint;

    final strokes = drawingCubit.activeStrokes;
    final hitIndex = _hitTestIconStrokeIndex(
      strokes: strokes,
      canvasPoint: canvasPoint,
    );

    if (hitIndex != null) {
      final hitStroke = strokes[hitIndex];
      _draggingIconIndex = hitIndex;
      _draggingIconDelta = canvasPoint - hitStroke.points.first;
      _draggingIconIsNewlyPlaced = false;
      return;
    }

    // If the user taps empty space in diagram mode, drop another icon at the tap.
    final iconPath = settings.selectedIconPath;
    if (iconPath == null) return;

    final newStroke = Stroke(
      points: [canvasPoint],
      color: settings.strokeColor,
      strokeWidth: settings.strokeWidth,
      type: StrokeType.icon,
      iconPath: iconPath,
    );

    final newIndex = strokes.length;
    drawingCubit.addStroke(newStroke);
    _loadSvg(iconPath);

    // Start dragging the newly placed icon immediately.
    _draggingIconIndex = newIndex;
    _draggingIconDelta = Offset.zero;
    _draggingIconIsNewlyPlaced = true;
    _activeHandle = _TransformHandle.none;
    drawingCubit.selectStroke(newIndex);
  }

  _TransformHandle _hitTestHandles(Offset canvasPoint, Stroke stroke) {
    const iconBaseSize = 48.0;
    final size = iconBaseSize * stroke.scale;
    final rect = Rect.fromCenter(
      center: stroke.points.first,
      width: size,
      height: size,
    ).inflate(4);

    const hitRadius = 24.0; // Generous hit area for touch

    // Note: handles are NOT rotated with the icon for simpler UX (fixed corners)
    if ((canvasPoint - rect.topLeft).distance < hitRadius) {
      return _TransformHandle.topLeft;
    }
    if ((canvasPoint - rect.topRight).distance < hitRadius) {
      return _TransformHandle.topRight;
    }
    if ((canvasPoint - rect.bottomLeft).distance < hitRadius) {
      return _TransformHandle.bottomLeft;
    }
    if ((canvasPoint - rect.bottomRight).distance < hitRadius) {
      return _TransformHandle.bottomRight;
    }

    final rotationPos = rect.topCenter - const Offset(0, 24);
    if ((canvasPoint - rotationPos).distance < hitRadius) {
      return _TransformHandle.rotate;
    }

    final deletePos = rect.topRight + const Offset(24, -24);
    if ((canvasPoint - deletePos).distance < hitRadius) {
      return _TransformHandle.delete;
    }

    return _TransformHandle.none;
  }

  void _autoDropSelectedIcon({
    required SettingsState settings,
    required DrawingCubit drawingCubit,
    required String iconPath,
  }) {
    final size = _lastBoardSize;
    if (size == null || size.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _autoDropSelectedIcon(
          settings: settings,
          drawingCubit: drawingCubit,
          iconPath: iconPath,
        );
      });
      return;
    }

    final localCenter = Offset(size.width / 2, size.height / 2);
    final canvasPoint = _toCanvasPoint(settings, localCenter);

    final iconStroke = Stroke(
      points: [canvasPoint],
      color: settings.strokeColor,
      strokeWidth: settings.strokeWidth,
      type: StrokeType.icon,
      iconPath: iconPath,
    );
    drawingCubit.addStroke(iconStroke);
    _loadSvg(iconPath);
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
