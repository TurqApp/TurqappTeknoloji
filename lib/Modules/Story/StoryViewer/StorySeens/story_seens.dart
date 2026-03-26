import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryContentProfiles/story_content_profiles.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StorySeens/story_seens_controller.dart';
import '../../../../Core/empty_row.dart';

class StorySeens extends StatefulWidget {
  final String storyID;
  const StorySeens({super.key, required this.storyID});

  @override
  State<StorySeens> createState() => _StorySeensState();
}

class _StorySeensState extends State<StorySeens> {
  late final String _controllerTag;
  late final StorySeensController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'story_seens_${widget.storyID}_${identityHashCode(this)}';
    final existingController =
        maybeFindStorySeensController(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = ensureStorySeensController(tag: _controllerTag);
      _ownsController = true;
    }
    controller.getData(widget.storyID);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindStorySeensController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<StorySeensController>(tag: _controllerTag, force: true);
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
                title: 'story.seens_title'.trParams({
                  'count': '${controller.totalSeen}',
                }),
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
                      child: EmptyRow(text: 'story.no_seens'.tr),
                    ),
            )
          ],
        );
      }),
    );
  }
}
