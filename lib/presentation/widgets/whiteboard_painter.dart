import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_state.dart';

class WhiteboardPainter extends CustomPainter {
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

  void _drawStrokes(Canvas canvas, Size size, List<Stroke> strokesToDraw) {
    if (strokesToDraw.isEmpty) return;

    for (final stroke in strokesToDraw) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.isEraser ? Colors.transparent : stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.isEraser) {
        paint.blendMode = BlendMode.clear;
      }

      if (stroke.type == StrokeType.text && stroke.text != null) {
        _drawTextStroke(canvas, stroke);
      } else if (stroke.type == StrokeType.icon && stroke.iconPath != null) {
        // Icon strokes are single-point "stamps", so handle them before the
        // generic single-point dot drawing.
        _drawIconStroke(canvas, stroke);
      } else if (stroke.points.length == 1) {
        // Draw a dot for single-point strokes
        final dotPaint = Paint()
          ..color = stroke.isEraser ? Colors.transparent : stroke.color
          ..style = PaintingStyle.fill;
        if (stroke.isEraser) dotPaint.blendMode = BlendMode.clear;
        canvas.drawCircle(
          stroke.points.first,
          stroke.strokeWidth / 2,
          dotPaint,
        );
      } else if (stroke.type == StrokeType.connector) {
        _drawConnectorStroke(canvas, stroke);
      } else if (stroke.type != StrokeType.pen) {
        _drawShapeStroke(canvas, stroke);
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

  void _drawIconStroke(Canvas canvas, Stroke stroke) {
    if (stroke.iconPath == null || stroke.points.isEmpty) return;

    final center = stroke.points.first;
    const size = 48.0; // Default icon size
    final rect = Rect.fromCenter(center: center, width: size, height: size);

    if (svgPictures != null && svgPictures!.containsKey(stroke.iconPath!)) {
      final info = svgPictures![stroke.iconPath!]!;
      final picture = info.picture;
      final pictureSize = info.size;
      if (pictureSize.isEmpty) return;

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
      // Fallback: simple box with first letter or icon-like shape
      final paint = Paint()
        ..color = stroke.color.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
      
      final borderPaint = Paint()
        ..color = stroke.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);
    }
  }

  void _drawConnectorStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color
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

  void _drawTextStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    // Calculate bounding box to determine font size
    double minX = stroke.points.first.dx, maxX = stroke.points.first.dx;
    double minY = stroke.points.first.dy, maxY = stroke.points.first.dy;

    for (final p in stroke.points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final height = maxY - minY;
    // Use the height of the handwriting as the font size, with a reasonable floor
    final fontSize = (height * 0.8).clamp(20.0, 200.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: stroke.text,
        style: TextStyle(
          color: stroke.color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Center the text vertically within the original handwriting area
    final textY = minY + (height - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(minX, textY));
  }

  void _drawShapeStroke(Canvas canvas, Stroke stroke) {
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
      ..color = stroke.color
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
    final effectiveColor = brushColor ?? Colors.blue;

    // Convert canvas hover position to screen position for drawing the cursor
    final screenPos = hoverPosition! * zoomLevel + panOffset;

    final paint = Paint()
      ..color = isEraser
          ? Colors.white.withValues(alpha: 0.22)
          : effectiveColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isEraser
          ? Colors.white.withValues(alpha: 0.7)
          : effectiveColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(screenPos, (effectiveSize * zoomLevel) / 2, paint);
    canvas.drawCircle(screenPos, (effectiveSize * zoomLevel) / 2, borderPaint);

    final dotPaint = Paint()
      ..color = isEraser
          ? Colors.white.withValues(alpha: 0.8)
          : effectiveColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final dotRadius = math.max(1.6, (effectiveSize * zoomLevel) / 18);
    canvas.drawCircle(screenPos, dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant WhiteboardPainter oldDelegate) => true;
}
