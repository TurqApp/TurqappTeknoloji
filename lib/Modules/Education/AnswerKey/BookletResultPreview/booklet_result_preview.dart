import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletResultPreview/booklet_result_preview_controller.dart';

part 'booklet_result_preview_content_part.dart';
part 'booklet_result_preview_questions_part.dart';

class BookletResultPreview extends StatefulWidget {
  final BookletResultModel model;

  const BookletResultPreview({super.key, required this.model});

  @override
  State<BookletResultPreview> createState() => _BookletResultPreviewState();
}

class _BookletResultPreviewState extends State<BookletResultPreview> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final BookletResultPreviewController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'booklet_result_preview_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        maybeFindBookletResultPreviewController(tag: _controllerTag) == null;
    controller = ensureBookletResultPreviewController(
      widget.model,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = maybeFindBookletResultPreviewController(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<BookletResultPreviewController>(
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
      body: _buildBody(),
    );
  }
}
