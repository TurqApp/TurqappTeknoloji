import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Tests/TestEntry/test_entry_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';

part 'test_entry_shell_part.dart';
part 'test_entry_shell_content_part.dart';
part 'test_entry_shell_layout_part.dart';

class TestEntry extends StatefulWidget {
  const TestEntry({super.key});

  @override
  State<TestEntry> createState() => _TestEntryState();
}

class _TestEntryState extends State<TestEntry> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final TestEntryController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'test_entry_${identityHashCode(this)}';
    _ownsController =
        TestEntryController.maybeFind(tag: _controllerTag) == null;
    controller = TestEntryController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          TestEntryController.maybeFind(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<TestEntryController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }
}
