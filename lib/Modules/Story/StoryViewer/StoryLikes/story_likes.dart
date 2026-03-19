import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';

import '../../../../Core/empty_row.dart';
import '../StoryContentProfiles/story_content_profiles.dart';
import 'story_likes_controller.dart';

class StoryLikes extends StatelessWidget {
  final String storyID;
  StoryLikes({super.key, required this.storyID});
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoryLikesController(), tag: storyID);
    controller.getData(storyID);
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
                      child: EmptyRow(text: "story.no_likes".tr),
                    ),
            )
          ],
        );
      }),
    );
  }
}
