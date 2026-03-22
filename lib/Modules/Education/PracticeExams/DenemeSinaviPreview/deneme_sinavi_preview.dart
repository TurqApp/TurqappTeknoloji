import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Services/education_feed_post_share_service.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviYap/deneme_sinavi_yap.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'deneme_sinavi_preview_actions_part.dart';
part 'deneme_sinavi_preview_content_part.dart';

class DenemeSinaviPreview extends StatefulWidget {
  const DenemeSinaviPreview({super.key, required this.model});

  final SinavModel model;
  @override
  State<DenemeSinaviPreview> createState() => _DenemeSinaviPreviewState();
}

class _DenemeSinaviPreviewState extends State<DenemeSinaviPreview> {
  final EducationFeedPostShareService shareService =
      const EducationFeedPostShareService();
  late final String _tag;
  late final DenemeSinaviPreviewController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag =
        'practice_exam_preview_${widget.model.docID}_${identityHashCode(this)}';
    final existing = DenemeSinaviPreviewController.maybeFind(tag: _tag);
    _ownsController = existing == null;
    controller = existing ??
        DenemeSinaviPreviewController.ensure(tag: _tag, model: widget.model);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          DenemeSinaviPreviewController.maybeFind(tag: _tag),
          controller,
        )) {
      Get.delete<DenemeSinaviPreviewController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }
}
