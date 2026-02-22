import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/infoMessage.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/SavedTutoringsController.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringController.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringWidgetBuilder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/ViewModeController.dart.dart';

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
                  return Obx(() {
                    final users = tutoringController.users;
                    return TutoringWidgetBuilder(
                      tutoringList: filteredList,
                      users: users,
                      isGridView: viewModeController.isGridView.value,
                      infoMessage: Infomessage(
                        infoMessage: "Kaydedilen ders bulunmuyor!",
                      ),
                    );
                  });
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
