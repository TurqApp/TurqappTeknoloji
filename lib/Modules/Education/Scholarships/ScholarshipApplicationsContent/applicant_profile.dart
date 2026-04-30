import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/Services/profile_navigation_service.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsContent/scholarship_applications_content_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';

part 'applicant_profile_content_part.dart';
part 'applicant_profile_widgets_part.dart';

class ApplicantProfile extends StatefulWidget {
  final String userID;

  const ApplicantProfile({super.key, required this.userID});

  @override
  State<ApplicantProfile> createState() => _ApplicantProfileState();
}

class _ApplicantProfileState extends State<ApplicantProfile> {
  late final ScholarshipApplicationsContentController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  String get userID => widget.userID;

  bool _isNoValue(String value) {
    final normalized = normalizeSearchText(value);
    return const <String>{
      'hayır',
      'hayir',
      'no',
      'nein',
      'non',
      'нет',
    }.contains(normalized);
  }

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'scholarship_applicant_profile_${widget.userID}_${identityHashCode(this)}';
    final existing = maybeFindScholarshipApplicationsContentController(
      tag: _controllerTag,
    );
    _ownsController = existing == null;
    controller = existing ??
        ensureScholarshipApplicationsContentController(
          tag: _controllerTag,
          userID: widget.userID,
        );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindScholarshipApplicationsContentController(
              tag: _controllerTag),
          controller,
        )) {
      Get.delete<ScholarshipApplicationsContentController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
