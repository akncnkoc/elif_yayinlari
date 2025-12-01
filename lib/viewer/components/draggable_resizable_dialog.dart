import 'package:flutter/material.dart';

/// Taşınabilir ve yeniden boyutlandırılabilir dialog widget'ı
class DraggableResizableDialog extends StatefulWidget {
  final Widget child;
  final double initialWidth;
  final double initialHeight;
  final double minWidth;
  final double minHeight;

  const DraggableResizableDialog({
    super.key,
    required this.child,
    this.initialWidth = 800,
    this.initialHeight = 600,
    this.minWidth = 400,
    this.minHeight = 300,
  });

  @override
  State<DraggableResizableDialog> createState() => _DraggableResizableDialogState();
}

class _DraggableResizableDialogState extends State<DraggableResizableDialog> {
  late double _width;
  late double _height;
  late double _x;
  late double _y;

  bool _isDragging = false;
  bool _isResizing = false;
  String? _resizeDirection;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
    _height = widget.initialHeight;
    // Dialog'u ortada başlat
    _x = 0;
    _y = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // İlk açılışta merkeze hizala
    if (_x == 0 && _y == 0) {
      final size = MediaQuery.of(context).size;
      _x = (size.width - _width) / 2;
      _y = (size.height - _height) / 2;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isResizing) {
      _handleResize(details);
    } else if (_isDragging) {
      _handleDrag(details);
    }
  }

  void _handleDrag(DragUpdateDetails details) {
    setState(() {
      _x += details.delta.dx;
      _y += details.delta.dy;

      // Ekran sınırlarını kontrol et
      final size = MediaQuery.of(context).size;
      _x = _x.clamp(0.0, size.width - _width);
      _y = _y.clamp(0.0, size.height - _height);
    });
  }

  void _handleResize(DragUpdateDetails details) {
    setState(() {
      final size = MediaQuery.of(context).size;

      switch (_resizeDirection) {
        case 'right':
          _width = (_width + details.delta.dx).clamp(widget.minWidth, size.width - _x);
          break;
        case 'bottom':
          _height = (_height + details.delta.dy).clamp(widget.minHeight, size.height - _y);
          break;
        case 'bottom-right':
          _width = (_width + details.delta.dx).clamp(widget.minWidth, size.width - _x);
          _height = (_height + details.delta.dy).clamp(widget.minHeight, size.height - _y);
          break;
        case 'left':
          final newWidth = _width - details.delta.dx;
          if (newWidth >= widget.minWidth && _x + details.delta.dx >= 0) {
            _width = newWidth;
            _x += details.delta.dx;
          }
          break;
        case 'top':
          final newHeight = _height - details.delta.dy;
          if (newHeight >= widget.minHeight && _y + details.delta.dy >= 0) {
            _height = newHeight;
            _y += details.delta.dy;
          }
          break;
        case 'top-left':
          final newWidth = _width - details.delta.dx;
          final newHeight = _height - details.delta.dy;
          if (newWidth >= widget.minWidth && _x + details.delta.dx >= 0) {
            _width = newWidth;
            _x += details.delta.dx;
          }
          if (newHeight >= widget.minHeight && _y + details.delta.dy >= 0) {
            _height = newHeight;
            _y += details.delta.dy;
          }
          break;
        case 'top-right':
          final newHeight = _height - details.delta.dy;
          if (newHeight >= widget.minHeight && _y + details.delta.dy >= 0) {
            _height = newHeight;
            _y += details.delta.dy;
          }
          _width = (_width + details.delta.dx).clamp(widget.minWidth, size.width - _x);
          break;
        case 'bottom-left':
          final newWidth = _width - details.delta.dx;
          if (newWidth >= widget.minWidth && _x + details.delta.dx >= 0) {
            _width = newWidth;
            _x += details.delta.dx;
          }
          _height = (_height + details.delta.dy).clamp(widget.minHeight, size.height - _y);
          break;
      }
    });
  }

  Widget _buildResizeHandle(String direction, Alignment alignment) {
    MouseCursor cursor;
    double? width, height, left, right, top, bottom;
    bool isCorner = false;

    switch (direction) {
      case 'right':
        cursor = SystemMouseCursors.resizeRight;
        width = 8;
        height = double.infinity;
        right = 0;
        top = 0;
        break;
      case 'bottom':
        cursor = SystemMouseCursors.resizeDown;
        width = double.infinity;
        height = 8;
        left = 0;
        bottom = 0;
        break;
      case 'left':
        cursor = SystemMouseCursors.resizeLeft;
        width = 8;
        height = double.infinity;
        left = 0;
        top = 0;
        break;
      case 'top':
        cursor = SystemMouseCursors.resizeUp;
        width = double.infinity;
        height = 8;
        left = 0;
        top = 0;
        break;
      case 'top-left':
        cursor = SystemMouseCursors.resizeUpLeft;
        width = 20;
        height = 20;
        left = 0;
        top = 0;
        isCorner = true;
        break;
      case 'top-right':
        cursor = SystemMouseCursors.resizeUpRight;
        width = 20;
        height = 20;
        right = 0;
        top = 0;
        isCorner = true;
        break;
      case 'bottom-left':
        cursor = SystemMouseCursors.resizeDownLeft;
        width = 20;
        height = 20;
        left = 0;
        bottom = 0;
        isCorner = true;
        break;
      case 'bottom-right':
        cursor = SystemMouseCursors.resizeDownRight;
        width = 20;
        height = 20;
        right = 0;
        bottom = 0;
        isCorner = true;
        break;
      default:
        cursor = SystemMouseCursors.basic;
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanStart: (_) {
            setState(() {
              _isResizing = true;
              _resizeDirection = direction;
            });
          },
          onPanUpdate: _onPanUpdate,
          onPanEnd: (_) {
            setState(() {
              _isResizing = false;
              _resizeDirection = null;
            });
          },
          child: Container(
            color: Colors.transparent,
            // Köşelerde görsel indicator ekle
            child: isCorner
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop yok - arkadaki işlemlere izin vermek için

        // Dialog
        Positioned(
          left: _x,
          top: _y,
          child: GestureDetector(
            onTap: () {}, // Backdrop'un tap'ini engelle
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: _width,
                height: _height,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // İçerik
                      widget.child,

                      // Resize handle'ları
                      _buildResizeHandle('top', Alignment.topCenter),
                      _buildResizeHandle('bottom', Alignment.bottomCenter),
                      _buildResizeHandle('left', Alignment.centerLeft),
                      _buildResizeHandle('right', Alignment.centerRight),
                      _buildResizeHandle('top-left', Alignment.topLeft),
                      _buildResizeHandle('top-right', Alignment.topRight),
                      _buildResizeHandle('bottom-left', Alignment.bottomLeft),
                      _buildResizeHandle('bottom-right', Alignment.bottomRight),
                    ],
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

/// Header widget'ı - Draggable yapabilmek için
class DraggableDialogHeader extends StatefulWidget {
  final Widget child;
  final VoidCallback? onClose;

  const DraggableDialogHeader({
    super.key,
    required this.child,
    this.onClose,
  });

  @override
  State<DraggableDialogHeader> createState() => _DraggableDialogHeaderState();
}

class _DraggableDialogHeaderState extends State<DraggableDialogHeader> {
  @override
  Widget build(BuildContext context) {
    // Parent'taki _DraggableResizableDialogState'e erişmek için
    final dialogState = context.findAncestorStateOfType<_DraggableResizableDialogState>();

    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(
        onPanStart: (_) {
          dialogState?.setState(() {
            dialogState._isDragging = true;
          });
        },
        onPanUpdate: (details) {
          dialogState?._onPanUpdate(details);
        },
        onPanEnd: (_) {
          dialogState?.setState(() {
            dialogState._isDragging = false;
          });
        },
        child: widget.child,
      ),
    );
  }
}
