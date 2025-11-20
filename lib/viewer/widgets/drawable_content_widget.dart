import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/utils/matrix_utils.dart' as custom_matrix;
import '../stroke.dart';
import '../tool_state.dart';

/// Optimized widget for drawing on content with minimal latency
class DrawableContentWidget extends StatefulWidget {
  final Widget child;
  final bool isDrawingEnabled;
  final ValueNotifier<ToolState> toolNotifier;
  final VoidCallback? onDrawingChanged;

  const DrawableContentWidget({
    super.key,
    required this.child,
    required this.isDrawingEnabled,
    required this.toolNotifier,
    this.onDrawingChanged,
  });

  @override
  State<DrawableContentWidget> createState() => DrawableContentWidgetState();
}

class DrawableContentWidgetState extends State<DrawableContentWidget> {
  final List<Stroke> _strokes = [];
  Stroke? _activeStroke;
  final TransformationController _transformController =
      TransformationController();

  bool _isDrawing = false;
  Offset? _shapeStartPoint;

  // Palm rejection
  bool _isStylusActive = false;
  DateTime? _lastStylusTime;
  static const Duration _palmRejectionWindow = Duration(milliseconds: 500);

  // Performance optimization: Cache the last transform matrix
  Matrix4? _cachedTransform;

  // Performance optimization: Track last update time for throttling
  DateTime? _lastUpdateTime;
  static const _updateThreshold = Duration(microseconds: 4000); // ~240 FPS max for ultra-smooth drawing

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Offset _transformPoint(Offset point) {
    // Use cached transform if available and unchanged
    final currentTransform = _transformController.value;
    if (_cachedTransform != currentTransform) {
      _cachedTransform = currentTransform;
    }
    return custom_matrix.MatrixUtils.transformPoint(currentTransform, point);
  }

  void _startStroke(Offset position) {
    if (!widget.isDrawingEnabled) return;

    final transformedPosition = _transformPoint(position);
    final tool = widget.toolNotifier.value;

    _isDrawing = true;

    if (tool.eraser) {
      _activeStroke = Stroke(
        color: tool.color,
        width: tool.width,
        erase: true,
      );
      _activeStroke!.points.add(transformedPosition);
      _eraseAt(transformedPosition, tool.width);
      _requestRepaint();
      return;
    }

    _activeStroke = Stroke(
      color: tool.color,
      width: tool.width,
      erase: false,
      isHighlighter: tool.highlighter,
    );
    _activeStroke!.points.add(transformedPosition);
    _strokes.add(_activeStroke!);

    _requestRepaint();
  }

  void _updateStroke(Offset position) {
    if (!_isDrawing || _activeStroke == null) return;
    if (!widget.isDrawingEnabled) return;

    // Throttle updates for better performance
    final now = DateTime.now();
    if (_lastUpdateTime != null) {
      final elapsed = now.difference(_lastUpdateTime!);
      if (elapsed < _updateThreshold) {
        return; // Skip this update, too soon
      }
    }
    _lastUpdateTime = now;

    final transformedPosition = _transformPoint(position);
    final tool = widget.toolNotifier.value;

    if (tool.eraser) {
      _activeStroke!.points.add(transformedPosition);
      _eraseAt(transformedPosition, tool.width);
      _requestRepaint();
    } else {
      // Add point without distance check for maximum responsiveness
      _activeStroke!.points.add(transformedPosition);
      _requestRepaint();
    }
  }

  void _endStroke() {
    if (!widget.isDrawingEnabled) return;

    _activeStroke = null;
    _isDrawing = false;
    _lastUpdateTime = null;
    _requestRepaint();
    widget.onDrawingChanged?.call();
  }

  void _startShape(Offset position) {
    if (!widget.isDrawingEnabled) return;

    final transformedPosition = _transformPoint(position);
    final tool = widget.toolNotifier.value;

    _isDrawing = true;
    _shapeStartPoint = transformedPosition;

    StrokeType shapeType;
    switch (tool.selectedShape) {
      case ShapeType.rectangle:
        shapeType = StrokeType.rectangle;
        break;
      case ShapeType.circle:
        shapeType = StrokeType.circle;
        break;
      case ShapeType.arrow:
        shapeType = StrokeType.arrow;
        break;
      case ShapeType.line:
        shapeType = StrokeType.line;
        break;
    }

    _activeStroke = Stroke.shape(
      color: tool.color,
      width: tool.width,
      type: shapeType,
      shapePoints: [transformedPosition, transformedPosition],
      isHighlighter: tool.highlighter,
    );
    _strokes.add(_activeStroke!);
    _requestRepaint();
  }

