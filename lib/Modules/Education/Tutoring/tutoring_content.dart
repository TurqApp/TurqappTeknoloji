import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/info_message.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_category.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';

class TutoringContent extends StatelessWidget {
  final String categoryName;

  const TutoringContent({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final TutoringController controller = ensureTutoringController();
    final ViewModeController viewModeController =
        ensureViewModeController(permanent: true);
    final localizedCategoryName = tutoringBranchLabel(categoryName);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: localizedCategoryName),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: CupertinoActivityIndicator());
                }
                final filteredTutoringList =
                    controller.tutoringList.where((tutoring) {
                  return tutoring.brans == categoryName;
                }).toList();

                if (filteredTutoringList.isEmpty) {
                  return Center(
                    child: Infomessage(
                      infoMessage: 'tutoring.no_lessons_in_category'.trParams({
                        'category': localizedCategoryName,
                      }),
                    ),
                  );
                }

                final content = SingleChildScrollView(
                  child: TutoringWidgetBuilder(
                    tutoringList: filteredTutoringList,
                    isGridView: viewModeController.isGridView.value,
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
