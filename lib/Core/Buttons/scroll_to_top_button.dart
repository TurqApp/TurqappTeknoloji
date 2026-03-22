import 'dart:ui';

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
    final effectiveBottom = bottom != null ? bottom! + 60 : null;
    return Positioned(
      bottom: effectiveBottom,
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
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 16,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      CupertinoIcons.arrow_up,
                      color: Colors.black,
                    ),
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
