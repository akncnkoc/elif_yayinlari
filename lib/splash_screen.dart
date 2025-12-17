import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_io/io.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'folder_homepage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _borderController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  Path? _logoBorderPath;

  @override
  void initState() {
    super.initState();
    // Snake Border Animation (Looping)
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Pulse/Breathing Animation (Looping)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Fade In Animation (One-time)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Default RRect path so it's never empty initially
    final rect = const Offset(0, 0) & const Size(1, 1);
    _logoBorderPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(0.1)));

    // Extract logo path and start app
    _extractLogoPath();
    _startApp();
  }

  Future<void> _extractLogoPath() async {
    try {
      debugPrint('🔍 Starting logo path extraction...');
      // 1. Load image
      final ByteData data = await rootBundle.load('assets/logo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;

      debugPrint('✅ Image loaded: ${image.width}x${image.height}');

      // 2. Get pixels
      final ByteData? rgba = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (rgba == null) {
        debugPrint('❌ Failed to get pixel data');
        return;
      }

      final width = image.width;
      final height = image.height;

      // 3. Trace boundary
      final points = _traceBoundary(rgba, width, height);
      debugPrint('🧩 Trace complete. Points found: ${points.length}');

      if (points.isNotEmpty) {
        // 4. Create Normalised Path (0.0 to 1.0)
        final path = Path();
        // Normalize coordinates to 0..1 range
        path.moveTo(points[0].dx / width, points[0].dy / height);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx / width, points[i].dy / height);
        }
        path.close();

        if (mounted) {
          setState(() {
            _logoBorderPath = path;
          });
        }
      } else {
        debugPrint(
          '⚠️ No boundary points found (image might be empty or full transparent)',
        );
      }
    } catch (e) {
      debugPrint('❌ Error extracting logo path: $e');
    }
  }

  // Basic implementation of boundary tracing
  List<Offset> _traceBoundary(ByteData data, int width, int height) {
    List<Offset> boundary = [];
    int startX = -1;
    int startY = -1;

    // Find starting pixel (first non-transparent)
    outerLoop:
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final alpha = data.getUint8((y * width + x) * 4 + 3);
        if (alpha > 40) {
          // Threshold for transparency
          startX = x;
          startY = y;
          break outerLoop;
        }
      }
    }

    if (startX == -1) return []; // Empty image

    int cx = startX;
    int cy = startY;
    boundary.add(Offset(cx.toDouble(), cy.toDouble()));

    // 8-connected neighbors relative directions
    final dx = [1, 1, 0, -1, -1, -1, 0, 1];
    final dy = [0, 1, 1, 1, 0, -1, -1, -1];

    int dir = 7;
    int maxPoints = width * height;

    do {
      bool found = false;
      // Search 8 neighbors
      for (int i = 0; i < 8; i++) {
        int checkDir = (dir + i) % 8;
        int nx = cx + dx[checkDir];
        int ny = cy + dy[checkDir];

        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
          final alpha = data.getUint8((ny * width + nx) * 4 + 3);
          if (alpha > 40) {
            cx = nx;
            cy = ny;
            boundary.add(Offset(cx.toDouble(), cy.toDouble()));
            // Backtrack direction logic for Moore tracing
            dir = (checkDir + 6) % 8; // (checkDir - 2) mod 8 for 8-connected
            found = true;
            break;
          }
        }
      }

      if (!found) break; // Isolated pixel
      if (boundary.length > maxPoints) break; // Safety break
    } while (cx != startX || cy != startY);

    return boundary;
  }

  @override
  void dispose() {
    _borderController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startApp() async {
    // 3 saniye bekle
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Windows'ta pencereyi tam ekran yap
    if (!kIsWeb && Platform.isWindows) {
      // Restore system UI overlays
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );

      // Set window style for Main App
      await windowManager.setAsFrameless(); // Maintain frameless look
      await windowManager.setHasShadow(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);

      // Enforce Main App constraints
      await windowManager.setResizable(false);
      await windowManager.setAlwaysOnTop(false);

      // Finally, go fullscreen
      await windowManager.setFullScreen(true);
      await windowManager.focus();
    }

    if (!mounted) return;

    // Ana sayfaya geç
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const FolderHomePage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: FadeTransition(
          opacity: _fadeController,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.70, end: 0.80).animate(
              CurvedAnimation(
                parent: _pulseController,
                curve: Curves.easeInOut,
              ),
            ),
            // Use foregroundPainter to draw ON TOP of the logo
            child: CustomPaint(
              foregroundPainter: SnakeBorderPainter(
                animation: _borderController,
                borderPath: _logoBorderPath,
              ),
              child: Image.asset(
                'assets/logo.png',
                width: 400,
                height: 400,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SnakeBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final Path? borderPath;

  SnakeBorderPainter({required this.animation, this.borderPath})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Determine path
    Path path;
    if (borderPath != null) {
      // Scale normalized path (0..1) to actual size
      final matrix = Matrix4.identity();
      matrix.scale(size.width, size.height);
      path = borderPath!.transform(matrix.storage);
    } else {
      // Fallback: simple rect
      path = Path()..addRect(Offset.zero & size);
    }

    // 1. Glow Effect (Shadow)
    final glowPaint = Paint()
      ..color = Colors.white
          .withValues(alpha: 0.5) // White Glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // 2. Animated Gradient Stroke
    // Define bounds for the gradient to sweep over (center of the path)
    final rect = path.getBounds();

    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [
          Colors.transparent,
          Colors.white, // Pure White Head
          Colors.white, // Pure White Body
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0], // Snake length
        transform: GradientRotation(animation.value * 2 * math.pi),
      ).createShader(rect); // Use path bounds for gradient center

    final metric = path.computeMetrics().first;
    final length = metric.length;
    final segmentLength = length * 0.40; // Length of the snake

    final start = animation.value * length;
    final end = start + segmentLength;

    if (end <= length) {
      final segment = metric.extractPath(start, end);
      canvas.drawPath(segment, glowPaint);
      canvas.drawPath(segment, gradientPaint);
    } else {
      final firstPart = metric.extractPath(start, length);
      final secondPart = metric.extractPath(0, end - length);

      canvas.drawPath(firstPart, glowPaint);
      canvas.drawPath(secondPart, glowPaint);

      canvas.drawPath(firstPart, gradientPaint);
      canvas.drawPath(secondPart, gradientPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SnakeBorderPainter oldDelegate) {
    return true;
  }
}
