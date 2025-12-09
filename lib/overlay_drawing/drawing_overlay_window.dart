import 'package:flutter/material.dart';
import 'drawing_canvas.dart';
import 'drawing_toolbar.dart';

/// Sistem genelinde çalışan şeffaf çizim overlay'i
class DrawingOverlayWindow extends StatefulWidget {
  const DrawingOverlayWindow({super.key});

  @override
  State<DrawingOverlayWindow> createState() => _DrawingOverlayWindowState();
}

class _DrawingOverlayWindowState extends State<DrawingOverlayWindow> {
  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.0;
  bool _isEraser = false;
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Çizim Canvas'ı (Tam ekran)
          Positioned.fill(
            child: DrawingCanvas(
              key: _canvasKey,
              color: _selectedColor,
              strokeWidth: _strokeWidth,
              isEraser: _isEraser,
            ),
          ),

          // Sol tarafta toolbar
          Positioned(
            left: 16,
            top: 100,
            child: DrawingToolbar(
              selectedColor: _selectedColor,
              strokeWidth: _strokeWidth,
              isEraser: _isEraser,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                  _isEraser = false;
                });
              },
              onStrokeWidthChanged: (width) {
                setState(() {
                  _strokeWidth = width;
                });
              },
              onEraserToggle: () {
                setState(() {
                  _isEraser = !_isEraser;
                });
              },
              onClear: () {
                _canvasKey.currentState?.clear();
              },
              onUndo: () {
                _canvasKey.currentState?.undo();
              },
              onClose: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
