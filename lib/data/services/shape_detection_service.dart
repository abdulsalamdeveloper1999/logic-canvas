import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/stroke.dart';

class ShapeDetectionService {
  static StrokeType detectShape(List<Offset> points) {
    if (points.length < 15) return StrokeType.pen;

    // 1. Calculate Bounding Box and Centroid
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;
    double sumX = 0;
    double sumY = 0;

    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
      sumX += p.dx;
      sumY += p.dy;
    }

    final width = maxX - minX;
    final height = maxY - minY;
    final centroid = Offset(sumX / points.length, sumY / points.length);

    // If it's too small, don't auto-shape
    if (width < 20 || height < 20) return StrokeType.pen;

    // 2. Check if closed loop
    final startEndDist = (points.first - points.last).distance;
    // Be more lenient with "closed" loops for manual detection (up to 40% of size)
    final isClosed = startEndDist < max(width, height) * 0.4;

    // 2.1. Line Heuristic: If it's NOT a closed loop, check if it's a straight line
    if (!isClosed) {
      double totalLength = 0;
      for (int i = 0; i < points.length - 1; i++) {
        totalLength += (points[i] - points[i + 1]).distance;
      }
      final straightDist = (points.first - points.last).distance;

      // If the path is nearly straight (within 15% margin), it's a line
      if (totalLength < straightDist * 1.15) {
        return StrokeType.pen;
      }

      // If it's a very simple open curve, don't even try ML Kit (stay as pen)
      if (points.length < 30) return StrokeType.pen;

      return StrokeType.pen;
    }

    // 3. Circle Heuristic: Distance from centroid should be consistent (radius)
    final double radius = (width + height) / 4;
    double totalVariance = 0;
    for (final p in points) {
      final dist = (p - centroid).distance;
      totalVariance += (dist - radius).abs();
    }
    final avgVariance = totalVariance / points.length;

    // Circle match if variance is low relative to radius
    if (avgVariance < radius * 0.15) {
      return StrokeType.circle;
    }

    // 4. Triangle Heuristic: Look for 3 dominant corners
    // We can use a simplified version: check distance from centroid and look for local maxima
    List<double> distances = points
        .map((p) => (p - centroid).distance)
        .toList();
    int peaks = 0;
    for (int i = 1; i < distances.length - 1; i++) {
      if (distances[i] > distances[i - 1] &&
          distances[i] > distances[i + 1] &&
          distances[i] > radius * 0.8) {
        peaks++;
      }
    }

    if (peaks == 3) return StrokeType.triangle;

    // 5. Diamond Heuristic: Vertices are at mid-points of bounding box edges
    final midLeft = Offset(minX, minY + height / 2);
    final midRight = Offset(maxX, minY + height / 2);
    final midTop = Offset(minX + width / 2, minY);
    final midBottom = Offset(minX + width / 2, maxY);

    double minToMids = 0;
    for (final p in points) {
      double d1 = (p - midLeft).distance;
      double d2 = (p - midRight).distance;
      double d3 = (p - midTop).distance;
      double d4 = (p - midBottom).distance;
      minToMids += [d1, d2, d3, d4].reduce(min);
    }

    if (minToMids / points.length < max(width, height) * 0.1) {
      return StrokeType.diamond;
    }

    // 6. Rectangle/Square Heuristic: Check if points are mostly on the bounding box edges
    double totalDistToEdge = 0;
    for (final p in points) {
      final distToLeft = (p.dx - minX).abs();
      final distToRight = (p.dx - maxX).abs();
      final distToTop = (p.dy - minY).abs();
      final distToBottom = (p.dy - maxY).abs();
      totalDistToEdge += [
        distToLeft,
        distToRight,
        distToTop,
        distToBottom,
      ].reduce(min);
    }

    final avgDistToEdge = totalDistToEdge / points.length;
    // If average distance to nearest edge is less than 10% of size, it's likely a rectangle
    if (avgDistToEdge < max(width, height) * 0.12 && isClosed) {
      // Check if it's roughly a square
      if ((width - height).abs() < max(width, height) * 0.2) {
        // We don't have a Square type, so use Rectangle (the painter can refine if needed)
        return StrokeType.rectangle;
      }
      return StrokeType.rectangle;
    }

    return StrokeType.pen;
  }
}
