import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';

part 'rozet_content_controller_part.dart';

Color mapRozetToColor(String rozetRaw) {
  final key = normalizeRozetValue(rozetRaw);
  switch (key) {
    case "kirmizi":
      return Colors.red;
    case "mavi":
      return Colors.blue;
    case "sari":
      return Colors.orange;
    case "siyah":
      return Colors.black;
    case "gri":
      return Colors.grey;
    case "turkuaz":
      return const Color(0xFF40E0D0);
    default:
      return Colors.transparent;
  }
}

class RozetContent extends StatefulWidget {
  final double size;
  final String userID;
  final double leftSpacing;
  final String? rozetValue;

  const RozetContent({
    super.key,
    required this.size,
    required this.userID,
    this.leftSpacing = 3,
    this.rozetValue,
  });

  @override
  State<RozetContent> createState() => _RozetContentState();
}

class _RozetContentState extends State<RozetContent> {
  late final String _controllerTag;
  late final RozetController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'rozet_${widget.userID}_${identityHashCode(this)}';
    _ownsController = RozetController.maybeFind(tag: _controllerTag) == null;
    controller = RozetController.ensure(widget.userID, tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          RozetController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<RozetController>(tag: _controllerTag);
    }
    super.dispose();
  }

  Widget _badge(Color color) {
    return Transform.translate(
      offset: const Offset(0, -1),
      child: Padding(
        padding: EdgeInsets.only(left: widget.leftSpacing),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size - 7,
              height: widget.size - 7,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: color,
              size: widget.size,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final knownRozet = (widget.rozetValue ?? '').trim();
    if (knownRozet.isNotEmpty) {
      final mapped = mapRozetToColor(knownRozet);
      return mapped == Colors.transparent
          ? const SizedBox.shrink()
          : _badge(mapped);
    }

    if (widget.userID.isEmpty) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final color = controller.color.value;
      return color == Colors.transparent
          ? const SizedBox.shrink()
          : _badge(color);
    });
  }
}
