import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Services/profile_navigation_service.dart';
import 'package:turqappv2/Core/Services/report_user_navigation_service.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_owner_card.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';

part 'booklet_preview_content_part.dart';
part 'booklet_preview_widgets_part.dart';

class BookletPreview extends StatefulWidget {
  const BookletPreview({required this.model, super.key});

  final BookletModel model;

  @override
  State<BookletPreview> createState() => _BookletPreviewState();
}

class _BookletPreviewState extends State<BookletPreview> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final BookletPreviewController controller;

  BookletModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'booklet_preview_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        maybeFindBookletPreviewController(tag: _controllerTag) == null;
    controller = ensureBookletPreviewController(model, tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = maybeFindBookletPreviewController(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<BookletPreviewController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
