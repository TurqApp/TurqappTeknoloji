import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScrollTotopButton extends StatelessWidget {
  final ScrollController scrollController;
  final double visibilityThreshold;
  final double? bottom;
  final double? right;
  final double? left;
  final double? top;

  const ScrollTotopButton({
    super.key,
    required this.scrollController,
    this.visibilityThreshold = 200,
    this.bottom = 20,
    this.right = 20,
    this.left,
    this.top,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: right,
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: scrollController,
        builder: (context, _) {
          bool isVisible = scrollController.hasClients &&
              scrollController.offset > visibilityThreshold;

          return Visibility(
            visible: isVisible,
            child: GestureDetector(
              onTap: () {
                scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: Opacity(
                opacity: 0.5,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_up,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
