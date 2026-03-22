import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/MyPastTestResultsPreview.dart/my_past_test_results_preview.dart';
import 'package:turqappv2/Modules/Education/Tests/TestPastResultContent/test_past_result_content_controller.dart';

part 'test_past_result_content_state_part.dart';
part 'test_past_result_content_card_part.dart';

class TestPastResultContent extends StatefulWidget {
  final TestsModel model;
  final int index;

  const TestPastResultContent({
    super.key,
    required this.index,
    required this.model,
  });

  @override
  State<TestPastResultContent> createState() => _TestPastResultContentState();
}

class _TestPastResultContentState extends State<TestPastResultContent> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final TestPastResultContentController controller;

  TestsModel get model => widget.model;
  int get index => widget.index;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'controller_${widget.model.docID}_${widget.index}';
    _ownsController =
        TestPastResultContentController.maybeFind(tag: _controllerTag) == null;
    controller = TestPastResultContentController.ensure(
      widget.model,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          TestPastResultContentController.maybeFind(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<TestPastResultContentController>(tag: _controllerTag);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => _buildBody());
  }
}
