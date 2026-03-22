import 'package:flutter/material.dart';

class MarketTopActionButton extends StatelessWidget {
  const MarketTopActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.semanticsLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final action = GestureDetector(
      key: semanticsLabel == null ? null : ValueKey<String>(semanticsLabel!),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? Colors.pink.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? Colors.pink.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 19,
          color: active ? Colors.pink : Colors.black,
        ),
      ),
    );
    if (semanticsLabel == null) {
      return action;
    }
    return Semantics(
      label: semanticsLabel!,
      button: true,
      child: action,
    );
  }
}
