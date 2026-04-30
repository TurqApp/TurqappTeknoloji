import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/profile_navigation_service.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/follower_controller.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'follower_content_view_part.dart';

class FollowerContent extends StatefulWidget {
  final String userID;
  @override
  final ValueKey key;

  const FollowerContent({required this.userID, required this.key})
      : super(key: key);

  @override
  State<FollowerContent> createState() => _FollowerContentState();
}

class _FollowerContentState extends State<FollowerContent> {
  late final String _followTag;
  late final FollowerController controller;

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _followTag = 'follower_content_${widget.userID}_${identityHashCode(this)}';
    controller = ensureFollowerController(tag: _followTag);
    controller.getData(widget.userID);
    if (widget.userID != _currentUid) {
      controller.followControl(widget.userID);
    }
  }

  @override
  void dispose() {
    final existing = maybeFindFollowerController(tag: _followTag);
    if (identical(existing, controller)) {
      Get.delete<FollowerController>(tag: _followTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildFollowerContent(context);
  }
}
