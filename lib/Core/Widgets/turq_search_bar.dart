import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TurqSearchBar extends StatelessWidget {
  const TurqSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = "",
    this.onTap,
    this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    final resolvedHintText = hintText.isEmpty ? 'common.search'.tr : hintText;
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
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onTap: onTap,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      hintText: resolvedHintText,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontFamily: "MontserratMedium",
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: value.text.trim().isEmpty
                          ? null
                          : GestureDetector(
                              onTap: () {
                                controller.clear();
                                onChanged?.call('');
                                onClear?.call();
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  CupertinoIcons.xmark,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                              ),
                            ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: "MontserratMedium",
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
