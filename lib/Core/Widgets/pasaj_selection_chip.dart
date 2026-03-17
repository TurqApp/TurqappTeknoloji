import 'package:flutter/material.dart';

class PasajSelectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final double fontSize;
  final String selectedFontFamily;
  final String unselectedFontFamily;
  final TextAlign textAlign;

  const PasajSelectionChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.width,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fontSize = 14,
    this.selectedFontFamily = "MontserratBold",
    this.unselectedFontFamily = "MontserratMedium",
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: width,
        height: height,
        alignment: Alignment.center,
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? Colors.black.withValues(alpha: 0.06) : Colors.white,
          borderRadius: borderRadius,
          border: Border.all(
            color: selected
                ? Colors.black.withValues(alpha: 0.32)
                : Colors.black.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          textAlign: textAlign,
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontFamily: selected ? selectedFontFamily : unselectedFontFamily,
          ),
        ),
      ),
    );
  }
}
