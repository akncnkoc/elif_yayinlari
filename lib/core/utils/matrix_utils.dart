import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class MatrixUtils {
  MatrixUtils._();

  static Offset transformPoint(Matrix4 transform, Offset point) {
    try {
      final Matrix4 invertedMatrix = Matrix4.inverted(transform);
      final Vector3 transformed = invertedMatrix.transform3(
        Vector3(point.dx, point.dy, 0),
      );
      return Offset(transformed.x, transformed.y);
    } catch (e) {
      return point;
    }
  }

  static Offset screenToContentSpace(Matrix4 transform, Offset screenPoint) {
    try {
      final Matrix4 invertedMatrix = Matrix4.inverted(transform);
      final Vector3 transformed = invertedMatrix.transform3(
        Vector3(screenPoint.dx, screenPoint.dy, 0),
      );
      return Offset(transformed.x, transformed.y);
    } catch (e) {
      return screenPoint;
    }
  }

  static Matrix4 createZoomTransform({
    required Offset focalPoint,
    required Matrix4 startTransform,
    required double startScale,
    required double newScale,
  }) {
    final startTranslation = startTransform.getTranslation();

    final scaleRatio = newScale / startScale;
    final newTranslationX =
        focalPoint.dx - (focalPoint.dx - startTranslation.x) * scaleRatio;
    final newTranslationY =
        focalPoint.dy - (focalPoint.dy - startTranslation.y) * scaleRatio;

    return Matrix4.identity()
      ..translateByVector3(Vector3(newTranslationX, newTranslationY, 0))
      ..scaleByDouble(newScale, newScale, 1, 1);
  }

  static double getScale(Matrix4 transform) {
    return transform.getMaxScaleOnAxis();
  }

  static Offset getTranslation(Matrix4 transform) {
    final translation = transform.getTranslation();
    return Offset(translation.x, translation.y);
  }

  static Matrix4 createScaleTransform(double scale) {
    return Matrix4.identity()..scaleByDouble(scale, scale, 1, 1);
  }

  static Matrix4 createTranslationTransform(Offset offset) {
    return Matrix4.identity()
      ..translateByVector3(Vector3(offset.dx, offset.dy, 0));
  }

  static Matrix4 createTransformWithTranslationAndScale({
    required Offset translation,
    required double scale,
  }) {
    return Matrix4.identity()
      ..translateByVector3(Vector3(translation.dx, translation.dy, 0))
      ..scaleByDouble(scale, scale, 1, 1);
  }

  static Rect transformRect(Matrix4 transform, Rect rect) {
    try {
      final topLeft = transformRectPoint(transform, rect.topLeft);
      final topRight = transformRectPoint(transform, rect.topRight);
      final bottomLeft = transformRectPoint(transform, rect.bottomLeft);
      final bottomRight = transformRectPoint(transform, rect.bottomRight);

      final left = [
        topLeft.dx,
        topRight.dx,
        bottomLeft.dx,
        bottomRight.dx,
      ].reduce((a, b) => a < b ? a : b);
      final top = [
        topLeft.dy,
        topRight.dy,
        bottomLeft.dy,
        bottomRight.dy,
      ].reduce((a, b) => a < b ? a : b);
      final right = [
        topLeft.dx,
        topRight.dx,
        bottomLeft.dx,
        bottomRight.dx,
      ].reduce((a, b) => a > b ? a : b);
      final bottom = [
        topLeft.dy,
        topRight.dy,
        bottomLeft.dy,
        bottomRight.dy,
      ].reduce((a, b) => a > b ? a : b);

      return Rect.fromLTRB(left, top, right, bottom);
    } catch (e) {
      return rect;
    }
  }

  static Offset transformRectPoint(Matrix4 transform, Offset point) {
    final Vector3 transformed = transform.transform3(
      Vector3(point.dx, point.dy, 0),
    );
    return Offset(transformed.x, transformed.y);
  }
}
