import 'package:flutter/material.dart';

class AppSheetActionTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  const AppSheetActionTile({
    super.key,
    this.leading,
    required this.title,
    required this.onTap,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    this.minHeight = 52,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: "MontserratMedium",
                    height: 1.2,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
