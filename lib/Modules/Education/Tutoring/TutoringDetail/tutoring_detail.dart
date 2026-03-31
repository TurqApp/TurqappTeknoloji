import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Services/education_feed_post_share_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Utils/phone_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';
import 'package:turqappv2/Core/Widgets/cache_first_network_image.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing.dart';
import 'package:turqappv2/Modules/Chat/chat.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:turqappv2/Modules/Education/Tutoring/CreateTutoring/create_tutoring_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart'
    show getCurrentUserId;
import 'package:url_launcher/url_launcher.dart';

part 'tutoring_detail_body_part.dart';
part 'tutoring_detail_sections_part.dart';

class TutoringDetail extends StatelessWidget {
  TutoringDetail({super.key});

  final ChatListingController chatListingController =
      ChatListingController.ensure();
  final EducationFeedPostShareService shareService =
      const EducationFeedPostShareService();

  @override
  Widget build(BuildContext context) => buildContent(context);
}
