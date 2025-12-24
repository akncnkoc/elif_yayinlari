import 'package:flutter/material.dart';

class AnatomyWidget extends StatefulWidget {
  const AnatomyWidget({super.key});

  @override
  State<AnatomyWidget> createState() => _AnatomyWidgetState();
}

class _AnatomyWidgetState extends State<AnatomyWidget> {
  BodyPart? _selectedPart;
  final TransformationController _transformationController =
      TransformationController();

  final List<BodyPart> _parts = [
    BodyPart(
      id: 'skull',
      name: 'Kafatası (Skull)',
      description:
          'Beyni koruyan karmaşık kemik yapısı. 22 kemikten oluşur.\n\nİşlevi: Beyni dış etkilerden korumak ve yüz şeklini oluşturmak.',
      path: _AnatomyPaths.skull,
    ),
    BodyPart(
      id: 'spine',
      name: 'Omurga (Vertebral Column)',
      description:
          'Vücudun ana desteği. 33 omurdan oluşur.\n\nİşlevi: Vücut ağırlığını taşımak ve omuriliği korumak.',
      path: _AnatomyPaths.spine,
    ),
    BodyPart(
      id: 'ribcage',
      name: 'Göğüs Kafesi (Ribcage)',
      description:
          'Hayati organları koruyan kafes yapı. 12 çift kaburga.\n\nİşlevi: Kalp ve akciğerleri korumak.',
      path: _AnatomyPaths.ribcage,
    ),
    BodyPart(
      id: 'pelvis',
      name: 'Leğen Kemiği (Pelvis)',
      description:
          'Gövdeyi bacaklara bağlayan kemik çatısı.\n\nİşlevi: Oturma, ayakta durma hareketlerinde denge ve destek.',
      path: _AnatomyPaths.pelvis,
    ),
    BodyPart(
      id: 'l_humerus',
      name: 'Sol Üst Kol (Humerus)',
      description: 'Omuzdan dirseğe uzanan uzun kemik.',
      path: _AnatomyPaths.lHumerus,
    ),
    BodyPart(
      id: 'r_humerus',
      name: 'Sağ Üst Kol (Humerus)',
      description: 'Omuzdan dirseğe uzanan uzun kemik.',
      path: _AnatomyPaths.rHumerus,
    ),
    BodyPart(
      id: 'l_forearm',
      name: 'Sol Ön Kol (Radius & Ulna)',
      description: 'Dirsekten bileğe uzanan iki kemik yapısı.',
      path: _AnatomyPaths.lForearm,
    ),
    BodyPart(
      id: 'r_forearm',
      name: 'Sağ Ön Kol (Radius & Ulna)',
      description: 'Dirsekten bileğe uzanan iki kemik yapısı.',
      path: _AnatomyPaths.rForearm,
    ),
    BodyPart(
      id: 'l_femur',
      name: 'Sol Uyluk (Femur)',
      description: 'Vücuttaki en uzun ve en güçlü kemik.',
      path: _AnatomyPaths.lFemur,
    ),
    BodyPart(
      id: 'r_femur',
      name: 'Sağ Uyluk (Femur)',
      description: 'Vücuttaki en uzun ve en güçlü kemik.',
      path: _AnatomyPaths.rFemur,
    ),
    BodyPart(
      id: 'l_tibia',
      name: 'Sol Kaval Kemiği (Tibia)',
      description: 'Dizden ayak bileğine uzanan kalın kemik.',
      path: _AnatomyPaths.lTibia,
    ),
    BodyPart(
      id: 'r_tibia',
      name: 'Sağ Kaval Kemiği (Tibia)',
      description: 'Dizden ayak bileğine uzanan kalın kemik.',
      path: _AnatomyPaths.rTibia,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF1E2833,
        ), // Professional Dark Blue/Grey Background
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // INTERACTIVE GRAPHIC AREA
            Expanded(
              flex: 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.blueGrey.shade800,
                          const Color(0xFF151920),
                        ],
                        center: Alignment.center,
                        radius: 0.8,
                      ),
                    ),
                  ),
                  InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.all(50),
                    child: Center(
                      child: SizedBox(
                        width: 300,
                        height: 600,
                        child: GestureDetector(
                          onTapUp: (details) {
                            // Hit testing logic for paths
                            // We need to inverse transform the tap to model coordinates (300x600)
                            // But since we are inside a fixed SizedBox(300,600), localPosition is exactly what we need
                            _checkHit(details.localPosition);
                          },
                          child: CustomPaint(
                            painter: _AnatomyPainter(
                              parts: _parts,
                              selectedPartId: _selectedPart?.id,
                            ),
                            size: const Size(300, 600),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // CONTROLS
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      children: [
                        _buildControlBtn(Icons.add, () {
                          _transformationController.value.scale(1.2);
                        }),
                        const SizedBox(height: 8),
                        _buildControlBtn(Icons.remove, () {
                          _transformationController.value.scale(0.8);
                        }),
                        const SizedBox(height: 8),
                        _buildControlBtn(Icons.refresh, () {
                          _transformationController.value = Matrix4.identity();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // INFO PANEL
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF263238),
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF37474F),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.monitor_heart_outlined,
                          color: Colors.tealAccent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ANATOMİ ATLASI',
                          style: TextStyle(
                            color: Colors.tealAccent.shade100,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedPart == null) ...[
                            const Icon(
                              Icons.touch_app,
                              size: 48,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "İncelemek için bir bölgeye dokunun.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 16,
                              ),
                            ),
                          ] else ...[
                            Text(
                              _selectedPart!.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 2,
                              width: 50,
                              color: Colors.tealAccent,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _selectedPart!.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 30),
                            _buildInfoCard("Sistem", "İskelet"),
                            const SizedBox(height: 10),
                            _buildInfoCard(
                              "Latince",
                              _selectedPart!.name
                                  .split('(')
                                  .last
                                  .replaceAll(')', ''),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkHit(Offset localPos) {
    // Check elements in reverse render order maybe, or just check all
    // Since paths can overlap, we might want top-most (z-index) or detailed check
    // For this simple atlas, checking sequential is fine.
    for (var part in _parts) {
      if (part.path.contains(localPos)) {
        setState(() {
          _selectedPart = part;
        });
        return;
      }
    }
  }

  Widget _buildControlBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.tealAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class BodyPart {
  final String id;
  final String name;
  final String description;
  final Path path;

  BodyPart({
    required this.id,
    required this.name,
    required this.description,
    required this.path,
  });
}

class _AnatomyPainter extends CustomPainter {
  final List<BodyPart> parts;
  final String? selectedPartId;

  _AnatomyPainter({required this.parts, this.selectedPartId});

  @override
  void paint(Canvas canvas, Size size) {
    // We are drawing in a 300x600 fixed logical space usually

    // Paint for bones
    final bonePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF8D6E63).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final selectedPaint = Paint()
      ..color = Colors.tealAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);

    for (var part in parts) {
      final isSelected = part.id == selectedPartId;

      // Draw shadow
      canvas.drawPath(
        part.path.shift(const Offset(2, 2)),
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Draw bone
      if (isSelected) {
        canvas.drawPath(
          part.path,
          Paint()
            ..color = const Color(0xFFE0F7FA)
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(part.path, selectedPaint);
      } else {
        canvas.drawPath(part.path, bonePaint);
      }

      // Draw details/texture lines if needed (omitted for cleaner verify)
      canvas.drawPath(part.path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnatomyPainter oldDelegate) {
    return oldDelegate.selectedPartId != selectedPartId;
  }
}

// Predefined Paths for a realistic looking Skeleton (Approximate)
class _AnatomyPaths {
  // Using a 300x600 coordinate system

  static final Path skull = Path()
    ..moveTo(130, 40)
    ..cubicTo(130, 20, 170, 20, 170, 40) // Top cranium
    ..cubicTo(180, 50, 180, 70, 170, 90) // Right Jaw
    ..cubicTo(160, 100, 140, 100, 130, 90) // Jaw
    ..cubicTo(120, 70, 120, 50, 130, 40) // Left cheek
    ..close();

  static final Path spine = Path()
    ..moveTo(148, 90)
    ..lineTo(152, 90) // Neck top
    ..quadraticBezierTo(155, 120, 152, 250)
    ..lineTo(148, 250)
    ..quadraticBezierTo(145, 120, 148, 90)
    ..close();

  static final Path ribcage = Path()
    ..moveTo(150, 110) // Sternum top
    ..cubicTo(190, 110, 200, 130, 200, 160) // Right ribs out
    ..quadraticBezierTo(200, 200, 160, 210) // Right ribs bottom
    ..lineTo(140, 210) // Left ribs bottom
    ..quadraticBezierTo(100, 200, 100, 160) // Left ribs out
    ..cubicTo(100, 130, 110, 110, 150, 110)
    ..close();

  static final Path pelvis = Path()
    ..moveTo(130, 250)
    ..quadraticBezierTo(100, 250, 100, 270) // Left Iliac crest
    ..quadraticBezierTo(110, 310, 140, 320) // Pubic
    ..lineTo(160, 320)
    ..quadraticBezierTo(190, 310, 200, 270)
    ..quadraticBezierTo(200, 250, 170, 250)
    ..close();

  static final Path lHumerus = Path()
    ..moveTo(100, 130) // Shoulder
    ..quadraticBezierTo(90, 180, 85, 230) // Elbow
    ..quadraticBezierTo(95, 230, 100, 230)
    ..quadraticBezierTo(110, 180, 115, 130)
    ..close();

  static final Path rHumerus = Path()
    ..moveTo(200, 130) // Shoulder
    ..quadraticBezierTo(210, 180, 215, 230) // Elbow
    ..quadraticBezierTo(205, 230, 200, 230)
    ..quadraticBezierTo(190, 180, 185, 130)
    ..close();

  static final Path lForearm = Path()
    ..moveTo(85, 235) // Elbow
    ..lineTo(70, 300) // Wrist
    ..lineTo(85, 300)
    ..lineTo(100, 235)
    ..close();

  static final Path rForearm = Path()
    ..moveTo(215, 235) // Elbow
    ..lineTo(230, 300) // Wrist
    ..lineTo(215, 300)
    ..lineTo(200, 235)
    ..close();

  static final Path lFemur = Path()
    ..moveTo(125, 300) // Hip
    ..quadraticBezierTo(110, 380, 120, 450) // Knee
    ..lineTo(135, 450)
    ..quadraticBezierTo(140, 380, 145, 300)
    ..close();

  static final Path rFemur = Path()
    ..moveTo(175, 300) // Hip
    ..quadraticBezierTo(190, 380, 180, 450) // Knee
    ..lineTo(165, 450)
    ..quadraticBezierTo(160, 380, 155, 300)
    ..close();

  static final Path lTibia = Path()
    ..moveTo(120, 455) // Knee
    ..lineTo(125, 550) // Ankle
    ..lineTo(135, 550)
    ..lineTo(135, 455)
    ..close();

  static final Path rTibia = Path()
    ..moveTo(180, 455) // Knee
    ..lineTo(175, 550) // Ankle
    ..lineTo(165, 550)
    ..lineTo(165, 455)
    ..close();
}
