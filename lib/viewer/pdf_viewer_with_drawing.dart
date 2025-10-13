import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'stroke.dart';
import 'drawing_painter.dart';
import 'tool_state.dart';
import 'dart:math' show cos, sin;

class PdfViewerWithDrawing extends StatefulWidget {
  final PdfController controller;
  const PdfViewerWithDrawing({super.key, required this.controller});

  @override
  State<PdfViewerWithDrawing> createState() => PdfViewerWithDrawingState();
}

class PdfViewerWithDrawingState extends State<PdfViewerWithDrawing> {
  final Map<int, List<Stroke>> _pageStrokes = {};
  Stroke? _activeStroke;
  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);
  final ValueNotifier<ToolState> toolNotifier = ValueNotifier<ToolState>(
    ToolState(
      mouse: true,
      eraser: false,
      pencil: false,
      grab: false,
      shape: false,
      selection: false,
      selectedShape: ShapeType.rectangle,
      color: Colors.red,
      width: 3.0,
    ),
  );

  int _currentPage = 1;
  final TransformationController _transformationController =
      TransformationController();
  final double _minZoom = 0.5;
  final double _maxZoom = 4.0;
  bool _isDrawing = false;
  bool _isPanning = false;
  double _rotationAngle = 0.0;
  double _lastRotation = 0.0;
  Offset? _shapeStartPoint;

  // Selection için
  final ValueNotifier<Rect?> selectedAreaNotifier = ValueNotifier<Rect?>(null);
  Offset? _selectionStart;

  // PDF rendering kalitesi için
  double _lastRenderedScale = 1.0;
  final ValueNotifier<double> _pdfScaleNotifier = ValueNotifier<double>(1.0);

  @override
  void initState() {
    super.initState();
    widget.controller.pageListenable.addListener(_onPageChanged);
    _transformationController.addListener(_onTransformChanged);
  }

  void _onPageChanged() {
    final page = widget.controller.pageListenable.value;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
      _repaintNotifier.value++;
    }
  }

  void _onTransformChanged() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    // Zoom seviyesi %5'den fazla değiştiyse PDF'i yeniden render et
    if ((currentScale - _lastRenderedScale).abs() / _lastRenderedScale > 0.05) {
      _lastRenderedScale = currentScale;
      _pdfScaleNotifier.value = currentScale;
    }
  }

  @override
  void dispose() {
    widget.controller.pageListenable.removeListener(_onPageChanged);
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _repaintNotifier.dispose();
    selectedAreaNotifier.dispose();
    _pdfScaleNotifier.dispose();
    super.dispose();
  }

  List<Stroke> get _strokes => _pageStrokes[_currentPage] ??= [];

  void _handleScaleStart(ScaleStartDetails details) {
    _lastRotation = 0.0;
    final tool = toolNotifier.value;

    if (details.pointerCount == 1) {
      if (tool.selection) {
        // Alan seçimi başlat
        _selectionStart = details.localFocalPoint;
        selectedAreaNotifier.value = null;
      } else if (tool.grab) {
        _isPanning = true;
      } else if (tool.shape) {
        _startShape(details.localFocalPoint);
      } else if (tool.pencil || tool.eraser) {
        _startStroke(details.localFocalPoint);
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final tool = toolNotifier.value;

    if (details.pointerCount == 2 &&
        !tool.pencil &&
        !tool.eraser &&
        !tool.shape &&
        !tool.selection) {
      final rotationDelta = details.rotation - _lastRotation;
      _rotationAngle += rotationDelta;
      _lastRotation = details.rotation;
      setState(() {});
      return;
    }

    if (details.pointerCount == 1) {
      if (tool.selection && _selectionStart != null) {
        // Alan seçimini güncelle
        final rect = Rect.fromPoints(_selectionStart!, details.localFocalPoint);
        selectedAreaNotifier.value = rect;
      } else if (tool.grab && _isPanning) {
        final currentTransform = _transformationController.value;
        final newTransform = Matrix4.copy(currentTransform)
          ..translateByVector3(
            Vector3(details.focalPointDelta.dx, details.focalPointDelta.dy, 0),
          );
        _transformationController.value = newTransform;
      } else if (tool.shape) {
        _updateShape(details.localFocalPoint);
      } else if (tool.pencil || tool.eraser) {
        _updateStroke(details.localFocalPoint);
      }
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    final tool = toolNotifier.value;

    if (tool.selection) {
      // Alan seçimi tamamlandı
      _selectionStart = null;
    } else if (tool.grab) {
      _isPanning = false;
    } else if (tool.shape) {
      _endShape();
    } else if (tool.pencil || tool.eraser) {
      _endStroke();
    }

    _lastRotation = 0.0;
  }

  void _startShape(Offset position) {
    _isDrawing = true;
    _shapeStartPoint = position;

    final tool = toolNotifier.value;
    StrokeType strokeType;

    switch (tool.selectedShape) {
      case ShapeType.rectangle:
        strokeType = StrokeType.rectangle;
        break;
      case ShapeType.circle:
        strokeType = StrokeType.circle;
        break;
      case ShapeType.line:
        strokeType = StrokeType.line;
        break;
      case ShapeType.arrow:
        strokeType = StrokeType.arrow;
        break;
    }

    _activeStroke = Stroke.shape(
      color: tool.color,
      width: tool.width,
      type: strokeType,
      shapePoints: [position, position],
    );

    _strokes.add(_activeStroke!);
    _repaintNotifier.value++;
  }

  void _updateShape(Offset position) {
    if (_activeStroke != null && _shapeStartPoint != null) {
      _activeStroke!.points[1] = position;
      _repaintNotifier.value++;
    }
  }

  void _endShape() {
    _activeStroke = null;
    _shapeStartPoint = null;
    _isDrawing = false;
    _repaintNotifier.value++;
  }

  void _startStroke(Offset position) {
    _isDrawing = true;

    final tool = toolNotifier.value;

    if (tool.eraser) {
      _activeStroke = Stroke(color: tool.color, width: tool.width, erase: true);
      _activeStroke!.points.add(position);
      _eraseAt(position, tool.width);
      return;
    }

    _activeStroke = Stroke(color: tool.color, width: tool.width, erase: false);
    _activeStroke!.points.add(position);
    _strokes.add(_activeStroke!);

    _repaintNotifier.value++;
  }

  void _updateStroke(Offset position) {
    if (!_isDrawing && _activeStroke == null) return;

    final tool = toolNotifier.value;

    if (tool.eraser) {
      _activeStroke?.points.add(position);
      _eraseAt(position, tool.width);
    } else {
      _activeStroke?.points.add(position);
    }

    _repaintNotifier.value++;
  }

  void _endStroke() {
    _activeStroke = null;
    _isDrawing = false;
    _repaintNotifier.value++;
  }

  void _eraseAt(Offset position, double eraserRadius) {
    final List<Stroke> newStrokes = [];

    for (final stroke in _strokes) {
      if (stroke.erase) continue;

      if (stroke.type != StrokeType.freehand) {
        final List<Offset> shapePoints = _expandShapeToPoints(stroke);
        final List<Offset> remainingPoints = [];
        final List<List<Offset>> segments = [];

        for (int i = 0; i < shapePoints.length; i++) {
          final point = shapePoints[i];
          final distance = (point - position).distance;

          if (distance >= eraserRadius * 1.2) {
            remainingPoints.add(point);
          } else {
            if (remainingPoints.isNotEmpty) {
              segments.add(List.from(remainingPoints));
              remainingPoints.clear();
            }
          }
        }

        if (remainingPoints.isNotEmpty) {
          segments.add(remainingPoints);
        }

        for (final segment in segments) {
          if (segment.length > 1) {
            final newStroke = Stroke(
              color: stroke.color,
              width: stroke.width,
              erase: false,
            );
            newStroke.points.addAll(segment);
            newStrokes.add(newStroke);
          }
        }
        continue;
      }

      final List<Offset> remainingPoints = [];
      final List<List<Offset>> segments = [];

      for (int i = 0; i < stroke.points.length; i++) {
        final point = stroke.points[i];
        final distance = (point - position).distance;

        if (distance >= eraserRadius * 1.2) {
          remainingPoints.add(point);
        } else {
          if (remainingPoints.isNotEmpty) {
            segments.add(List.from(remainingPoints));
            remainingPoints.clear();
          }
        }
      }

      if (remainingPoints.isNotEmpty) {
        segments.add(remainingPoints);
      }

      for (final segment in segments) {
        if (segment.length > 1) {
          final newStroke = Stroke(
            color: stroke.color,
            width: stroke.width,
            erase: false,
          );
          newStroke.points.addAll(segment);
          newStrokes.add(newStroke);
        }
      }
    }

    _strokes.removeWhere((stroke) => !stroke.erase);
    _strokes.addAll(newStrokes);
  }

  List<Offset> _expandShapeToPoints(Stroke stroke) {
    if (stroke.points.length < 2) return stroke.points;

    final p1 = stroke.points[0];
    final p2 = stroke.points[1];
    final List<Offset> expandedPoints = [];

    switch (stroke.type) {
      case StrokeType.line:
      case StrokeType.arrow:
        final steps = ((p2 - p1).distance / 2).ceil();
        for (int i = 0; i <= steps; i++) {
          final t = i / steps;
          expandedPoints.add(
            Offset(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t),
          );
        }
        break;

      case StrokeType.rectangle:
        final topLeft = Offset(
          p1.dx < p2.dx ? p1.dx : p2.dx,
          p1.dy < p2.dy ? p1.dy : p2.dy,
        );
        final bottomRight = Offset(
          p1.dx > p2.dx ? p1.dx : p2.dx,
          p1.dy > p2.dy ? p1.dy : p2.dy,
        );
        final topRight = Offset(bottomRight.dx, topLeft.dy);
        final bottomLeft = Offset(topLeft.dx, bottomRight.dy);

        expandedPoints.addAll(_interpolateLine(topLeft, topRight));
        expandedPoints.addAll(_interpolateLine(topRight, bottomRight));
        expandedPoints.addAll(_interpolateLine(bottomRight, bottomLeft));
        expandedPoints.addAll(_interpolateLine(bottomLeft, topLeft));
        break;

      case StrokeType.circle:
        final center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        final radius = (p2 - p1).distance / 2;
        final steps = (radius * 2).ceil();

        for (int i = 0; i < steps; i++) {
          final angle = (i / steps) * 2 * 3.14159;
          expandedPoints.add(
            Offset(
              center.dx + radius * cos(angle),
              center.dy + radius * sin(angle),
            ),
          );
        }
        break;

      default:
        expandedPoints.addAll(stroke.points);
    }

    return expandedPoints;
  }

  List<Offset> _interpolateLine(Offset start, Offset end) {
    final List<Offset> points = [];
    final steps = ((end - start).distance / 2).ceil();

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      points.add(
        Offset(
          start.dx + (end.dx - start.dx) * t,
          start.dy + (end.dy - start.dy) * t,
        ),
      );
    }

    return points;
  }

  void clearCurrentPage() {
    _strokes.clear();
    setState(() {
      _repaintNotifier.value++;
    });
  }

  double get zoomLevel => _transformationController.value.getMaxScaleOnAxis();

  void zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(_minZoom, _maxZoom);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(_minZoom, _maxZoom);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void resetZoom() {
    _transformationController.value = Matrix4.identity();
    _lastRenderedScale = 1.0;
    _pdfScaleNotifier.value = 1.0;
  }

  void rotateLeft() {
    setState(() {
      _rotationAngle -= 1.5708;
    });
  }

  void rotateRight() {
    setState(() {
      _rotationAngle += 1.5708;
    });
  }

  void resetRotation() {
    setState(() {
      _rotationAngle = 0.0;
    });
  }

  void setPencil(bool value) {
    toolNotifier.value = toolNotifier.value.copyWith(
      pencil: value,
      eraser: false,
      grab: false,
      shape: false,
      mouse: false,
      selection: false,
    );
  }

  void setEraser(bool value) {
    toolNotifier.value = toolNotifier.value.copyWith(
      eraser: value,
      pencil: false,
      grab: false,
      shape: false,
      mouse: false,
      selection: false,
    );
  }

  void setGrab(bool value) {
    toolNotifier.value = toolNotifier.value.copyWith(
      grab: value,
      pencil: false,
      eraser: false,
      shape: false,
      mouse: false,
      selection: false,
    );
  }

  void setMouse(bool value) {
    toolNotifier.value = toolNotifier.value.copyWith(
      mouse: value,
      pencil: false,
      eraser: false,
      grab: false,
      shape: false,
      selection: false,
    );
  }

  void setShape(bool value) {
    toolNotifier.value = toolNotifier.value.copyWith(
      shape: value,
      pencil: false,
      eraser: false,
      grab: false,
      mouse: false,
      selection: false,
    );
  }

  void setSelectedShape(ShapeType shapeType) {
    toolNotifier.value = toolNotifier.value.copyWith(
      selectedShape: shapeType,
      shape: true,
      pencil: false,
      eraser: false,
      grab: false,
      mouse: false,
      selection: false,
    );
  }

  void setColor(Color value) {
    toolNotifier.value = toolNotifier.value.copyWith(
      color: value,
      pencil: !toolNotifier.value.shape,
      shape: toolNotifier.value.shape,
      eraser: false,
      grab: false,
      mouse: false,
      selection: false,
    );
  }

  void setWidth(double value) {
    toolNotifier.value = toolNotifier.value.copyWith(width: value);
  }

  void setSelection(bool value) {
    toolNotifier.value = toolNotifier.value.copyWith(
      selection: value,
      mouse: false,
      pencil: false,
      eraser: false,
      grab: false,
      shape: false,
    );
    if (!value) {
      selectedAreaNotifier.value = null;
      _selectionStart = null;
    }
  }

  void clearSelection() {
    selectedAreaNotifier.value = null;
    _selectionStart = null;
    setMouse(true);
  }

  @override
  Widget build(BuildContext context) {
    final tool = toolNotifier.value;

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

          if (isCtrlPressed) {
            final delta = pointerSignal.scrollDelta.dy;
            final currentScale =
                _transformationController.value.getMaxScaleOnAxis();

            double zoomFactor;
            if (delta < 0) {
              zoomFactor = 1.1;
            } else {
              zoomFactor = 0.9;
            }

            final newScale =
                (currentScale * zoomFactor).clamp(_minZoom, _maxZoom);

            if (newScale != currentScale) {
              _transformationController.value =
                  Matrix4.identity()..scale(newScale);
            }
          }
        }
      },
      child: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

            if (isCtrlPressed) {
              switch (event.logicalKey) {
                case LogicalKeyboardKey.arrowLeft:
                  rotateLeft();
                  break;
                case LogicalKeyboardKey.arrowRight:
                  rotateRight();
                  break;
                case LogicalKeyboardKey.keyR:
                  resetRotation();
                  break;
              }
            }
          }
        },
        child: MouseRegion(
          cursor: tool.mouse
              ? SystemMouseCursors.move
              : tool.grab
                  ? SystemMouseCursors.grab
                  : tool.pencil
                      ? SystemMouseCursors.precise
                      : tool.shape
                          ? SystemMouseCursors.cell
                          : tool.eraser
                              ? SystemMouseCursors.click
                              : tool.selection
                                  ? SystemMouseCursors.precise
                                  : SystemMouseCursors.basic,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: _minZoom,
            maxScale: _maxZoom,
            boundaryMargin: const EdgeInsets.all(20),
            panEnabled: tool.grab,
            scaleEnabled: true,
            child: GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              child: Transform.rotate(
                angle: _rotationAngle,
                child: Stack(
                  children: [
                    ValueListenableBuilder<double>(
                      valueListenable: _pdfScaleNotifier,
                      builder: (context, scale, child) {
                        // Zoom seviyesine göre render kalitesini ayarla
                        // Daha yüksek kalite için çarpan ve limitleri artırdık
                        final quality = (scale * 6).clamp(4.0, 12.0);

                        return PdfView(
                          controller: widget.controller,
                          renderer: (page) {
                            return page.render(
                              width: (page.width * quality).toDouble(),
                              height: (page.height * quality).toDouble(),
                              format: PdfPageImageFormat.png,
                              backgroundColor: '#FFFFFF',
                            );
                          },
                        );
                      },
                    ),
                    Positioned.fill(
                      child: ValueListenableBuilder(
                        valueListenable: _repaintNotifier,
                        builder: (_, __, ___) {
                          return CustomPaint(
                            painter: DrawingPainter(strokes: _strokes),
                            size: Size.infinite,
                            child: Container(),
                          );
                        },
                      ),
                    ),
                    // Selection overlay
                    Positioned.fill(
                      child: ValueListenableBuilder<Rect?>(
                        valueListenable: selectedAreaNotifier,
                        builder: (context, selectedRect, child) {
                          if (selectedRect == null) {
                            return const SizedBox.shrink();
                          }
                          return CustomPaint(
                            painter: _SelectionPainter(selectedRect),
                            size: Size.infinite,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Selection painter - mavi dikdörtgen çizer
class _SelectionPainter extends CustomPainter {
  final Rect rect;

  _SelectionPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}
