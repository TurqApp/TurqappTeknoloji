import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalPreview/optical_preview_controller.dart';

part 'optical_preview_intro_part.dart';
part 'optical_preview_exam_part.dart';

class OpticalPreview extends StatefulWidget {
  final OpticalFormModel model;
  final Function? update;

  const OpticalPreview({
    super.key,
    required this.model,
    this.update,
  });

  @override
  State<OpticalPreview> createState() => _OpticalPreviewState();
}

class _OpticalPreviewState extends State<OpticalPreview> {
  late final OpticalPreviewController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  OpticalFormModel get model => widget.model;
  Function? get update => widget.update;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'optical_preview_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        OpticalPreviewController.maybeFind(tag: _controllerTag) == null;
    controller = OpticalPreviewController.ensure(
      widget.model,
      widget.update,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    final registeredController = OpticalPreviewController.maybeFind(
      tag: _controllerTag,
    );
    if (_ownsController && identical(registeredController, controller)) {
      Get.delete<OpticalPreviewController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