  void _updateShape(Offset position) {
    if (_activeStroke == null || _shapeStartPoint == null) return;
    if (!widget.isDrawingEnabled) return;

    final transformedPosition = _transformPoint(position);
    _activeStroke!.points[1] = transformedPosition;
    _requestRepaint();
  }

  void _endShape() {
    if (!widget.isDrawingEnabled) return;

    _activeStroke = null;
    _shapeStartPoint = null;
    _isDrawing = false;
    _requestRepaint();
    widget.onDrawingChanged?.call();
  }

  void _eraseAt(Offset position, double eraserRadius) {
    final List<Stroke> newStrokes = [];

    for (final stroke in _strokes) {
      if (stroke.erase) continue;

      final List<Offset> remaining = [];
      final List<List<Offset>> segments = [];

      for (final point in stroke.points) {
        final distance = (point - position).distance;
        if (distance >= eraserRadius * 1.2) {
          remaining.add(point);
        } else {
          if (remaining.isNotEmpty) {
            segments.add(List.from(remaining));
            remaining.clear();
          }
        }
      }

      if (remaining.isNotEmpty) {
        segments.add(remaining);
      }

      for (final segment in segments) {
        if (segment.length > 1) {
          final newStroke = Stroke(
            color: stroke.color,
            width: stroke.width,
            erase: false,
            isHighlighter: stroke.isHighlighter,
          );
          newStroke.points.addAll(segment);
          newStrokes.add(newStroke);
        }
      }
    }

    _strokes.removeWhere((s) => !s.erase);
    _strokes.addAll(newStrokes);
  }

  void _handleDrawingPointerDown(PointerDownEvent event) {
    if (!widget.isDrawingEnabled) return;

    final tool = widget.toolNotifier.value;

    // Palm rejection
    final isStylus = event.kind == PointerDeviceKind.stylus;
    final isTouch = event.kind == PointerDeviceKind.touch;

    if (isStylus) {
      _isStylusActive = true;
      _lastStylusTime = DateTime.now();
    }

    if (isTouch && _isStylusActive && _lastStylusTime != null) {
      final timeSinceStylus = DateTime.now().difference(_lastStylusTime!);
      if (timeSinceStylus < _palmRejectionWindow) {
        return;
      }
    }

    if (tool.shape) {
      _startShape(event.localPosition);
    } else if (tool.pencil || tool.eraser || tool.highlighter) {
      _startStroke(event.localPosition);
    }
  }

  void _handleDrawingPointerMove(PointerMoveEvent event) {
    if (!_isDrawing && _activeStroke == null) return;
    if (!widget.isDrawingEnabled) return;

    // Palm rejection
    final isTouch = event.kind == PointerDeviceKind.touch;
    if (isTouch && _isStylusActive && _lastStylusTime != null) {
      final timeSinceStylus = DateTime.now().difference(_lastStylusTime!);
      if (timeSinceStylus < _palmRejectionWindow) {
        return;
      }
    }

    final tool = widget.toolNotifier.value;

    if (tool.shape) {
      _updateShape(event.localPosition);
    } else if (tool.pencil || tool.eraser || tool.highlighter) {
      _updateStroke(event.localPosition);
    }
  }

  void _handleDrawingPointerUp(PointerUpEvent event) {
    if (!widget.isDrawingEnabled) return;

    // Palm rejection
    final isTouch = event.kind == PointerDeviceKind.touch;
    if (isTouch && _isStylusActive && _lastStylusTime != null) {
      final timeSinceStylus = DateTime.now().difference(_lastStylusTime!);
      if (timeSinceStylus < _palmRejectionWindow) {
        return;
      }
    }

    final tool = widget.toolNotifier.value;

    if (tool.shape) {
      _endShape();
    } else if (tool.pencil || tool.eraser || tool.highlighter) {
      _endStroke();
    }
  }

