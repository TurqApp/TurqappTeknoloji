import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';

class EducationActionIconButton extends StatelessWidget {
  const EducationActionIconButton({
    super.key,
    required this.onTap,
    this.icon,
    this.child,
    this.size = 28,
    this.iconSize = 17,
    this.iconColor = Colors.black87,
  }) : assert(icon != null || child != null);

  final VoidCallback onTap;
  final IconData? icon;
  final Widget? child;
  final double size;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AppIconSurface(
        size: size,
        radius: 10,
        child: child ??
            Icon(
              icon,
              color: iconColor,
              size: iconSize,
            ),
      ),
    );
  }
}

class EducationShareIconButton extends StatelessWidget {
  const EducationShareIconButton({
    super.key,
    required this.onTap,
    this.size = 28,
    this.iconSize = 17,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return EducationActionIconButton(
      onTap: onTap,
      icon: CupertinoIcons.share_up,
      size: size,
      iconSize: iconSize,
    );
  }
}

class EducationFeedShareIconButton extends StatelessWidget {
  const EducationFeedShareIconButton({
    super.key,
    required this.onTap,
    this.size = 28,
    this.iconSize = 17,
    this.iconColor = Colors.black87,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return EducationActionIconButton(
      onTap: onTap,
      size: size,
      child: SizedBox(
        width: iconSize,
        height: iconSize,
        child: CustomPaint(
          painter: _EducationFeedSharePainter(color: iconColor),
        ),
      ),
    );
  }
}

class _EducationFeedSharePainter extends CustomPainter {
  const _EducationFeedSharePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final left = Offset(size.width * 0.28, size.height * 0.56);
    final topRight = Offset(size.width * 0.74, size.height * 0.28);
    final bottomRight = Offset(size.width * 0.74, size.height * 0.78);
    final radius = size.width * 0.16;

    canvas.drawLine(left, topRight, stroke);
    canvas.drawLine(left, bottomRight, stroke);
    canvas.drawCircle(left, radius, fill);
    canvas.drawCircle(topRight, radius, fill);
    canvas.drawCircle(bottomRight, radius, fill);
  }

  @override
  bool shouldRepaint(covariant _EducationFeedSharePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
