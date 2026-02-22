import 'package:flutter/material.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';

class TopBar extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color iconColor;
  final Color borderColor;
  final Color backgroundColor;
  final TextStyle textStyle;
  final double iconSize;
  final EdgeInsets padding;

  const TopBar({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.iconColor = Colors.black87,
    this.borderColor = Colors.black87,
    this.backgroundColor = Colors.white,
    this.textStyle = const TextStyle(
      fontSize: 15,
      color: Colors.black87,
      fontFamily: "MontserratMedium",
    ),
    this.iconSize = 15,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        height: 35,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: iconSize, weight: 2),
            8.pw,
            Text(text, style: textStyle),
          ],
        ),
      ),
    );
  }
}
