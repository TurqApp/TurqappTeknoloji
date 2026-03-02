import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TurqSearchBar extends StatelessWidget {
  const TurqSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = "Ara",
    this.onTap,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(CupertinoIcons.search, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onTap: onTap,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontFamily: "MontserratMedium",
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
