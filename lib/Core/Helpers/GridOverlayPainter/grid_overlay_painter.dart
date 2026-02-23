import 'package:flutter/material.dart';

class GridCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    final lineLength = 20.0;

    // Sol üst köşe
    canvas.drawLine(Offset(0, 0), Offset(lineLength, 0), paint); // yatay
    canvas.drawLine(Offset(0, 0), Offset(0, lineLength), paint); // dikey

    // Sağ üst köşe
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - lineLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, lineLength), paint);

    // Sol alt köşe
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - lineLength), paint);
    canvas.drawLine(Offset(0, size.height), Offset(lineLength, size.height), paint);

    // Sağ alt köşe
    canvas.drawLine(
        Offset(size.width, size.height), Offset(size.width - lineLength, size.height), paint);
    canvas.drawLine(
        Offset(size.width, size.height), Offset(size.width, size.height - lineLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
