import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/info_message.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';

class SavedTutorings extends StatefulWidget {
  const SavedTutorings({super.key});

  @override
  State<SavedTutorings> createState() => _SavedTutoringsState();
}

class _SavedTutoringsState extends State<SavedTutorings> {
  late final SavedTutoringsController savedController;
  late final bool _ownsSavedController;

  @override
  void initState() {
    super.initState();
    _ownsSavedController = maybeFindSavedTutoringsController() == null;
    savedController = ensureSavedTutoringsController();
  }

  @override
  void dispose() {
    if (_ownsSavedController &&
        identical(maybeFindSavedTutoringsController(), savedController)) {
      Get.delete<SavedTutoringsController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ViewModeController viewModeController =
        ensureViewModeController(permanent: true);
    final TutoringController tutoringController = ensureTutoringController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle('tutoring.saved'.tr),
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
