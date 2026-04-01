import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Services/reshare_helper.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/follower_controller.dart';
import 'package:turqappv2/Modules/Social/PostSharers/post_sharers_controller.dart';
import 'package:turqappv2/Models/post_sharers_model.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

part 'post_sharers_shell_part.dart';
part 'post_sharers_shell_content_part.dart';
part 'post_sharers_tile_part.dart';

class PostSharers extends StatefulWidget {
  final String postID;

  const PostSharers({super.key, required this.postID});

  @override
  State<PostSharers> createState() => _PostSharersState();
}

class _PostSharersState extends State<PostSharers> {
  late final String _controllerTag;
  late final PostSharersController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'post_sharers_${widget.postID}_${DateTime.now().microsecondsSinceEpoch}';
    _ownsController =
        maybeFindPostSharersController(tag: _controllerTag) == null;
    controller = ensurePostSharersController(
      postID: widget.postID,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindPostSharersController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<PostSharersController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPostSharersShell(context);
  }
}
