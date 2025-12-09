import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_io/io.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

import 'overlay_drawing/drawing_canvas.dart';
import 'overlay_drawing/drawing_toolbar.dart';

/// Fatih Kalem benzeri - Sistem genelinde çalışan çizim uygulaması
///
/// Kullanım: flutter run -t lib/drawing_pen_main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sadece desktop'ta çalışır
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    // Ekran boyutunu al
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final screenWidth = primaryDisplay.size.width;
    final screenHeight = primaryDisplay.size.height;

    // Transparent, always-on-top, tam ekran window
    WindowOptions windowOptions = WindowOptions(
      size: Size(screenWidth, screenHeight),
      center: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      alwaysOnTop: true,
      fullScreen: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();

      // Linux için özel transparency ayarları
      if (Platform.isLinux) {
        await windowManager.setBackgroundColor(Colors.transparent);
      }

      await windowManager.setAlwaysOnTop(true);
      await windowManager.setPosition(Offset.zero);
      await windowManager.setSize(Size(screenWidth, screenHeight));
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const DrawingPenApp());
}

class DrawingPenApp extends StatelessWidget {
  const DrawingPenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Çizim Kalemi',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const TransparentDrawingOverlay(),
    );
  }
}

/// Transparent overlay window
class TransparentDrawingOverlay extends StatefulWidget {
  const TransparentDrawingOverlay({super.key});

  @override
  State<TransparentDrawingOverlay> createState() => _TransparentDrawingOverlayState();
}

class _TransparentDrawingOverlayState extends State<TransparentDrawingOverlay> {
  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.0;
  bool _isEraser = false;
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Tam ekran çizim canvas'ı
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
              onClose: () async {
                // Uygulamayı kapat
                if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
                  await windowManager.close();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
