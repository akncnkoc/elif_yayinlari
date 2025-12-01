import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

/// Utility functions for Matrix4 transformations
class MatrixUtils {
  MatrixUtils._();

  /// Transforms a point from screen space to content space
  /// When GestureDetector is OUTSIDE InteractiveViewer, we need inverse transform
  /// When GestureDetector is INSIDE InteractiveViewer, we need direct transform
  static Offset transformPoint(Matrix4 transform, Offset point) {
    try {
      final Matrix4 invertedMatrix = Matrix4.inverted(transform);
      final Vector3 transformed = invertedMatrix.transform3(
        Vector3(point.dx, point.dy, 0),
      );
      return Offset(transformed.x, transformed.y);
    } catch (e) {
      // If matrix can't be inverted, return original point
      return point;
    }
  }

  /// Transforms a point from screen space to content space (for gestures outside IV)
  /// This is the correct transform when GestureDetector is outside InteractiveViewer
  static Offset screenToContentSpace(Matrix4 transform, Offset screenPoint) {
    try {
      // When GestureDetector is outside InteractiveViewer:
      // Screen coordinates need to be transformed to content space
      // This requires the inverse of the transformation matrix
      final Matrix4 invertedMatrix = Matrix4.inverted(transform);
      final Vector3 transformed = invertedMatrix.transform3(
        Vector3(screenPoint.dx, screenPoint.dy, 0),
      );
      return Offset(transformed.x, transformed.y);
    } catch (e) {
      return screenPoint;
    }
  }

  /// Creates a zoom transformation around a focal point
  ///
  /// [focalPoint] - The point that should remain fixed during zoom
  /// [startTransform] - The transformation matrix before zoom started
  /// [startScale] - The scale value before zoom started
  /// [newScale] - The new scale value to apply
  static Matrix4 createZoomTransform({
    required Offset focalPoint,
    required Matrix4 startTransform,
    required double startScale,
    required double newScale,
  }) {
    // Get translation from start transform
    final startTranslation = startTransform.getTranslation();

    // Calculate new translation to keep focal point fixed
    // Formula: newTranslation = focalPoint - (focalPoint - oldTranslation) * (newScale / oldScale)
    final scaleRatio = newScale / startScale;
    final newTranslationX = focalPoint.dx - (focalPoint.dx - startTranslation.x) * scaleRatio;
    final newTranslationY = focalPoint.dy - (focalPoint.dy - startTranslation.y) * scaleRatio;

    // Create new transformation matrix
    return Matrix4.identity()
      ..translateByVector3(Vector3(newTranslationX, newTranslationY, 0))
      ..scaleByDouble(newScale, newScale, 1, 1);
  }

  /// Extracts the scale value from a transformation matrix
  static double getScale(Matrix4 transform) {
    return transform.getMaxScaleOnAxis();
  }

  /// Extracts the translation from a transformation matrix
  static Offset getTranslation(Matrix4 transform) {
    final translation = transform.getTranslation();
    return Offset(translation.x, translation.y);
  }

  /// Creates a simple scale transformation
  static Matrix4 createScaleTransform(double scale) {
    return Matrix4.identity()..scaleByDouble(scale, scale, 1, 1);
  }

  /// Creates a translation transformation
  static Matrix4 createTranslationTransform(Offset offset) {
    return Matrix4.identity()
      ..translateByVector3(Vector3(offset.dx, offset.dy, 0));
  }

  /// Combines translation and scale transformations
  static Matrix4 createTransformWithTranslationAndScale({
    required Offset translation,
    required double scale,
  }) {
    return Matrix4.identity()
      ..translateByVector3(Vector3(translation.dx, translation.dy, 0))
      ..scaleByDouble(scale, scale, 1, 1);
  }

  /// Transforms a Rect from content space to screen space
  /// This is used when we have content-space coordinates (inside InteractiveViewer)
  /// and need to map them to screen-space coordinates (outside InteractiveViewer)
  static Rect transformRect(Matrix4 transform, Rect rect) {
    try {
      // Transform all four corners of the rect
      final topLeft = transformRectPoint(transform, rect.topLeft);
      final topRight = transformRectPoint(transform, rect.topRight);
      final bottomLeft = transformRectPoint(transform, rect.bottomLeft);
      final bottomRight = transformRectPoint(transform, rect.bottomRight);

      // Find the bounding box of the transformed corners
      final left = [topLeft.dx, topRight.dx, bottomLeft.dx, bottomRight.dx].reduce((a, b) => a < b ? a : b);
      final top = [topLeft.dy, topRight.dy, bottomLeft.dy, bottomRight.dy].reduce((a, b) => a < b ? a : b);
      final right = [topLeft.dx, topRight.dx, bottomLeft.dx, bottomRight.dx].reduce((a, b) => a > b ? a : b);
      final bottom = [topLeft.dy, topRight.dy, bottomLeft.dy, bottomRight.dy].reduce((a, b) => a > b ? a : b);

      return Rect.fromLTRB(left, top, right, bottom);
    } catch (e) {
      return rect;
    }
  }

  /// Helper to transform a point from content space to screen space
  /// This applies the FORWARD transform (not inverse)
  static Offset transformRectPoint(Matrix4 transform, Offset point) {
    final Vector3 transformed = transform.transform3(
      Vector3(point.dx, point.dy, 0),
    );
    return Offset(transformed.x, transformed.y);
  }
}
