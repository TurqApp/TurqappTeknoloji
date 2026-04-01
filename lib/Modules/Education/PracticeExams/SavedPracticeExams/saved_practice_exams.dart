import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';

class SavedPracticeExams extends StatefulWidget {
  const SavedPracticeExams({super.key});

  @override
  State<SavedPracticeExams> createState() => _SavedPracticeExamsState();
}

class _SavedPracticeExamsState extends State<SavedPracticeExams> {
  late final SavedPracticeExamsController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existing = maybeFindSavedPracticeExamsController();
    _ownsController = existing == null;
    controller = existing ?? ensureSavedPracticeExamsController();
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(maybeFindSavedPracticeExamsController(), controller)) {
      Get.delete<SavedPracticeExamsController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildSavedPracticeExamsBody());
  }

  Widget _buildSavedPracticeExamsBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          BackButtons(text: 'common.saved'.tr),
          Expanded(child: _buildSavedPracticeExamsContent()),
        ],
      ),
    );
  }

  Widget _buildSavedPracticeExamsContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CupertinoActivityIndicator());
      }

      if (controller.savedExams.isEmpty) {
        return Center(
          child: Text(
            'practice.saved_empty'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "MontserratMedium",
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: GridView.builder(
          itemCount: controller.savedExams.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 0.52,
          ),
          itemBuilder: (context, index) {
            return DenemeGrid(
              model: controller.savedExams[index],
              getData: controller.loadSavedExams,
            );
          },
        ),
      );
    });
  }
}
