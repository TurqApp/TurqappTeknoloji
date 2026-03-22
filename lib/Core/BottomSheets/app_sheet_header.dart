import 'package:flutter/material.dart';

class AppSheetHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;
  final double titleSize;
  final String fontFamily;
  final FontWeight? fontWeight;

  const AppSheetHeader({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.only(bottom: 14),
    this.titleSize = 18,
    this.fontFamily = "MontserratBold",
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: titleSize,
              fontFamily: fontFamily,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}
