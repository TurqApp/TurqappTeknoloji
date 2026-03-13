import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Services/post_count_manager.dart';
import '../formatters.dart';

class SeenCountLabel extends StatefulWidget {
  final String postID;
  const SeenCountLabel(this.postID, {super.key});

  @override
  State<SeenCountLabel> createState() => _SeenCountLabelState();
}

class _SeenCountLabelState extends State<SeenCountLabel> {
  final PostCountManager _countManager = PostCountManager.instance;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = _countManager.getStatsCount(widget.postID).value;
      return Text(
        NumberFormatter.format(count),
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontFamily: "MontserratBold",
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ],
        ),
      );
    });
  }
}
