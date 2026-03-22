import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclariPreview/sinav_sonuclari_preview_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'sinav_sonuclari_preview_content_part.dart';
part 'sinav_sonuclari_preview_questions_part.dart';

class SinavSonuclariPreview extends StatefulWidget {
  final SinavModel model;

  const SinavSonuclariPreview({super.key, required this.model});

  @override
  State<SinavSonuclariPreview> createState() => _SinavSonuclariPreviewState();
}

class _SinavSonuclariPreviewState extends State<SinavSonuclariPreview> {
  late final String _tag;
  late final SinavSonuclariPreviewController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag =
        'practice_results_preview_${widget.model.docID}_${identityHashCode(this)}';
    final existing = SinavSonuclariPreviewController.maybeFind(tag: _tag);
    _ownsController = existing == null;
    controller = existing ??
        SinavSonuclariPreviewController.ensure(
          tag: _tag,
          model: widget.model,
        );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          SinavSonuclariPreviewController.maybeFind(tag: _tag),
          controller,
        )) {
      Get.delete<SinavSonuclariPreviewController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
