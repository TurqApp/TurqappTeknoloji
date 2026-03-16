import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';

class AppHeaderActionButton extends StatelessWidget {
  const AppHeaderActionButton({
    super.key,
    required this.child,
    this.onTap,
    this.showBadge = false,
    this.badgeColor = const Color(0xFF00C853),
    this.size = AppIconSurface.kSize,
    this.opacity = 1,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool showBadge;
  final Color badgeColor;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final content = Opacity(
      opacity: opacity,
      child: AppIconSurface(
        size: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (showBadge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}
