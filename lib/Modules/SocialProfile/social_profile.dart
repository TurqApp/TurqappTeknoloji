import 'dart:ui';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:svg_flutter/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Helpers/RoadToTop/road_to_top.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/Helpers/show_map_sheet.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/iz_birak_subscription_service.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/AgendaContent/agenda_content.dart';
import 'package:turqappv2/Modules/Profile/AboutProfile/about_profile.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import '../../Core/Helpers/seen_count_label.dart';
import '../Chat/chat.dart';
import '../Chat/ChatListing/chat_listing_controller.dart';
import '../Profile/SocialMediaLinks/social_media_content.dart';
import '../Short/single_short_view.dart';
import '../Social/PhotoShorts/photo_shorts.dart';
import '../Story/StoryViewer/story_viewer.dart';
import '../Story/StoryHighlights/story_highlights_controller.dart';
import '../Story/StoryHighlights/story_highlight_circle.dart';
import '../Story/StoryHighlights/story_highlight_model.dart';
import '../Story/StoryHighlights/highlight_story_viewer_service.dart';
import '../Agenda/FloodListing/flood_listing.dart';
import '../../Models/social_media_model.dart';

part 'social_profile_lifecycle_part.dart';
part 'social_profile_content_part.dart';
part 'social_profile_sections_part.dart';

class SocialProfile extends StatefulWidget {
  final String userID;
  const SocialProfile({super.key, required this.userID});

  @override
  State<SocialProfile> createState() => _SocialProfileState();
}

class _SocialProfileState extends State<SocialProfile> {
  late SocialProfileController controller;
  late ChatListingController chatListingController;
  final Map<int, ScrollController> _scrollControllers =
      <int, ScrollController>{};
  bool _scrollProbeScheduled = false;
  bool _ownsController = false;
  bool _ownsHighlightsController = false;
  bool _ownsChatListingController = false;
  final userService = CurrentUserService.instance;
  final ShortLinkService _shortLinkService = ShortLinkService();

  ScrollController get _currentScrollController =>
      _scrollControllerForSelection(controller.postSelection.value);

  String get _myUserId => userService.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _initializeSocialProfile();
  }

  void _updateSocialProfileState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void dispose() {
    _disposeSocialProfile();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildSocialProfileScaffold(context);
  }
}
