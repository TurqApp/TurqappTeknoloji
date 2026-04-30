import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/full_screen_image_viewer.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanComments/antreman_comments_controller.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Themes/app_icons.dart';

part 'antreman_comments_content_part.dart';
part 'antreman_comments_input_part.dart';

class AntremanComments extends StatefulWidget {
  final QuestionBankModel question;

  const AntremanComments({super.key, required this.question});

  @override
  State<AntremanComments> createState() => _AntremanCommentsState();
}

class _AntremanCommentsState extends State<AntremanComments> {
  late final AntremanCommentsController controller;
  late final String _controllerTag;

  Rect getWidgetPosition(GlobalKey key) {
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Rect.zero;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return Rect.fromLTWH(
      position.dx + size.width - 100,
      position.dy,
      size.width,
      size.height,
    );
  }

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'antreman_comments_${widget.question.docID}_${identityHashCode(this)}';
    controller = ensureAntremanCommentsController(
      question: widget.question,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    final existing = maybeFindAntremanCommentsController(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<AntremanCommentsController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildAntremanCommentsSheet(context);
  }
}
