import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTestResults/my_test_results_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestPastResultContent/test_past_result_content.dart';

part 'my_test_results_shell_part.dart';
part 'my_test_results_content_part.dart';

class MyTestResults extends StatefulWidget {
  const MyTestResults({super.key});

  @override
  State<MyTestResults> createState() => _MyTestResultsState();
}

class _MyTestResultsState extends State<MyTestResults> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final MyTestResultsController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'tests_results_${identityHashCode(this)}';
    final existing = MyTestResultsController.maybeFind(tag: _controllerTag);
    _ownsController = existing == null;
    controller =
        existing ?? MyTestResultsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = MyTestResultsController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<MyTestResultsController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }
}
