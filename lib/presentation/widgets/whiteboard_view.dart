import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_state.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';
import 'package:logic_canvas/presentation/cubits/live_drawing/live_drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/live_drawing/live_drawing_state.dart';
import 'package:logic_canvas/presentation/widgets/grid_painter.dart';
import 'package:logic_canvas/presentation/widgets/whiteboard_painter.dart';

import 'package:screenshot/screenshot.dart';
import 'package:logic_canvas/data/services/export_service.dart';
import 'package:logic_canvas/core/injection.dart';

import '../cubits/settings/settings_state.dart';

enum _TransformHandle {
  none,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  rotate,
  delete,
}

class WhiteboardView extends StatefulWidget {
  const WhiteboardView({super.key});

  @override
  State<WhiteboardView> createState() => _WhiteboardViewState();
}

class _WhiteboardViewState extends State<WhiteboardView> {
  final ExportService _exportService = getIt<ExportService>();
  final LiveDrawingCubit _liveDrawingCubit = LiveDrawingCubit();
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
  final ValueNotifier<int> _selectionRevision = ValueNotifier<int>(0);
  List<Offset>? _activeStrokePoints;
  Offset? _selectionStart;
  Offset? _selectionCurrent;
  final Set<int> _selectedStrokeIndices = <int>{};
  Rect? _selectedGroupBounds;
  bool _isDraggingSelection = false;
  bool _didMoveSelection = false;
  Offset? _selectionDragLastCanvasPoint;
  final Map<String, PictureInfo> _svgCache = {};
  int _debugMoveCount = 0;
  int? _debugLastMoveMicros;

