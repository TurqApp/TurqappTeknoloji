import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Education/Tests/SolveTest/solve_test_controller.dart';

part 'solve_test_shell_part.dart';
part 'solve_test_question_part.dart';

class SolveTest extends StatefulWidget {
  final String testID;
  final Function showSucces;

  const SolveTest({super.key, required this.testID, required this.showSucces});

  @override
  State<SolveTest> createState() => _SolveTestState();
}

class _SolveTestState extends State<SolveTest> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final SolveTestController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'solve_test_${widget.testID}_${identityHashCode(this)}';
    _ownsController = maybeFindSolveTestController(tag: _controllerTag) == null;
    controller = ensureSolveTestController(
      testID: widget.testID,
      showSucces: widget.showSucces,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          maybeFindSolveTestController(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<SolveTestController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _buildBody(context),
      ),
    );
  }
}
