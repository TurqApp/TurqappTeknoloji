import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';

class AppHeaderActionButton extends StatelessWidget {
  const AppHeaderActionButton({
    super.key,
    required this.child,
    this.onTap,
    this.showBadge = false,
    this.badgeKey,
    this.badgeColor = const Color(0xFF00C853),
    this.size = AppIconSurface.kSize,
    this.opacity = 1,
    this.surfaceColor = const Color(0xFFFFFFFF),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool showBadge;
  final Key? badgeKey;
  final Color badgeColor;
  final double size;
  final double opacity;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final content = Opacity(
      opacity: opacity,
      child: AppIconSurface(
        size: size,
        color: surfaceColor,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (showBadge)
              Positioned(
                key: badgeKey,
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

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onTap,
    this.icon = CupertinoIcons.arrow_left,
    this.iconSize = 20,
    this.iconColor = Colors.black,
    this.surfaceColor = const Color(0xFFFFFFFF),
  });

  final VoidCallback? onTap;
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return AppHeaderActionButton(
      onTap: onTap ?? () => Get.back(),
      surfaceColor: surfaceColor,
      child: Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
    );
  }
}

class AppPageTitle extends StatelessWidget {
  const AppPageTitle(
    this.title, {
    super.key,
    this.fontSize = 20,
    this.translate = false,
  });

  final String title;
  final double fontSize;
  final bool translate;

  @override
  Widget build(BuildContext context) {
    final displayTitle = translate ? title.tr : title;
    return Text(
      displayTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontFamily: 'MontserratBold',
      ),
    );
  }
}