  void clearDrawing() {
    _strokes.clear();
    _activeStroke = null;
    _requestRepaint();
    widget.onDrawingChanged?.call();
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      _requestRepaint();
      widget.onDrawingChanged?.call();
    }
  }

  // Optimized repaint request - use setState only when needed
  void _requestRepaint() {
    setState(() {
      // Force rebuild to update CustomPaint
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Content layer with InteractiveViewer
        InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.5,
          maxScale: 5.0,
          panEnabled: !widget.isDrawingEnabled,
          scaleEnabled: !widget.isDrawingEnabled,
          child: widget.child,
        ),

        // Drawing layer - Optimized for performance
        if (widget.isDrawingEnabled || _strokes.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !widget.isDrawingEnabled,
              child: Listener(
                onPointerDown: _handleDrawingPointerDown,
                onPointerMove: _handleDrawingPointerMove,
                onPointerUp: _handleDrawingPointerUp,
                behavior: HitTestBehavior.translucent,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _FastDrawingPainter(
                      strokes: _strokes,
                      activeStroke: _activeStroke,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ultra-optimized painter that paints strokes directly
class _FastDrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? activeStroke;

  _FastDrawingPainter({
    required this.strokes,
    this.activeStroke,
  });

  // Cache Paint objects
  static final Map<String, Paint> _paintCache = {};

  Paint _getPaint(Stroke stroke) {
    final key = '${stroke.color.hashCode}_${stroke.width}_${stroke.isHighlighter}';

    return _paintCache.putIfAbsent(key, () {
      return Paint()
        ..color = stroke.isHighlighter
            ? stroke.color.withValues(alpha: 0.4)
            : stroke.color
        ..strokeWidth = stroke.isHighlighter
            ? stroke.width * 2.5
            : stroke.width
        ..strokeCap = stroke.isHighlighter
            ? StrokeCap.square
            : StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..blendMode = stroke.isHighlighter
            ? BlendMode.multiply
            : BlendMode.srcOver;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed strokes
    for (final stroke in strokes) {
      if (stroke.points.isEmpty || stroke.erase) continue;

      final paint = _getPaint(stroke);
      _drawStroke(canvas, stroke, paint);
    }

    // Draw active stroke
    if (activeStroke != null && activeStroke!.points.isNotEmpty && !activeStroke!.erase) {
      final paint = _getPaint(activeStroke!);
      _drawStroke(canvas, activeStroke!, paint);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke, Paint paint) {
    switch (stroke.type) {
      case StrokeType.freehand:
        _drawFreehand(canvas, stroke, paint);
        break;
      case StrokeType.rectangle:
        _drawRectangle(canvas, stroke, paint);
        break;
      case StrokeType.circle:
        _drawCircle(canvas, stroke, paint);
        break;
      case StrokeType.line:
        _drawLine(canvas, stroke, paint);
        break;
      case StrokeType.arrow:
        _drawArrow(canvas, stroke, paint);
        break;
    }
  }

  void _drawFreehand(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, stroke.width / 2, paint);
    } else if (stroke.points.length == 2) {
      canvas.drawLine(stroke.points.first, stroke.points.last, paint);
    } else {
      // Fast path drawing - just draw lines between points
      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  void _drawRectangle(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.length >= 2) {
      final rect = Rect.fromPoints(stroke.points.first, stroke.points.last);
      canvas.drawRect(rect, paint);
    }
  }

  void _drawCircle(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.length >= 2) {
      final center = stroke.points.first;
      final radius = (stroke.points.first - stroke.points.last).distance;
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _drawLine(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.length >= 2) {
      canvas.drawLine(stroke.points.first, stroke.points.last, paint);
    }
  }

  void _drawArrow(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.length >= 2) {
      final start = stroke.points.first;
      final end = stroke.points.last;

      canvas.drawLine(start, end, paint);

      // Arrow head
      const arrowLength = 20.0;
      const arrowAngle = 25.0 * math.pi / 180;

      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);

      final arrowPoint1 = Offset(
        end.dx - arrowLength * math.cos(angle - arrowAngle),
        end.dy - arrowLength * math.sin(angle - arrowAngle),
      );

      final arrowPoint2 = Offset(
        end.dx - arrowLength * math.cos(angle + arrowAngle),
        end.dy - arrowLength * math.sin(angle + arrowAngle),
      );

      canvas.drawLine(end, arrowPoint1, paint);
      canvas.drawLine(end, arrowPoint2, paint);
    }
  }

  @override
  bool shouldRepaint(_FastDrawingPainter oldDelegate) {
    // Always repaint during active drawing for responsiveness
    return activeStroke != null ||
           oldDelegate.activeStroke != null ||
           strokes.length != oldDelegate.strokes.length;
  }
}
