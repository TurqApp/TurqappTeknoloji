import 'package:get/get.dart';
import 'package:flutter/material.dart';
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
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey.withAlpha(50),
                    ),
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Text(
                    "Görüntüleme (${controller.totalSeen})",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratBold"),
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey.withAlpha(50),
                    ),
                  )
                ],
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
