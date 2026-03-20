import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/info_message.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';

class SavedTutorings extends StatelessWidget {
  const SavedTutorings({super.key});

  @override
  Widget build(BuildContext context) {
    final SavedTutoringsController savedController = Get.put(
      SavedTutoringsController(),
    );
    final ViewModeController viewModeController =
        Get.find<ViewModeController>();
    final TutoringController tutoringController =
        Get.find<TutoringController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
        ),
        title: Text(
          'tutoring.saved'.tr,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final filteredList = tutoringController.tutoringList
                    .where(
                      (tutoring) => savedController.savedTutoringIds.contains(
                        tutoring.docID,
                      ),
                    )
                    .toList();
                final content = TutoringWidgetBuilder(
                  tutoringList: filteredList,
                  isGridView: viewModeController.isGridView.value,
                  infoMessage: Infomessage(
                    infoMessage: 'tutoring.saved_empty'.tr,
                  ),
                );
                if (viewModeController.isGridView.value) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: content,
                  );
                }
                return content;
              }),
            ),
          ],
        ),
      ),
    );
  }
}
