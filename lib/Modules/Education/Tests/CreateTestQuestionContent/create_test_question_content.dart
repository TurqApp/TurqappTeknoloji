import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTestQuestionContent/create_test_question_content_controller.dart';

part 'create_test_question_content_shell_part.dart';
part 'create_test_question_content_choice_part.dart';

class CreateTestQuestionContent extends StatefulWidget {
  final TestReadinessModel model;
  final String testID;
  final int index;

  const CreateTestQuestionContent({
    super.key,
    required this.model,
    required this.testID,
    required this.index,
  });

  @override
  State<CreateTestQuestionContent> createState() =>
      _CreateTestQuestionContentState();
}

class _CreateTestQuestionContentState extends State<CreateTestQuestionContent> {
  late final CreateTestQuestionContentController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  TestReadinessModel get model => widget.model;
  String get testID => widget.testID;
  int get index => widget.index;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'test_question_${widget.testID}_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        CreateTestQuestionContentController.maybeFind(tag: _controllerTag) ==
            null;
    controller = CreateTestQuestionContentController.ensure(
      model: widget.model,
      testID: widget.testID,
      index: widget.index,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          CreateTestQuestionContentController.maybeFind(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<CreateTestQuestionContentController>(tag: _controllerTag);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildQuestionContent(context);
}
