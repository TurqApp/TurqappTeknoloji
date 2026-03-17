import 'package:flutter/material.dart';

class AppSheetActionTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const AppSheetActionTile({
    super.key,
    this.leading,
    required this.title,
    required this.onTap,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
