import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EducationActionIconButton extends StatelessWidget {
  const EducationActionIconButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.size = 28,
    this.iconSize = 17,
    this.iconColor = Colors.black87,
  });

  final VoidCallback onTap;
  final IconData icon;
  final double size;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
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
