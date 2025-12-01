// drawing_painter.dart dosyasının SONUNA ekleyin

import 'package:flutter/material.dart';

class SelectionPainter extends CustomPainter {
  final Rect selectionRect;

  SelectionPainter(this.selectionRect);

  @override
  void paint(Canvas canvas, Size size) {
    // Tüm ekranı yarı saydam siyah ile karart
    final darkPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Seçili alan dışındaki her yeri karart
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRect(selectionRect)
      ..fillType = PathFillType.evenOdd; // Seçili alanı boşluk olarak bırak

    canvas.drawPath(path, darkPaint);

    // Seçili alanın kenarları (mavi parlak çizgi)
    final borderPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(selectionRect, borderPaint);

    // İç border (beyaz ince çizgi - daha belirgin olması için)
    final innerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(selectionRect.deflate(1.5), innerBorderPaint);

    // Köşe tutacakları (mavi daireler)
    final handlePaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;

    final handleOutlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final handleSize = 8.0;
    final corners = [
      selectionRect.topLeft,
      selectionRect.topRight,
      selectionRect.bottomLeft,
      selectionRect.bottomRight,
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, handleSize, handleOutlinePaint);
      canvas.drawCircle(corner, handleSize, handlePaint);
    }

    // Seçim bilgisi (boyut göster) - Daha güzel bir arka plan ile
    final textSpan = TextSpan(
      text:
          '${selectionRect.width.toInt()} × ${selectionRect.height.toInt()} px',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Text arka plan kutusu
    final textX = selectionRect.left;
    final textY = selectionRect.top - textPainter.height - 8;

    final textBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        textX,
        textY,
        textPainter.width + 16,
        textPainter.height + 8,
      ),
      const Radius.circular(4),
    );

    final textBgPaint = Paint()..color = const Color(0xFF2196F3);

    canvas.drawRRect(textBgRect, textBgPaint);

    // Text'i çiz
    textPainter.paint(canvas, Offset(textX + 8, textY + 4));
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) {
    return oldDelegate.selectionRect != selectionRect;
  }
}
