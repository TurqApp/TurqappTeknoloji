import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Services/education_detail_navigation_service.dart';
import 'package:turqappv2/Core/Services/education_feed_post_share_service.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/profile_navigation_service.dart';
import 'package:turqappv2/Core/Services/report_user_navigation_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Helpers/clickable_text_content.dart';
import 'package:turqappv2/Core/Repositories/username_lookup_repository.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/cache_first_network_image.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details_controller.dart';
import 'package:turqappv2/Modules/JobFinder/job_localization_utils.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'job_details_meta_part.dart';
part 'job_details_reviews_part.dart';
part 'job_details_body_part.dart';
part 'job_details_actions_part.dart';

class JobDetails extends StatefulWidget {
  final JobModel model;
  const JobDetails({super.key, required this.model});

  @override
  State<JobDetails> createState() => _JobDetailsState();
}

class _JobDetailsState extends State<JobDetails> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final JobDetailsController controller;
  final EducationFeedPostShareService shareService =
      const EducationFeedPostShareService();
  final EducationDetailNavigationService detailNavigationService =
      const EducationDetailNavigationService();

  JobModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'job_details_${widget.model.docID}_${identityHashCode(this)}';
    _ownsController =
        maybeFindJobDetailsController(tag: _controllerTag) == null;
    controller = ensureJobDetailsController(
      model: model,
      tag: _controllerTag,
    );
  }

  String get _currentUid {
    return CurrentUserService.instance.effectiveUserId;
  }

  Future<void> _openMentionProfile(String mention) async {
    final normalizedMention = normalizeHandleInput(mention);
    if (normalizedMention.isEmpty) return;
    final targetUid =
        await UsernameLookupRepository.ensure().findUidForHandle(mention) ?? '';

    if (targetUid.isNotEmpty && targetUid != _currentUid) {
      await const ProfileNavigationService().openSocialProfile(targetUid);
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = maybeFindJobDetailsController(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<JobDetailsController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildContent(context);
}
