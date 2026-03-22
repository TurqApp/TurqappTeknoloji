import 'package:flutter/material.dart';

class SlimSendIcon extends StatelessWidget {
  const SlimSendIcon({
    super.key,
    required this.color,
    this.size = 18,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SlimSendIconPainter(color: color),
      ),
    );
  }
}

class _SlimSendIconPainter extends CustomPainter {
  const _SlimSendIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.52)
      ..lineTo(size.width * 0.82, size.height * 0.20)
      ..lineTo(size.width * 0.58, size.height * 0.84)
      ..close();

    canvas.drawPath(path, stroke);
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.50),
      Offset(size.width * 0.68, size.height * 0.34),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SlimSendIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
