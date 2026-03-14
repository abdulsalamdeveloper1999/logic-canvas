import 'package:flutter/material.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_state.dart';

class GridPainter extends CustomPainter {
  final BackgroundPattern pattern;
  final Offset panOffset;
  final double zoomLevel;
  final ThemeMode themeMode;

  GridPainter({
    required this.pattern,
    required this.panOffset,
    required this.zoomLevel,
    required this.themeMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == BackgroundPattern.none) return;

    final majorPaint = Paint()
      ..color = Colors.grey.withValues(alpha: themeMode == ThemeMode.dark ? 0.15 : 0.2)
      ..strokeWidth = 1.0;

    final minorPaint = Paint()
      ..color = Colors.grey.withValues(alpha: (themeMode == ThemeMode.dark ? 0.05 : 0.08) * zoomLevel.clamp(0.5, 1.0))
      ..strokeWidth = 0.5;

    final double majorStep = 100.0 * zoomLevel;
    final double minorStep = 20.0 * zoomLevel;
    
    // Calculate the start positions based on panOffset
    final double majorStartX = panOffset.dx % majorStep;
    final double majorStartY = panOffset.dy % majorStep;
    final double minorStartX = panOffset.dx % minorStep;
    final double minorStartY = panOffset.dy % minorStep;

    if (pattern == BackgroundPattern.grid) {
      // 1. Draw Minor Grid
      if (zoomLevel > 0.6) {
        for (double i = minorStartX; i < size.width; i += minorStep) {
          canvas.drawLine(Offset(i, 0), Offset(i, size.height), minorPaint);
        }
        for (double i = minorStartY; i < size.height; i += minorStep) {
          canvas.drawLine(Offset(0, i), Offset(size.width, i), minorPaint);
        }
      }

      // 2. Draw Major Grid
      for (double i = majorStartX; i < size.width; i += majorStep) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), majorPaint);
      }
      for (double i = majorStartY; i < size.height; i += majorStep) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), majorPaint);
      }
    } else if (pattern == BackgroundPattern.lines) {
      // Horizontal lines only
      for (double i = minorStartY; i < size.height; i += minorStep) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), minorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.themeMode != themeMode;
  }
}
