import 'dart:math';
import 'package:flutter/material.dart';

enum RecognizedShapeType { none, line, circle, rectangle, triangle }

class RecognizedShape {
  final RecognizedShapeType type;
  final Path path;

  RecognizedShape(this.type, this.path);
}

class ShapeRecognizer {
  // Configurable thresholds
  static const double _closureThreshold = 0.20; // % of bounding box diagonal
  static const double _circleVarianceThreshold =
      0.15; // TIGHTENED from 0.25 to 0.15

  /// Analyzes a list of points and returns a recognized shape or none.
  static RecognizedShape recognize(List<Offset> points) {
    if (points.length < 10)
      return RecognizedShape(RecognizedShapeType.none, Path());

    final bounds = _computeBounds(points);
    final diagonal = sqrt(pow(bounds.width, 2) + pow(bounds.height, 2));
    final start = points.first;
    final end = points.last;
    final distance = (start - end).distance;

    // Check if closed (start is near end)
    bool isClosed = distance < (diagonal * _closureThreshold);

    // 1. LINE CHECK (If not closed)
    if (!isClosed) {
      if (_isLine(points)) {
        final p = Path();
        p.moveTo(start.dx, start.dy);
        p.lineTo(end.dx, end.dy);
        return RecognizedShape(RecognizedShapeType.line, p);
      }
      return RecognizedShape(RecognizedShapeType.none, Path());
    }

    // 2. POLYGON SIMPLIFICATION (Corner Detection)
    // Simplify the points to find finding corners.
    // Epsilon is the tolerance. 5% of diagonal is usually good for rough shapes.
    final simplified = _simplifyPoints(points, diagonal * 0.06);

    // If start and end are close, RDP might leave them as separate points.
    // For closed shape logic, if first and last are same-ish, count as one.
    int vertices = simplified.length;
    if ((simplified.first - simplified.last).distance < (diagonal * 0.1)) {
      vertices--;
    }

    // TRIANGLE (3 Corners)
    if (vertices == 3) {
      final p = Path();
      p.addPolygon(simplified.sublist(0, 3), true);
      return RecognizedShape(RecognizedShapeType.triangle, p);
    }

    // RECTANGLE (4 Corners)
    // Also matching loose rectangles that might be 5 points (start/end overlap)
    if (vertices == 4) {
      // Use bounding box for perfect axis-aligned rectangle (better UX than rotated quad usually)
      final p = Path();
      p.addRect(bounds);
      return RecognizedShape(RecognizedShapeType.rectangle, p);
    }

    // 3. CIRCLE CHECK (Fallback if many vertices)
    // If it has many vertices, it might be a circle or a complex shape.
    if (_isCircle(points, bounds)) {
      final p = Path();
      p.addOval(bounds);
      return RecognizedShape(RecognizedShapeType.circle, p);
    }

    // Fallback: Check if it looks like a rectangle even if corner detection failed (e.g. rounded corners)
    if (_isRectangle(points, bounds)) {
      final p = Path();
      p.addRect(bounds);
      return RecognizedShape(RecognizedShapeType.rectangle, p);
    }

    return RecognizedShape(RecognizedShapeType.none, Path());
  }

  // --- Helpers ---

  static Rect _computeBounds(List<Offset> points) {
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Ramer-Douglas-Peucker Algorithm
  static List<Offset> _simplifyPoints(List<Offset> points, double epsilon) {
    if (points.length < 3) return points;

    double dmax = 0;
    int index = 0;
    int end = points.length - 1;

    for (int i = 1; i < end; i++) {
      double d = _perpendicularDistance(points[i], points[0], points[end]);
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    if (dmax > epsilon) {
      List<Offset> recResults1 = _simplifyPoints(
        points.sublist(0, index + 1),
        epsilon,
      );
      List<Offset> recResults2 = _simplifyPoints(
        points.sublist(index, end + 1),
        epsilon,
      );

      // recResults1.removeLast(); // Avoid duplicate point
      // concat
      return [
        ...recResults1.sublist(0, recResults1.length - 1),
        ...recResults2,
      ];
    } else {
      return [points[0], points[end]];
    }
  }

  static double _perpendicularDistance(Offset point, Offset start, Offset end) {
    if (start.dx == end.dx && start.dy == end.dy) {
      return (point - start).distance;
    }

    double num =
        ((end.dy - start.dy) * point.dx -
                (end.dx - start.dx) * point.dy +
                end.dx * start.dy -
                end.dy * start.dx)
            .abs();
    double den = sqrt(pow(end.dy - start.dy, 2) + pow(end.dx - start.dx, 2));
    return num / den;
  }

  static bool _isLine(List<Offset> points) {
    final start = points.first;
    final end = points.last;
    final totalLength = (end - start).distance;
    if (totalLength < 20) return false;

    double maxDeviation = 0;
    double A = start.dy - end.dy;
    double B = end.dx - start.dx;
    double C = start.dx * end.dy - end.dx * start.dy;
    double denom = sqrt(A * A + B * B);

    if (denom == 0) return false;

    for (var p in points) {
      double dist = (A * p.dx + B * p.dy + C).abs() / denom;
      if (dist > maxDeviation) maxDeviation = dist;
    }

    return maxDeviation < (totalLength * 0.1) || maxDeviation < 15.0;
  }

  static bool _isCircle(List<Offset> points, Rect bounds) {
    double aspectRatio = bounds.width / bounds.height;
    if (aspectRatio < 0.6 || aspectRatio > 1.6) return false;

    Offset center = bounds.center;
    double radius = (bounds.width + bounds.height) / 4;

    double totalDiff = 0;
    int count = 0;

    int step = max(1, points.length ~/ 40);
    for (int i = 0; i < points.length; i += step) {
      double d = (points[i] - center).distance;
      totalDiff += (d - radius).abs();
      count++;
    }

    double avgDiff = totalDiff / count;
    return avgDiff < (radius * _circleVarianceThreshold);
  }

  static bool _isRectangle(List<Offset> points, Rect bounds) {
    int matches = 0;
    int count = 0;
    double tolerance = min(bounds.width, bounds.height) * 0.20;

    int step = max(1, points.length ~/ 40);
    for (int i = 0; i < points.length; i += step) {
      final p = points[i];
      double dLeft = (p.dx - bounds.left).abs();
      double dRight = (p.dx - bounds.right).abs();
      double dTop = (p.dy - bounds.top).abs();
      double dBottom = (p.dy - bounds.bottom).abs();

      double minDist = min(min(dLeft, dRight), min(dTop, dBottom));

      if (minDist < tolerance) {
        matches++;
      }
      count++;
    }
    return (matches / count) > 0.85;
  }
}
