import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';

import '../StoryContentProfiles/story_content_profiles.dart';
import 'story_likes_controller.dart';

class StoryLikes extends StatefulWidget {
  final String storyID;
  const StoryLikes({super.key, required this.storyID});

  @override
  State<StoryLikes> createState() => _StoryLikesState();
}

class _StoryLikesState extends State<StoryLikes> {
  late final String _controllerTag;
  late final StoryLikesController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'story_likes_${widget.storyID}_${identityHashCode(this)}';
    final existingController =
        StoryLikesController.maybeFind(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = StoryLikesController.ensure(tag: _controllerTag);
      _ownsController = true;
    }
    controller.getData(widget.storyID);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          StoryLikesController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<StoryLikesController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: AppSheetHeader(
                title: "story.likes_title"
                    .trParams({"count": controller.totalLike.toString()}),
              ),
            ),
            Expanded(
              child: controller.list.isNotEmpty
                  ? ListView.builder(
                      itemCount: controller.list.length,
                      itemBuilder: (context, index) {
                        final userid = controller.list[index];
                        return StoryContentProfiles(userID: userid);
                      },
                    )
                  : Center(
                      child: AppStateView.empty(title: "story.no_likes".tr),
                    ),
            )
          ],
        );
      }),
    );
  }
}
