import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Helpers/RoadToTop/road_to_top.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/Helpers/show_map_sheet.dart';
import 'package:turqappv2/Core/Helpers/seen_count_label.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/AgendaContent/agenda_content.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';
import 'package:turqappv2/Services/post_delete_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Modules/EditPost/edit_post.dart';
import 'package:turqappv2/Modules/Profile/AboutProfile/about_profile.dart';
import 'package:turqappv2/Modules/Profile/BecomeVerifiedAccount/become_verified_account.dart';
import 'package:turqappv2/Modules/Profile/BiographyMaker/biography_maker.dart';
import 'package:turqappv2/Modules/Profile/MyStatistic/my_statistic_view.dart';
import 'package:turqappv2/Modules/Profile/EditProfile/edit_profile.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Modules/Profile/MyQRCode/my_q_r_code.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_content.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Modules/Story/StoryHighlights/story_highlight_circle.dart';
import 'package:turqappv2/Modules/Story/StoryHighlights/story_highlight_model.dart';
import 'package:turqappv2/Modules/Story/StoryHighlights/story_highlights_controller.dart';
import 'package:turqappv2/Modules/Story/StoryHighlights/highlight_story_viewer_service.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings.dart';
import 'package:turqappv2/Ads/admob_kare.dart';

import '../../../Core/text_styles.dart';
import '../../Agenda/agenda_controller.dart';
import '../../Explore/explore_controller.dart';
import '../../Short/short_controller.dart';
import '../../Story/StoryMaker/story_maker.dart';
import '../../Story/StoryRow/story_row_controller.dart';
import '../../Story/StoryRow/story_user_model.dart';
import '../../../Core/Services/audio_focus_coordinator.dart';
import '../../../Core/Services/integration_test_keys.dart';
import '../../../Core/Services/iz_birak_subscription_service.dart';
import '../../../Core/Services/turq_image_cache_manager.dart';
import '../../../Core/Services/video_state_manager.dart';
import '../SocialMediaLinks/social_media_links_controller.dart';
import '../../../Models/social_media_model.dart';

part 'profile_view_sections_part.dart';
part 'profile_view_header_part.dart';
part 'profile_view_grids_part.dart';
part 'profile_view_lifecycle_part.dart';
part 'profile_view_shell_part.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileController controller;
  late final SocialMediaController socialMediaController;
  final userService = CurrentUserService.instance;
  final PostRepository _postRepository = PostRepository.ensure();
  final MarketRepository _marketRepository = MarketRepository.ensure();
  List<MarketItemModel> _marketItems = const <MarketItemModel>[];
  bool _marketLoading = false;
  bool _scrollProbeScheduled = false;
  bool _ownsController = false;
  bool _ownsSocialMediaController = false;
  bool _ownsHighlightsController = false;
  Worker? _marketUserWorker;

  String get _myUserId => userService.effectiveUserId;

  String get _myNickname => userService.nickname;
  String get _myIosSafeNickname {
    final controllerNickname = controller.headerNickname.value.trim();
    if (controllerNickname.isNotEmpty) return controllerNickname;
    final direct = _myNickname.trim();
    if (direct.isNotEmpty) return direct;
    return _myNickname;
  }

  String get _myAvatarUrl {
    final direct = controller.headerAvatarUrl.value.trim();
    if (direct.isNotEmpty) return direct;
    return userService.avatarUrl;
  }

  String get _myFirstName => userService.firstName;
  String get _myLastName => userService.lastName;
  bool get _hasVerifiedRozet {
    final headerRozet = normalizeRozetValue(controller.headerRozet.value);
    if (headerRozet.isNotEmpty) return true;
    return normalizeRozetValue(userService.rozet).isNotEmpty;
  }

  String get _myMeslek => userService.meslekKategori;
  String get _myBio => userService.bio;
  String get _myAdres => userService.adres;
  String get _myDisplayFirstName {
    final display = controller.headerDisplayName.value.trim();
    if (display.isNotEmpty) return display;
    final direct = controller.headerFirstName.value.trim();
    if (direct.isNotEmpty) return direct;
    return _myFirstName.trim();
  }

  String get _myDisplayLastName {
    if (controller.headerDisplayName.value.trim().isNotEmpty) return '';
    final direct = controller.headerLastName.value.trim();
    if (direct.isNotEmpty) return direct;
    return _myLastName.trim();
  }

  String get _myDisplayMeslek {
    final direct = controller.headerMeslek.value.trim();
    if (direct.isNotEmpty) return direct;
    return _myMeslek.trim();
  }

  String get _myDisplayBio {
    final direct = controller.headerBio.value.trim();
    if (direct.isNotEmpty) return direct;
    return _myBio.trim();
  }

  String get _myDisplayAdres {
    final direct = controller.headerAdres.value.trim();
    if (direct.isNotEmpty) return direct;
    return _myAdres.trim();
  }

  int get _myTotalPosts => userService.counterOfPosts;
  int get _myTotalLikes => userService.counterOfLikes;
  int get _myTotalMarket =>
      _marketItems.where((item) => item.status != 'archived').length;
  bool get _hasMyStories =>
      _myUserId.isNotEmpty &&
      storyOwnerUsers.any((u) => u.userID == _myUserId && u.stories.isNotEmpty);

  List<StoryUserModel> get storyOwnerUsers {
    final rowController = StoryRowController.maybeFind();
    if (rowController == null) {
      return const <StoryUserModel>[];
    }
    return rowController.users;
  }

  StoryHighlightsController? _ensureProfileHighlightsController() {
    final uid = _myUserId.trim();
    if (uid.isEmpty) return null;
    final tag = 'highlights_$uid';
    final existing = StoryHighlightsController.maybeFind(tag: tag);
    if (existing != null) {
      return existing;
    }
    _ownsHighlightsController = true;
    return StoryHighlightsController.ensure(userId: uid, tag: tag);
  }

  Future<void> _refreshProfileSurfaceMeta({bool force = false}) async {
    final uid = _myUserId.trim();
    if (uid.isEmpty) return;
    await controller.refreshAll(forceSync: force);
    await socialMediaController.getData(
      silent: !force,
      forceRefresh: force,
    );
    final highlightsController = _ensureProfileHighlightsController();
    if (highlightsController != null) {
      await highlightsController.loadHighlights(
        silent: !force,
        forceRefresh: force,
      );
    }
    unawaited(_loadMarketItems(force: force));
  }

  void _updateViewState(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  @override
  void initState() {
    super.initState();
    _initializeProfileView();
  }

  @override
  void dispose() {
    _disposeProfileView();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
