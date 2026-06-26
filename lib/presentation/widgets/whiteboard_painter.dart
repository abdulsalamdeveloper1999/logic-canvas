import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_state.dart';

class WhiteboardPainter extends CustomPainter {
  static const double _autoFormattedTextFontSize = 28.0;
  static const double _gridStep = 20.0;

  final List<Stroke> strokes;
  final Stroke? activeStroke;
  final int activeStrokeRevision;
  final BackgroundPattern pattern;
  final ThemeMode themeMode;
  final Offset? hoverPosition;
  final double? brushSize;
  final Color? brushColor;
  final bool isEraser;
  final Offset panOffset;
  final double zoomLevel;
  final int? selectedStrokeIndex;
  final Rect? selectionRect;
  final Rect? selectedGroupBounds;
  final Map<String, PictureInfo>? svgPictures;

  WhiteboardPainter({
    super.repaint,
    required this.strokes,
    this.activeStroke,
    this.activeStrokeRevision = 0,
    required this.pattern,
    required this.themeMode,
    this.hoverPosition,
    this.brushSize,
    this.brushColor,
    this.isEraser = false,
    required this.panOffset,
    required this.zoomLevel,
    this.selectedStrokeIndex,
    this.selectionRect,
    this.selectedGroupBounds,
    this.svgPictures,
  });

  Paint _getStrokePaint(Color color, double width, bool isEraser) {
    return Paint()
      ..color = isEraser ? Colors.transparent : color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver;
  }

  Paint _getDotPaint(Color color, bool isEraser) {
    return Paint()
      ..color = isEraser ? Colors.transparent : color
      ..style = PaintingStyle.fill
      ..blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Isolate BlendMode.clear so it doesn't punch a hole through the background grid.
    final hasEraser =
        strokes.any((s) => s.isEraser) || (activeStroke?.isEraser ?? false);
    if (hasEraser) {
      canvas.saveLayer(Offset.zero & size, Paint());
    }

    // 1. Apply Transformation for strokes
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomLevel);

    _drawStrokes(canvas, size, strokes, isActive: false);
    if (activeStroke != null) {
      _drawStrokes(
        canvas,
        size,
        [activeStroke!],
        isActive: true,
      );
    }

    if (selectionRect != null) {
      _drawSelectionOverlay(canvas, selectionRect!, fill: true);
    }
    if (selectedGroupBounds != null) {
      _drawSelectionOverlay(canvas, selectedGroupBounds!, fill: false);
    }

    canvas.restore();

    // 4. Draw hover cursor (in screen space, on top)
    if (hoverPosition != null) {
      _drawHoverCursor(canvas, size);
    }

