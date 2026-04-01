import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg_flutter.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Widgets/pasaj_grid_card.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'answer_key_content_grid_part.dart';
part 'answer_key_content_list_part.dart';

class AnswerKeyContent extends StatefulWidget {
  const AnswerKeyContent({
    required this.model,
    required this.onUpdate,
    this.isListLayout = false,
    super.key,
  });

  final BookletModel model;
  final Function(bool) onUpdate;
  final bool isListLayout;

  @override
  State<AnswerKeyContent> createState() => _AnswerKeyContentState();
}

class _AnswerKeyContentState extends State<AnswerKeyContent> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final AnswerKeyContentController controller;

  BookletModel get model => widget.model;
  Function(bool) get onUpdate => widget.onUpdate;
  bool get isListLayout => widget.isListLayout;

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'answer_key_content_${model.docID}_${identityHashCode(this)}';
    _ownsController =
        maybeFindAnswerKeyContentController(tag: _controllerTag) == null;
    controller = ensureAnswerKeyContentController(
      model,
      onUpdate,
      tag: _controllerTag,
    );
    controller.syncModel(model);
  }

  @override
  void didUpdateWidget(covariant AnswerKeyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.syncModel(model);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = maybeFindAnswerKeyContentController(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<AnswerKeyContentController>(tag: _controllerTag);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isListLayout
        ? _buildListCard(context, controller)
        : _buildGridCard(context, controller);
  }
}
