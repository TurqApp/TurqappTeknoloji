import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTests/my_tests_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestsGrid/tests_grid.dart';

part 'my_tests_shell_part.dart';
part 'my_tests_content_part.dart';

class MyTests extends StatefulWidget {
  const MyTests({super.key});

  @override
  State<MyTests> createState() => _MyTestsState();
}

class _MyTestsState extends State<MyTests> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final MyTestsController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'tests_my_${identityHashCode(this)}';
    final existing = MyTestsController.maybeFind(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ?? MyTestsController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = MyTestsController.maybeFind(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<MyTestsController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }
}
