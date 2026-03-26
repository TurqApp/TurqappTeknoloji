import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Modules/Education/Tests/AddTestQuestion/add_test_question_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTestQuestionContent/create_test_question_content.dart';

part 'add_test_question_shell_part.dart';
part 'add_test_question_content_part.dart';

class AddTestQuestion extends StatefulWidget {
  final List<TestReadinessModel> soruList;
  final String testID;
  final String testTuru;
  final Function update;

  const AddTestQuestion({
    super.key,
    required this.soruList,
    required this.testID,
    required this.update,
    required this.testTuru,
  });

  @override
  State<AddTestQuestion> createState() => _AddTestQuestionState();
}

class _AddTestQuestionState extends State<AddTestQuestion> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final AddTestQuestionController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'add_test_question_${widget.testID}_${identityHashCode(this)}';
    _ownsController =
        maybeFindAddTestQuestionController(tag: _controllerTag) == null;
    controller = ensureAddTestQuestionController(
      initialSoruList: widget.soruList,
      testID: widget.testID,
      testTuru: widget.testTuru,
      onUpdate: widget.update,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          maybeFindAddTestQuestionController(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<AddTestQuestionController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildScaffold(context);
}
