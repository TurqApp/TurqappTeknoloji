import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';

part 'saved_practice_exams_shell_part.dart';
part 'saved_practice_exams_content_part.dart';

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
    final existing = SavedPracticeExamsController.maybeFind();
    _ownsController = existing == null;
    controller = existing ?? SavedPracticeExamsController.ensure();
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(SavedPracticeExamsController.maybeFind(), controller)) {
      Get.delete<SavedPracticeExamsController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildSavedPracticeExamsBody());
  }
}
