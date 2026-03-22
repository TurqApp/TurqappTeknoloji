import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/MyPastTestResultsPreview.dart/my_past_test_results_preview_controller.dart';

part 'my_past_test_results_preview_content_part.dart';
part 'my_past_test_results_preview_choices_part.dart';

class MyPastTestResultsPreview extends StatefulWidget {
  final TestsModel model;

  const MyPastTestResultsPreview({super.key, required this.model});

  @override
  State<MyPastTestResultsPreview> createState() =>
      _MyPastTestResultsPreviewState();
}

class _MyPastTestResultsPreviewState extends State<MyPastTestResultsPreview> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final MyPastTestResultsPreviewController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'test_results_preview_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        MyPastTestResultsPreviewController.maybeFind(tag: _controllerTag) ==
            null;
    controller = MyPastTestResultsPreviewController.ensure(
      widget.model,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          MyPastTestResultsPreviewController.maybeFind(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<MyPastTestResultsPreviewController>(
          tag: _controllerTag,
          force: true,
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _buildBody(),
      ),
    );
  }
}