    if (hasEraser) {
      canvas.restore();
    }
  }

  void _drawSelectionOverlay(Canvas canvas, Rect rect, {required bool fill}) {
    final normalized = Rect.fromLTRB(
      math.min(rect.left, rect.right),
      math.min(rect.top, rect.bottom),
      math.max(rect.left, rect.right),
      math.max(rect.top, rect.bottom),
    );
    final strokeWidth = 1.5 / zoomLevel.clamp(0.1, 5.0);
    final color = themeMode == ThemeMode.dark
        ? Colors.lightBlueAccent
        : Colors.blueAccent;

    if (fill) {
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill;
      canvas.drawRect(normalized, fillPaint);
    }

    final borderPaint = Paint()
      ..color = color.withValues(alpha: fill ? 0.9 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRect(normalized, borderPaint);
  }

  Color _getThemeAwareColor(Color color) {
    final isDark = themeMode == ThemeMode.dark;

    if (!isDark && (color == Colors.white || color.computeLuminance() > 0.9)) {
      return Colors.black;
    } else if (isDark &&
        (color == Colors.black || color.computeLuminance() < 0.1)) {
      return Colors.white;
    } else {
      return color;
    }
  }

  void _drawStrokes(
    Canvas canvas,
    Size size,
    List<Stroke> strokesToDraw, {
    bool isActive = false,
  }) {
    if (strokesToDraw.isEmpty) return;

    for (int i = 0; i < strokesToDraw.length; i++) {
      final stroke = strokesToDraw[i];
      final points = stroke.points;
      if (points.isEmpty) continue;

      bool isSelected = false;
      if (selectedStrokeIndex != null) {
        if (identical(strokesToDraw, strokes)) {
          isSelected = i == selectedStrokeIndex;
        } else {
          isSelected = strokes.indexOf(stroke) == selectedStrokeIndex;
        }
      }

      final strokeColor = _getThemeAwareColor(
        isSelected ? Colors.blue : stroke.color,
      );
      final strokePaint = _getStrokePaint(
        strokeColor,
        stroke.strokeWidth,
        stroke.isEraser,
      );

      if (stroke.type == StrokeType.text && stroke.text != null) {
        _drawTextStroke(canvas, stroke, strokeColor);
      } else if (stroke.type == StrokeType.icon && stroke.iconPath != null) {
        _drawIconStroke(canvas, stroke, isSelected, strokeColor);
      } else if (points.length == 1) {
        final dotPaint = _getDotPaint(strokeColor, stroke.isEraser);
        canvas.drawCircle(points.first, stroke.strokeWidth / 2, dotPaint);
      } else if (stroke.type == StrokeType.connector) {
        _drawConnectorStroke(canvas, stroke, strokeColor);
      } else if (stroke.type != StrokeType.pen) {
        _drawShapeStroke(canvas, stroke, strokeColor);
      } else {
        if (isActive) {
          for (int j = 0; j < points.length - 1; j++) {
            canvas.drawLine(points[j], points[j + 1], strokePaint);
          }
        } else {
          final path = Path();
          if (points.isNotEmpty) {
            path.moveTo(points.first.dx, points.first.dy);
            for (int j = 1; j < points.length; j++) {
              path.lineTo(points[j].dx, points[j].dy);
            }
          }
          canvas.drawPath(path, strokePaint);
        }
      }
    }
  }

  void _drawIconStroke(
    Canvas canvas,
    Stroke stroke,
    bool isSelected,
    Color color,
  ) {
    if (stroke.iconPath == null || stroke.points.isEmpty) return;

    final center = stroke.points.first;
    if (!center.dx.isFinite ||
        !center.dy.isFinite ||
        !stroke.scale.isFinite ||
        !stroke.rotation.isFinite) {
      return;
    }

    const baseSize = 48.0;
    final size = (baseSize * stroke.scale.abs()).clamp(4.0, 4096.0);
    final rect = Rect.fromCenter(center: center, width: size, height: size);

    canvas.save();
    // 1. Apply Rotation around center
    canvas.translate(center.dx, center.dy);
    canvas.rotate(stroke.rotation);
    canvas.translate(-center.dx, -center.dy);

    if (svgPictures != null && svgPictures!.containsKey(stroke.iconPath!)) {
      final info = svgPictures![stroke.iconPath!]!;
      final picture = info.picture;
      final pictureSize = info.size;
      if (pictureSize.isEmpty) {
        canvas.restore();
        return;
      }

      final scale = math.min(
        rect.width / pictureSize.width,
        rect.height / pictureSize.height,
      );
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.scale(scale, scale);
      canvas.translate(-pictureSize.width / 2, -pictureSize.height / 2);
      canvas.drawPicture(picture);
      canvas.restore();
    } else {
      // Fallback: simple box
      final paint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);

      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(rect, borderPaint);
    }

    if (isSelected) {
      _drawSelectionHandles(canvas, rect, color);
    }

    canvas.restore();
  }

  void _drawSelectionHandles(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw bounding box
    canvas.drawRect(rect.inflate(4), paint);

    // Draw handles at corners
    final handlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const handleSize = 8.0;
    final corners = [
      rect.inflate(4).topLeft,
      rect.inflate(4).topRight,
      rect.inflate(4).bottomLeft,
      rect.inflate(4).bottomRight,
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, handleSize / 2, handlePaint);
      canvas.drawCircle(
        corner,
        handleSize / 2,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Draw rotation handle
    final rotationHandlePos = rect.inflate(4).topCenter - const Offset(0, 24);
    canvas.drawLine(rect.inflate(4).topCenter, rotationHandlePos, paint);
    canvas.drawCircle(rotationHandlePos, handleSize / 2, handlePaint);
    canvas.drawCircle(
      rotationHandlePos,
      handleSize / 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Draw delete handle
    final deleteHandlePos = rect.inflate(4).topRight + const Offset(24, -24);
    final deletePaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(deleteHandlePos, handleSize / 1.2, deletePaint);
    canvas.drawCircle(
      deleteHandlePos,
      handleSize / 1.2,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Draw white X in the red circle
    final xPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const xSize = 4.0;
    canvas.drawLine(
      deleteHandlePos + const Offset(-xSize, -xSize),
      deleteHandlePos + const Offset(xSize, xSize),
      xPaint,
    );
    canvas.drawLine(
      deleteHandlePos + const Offset(xSize, -xSize),
      deleteHandlePos + const Offset(-xSize, xSize),
      xPaint,
    );
  }

  void _drawConnectorStroke(Canvas canvas, Stroke stroke, Color color) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final start = stroke.points.first;
    final end = stroke.points.last;

    // Draw straight line for connector
    canvas.drawLine(start, end, paint);

    // Draw arrow head at the end
    final angle = (end - start).direction;
    const arrowSize = 15.0;
    const arrowAngle = 0.5; // radians

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - arrowAngle),
        end.dy - arrowSize * math.sin(angle - arrowAngle),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + arrowAngle),
        end.dy - arrowSize * math.sin(angle + arrowAngle),
      );

    canvas.drawPath(path, paint);
  }

  void _drawTextStroke(Canvas canvas, Stroke stroke, Color color) {
    if (stroke.points.isEmpty) return;

    // Calculate bounding box for placement and wrapping.
    double minX = stroke.points.first.dx, maxX = stroke.points.first.dx;
    double minY = stroke.points.first.dy, maxY = stroke.points.first.dy;

    for (final p in stroke.points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final height = maxY - minY;

    final textPainter = TextPainter(
      text: TextSpan(
        text: stroke.text,
        style: TextStyle(
          color: color,
          fontSize: _autoFormattedTextFontSize,
          fontWeight: FontWeight.w500,
          // Use a clean handwriting font known to be available on iOS/macOS
          fontFamily: 'Noteworthy',
          package: null,
          fontFamilyFallback: const [
            'Chalkboard SE',
            'Marker Felt',
            'Apple SD Gothic Neo',
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    // Support wrapping for description-style text
    final maxWidth = stroke.points.length <= 1
        ? 600.0
        : (maxX - minX).clamp(100.0, 1000.0);
    textPainter.layout(maxWidth: maxWidth);

    // For single-point description text, use minY as the top.
    // Otherwise, center vertically only when the handwriting area is taller than the text.
    double textY = height < textPainter.height
        ? minY
        : minY + (height - textPainter.height) / 2;

    final metrics = textPainter.computeLineMetrics();
    if (metrics.isNotEmpty) {
      final firstLineBaseline = stroke.points.length <= 1
          ? textY + metrics.first.baseline
          : _estimateHandwritingBaseline(stroke.points, minY, maxY);
      final snappedBaseline =
          (firstLineBaseline / _gridStep).round() * _gridStep;
      textY = snappedBaseline - metrics.first.baseline;
    }

    textPainter.paint(canvas, Offset(minX, textY));
  }

  double _estimateHandwritingBaseline(
    List<Offset> points,
    double minY,
    double maxY,
  ) {
    if (points.length < 3) return maxY;

    final sortedY = points.map((point) => point.dy).toList()..sort();
    final lowerIndex = ((sortedY.length - 1) * 0.72).round();
    final upperIndex = ((sortedY.length - 1) * 0.88).round();
    final lower = sortedY[lowerIndex.clamp(0, sortedY.length - 1)];
    final upper = sortedY[upperIndex.clamp(0, sortedY.length - 1)];

    // Average a trimmed lower band to reduce the effect of descenders and stray points.
    final baselineBand = sortedY
        .where((y) => y >= lower && y <= upper)
        .toList(growable: false);
    if (baselineBand.isEmpty) {
      return maxY;
    }

    final baseline =
        baselineBand.reduce((sum, y) => sum + y) / baselineBand.length;
    return baseline.clamp(minY, maxY);
  }

  void _drawShapeStroke(Canvas canvas, Stroke stroke, Color color) {
    if (stroke.points.isEmpty) return;

    double minX = stroke.points.first.dx, maxX = stroke.points.first.dx;
    double minY = stroke.points.first.dy, maxY = stroke.points.first.dy;

    for (final p in stroke.points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final rect = Rect.fromLTRB(minX, minY, maxX, maxY);
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke;

    switch (stroke.type) {
      case StrokeType.circle:
        canvas.drawOval(rect, paint);
        break;
      case StrokeType.rectangle:
        canvas.drawRect(rect, paint);
        break;
      case StrokeType.triangle:
        final path = Path()
          ..moveTo(rect.centerLeft.dx, rect.bottom)
          ..lineTo(rect.topCenter.dx, rect.top)
          ..lineTo(rect.centerRight.dx, rect.bottom)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case StrokeType.diamond:
        final path = Path()
          ..moveTo(rect.centerLeft.dx, rect.centerLeft.dy)
          ..lineTo(rect.topCenter.dx, rect.topCenter.dy)
          ..lineTo(rect.centerRight.dx, rect.centerRight.dy)
          ..lineTo(rect.bottomCenter.dx, rect.bottomCenter.dy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      default:
        break;
    }
  }

  void _drawHoverCursor(Canvas canvas, Size size) {
    final effectiveSize = brushSize ?? 10.0;
    final effectiveColor = _getThemeAwareColor(brushColor ?? Colors.blue);

    // Convert canvas hover position to screen position for drawing the cursor
    final screenPos = hoverPosition! * zoomLevel + panOffset;

    final isDark = themeMode == ThemeMode.dark;
    final cursorColor = isDark ? Colors.white : Colors.black;

    final paint = Paint()
      ..color = isEraser
          ? cursorColor.withValues(alpha: 0.22)
          : effectiveColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isEraser
          ? cursorColor.withValues(alpha: 0.7)
          : effectiveColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(screenPos, (effectiveSize * zoomLevel) / 2, paint);
    canvas.drawCircle(screenPos, (effectiveSize * zoomLevel) / 2, borderPaint);

    final dotPaint = Paint()
      ..color = isEraser
          ? cursorColor.withValues(alpha: 0.8)
          : effectiveColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final dotRadius = math.max(1.6, (effectiveSize * zoomLevel) / 18);
    canvas.drawCircle(screenPos, dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant WhiteboardPainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        activeStroke != oldDelegate.activeStroke ||
        activeStrokeRevision != oldDelegate.activeStrokeRevision ||
        panOffset != oldDelegate.panOffset ||
        zoomLevel != oldDelegate.zoomLevel ||
        hoverPosition != oldDelegate.hoverPosition ||
        brushSize != oldDelegate.brushSize ||
        brushColor != oldDelegate.brushColor ||
        isEraser != oldDelegate.isEraser ||
        themeMode != oldDelegate.themeMode ||
        selectedStrokeIndex != oldDelegate.selectedStrokeIndex ||
        selectionRect != oldDelegate.selectionRect ||
        selectedGroupBounds != oldDelegate.selectedGroupBounds;
  }
}
