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
  final BackgroundPattern pattern;
  final ThemeMode themeMode;
  final Offset? hoverPosition;
  final double? brushSize;
  final Color? brushColor;
  final bool isEraser;
  final Offset panOffset;
  final double zoomLevel;
  final int? selectedStrokeIndex;
  final Map<String, PictureInfo>? svgPictures;

  WhiteboardPainter({
    required this.strokes,
    this.activeStroke,
    required this.pattern,
    required this.themeMode,
    this.hoverPosition,
    this.brushSize,
    this.brushColor,
    this.isEraser = false,
    required this.panOffset,
    required this.zoomLevel,
    this.selectedStrokeIndex,
    this.svgPictures,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Apply Transformation for strokes
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomLevel);

    // 2. Draw strokes + active stroke in ONE layer so eraser clears in real time.
    canvas.saveLayer(null, Paint());
    _drawStrokes(canvas, size, strokes);
    if (activeStroke != null) {
      _drawStrokes(canvas, size, [activeStroke!]);
    }
    canvas.restore();

    canvas.restore();

    // 4. Draw hover cursor (in screen space, on top)
    if (hoverPosition != null) {
      _drawHoverCursor(canvas, size);
    }
  }

  Color _getThemeAwareColor(Color color) {
    final isDark = themeMode == ThemeMode.dark;

    // If we're in Light Mode and the color is white/near-white, flip to black
    if (!isDark && (color == Colors.white || color.computeLuminance() > 0.9)) {
      return Colors.black;
    }

    // If we're in Dark Mode and the color is black/near-black, flip to white
    if (isDark && (color == Colors.black || color.computeLuminance() < 0.1)) {
      return Colors.white;
    }

    return color;
  }

  void _drawStrokes(Canvas canvas, Size size, List<Stroke> strokesToDraw) {
    if (strokesToDraw.isEmpty) return;

    for (int i = 0; i < strokesToDraw.length; i++) {
      final stroke = strokesToDraw[i];
      final isSelected = strokesToDraw == strokes && i == selectedStrokeIndex;
      if (stroke.points.isEmpty) continue;

      final strokeColor = _getThemeAwareColor(stroke.color);

      final paint = Paint()
        ..color = stroke.isEraser ? Colors.transparent : strokeColor
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.isEraser) {
        paint.blendMode = BlendMode.clear;
      }

      if (stroke.type == StrokeType.text && stroke.text != null) {
        _drawTextStroke(canvas, stroke, strokeColor);
      } else if (stroke.type == StrokeType.icon && stroke.iconPath != null) {
        _drawIconStroke(canvas, stroke, isSelected, strokeColor);
      } else if (stroke.points.length == 1) {
        final dotPaint = Paint()
          ..color = stroke.isEraser ? Colors.transparent : strokeColor
          ..style = PaintingStyle.fill;
        if (stroke.isEraser) dotPaint.blendMode = BlendMode.clear;
        canvas.drawCircle(
          stroke.points.first,
          stroke.strokeWidth / 2,
          dotPaint,
        );
      } else if (stroke.type == StrokeType.connector) {
        _drawConnectorStroke(canvas, stroke, strokeColor);
      } else if (stroke.type != StrokeType.pen) {
        _drawShapeStroke(canvas, stroke, strokeColor);
      } else {
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, paint);
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
    const baseSize = 48.0;
    final size = baseSize * stroke.scale;
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
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );

      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        borderPaint,
      );
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
  bool shouldRepaint(covariant WhiteboardPainter oldDelegate) => true;
}