  @override
  void dispose() {
    _liveDrawingCubit.close();
    _selectionRevision.dispose();
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
          child: BlocProvider.value(
            value: _liveDrawingCubit,
            child: Listener(
              onPointerHover: (event) {
                final settings = settingsCubit.state;
                if (settings.toolMode != ToolMode.hand) {
                  final canvasPoint = _toCanvasPoint(
                    settings,
                    event.localPosition,
                  );
                  _liveDrawingCubit.updateHover(canvasPoint);
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

                if (settings.toolMode != ToolMode.hand) {
                  // Recover from any stuck state (missed onPointerUp/Cancel or
                  // drawingCubit.isDrawing stuck at true after a failed cleanup).
                  if (_activePointerId != null || drawingState.isDrawing) {
                    _cancelActiveStroke(drawingCubit);
                  }

                  _activePointerId = event.pointer;
                  _activePointerKind = event.kind;
                  _pendingPoint = event.localPosition;
                  _hasInitiatedWithMovement = false;

                  if (settings.toolMode == ToolMode.select) {
                    _handleSelectionPointerDown(
                      canvasPoint: _toCanvasPoint(
                        settings,
                        event.localPosition,
                      ),
                    );
                    _pendingPoint = null;
                    return;
                  }

                  if (settings.toolMode == ToolMode.diagram) {
                    final canvasPoint = _toCanvasPoint(
                      settings,
                      event.localPosition,
                    );

                    // 1. Check if we hit a handle of already selected icon
                    if (drawingState.selectedStrokeIndex != null &&
                        drawingState.selectedStrokeIndex! <
                            drawingState.activeStrokes.length) {
                      final stroke = drawingState
                          .activeStrokes[drawingState.selectedStrokeIndex!];
                      if (stroke.type == StrokeType.icon) {
                        final handle = _hitTestHandles(canvasPoint, stroke);
                        if (handle == _TransformHandle.delete) {
                          drawingCubit.removeStrokeAt(
                            drawingState.selectedStrokeIndex!,
                          );
                          _activePointerId = null;
                          _activePointerKind = null;
                          return;
                        }
                        if (handle != _TransformHandle.none) {
                          _activeHandle = handle;
                          _draggingIconIndex = drawingState.selectedStrokeIndex;
                          _initialScale = stroke.scale;
                          _initialRotation = stroke.rotation;
                          _initialHandleOffset =
                              canvasPoint - stroke.points.first;
                          _initialAngle =
                              (canvasPoint - stroke.points.first).direction;
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
              },
              onPointerMove: (event) {
                if (event.pointer != _activePointerId) return;

                final settings = settingsCubit.state;
                if (settings.toolMode == ToolMode.hand) return;

                final canvasPoint = _toCanvasPoint(
                  settings,
                  event.localPosition,
                );

                if (settings.toolMode == ToolMode.select) {
                  _liveDrawingCubit.updateHover(canvasPoint);
                  _handleSelectionPointerMove(
                    canvasPoint: canvasPoint,
                    drawingCubit: drawingCubit,
                  );
                  return;
                }

                if (_draggingIconIndex != null) {
                  if (_activeTouchPointers.length >= 2) return;
                  final idx = _draggingIconIndex!;
                  if (idx < 0 || idx >= drawingCubit.activeStrokes.length)
                    return;
                  final s = drawingCubit.activeStrokes[idx];

                  if (_activeHandle == _TransformHandle.none) {
                    // Standard Drag
                    final updated = s.copyWith(
                      points: [canvasPoint - _draggingIconDelta],
                    );
                    drawingCubit.updateStrokeAt(idx, updated);
                  } else if (_activeHandle == _TransformHandle.rotate) {
                    // Rotation logic
                    final currentAngle =
                        (canvasPoint - s.points.first).direction;
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

                final currentStroke = _liveDrawingCubit.state.activeStroke;
                if (currentStroke != null) {
                  if (currentStroke.type == StrokeType.connector &&
                      currentStroke.points.isNotEmpty) {
                    final start = currentStroke.points.first;
                    Offset snappedPoint = canvasPoint;

                    const double snapThreshold = 20.0;
                    final dx = (canvasPoint.dx - start.dx).abs();
                    final dy = (canvasPoint.dy - start.dy).abs();

                    if (dy < snapThreshold) {
                      snappedPoint = Offset(canvasPoint.dx, start.dy);
                    } else if (dx < snapThreshold) {
                      snappedPoint = Offset(start.dx, canvasPoint.dy);
                    }

                    final points = _activeStrokePoints;
                    if (points != null) {
                      if (points.length == 1) {
                        points.add(snappedPoint);
                      } else {
                        points[1] = snappedPoint;
                      }
                      _liveDrawingCubit.notifyChange();
                    }
                  } else {
                    final points = _activeStrokePoints;
                    if (points != null && points.isNotEmpty) {
                      final lastPoint = points.last;
                      final distance = (canvasPoint - lastPoint).distance;
                      if (distance >= 2.0 && points.length < 2000) {
                        points.add(canvasPoint);
                        _liveDrawingCubit.notifyChange();
                      }
                    }
                  }
                }
              },
              onPointerUp: (event) {
                if (event.kind == PointerDeviceKind.touch) {
                  _activeTouchPointers.remove(event.pointer);
                }
                if (event.pointer != _activePointerId) return;
                _activePointerId = null;
                _activePointerKind = null;

                if (settingsCubit.state.toolMode == ToolMode.select) {
                  _handleSelectionPointerUp(drawingCubit);
                  return;
                }

                if (_draggingIconIndex != null) {
                  _draggingIconIndex = null;
                  _draggingIconDelta = Offset.zero;
                  drawingCubit.persistState();
                  return;
                }

                final settings = settingsCubit.state;
                final now = _nowMicros;
                final sinceLastMoveMs = _debugLastMoveMicros == null
                    ? 'n/a'
                    : ((now - _debugLastMoveMicros!) / 1000).toStringAsFixed(1);
                _inkLog(
                  'up kind=${event.kind.name} moves=$_debugMoveCount points=${_activeStrokePoints?.length ?? 0} local=${_pointLabel(event.localPosition)} msSinceLastMove=$sinceLastMoveMs',
                );
                _appendFinalPointerPoint(settings, event.localPosition);
                final isSubscribed = context
                    .read<EntitlementsCubit>()
                    .state
                    .isSubscribed;
                _scheduleDrawingCleanup(
                  drawingCubit,
                  isSubscribed && settings.enableShapeDetection,
                  isSubscribed && settings.enableHandwritingRecognition,
                );
              },
              onPointerCancel: (event) {
                if (event.kind == PointerDeviceKind.touch) {
                  _activeTouchPointers.remove(event.pointer);
                }
                if (event.pointer != _activePointerId) return;
                _activePointerId = null;
                _activePointerKind = null;

                if (settingsCubit.state.toolMode == ToolMode.select) {
                  _handleSelectionPointerUp(drawingCubit);
                  return;
                }

                if (_draggingIconIndex != null) {
                  _draggingIconIndex = null;
                  _draggingIconDelta = Offset.zero;
                  drawingCubit.persistState();
                  return;
                }

                final settings = settingsCubit.state;
                _appendFinalPointerPoint(settings, event.localPosition);
                final isSubscribed = context
                    .read<EntitlementsCubit>()
                    .state
                    .isSubscribed;
                _scheduleDrawingCleanup(
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
                      _liveDrawingCubit.state.activeStroke != null) {
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
                      _liveDrawingCubit.state.activeStroke != null) {
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
                    final isSubscribed = context
                        .read<EntitlementsCubit>()
                        .state
                        .isSubscribed;
                    _scheduleDrawingCleanup(
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
                      listenWhen: (prev, curr) =>
                          prev.activeStrokes != curr.activeStrokes,
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

                        // 2. History Layer: Completed strokes. This layer should
                        // not repaint for every active pen sample.
                        BlocBuilder<SettingsCubit, SettingsState>(
                          buildWhen: (prev, curr) =>
                              prev.panOffset != curr.panOffset ||
                              prev.zoomLevel != curr.zoomLevel ||
                              prev.themeMode != curr.themeMode,
                          builder: (context, settings) {
                            return BlocBuilder<DrawingCubit, DrawingState>(
                              buildWhen: (prev, curr) =>
                                  prev.activeStrokes != curr.activeStrokes ||
                                  prev.selectedStrokeIndex !=
                                      curr.selectedStrokeIndex,
                              builder: (context, drawingState) {
                                return BlocBuilder<
                                  LiveDrawingCubit,
                                  LiveDrawingState
                                >(
                                  buildWhen: (prev, curr) =>
                                      prev.activeStroke != curr.activeStroke,
                                  builder: (context, liveState) {
                                    if (liveState.activeStroke?.isEraser ??
                                        false) {
                                      return const SizedBox.shrink();
                                    }

                                    return RepaintBoundary(
                                      child: SizedBox.expand(
                                        child: CustomPaint(
                                          painter: WhiteboardPainter(
                                            strokes: drawingState.activeStrokes,
                                            activeStroke: null,
                                            pattern: BackgroundPattern.none,
                                            themeMode: settings.themeMode,
                                            panOffset: settings.panOffset,
                                            zoomLevel: settings.zoomLevel,
                                            selectedStrokeIndex: drawingState
                                                .selectedStrokeIndex,
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
                        ),

                        // 3. Live Layer: active stroke, cursor, and selection
                        // overlays. During normal pen drawing, only this lightweight
                        // layer repaints for each pointer sample.
                        BlocBuilder<SettingsCubit, SettingsState>(
                          buildWhen: (prev, curr) =>
                              prev.panOffset != curr.panOffset ||
                              prev.zoomLevel != curr.zoomLevel ||
                              prev.strokeWidth != curr.strokeWidth ||
                              prev.strokeColor != curr.strokeColor ||
                              prev.isEraser != curr.isEraser ||
                              prev.themeMode != curr.themeMode ||
                              prev.toolMode != curr.toolMode,
                          builder: (context, settings) {
                            return BlocBuilder<
                              LiveDrawingCubit,
                              LiveDrawingState
                            >(
                              builder: (context, liveState) {
                                return BlocBuilder<DrawingCubit, DrawingState>(
                                  buildWhen: (prev, curr) =>
                                      prev.activeStrokes != curr.activeStrokes,
                                  builder: (context, drawingState) {
                                    final isLiveEraser =
                                        liveState.activeStroke?.isEraser ??
                                        false;

                                    return RepaintBoundary(
                                      child: SizedBox.expand(
                                        child: CustomPaint(
                                          painter: WhiteboardPainter(
                                            strokes: isLiveEraser
                                                ? drawingState.activeStrokes
                                                : const <Stroke>[],
                                            activeStroke:
                                                liveState.activeStroke,
                                            activeStrokeRevision:
                                                liveState.revision,
                                            pattern: BackgroundPattern.none,
                                            themeMode: settings.themeMode,
                                            hoverPosition:
                                                liveState.hoverPosition,
                                            brushSize: settings.strokeWidth,
                                            brushColor: settings.strokeColor,
                                            isEraser: settings.isEraser,
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
                            );
                          },
                        ),
                      ],
                    ),
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

  int get _nowMicros => DateTime.now().microsecondsSinceEpoch;

  String _pointLabel(Offset point) {
    return '(${point.dx.toStringAsFixed(1)}, ${point.dy.toStringAsFixed(1)})';
  }

  void _inkLog(String message) {
    // debugPrint('INK $_debugStrokeId: $message');
  }

  Rect? get _currentSelectionRect {
    final start = _selectionStart;
    final current = _selectionCurrent;
    if (start == null || current == null) return null;
    return Rect.fromPoints(start, current);
  }

  void _handleSelectionPointerDown({required Offset canvasPoint}) {
    if (_selectedGroupBounds?.inflate(12).contains(canvasPoint) ?? false) {
      _isDraggingSelection = true;
      _didMoveSelection = false;
      _selectionDragLastCanvasPoint = canvasPoint;
      _selectionStart = null;
      _selectionCurrent = null;
    } else {
      _isDraggingSelection = false;
      _didMoveSelection = false;
      _selectionDragLastCanvasPoint = null;
      _selectionStart = canvasPoint;
      _selectionCurrent = canvasPoint;
      _selectedStrokeIndices.clear();
      _selectedGroupBounds = null;
    }
    _selectionRevision.value++;
  }

  void _handleSelectionPointerMove({
    required Offset canvasPoint,
    required DrawingCubit drawingCubit,
  }) {
    if (_isDraggingSelection) {
      final lastPoint = _selectionDragLastCanvasPoint;
      if (lastPoint == null) return;

      final delta = canvasPoint - lastPoint;
      if (delta == Offset.zero) return;

      drawingCubit.moveStrokesBy(_selectedStrokeIndices, delta);
      _selectedGroupBounds = _selectedGroupBounds?.shift(delta);
      _selectionDragLastCanvasPoint = canvasPoint;
      _didMoveSelection = true;
      _selectionRevision.value++;
      return;
    }

    if (_selectionStart != null) {
      _selectionCurrent = canvasPoint;
      _selectionRevision.value++;
    }
  }

  void _handleSelectionPointerUp(DrawingCubit drawingCubit) {
    if (_isDraggingSelection) {
      _isDraggingSelection = false;
      _selectionDragLastCanvasPoint = null;
      if (_didMoveSelection) {
        drawingCubit.persistState();
      }
      _didMoveSelection = false;
      _selectionRevision.value++;
      return;
    }

    final selectionRect = _currentSelectionRect;
    _selectionStart = null;
    _selectionCurrent = null;

    if (selectionRect == null ||
        selectionRect.width.abs() < 4 ||
        selectionRect.height.abs() < 4) {
      _selectedStrokeIndices.clear();
      _selectedGroupBounds = null;
      _selectionRevision.value++;
      return;
    }

    final rect = _normalizeRect(selectionRect);
    final selected = <int>{};
    Rect? groupBounds;
    final strokes = drawingCubit.activeStrokes;
    for (int i = 0; i < strokes.length; i++) {
      final bounds = _strokeBounds(strokes[i]);
      if (bounds == null || !rect.overlaps(bounds)) continue;
      selected.add(i);
      groupBounds = groupBounds == null
          ? bounds
          : groupBounds.expandToInclude(bounds);
    }

    _selectedStrokeIndices
      ..clear()
      ..addAll(selected);
    _selectedGroupBounds = groupBounds;
    drawingCubit.selectStroke(null);
    _selectionRevision.value++;
  }

  void _appendFinalPointerPoint(SettingsState settings, Offset localPosition) {
    final activeStroke = _liveDrawingCubit.state.activeStroke;
    final points = _activeStrokePoints;
    if (activeStroke == null || points == null || points.isEmpty) return;

    if (activeStroke.type != StrokeType.connector) {
      _inkLog('final pointer ignored for ${activeStroke.type.name}');
      return;
    }

    final canvasPoint = _toCanvasPoint(settings, localPosition);
    final start = points.first;
    Offset snappedPoint = canvasPoint;
    const double snapThreshold = 20.0;
    final dx = (canvasPoint.dx - start.dx).abs();
    final dy = (canvasPoint.dy - start.dy).abs();
    if (dy < snapThreshold) {
      snappedPoint = Offset(canvasPoint.dx, start.dy);
    } else if (dx < snapThreshold) {
      snappedPoint = Offset(start.dx, canvasPoint.dy);
    }

    if (points.length == 1) {
      points.add(snappedPoint);
    } else {
      points[1] = snappedPoint;
    }
    _liveDrawingCubit.notifyChange();
    _inkLog(
      'connector final point applied points=${points.length} revision=${_liveDrawingCubit.state.revision}',
    );
  }

  Rect _normalizeRect(Rect rect) {
    return Rect.fromLTRB(
      math.min(rect.left, rect.right),
      math.min(rect.top, rect.bottom),
      math.max(rect.left, rect.right),
      math.max(rect.top, rect.bottom),
    );
  }

  Rect? _strokeBounds(Stroke stroke) {
    if (stroke.points.isEmpty) return null;

    if (stroke.type == StrokeType.icon) {
      const iconBaseSize = 48.0;
      final size = iconBaseSize * stroke.scale;
      return Rect.fromCenter(
        center: stroke.points.first,
        width: size,
        height: size,
      ).inflate(8);
    }

    if (stroke.type == StrokeType.text && stroke.points.length == 1) {
      return Rect.fromLTWH(
        stroke.points.first.dx,
        stroke.points.first.dy,
        600,
        120,
      );
    }

    double minX = stroke.points.first.dx;
    double maxX = stroke.points.first.dx;
    double minY = stroke.points.first.dy;
    double maxY = stroke.points.first.dy;

    for (final point in stroke.points) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    return Rect.fromLTRB(
      minX,
      minY,
      maxX,
      maxY,
    ).inflate(math.max(stroke.strokeWidth / 2, 6));
  }

  void _cancelActiveStroke(DrawingCubit drawingCubit) {
    _activePointerId = null;
    _activePointerKind = null;
    _pendingPoint = null;
    _hasInitiatedWithMovement = false;
    _liveDrawingCubit.cancel();
    _activeStrokePoints = null;
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
      final rect = Rect.fromLTWH(
        c.dx - half,
        c.dy - half,
        size,
        size,
      ).inflate(8);
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
    _liveDrawingCubit.updateHover(canvasPoint);

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

  void _scheduleDrawingCleanup(
    DrawingCubit drawingCubit,
    bool enableShapeDetection,
    bool enableHandwriting,
  ) {
    final activeStroke = _liveDrawingCubit.state.activeStroke;
    if (activeStroke == null) return; // Already cleaned up

    final finalStroke = activeStroke.copyWith(
      points: List<Offset>.from(_activeStrokePoints ?? activeStroke.points),
    );

    _inkLog(
      'cleanup scheduled type=${finalStroke.type.name} points=${finalStroke.points.length} shape=$enableShapeDetection handwriting=$enableHandwriting',
    );

    _pendingPoint = null;
    _hasInitiatedWithMovement = false;

    // Commit before another pointer-down can start a new stroke. The cleanup
    // itself keeps the live overlay until the committed layer has rendered.
    unawaited(
      _cleanupDrawing(
        drawingCubit,
        activeStroke,
        finalStroke,
        enableShapeDetection,
        enableHandwriting,
      ),
    );
  }

  Future<void> _cleanupDrawing(
    DrawingCubit drawingCubit,
    Stroke activeStrokeRef,
    Stroke finalStroke,
    bool enableShapeDetection,
    bool enableHandwriting,
  ) async {
    final cleanupStart = _nowMicros;

    _inkLog(
      'cleanup begin type=${finalStroke.type.name} points=${finalStroke.points.length} shape=$enableShapeDetection handwriting=$enableHandwriting',
    );

    try {
      // Commit the completed stroke to the Cubit
      await drawingCubit.endStroke(
        finalStroke,
        enableShapeDetection,
        enableHandwriting: enableHandwriting,
      );
    } catch (e) {
      _inkLog('cleanup commit error: $e');
    }

    _inkLog('commit returned; waiting for history layer frame');
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    if (identical(_liveDrawingCubit.state.activeStroke, activeStrokeRef)) {
      _liveDrawingCubit.endStroke();
      _activeStrokePoints = null;
    } else {
      _inkLog('live layer kept because another stroke started');
    }
    _pendingPoint = null;
    _hasInitiatedWithMovement = false;

    final cleanupMs = ((_nowMicros - cleanupStart) / 1000).toStringAsFixed(1);
    _inkLog('cleanup complete after ${cleanupMs}ms');

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
    _debugMoveCount = 0;
    _debugLastMoveMicros = null;

    // Create new active stroke
    final points = <Offset>[canvasPoint];
    _activeStrokePoints = points;

    final newStroke = Stroke(
      points: points,
      color: settings.isEraser ? Colors.transparent : settings.strokeColor,
      strokeWidth: settings.strokeWidth,
      isEraser: settings.isEraser,
      type: settings.toolMode == ToolMode.connector
          ? StrokeType.connector
          : StrokeType.pen,
    );

    _inkLog(
      'start kind=$_activePointerKind mode=${settings.toolMode.name} width=${settings.strokeWidth} canvas=${_pointLabel(canvasPoint)}',
    );
    _liveDrawingCubit.startStroke(newStroke, canvasPoint);
    drawingCubit.startStroke();
  }
}
