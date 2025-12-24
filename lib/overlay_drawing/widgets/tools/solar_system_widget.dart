import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as v;

class SolarSystemWidget extends StatefulWidget {
  const SolarSystemWidget({super.key});

  @override
  State<SolarSystemWidget> createState() => _SolarSystemWidgetState();
}

class _SolarSystemWidgetState extends State<SolarSystemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = true;
  double _speedMultiplier = 1.0;

  // Camera State
  double _rotationX = 0.0; // Pitch
  double _rotationY = 0.0; // Yaw
  double _startRotationX = 0.0;
  double _startRotationY = 0.0;
  Offset _lastFocalPoint = Offset.zero;
  double _scale = 0.8;
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _rotationX = 0.4;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying)
        _controller.repeat();
      else
        _controller.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        // Starfield background
        image: DecorationImage(
          image: AssetImage(
            'assets/stars_bg.png',
          ), // Fallback handled by color if missing
          fit: BoxFit.cover,
          opacity: 0.5,
        ),
      ),
      child: Stack(
        children: [
          // Stars (Procedural fallback if no image)
          if (true)
            Positioned.fill(child: CustomPaint(painter: _StarFieldPainter())),

          // 3D Viewport
          GestureDetector(
            onScaleStart: (details) {
              _startRotationX = _rotationX;
              _startRotationY = _rotationY;
              _lastFocalPoint = details.focalPoint;
              _baseScale = _scale;
            },
            onScaleUpdate: (details) {
              setState(() {
                final dx = details.focalPoint.dx - _lastFocalPoint.dx;
                final dy = details.focalPoint.dy - _lastFocalPoint.dy;
                _rotationY = _startRotationY + (dx * 0.01);
                _rotationX = (_startRotationX - (dy * 0.01)).clamp(
                  -math.pi / 2 + 0.1,
                  math.pi / 2 - 0.1,
                );
                _scale = (_baseScale * details.scale).clamp(0.2, 5.0);
              });
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _SolarSystem3DPainter(
                      progress: _controller.value,
                      rotationX: _rotationX,
                      rotationY: _rotationY,
                      scale: _scale,
                    ),
                  );
                },
              ),
            ),
          ),

          // Controls
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: _togglePlay,
                  ),
                  const Text('Hız: ', style: TextStyle(color: Colors.white)),
                  DropdownButton<double>(
                    dropdownColor: Colors.grey.shade900,
                    value: _speedMultiplier,
                    style: const TextStyle(color: Colors.white),
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                      DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                      DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                      DropdownMenuItem(value: 5.0, child: Text('5.0x')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _speedMultiplier = val!;
                        _controller.duration = Duration(
                          milliseconds: (60000 / _speedMultiplier).round(),
                        );
                        if (_isPlaying) _controller.repeat();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const Positioned(
            top: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3D Güneş Sistemi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sürükleyerek döndürün',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final List<Offset> stars = List.generate(
    200,
    (index) => Offset(math.Random().nextDouble(), math.Random().nextDouble()),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var star in stars) {
      double r = math.Random().nextDouble() * 1.5;
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SolarSystem3DPainter extends CustomPainter {
  final double progress;
  final double rotationX;
  final double rotationY;
  final double scale;

  _SolarSystem3DPainter({
    required this.progress,
    required this.rotationX,
    required this.rotationY,
    required this.scale,
  });

  // Schematic Distances
  final List<_Planet> _planets = [
    _Planet('Merkür', const Color(0xFFBEBEBE), 50, 5, 4.1),
    _Planet('Venüs', const Color(0xFFE3BB76), 80, 9, 1.6),
    _Planet('Dünya', const Color(0xFF2196F3), 110, 10, 1.0),
    _Planet('Mars', const Color(0xFFD84315), 140, 7, 0.53),
    _Planet('Jüpiter', const Color(0xFFDFA878), 200, 24, 0.4),
    _Planet('Satürn', const Color(0xFFF4D03F), 280, 20, 0.15),
    _Planet('Uranüs', const Color(0xFF81D4FA), 360, 15, 0.05),
    _Planet('Neptün', const Color(0xFF3F51B5), 440, 14, 0.03),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    List<_RenderObject> drawList = [];

    // Sun
    drawList.add(
      _RenderObject(
        pos: v.Vector3(0, 0, 0),
        radius: 28,
        color: Colors.orange,
        type: _RenderType.sun,
      ),
    );

    // Planets
    for (var planet in _planets) {
      double angle = 2 * math.pi * (progress * 5 * planet.speed % 1.0);
      double x = planet.distance * math.cos(angle);
      double z = planet.distance * math.sin(angle);

      drawList.add(
        _RenderObject(
          pos: v.Vector3(x, 0, z),
          radius: planet.size,
          color: planet.color,
          type: _RenderType.planet,
          planet: planet,
        ),
      );
    }

    // Transform
    final rotMatrix = v.Matrix4.identity()
      ..rotateX(rotationX)
      ..rotateY(rotationY);

    for (var obj in drawList) {
      obj.transformedPos = rotMatrix.transform3(obj.pos.clone());
    }

    // Sort
    drawList.sort((a, b) => a.transformedPos!.z.compareTo(b.transformedPos!.z));

    // Draw Orbits
    _drawOrbits(canvas, center, rotMatrix);

    // Draw Objects
    for (var obj in drawList) {
      _drawObject(canvas, center, obj);
    }
  }

  void _drawOrbits(Canvas canvas, Offset center, v.Matrix4 rotMatrix) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var planet in _planets) {
      Path path = Path();
      bool first = true;
      // High res orbit
      for (int i = 0; i <= 90; i++) {
        double angle = (i / 90) * 2 * math.pi;
        double x = planet.distance * math.cos(angle);
        double z = planet.distance * math.sin(angle);
        v.Vector3 tp = rotMatrix.transform3(v.Vector3(x, 0, z));
        Offset screenP = center + Offset(tp.x, tp.y) * scale;

        if (first) {
          path.moveTo(screenP.dx, screenP.dy);
          first = false;
        } else {
          path.lineTo(screenP.dx, screenP.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawObject(Canvas canvas, Offset center, _RenderObject obj) {
    Offset screenPos =
        center + Offset(obj.transformedPos!.x, obj.transformedPos!.y) * scale;
    double r = obj.radius * scale;

    if (obj.type == _RenderType.sun) {
      // Sun Glow
      var paintGlow = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
      paintGlow.color = Colors.orangeAccent.withValues(alpha: 0.6);
      canvas.drawCircle(screenPos, r * 1.8, paintGlow);

      paintGlow.color = Colors.yellow.withValues(alpha: 0.8);
      canvas.drawCircle(screenPos, r * 1.3, paintGlow);

      // Sun Body
      var paintSun = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, Colors.yellow, Colors.orange],
          stops: const [0.1, 0.4, 1.0],
          center: Alignment.center,
        ).createShader(Rect.fromCircle(center: screenPos, radius: r));
      canvas.drawCircle(screenPos, r, paintSun);
    } else {
      // Planet Base
      var paintBase = Paint()..color = obj.color;

      // Texture Effects (Bands for Jupiter)
      if (obj.planet?.name == 'Jüpiter') {
        paintBase.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            obj.color,
            Colors.brown.shade300,
            obj.color,
            Colors.brown.shade400,
            obj.color,
          ],
          stops: const [0.1, 0.3, 0.5, 0.7, 0.9],
        ).createShader(Rect.fromCircle(center: screenPos, radius: r));
      } else if (obj.planet?.name == 'Dünya') {
        // Subtle atmosphere gradient
        paintBase.shader = RadialGradient(
          colors: [obj.color, Colors.blue.shade900],
          stops: const [0.6, 1.0],
          center: Alignment.center,
        ).createShader(Rect.fromCircle(center: screenPos, radius: r));
      }

      // Draw Planet Body
      canvas.drawCircle(screenPos, r, paintBase);

      // Saturn Rings (Behind if tilted back?)
      // Complex sorting for rings. Simpler: Draw Ring, erase center? No, Painter's algo.
      // We'll draw Ring AFTER if Z sort allows, but ring goes around.
      // Simple implementation: Draw Ring on top but masked?
      // Let's just draw scale-adjusted Oval.
      if (obj.planet?.name == 'Satürn') {
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.3
          ..shader =
              LinearGradient(
                colors: [
                  Colors.white24,
                  Colors.amber.withValues(alpha: 0.3),
                  Colors.white12,
                ],
              ).createShader(
                Rect.fromLTWH(
                  screenPos.dx - r * 2,
                  screenPos.dy - r,
                  r * 4,
                  r * 2,
                ),
              );

        canvas.drawOval(
          Rect.fromCenter(center: screenPos, width: r * 3.5, height: r * 0.8),
          ringPaint,
        );
      }

      // Dynamic Lighting (Shadow)
      // Light is at (0,0,0). Planet is at obj.pos.
      // In Screen Space, the vector from Planet to Sun is (Center - ScreenPos).
      // The "Lit" side faces Center. The "Dark" side faces Away.
      // We can draw a RadialGradient offset towards the Sun.

      Offset toSun = center - screenPos;
      double dist = toSun.distance;
      Offset lightOffset = Offset.zero;
      if (dist > 0) {
        // Normalize and scale magnitude to radius (shift highlight)
        lightOffset = Offset(toSun.dx / dist, toSun.dy / dist) * (r * 0.5);
      }

      final shadowPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
          stops: const [0.2, 1.0], // Start shadow away from light center
          center: Alignment(
            lightOffset.dx / r,
            lightOffset.dy / r,
          ), // Offset highlight
          radius: 1.3,
        ).createShader(Rect.fromCircle(center: screenPos, radius: r));

      canvas.drawCircle(screenPos, r, shadowPaint);

      // Label
      if (r > 4) {
        TextSpan span = TextSpan(
          text: obj.planet?.name,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        );
        TextPainter tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(
          canvas,
          Offset(screenPos.dx - tp.width / 2, screenPos.dy + r + 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SolarSystem3DPainter oldDelegate) => true;
}

enum _RenderType { sun, planet }

class _RenderObject {
  final v.Vector3 pos;
  v.Vector3? transformedPos;
  final double radius;
  final Color color;
  final _RenderType type;
  final _Planet? planet;

  _RenderObject({
    required this.pos,
    required this.radius,
    required this.color,
    required this.type,
    this.planet,
  });
}

class _Planet {
  final String name;
  final Color color;
  final double distance;
  final double size;
  final double speed;

  _Planet(this.name, this.color, this.distance, this.size, this.speed);
}
