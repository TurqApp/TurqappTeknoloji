import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryContentProfiles/story_content_profiles.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StorySeens/story_seens_controller.dart';
import '../../../../Core/empty_row.dart';

class StorySeens extends StatelessWidget {
  final String storyID;
  StorySeens({super.key, required this.storyID});
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StorySeensController(), tag: storyID);
    controller.getData(storyID);
    return SafeArea(
      child: Obx(() {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: AppSheetHeader(
                title: "Görüntüleme (${controller.totalSeen})",
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
                      child: EmptyRow(text: "Kimse hikayeni görüntülemedi"),
                    ),
            )
          ],
        );
      }),
    );
  }
}
