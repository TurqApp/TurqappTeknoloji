import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';

class EducationActionIconButton extends StatelessWidget {
  const EducationActionIconButton({
    super.key,
    required this.onTap,
    this.icon,
    this.child,
    this.size = 28,
    this.radius = AppIconSurface.kRadius,
    this.iconSize = 17,
    this.iconColor = Colors.black87,
  }) : assert(icon != null || child != null);

  final VoidCallback onTap;
  final IconData? icon;
  final Widget? child;
  final double size;
  final double radius;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return AppHeaderActionButton(
      onTap: onTap,
      size: size,
      radius: radius,
      child: child ??
          Icon(
            icon,
            color: iconColor,
            size: iconSize,
          ),
    );
  }
}

class EducationShareIconButton extends StatelessWidget {
  const EducationShareIconButton({
    super.key,
    required this.onTap,
    this.size = 28,
    this.radius = AppIconSurface.kRadius,
    this.iconSize = 18,
  });

  final VoidCallback onTap;
  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return EducationActionIconButton(
      onTap: onTap,
      icon: CupertinoIcons.share_up,
      size: size,
      radius: radius,
      iconSize: iconSize,
    );
  }
}

class EducationFeedShareIconButton extends StatelessWidget {
  const EducationFeedShareIconButton({
    super.key,
    required this.onTap,
    this.size = 28,
    this.iconSize = 18,
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
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final nodeRadius = size.width * 0.12;
    final left = Offset(size.width * 0.26, size.height * 0.56);
    final topRight = Offset(size.width * 0.72, size.height * 0.30);
    final bottomRight = Offset(size.width * 0.72, size.height * 0.78);

    canvas.drawLine(
      Offset(left.dx + nodeRadius * 0.85, left.dy - nodeRadius * 0.55),
      Offset(topRight.dx - nodeRadius * 0.95, topRight.dy + nodeRadius * 0.45),
      stroke,
    );
    canvas.drawLine(
      Offset(left.dx + nodeRadius * 0.85, left.dy + nodeRadius * 0.55),
      Offset(bottomRight.dx - nodeRadius * 0.95,
          bottomRight.dy - nodeRadius * 0.45),
      stroke,
    );
    canvas.drawCircle(left, nodeRadius, stroke);
    canvas.drawCircle(topRight, nodeRadius, stroke);
    canvas.drawCircle(bottomRight, nodeRadius, stroke);
  }

  @override
  bool shouldRepaint(covariant _EducationFeedSharePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
