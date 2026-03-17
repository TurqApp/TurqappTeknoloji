import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/Helpers/scholarship_rich_text.dart';
import 'package:turqappv2/Core/Services/education_feed_post_share_service.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsList/scholarship_applications_list.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'scholarship_detail_controller.dart';
import 'package:turqappv2/Ads/admob_kare.dart';

part 'scholarship_detail_view_body_part.dart';
part 'scholarship_detail_view_helpers_part.dart';
part 'scholarship_detail_view_actions_part.dart';

class ScholarshipDetailView extends GetView<ScholarshipDetailController> {
  ScholarshipDetailView({super.key});

  final ScholarshipsController scholarshipsController = Get.put(
    ScholarshipsController(),
  );
  final EducationFeedPostShareService shareService =
      const EducationFeedPostShareService();

  @override
  Widget build(BuildContext context) => buildContent(context);
}
