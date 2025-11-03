import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

/// Utility functions for Matrix4 transformations
class MatrixUtils {
  MatrixUtils._();

  /// Transforms a point using the inverse of a transformation matrix
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
}
