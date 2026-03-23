import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/MyPracticeExams/my_practice_exams_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_practice_exams_shell_part.dart';
part 'my_practice_exams_content_part.dart';

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
}
