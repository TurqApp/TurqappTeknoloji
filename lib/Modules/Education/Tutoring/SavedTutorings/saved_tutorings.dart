import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Kaydedilen Dersler"),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Obx(() {
                  final filteredList = tutoringController.tutoringList
                      .where(
                        (tutoring) => savedController.savedTutoringIds
                            .contains(tutoring.docID),
                      )
                      .toList();
                  return TutoringWidgetBuilder(
                    tutoringList: filteredList,
                    users: tutoringController.users,
                    isGridView: viewModeController.isGridView.value,
                    infoMessage: Infomessage(
                      infoMessage: "Kaydedilen ders bulunmuyor!",
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
