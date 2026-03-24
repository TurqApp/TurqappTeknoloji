import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Tests/LessonsBasedTests/lesson_based_tests_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid.dart';

part 'lesson_based_tests_content_part.dart';

class LessonBasedTests extends StatefulWidget {
  final String testTuru;

  const LessonBasedTests({super.key, required this.testTuru});

  @override
  State<LessonBasedTests> createState() => _LessonBasedTestsState();
}

class _LessonBasedTestsState extends State<LessonBasedTests> {
  late final LessonBasedTestsController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  String get testTuru => widget.testTuru;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'lesson_based_tests_${widget.testTuru.hashCode}_${identityHashCode(this)}';
    _ownsController =
        LessonBasedTestsController.maybeFind(tag: _controllerTag) == null;
    controller = LessonBasedTestsController.ensure(
      widget.testTuru,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          LessonBasedTestsController.maybeFind(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<LessonBasedTestsController>(tag: _controllerTag);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }

  Widget _buildPage() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackButtons(
              text: 'tests.lesson_based_title'.trParams({'type': testTuru}),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.black,
                  onRefresh: controller.getData,
                  child: Obx(() => _buildContent()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
