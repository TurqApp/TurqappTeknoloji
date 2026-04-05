import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TurqSearchBar extends StatefulWidget {
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
  State<TurqSearchBar> createState() => _TurqSearchBarState();
}

class _TurqSearchBarState extends State<TurqSearchBar> {
  final FocusNode _fallbackFocusNode = FocusNode();
  final TextEditingController _fallbackController = TextEditingController();

  static void _noopFocusListener() {}
  static void _noopTextListener() {}

  FocusNode? _resolveUsableFocusNode(FocusNode? candidate) {
    if (candidate == null) return null;
    try {
      candidate.addListener(_noopFocusListener);
      candidate.removeListener(_noopFocusListener);
      return candidate;
    } catch (_) {
      return null;
    }
  }

  TextEditingController _resolveUsableController(
    TextEditingController candidate,
  ) {
    try {
      candidate.addListener(_noopTextListener);
      candidate.removeListener(_noopTextListener);
      if (_fallbackController.text != candidate.text) {
        _fallbackController.value = candidate.value;
      }
      return candidate;
    } catch (_) {
      return _fallbackController;
    }
  }

  @override
  void dispose() {
    _fallbackFocusNode.dispose();
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedHintText =
        widget.hintText.isEmpty ? 'common.search'.tr : widget.hintText;
    final effectiveFocusNode =
        _resolveUsableFocusNode(widget.focusNode) ?? _fallbackFocusNode;
    final effectiveController = _resolveUsableController(widget.controller);

    return Container(
      height: TurqSearchBar.height,
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
                valueListenable: effectiveController,
                builder: (context, value, _) {
                  return TextField(
                    controller: effectiveController,
                    focusNode: effectiveFocusNode,
                    onTap: widget.onTap,
                    onChanged: widget.onChanged,
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
                                effectiveController.clear();
                                widget.onChanged?.call('');
                                widget.onClear?.call();
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
