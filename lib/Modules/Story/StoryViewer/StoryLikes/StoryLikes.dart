import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../Core/EmptyRow.dart';
import '../StoryContentProfiles/StoryContentProfiles.dart';
import 'StoryLikesController.dart';

class StoryLikes extends StatelessWidget {
  String storyID;
  StoryLikes({super.key, required this.storyID});
  late StoryLikesController controller;
  @override
  Widget build(BuildContext context) {
    controller = Get.put(StoryLikesController(), tag: storyID);
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
                    "Beğeniler (${controller.totalLike})",
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
                      child: EmptyRow(text: "Kimse hikayeni beğenmedi"),
                    ),
            )
          ],
        );
      }),
    );
  }
}
