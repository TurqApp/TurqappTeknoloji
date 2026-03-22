import 'package:flutter/widgets.dart';

class AppIconSurface extends StatelessWidget {
  static const double kSize = 36;
  static const double kRadius = 10;
  static const double kIconSize = 20;
  static const double kGap = 2;

  const AppIconSurface({
    super.key,
    required this.child,
    this.size = kSize,
    this.radius = kRadius,
    this.color = const Color(0xFFFFFFFF),
  });

  final Widget child;
  final double size;
  final double radius;
  final Color color;

  static BoxDecoration decoration({
    double radius = 10,
    Color color = const Color(0xFFFFFFFF),
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: decoration(radius: radius, color: color),
      alignment: Alignment.center,
      child: child,
    );
  }
}
