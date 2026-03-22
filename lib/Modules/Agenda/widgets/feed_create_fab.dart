import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

class FeedCreateFab extends StatelessWidget {
  const FeedCreateFab({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey(IntegrationTestKeys.actionFeedCreate),
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.24),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 16,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
