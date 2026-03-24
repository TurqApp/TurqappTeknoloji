import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/MyPracticeExams/my_practice_exams_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MyPracticeExams extends StatefulWidget {
  const MyPracticeExams({super.key});

  @override
  State<MyPracticeExams> createState() => _MyPracticeExamsState();
}

class _MyPracticeExamsState extends State<MyPracticeExams> {
  late final MyPracticeExamsController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existing = MyPracticeExamsController.maybeFind();
    _ownsController = existing == null;
    controller = existing ?? MyPracticeExamsController.ensure();
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(MyPracticeExamsController.maybeFind(), controller)) {
      Get.delete<MyPracticeExamsController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = CurrentUserService.instance.effectiveUserId;

    if (uid.isEmpty) {
      return _buildMissingSessionShell();
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'pasaj.common.published'.tr),
            Expanded(
              child: Obx(() {
                return _buildPublishedExamsContent();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingSessionShell() {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'pasaj.common.published'.tr),
            Expanded(
              child: Center(
                child: Text(
                  'practice.user_session_missing'.tr,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishedExamsContent() {
    if (controller.isLoading.value) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (controller.exams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'practice.published_empty'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 15,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: () => controller.fetchExams(forceRefresh: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 0.52,
          ),
          itemCount: controller.exams.length,
          itemBuilder: (context, index) {
            return DenemeGrid(
              model: controller.exams[index],
              getData: () async {},
            );
          },
        ),
      ),
    );
  }
}
