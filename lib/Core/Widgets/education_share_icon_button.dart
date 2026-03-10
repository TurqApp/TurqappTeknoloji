import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
          CupertinoIcons.share_up,
          color: Colors.black87,
          size: iconSize,
        ),
      ),
    );
  }
}
