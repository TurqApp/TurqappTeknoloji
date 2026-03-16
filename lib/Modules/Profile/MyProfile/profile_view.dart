import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Helpers/RoadToTop/road_to_top.dart';
import 'package:turqappv2/Core/Helpers/show_map_sheet.dart';
import 'package:turqappv2/Core/Helpers/seen_count_label.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/AgendaContent/agenda_content.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Services/post_delete_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';
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
import 'package:url_launcher/url_launcher.dart';
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
import '../../../Core/Services/iz_birak_subscription_service.dart';
import '../../../Core/Services/turq_image_cache_manager.dart';
import '../../../Core/Services/video_state_manager.dart';
import '../SocialMediaLinks/social_media_links_controller.dart';
import '../../../Models/social_media_model.dart';

part 'profile_view_sections_part.dart';
part 'profile_view_header_part.dart';
part 'profile_view_grids_part.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ProfileController controller = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());
  final SocialMediaController socialMediaController =
      Get.isRegistered<SocialMediaController>()
          ? Get.find<SocialMediaController>()
          : Get.put(SocialMediaController());
  final userService = CurrentUserService.instance;
  final PostRepository _postRepository = PostRepository.ensure();
  final MarketRepository _marketRepository = MarketRepository.ensure();
  List<MarketItemModel> _marketItems = const <MarketItemModel>[];
  bool _marketLoading = false;
  Worker? _marketUserWorker;

  String get _myUserId {
    final serviceUserId =
        (userService.currentUserRx.value?.userID ?? '').trim();
    if (serviceUserId.isNotEmpty) return serviceUserId;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }
  String get _myNickname => userService.currentUserRx.value?.nickname ?? '';
  String get _myIosSafeNickname {
    final controllerNickname = controller.headerNickname.value.trim();
    if (controllerNickname.isNotEmpty) return controllerNickname;
    final direct = _myNickname.trim();
    if (direct.isNotEmpty) return direct;
    final authDisplay =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    if (authDisplay.isNotEmpty) return authDisplay;
    return _myNickname;
  }

  String get _myAvatarUrl {
    final direct = controller.headerAvatarUrl.value.trim();
    if (direct.isNotEmpty) return direct;
    return userService.avatarUrl;
  }
  String get _myFirstName => userService.currentUserRx.value?.firstName ?? '';
  String get _myLastName => userService.currentUserRx.value?.lastName ?? '';
  String get _myRozet {
    final direct = controller.headerRozet.value.trim();
    if (direct.isNotEmpty) return direct;
    return userService.currentUserRx.value?.rozet ?? '';
  }
  bool get _hasVerifiedRozet {
    final headerRozet = controller.headerRozet.value.trim();
    if (headerRozet.isNotEmpty) return true;
    return _myRozet.trim().isNotEmpty;
  }

  String get _myMeslek => userService.currentUserRx.value?.meslekKategori ?? '';
  String get _myBio => userService.currentUserRx.value?.bio ?? '';
  String get _myAdres => userService.currentUserRx.value?.adres ?? '';
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

  int get _myTotalPosts => userService.currentUserRx.value?.counterOfPosts ?? 0;
  int get _myTotalLikes => userService.currentUserRx.value?.counterOfLikes ?? 0;
  int get _myTotalMarket =>
      _marketItems.where((item) => item.status != 'archived').length;
  bool get _hasMyStories =>
      _myUserId.isNotEmpty &&
      storyOwnerUsers.any((u) => u.userID == _myUserId && u.stories.isNotEmpty);

  List<StoryUserModel> get storyOwnerUsers {
    if (!Get.isRegistered<StoryRowController>()) {
      return const <StoryUserModel>[];
    }
    return Get.find<StoryRowController>().users;
  }

  @override
  void initState() {
    super.initState();
    try {
      VideoStateManager.instance.pauseAllVideos(force: true);
    } catch (_) {}
    try {
      AudioFocusCoordinator.instance.pauseAllAudioPlayers();
    } catch (_) {}
    controller.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      socialMediaController.getData();
    });
    unawaited(_loadMarketItems());
    _marketUserWorker = ever(userService.currentUserRx, (_) {
      unawaited(_loadMarketItems(force: true));
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      final tag = 'highlights_$uid';
      if (Get.isRegistered<StoryHighlightsController>(tag: tag)) {
        Get.find<StoryHighlightsController>(tag: tag).loadHighlights();
      } else {
        Get.put(StoryHighlightsController(userId: uid), tag: tag);
      }
    }
  }

  void _refreshUserState() {
    userService.forceRefresh();
    StoryRowController.refreshStoriesGlobally();
    unawaited(_loadMarketItems(force: true));
  }

  Future<void> _loadMarketItems({bool force = false}) async {
    final uid = _myUserId.trim();
    if (uid.isEmpty) return;
    if (_marketLoading && !force) return;
    if (mounted) {
      setState(() {
        _marketLoading = true;
      });
    }
    try {
      final items = await _marketRepository.fetchByOwner(
        uid,
        preferCache: !force,
        forceRefresh: force,
      );
      if (!mounted) return;
      setState(() {
        _marketItems = items
            .where((item) => item.status != 'archived')
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _marketItems = const <MarketItemModel>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _marketLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!mounted) return;
    // ScrollController bağlı değilse çık
    if (!controller.scrollController.hasClients) return;

    final position = controller.scrollController.position;
    // Sayfanın sonuna yaklaşıldıysa yeni postları getir
    if (position.pixels >= position.maxScrollExtent - 300) {
      controller.fetchPosts();
      controller.fetchPhotos();
      controller.fetchVideos();
    }

    // Ortadaki widget’ı tespit etmek için
    final screenHeight = MediaQuery.of(context).size.height;
    final centerY = screenHeight / 2;

    for (int i = 0; i < controller.allPosts.length; i++) {
      final key = controller.getPostKey(i);
      final ctx = key.currentContext;
      if (ctx == null) continue;
      if (!ctx.mounted) continue;

      RenderBox? box;
      try {
        box = ctx.findRenderObject() as RenderBox?;
      } catch (_) {
        continue;
      }
      if (box == null || !box.attached) continue;

      final pos = box.localToGlobal(Offset.zero);
      final top = pos.dy;
      final bottom = pos.dy + box.size.height;

      if (top <= centerY && bottom >= centerY) {
        if (controller.centeredIndex.value != i) {
          if (!mounted) return;
          setState(() {
            controller.centeredIndex.value = i;
          });
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    controller.scrollController.removeListener(_onScroll);
    _marketUserWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await controller.refreshAll();
                      await _loadMarketItems(force: true);
                      socialMediaController.getData();
                    },
                    child: Obx(() {
                      return controller.postSelection.value == 0
                          ? () {
                              final combinedPosts = controller.mergedPosts;

                              return combinedPosts.isNotEmpty
                                  ? NotificationListener<ScrollNotification>(
                                      onNotification: (notification) {
                                        _onScroll();
                                        return false;
                                      },
                                      child: ListView.builder(
                                        controller: controller.scrollController,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(
                                                parent:
                                                    BouncingScrollPhysics()),
                                        itemCount: combinedPosts.length + 2,
                                        itemBuilder: (context, index) {
                                          if (index == 0) {
                                            return header();
                                          }

                                          if (index ==
                                              combinedPosts.length + 1) {
                                            return 50.ph;
                                          }

                                          final actualIndex = index - 1;
                                          final item =
                                              combinedPosts[actualIndex];
                                          final model =
                                              item['post'] as PostsModel;
                                          final isReshare =
                                              item['isReshare'] as bool;
                                          final itemKey = controller
                                              .getPostKey(actualIndex);

                                          return Padding(
                                            padding: EdgeInsets.only(bottom: 5),
                                            child: Column(
                                              children: [
                                                Obx(() {
                                                  final isCentered = controller
                                                          .centeredIndex
                                                          .value ==
                                                      actualIndex;
                                                  return Padding(
                                                    padding: EdgeInsets.only(
                                                        top: actualIndex == 0
                                                            ? 12
                                                            : 0),
                                                    child: AgendaContent(
                                                      key: itemKey,
                                                      model: model,
                                                      isPreview: false,
                                                      shouldPlay: !controller
                                                              .pausetheall
                                                              .value &&
                                                          !controller
                                                              .showPfImage
                                                              .value &&
                                                          isCentered,
                                                      isYenidenPaylasilanPost:
                                                          isReshare,
                                                      reshareUserID: isReshare
                                                          ? _myUserId
                                                          : null,
                                                    ),
                                                  );
                                                }),
                                                SizedBox(
                                                  height: 2,
                                                  child: Divider(
                                                    color: Colors.grey
                                                        .withAlpha(50),
                                                  ),
                                                ),
                                                if ((actualIndex + 1) % 4 == 0)
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8.0),
                                                    child: AdmobKare(
                                                        key: ValueKey(
                                                            'myprof-ad-slot')),
                                                  ),
                                                if (combinedPosts.isNotEmpty &&
                                                    combinedPosts.length < 4 &&
                                                    actualIndex ==
                                                        combinedPosts.length -
                                                            1)
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8.0),
                                                    child: AdmobKare(
                                                        key: ValueKey(
                                                            'myprof-ad-end')),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ))
                                  : CustomScrollView(
                                      controller: controller.scrollController,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                              parent: BouncingScrollPhysics()),
                                      slivers: [
                                        SliverToBoxAdapter(child: header()),
                                        const SliverToBoxAdapter(
                                            child: SizedBox(height: 8)),
                                        SliverToBoxAdapter(
                                            child:
                                                EmptyRow(text: "Gönderi Yok")),
                                        const SliverToBoxAdapter(
                                            child: SizedBox(height: 50)),
                                      ],
                                    );
                            }()
                          : controller.postSelection.value == 1
                              ? buildVideoGrid()
                              : controller.postSelection.value == 2
                                  ? buildPhotoGrid()
                                  : controller.postSelection.value == 3
                                      ? buildReshares()
                                      : controller.postSelection.value == 4
                                          ? buildMarkets(context)
                                          : controller.postSelection.value == 5
                                              ? buildIzbiraklar(context)
                                              : Column(children: [header()]);
                    }),
                  ),
                ),
              ],
            ),
            Obx(() => controller.showScrollToTop.value
                ? Positioned(
                    bottom: 90,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        controller.scrollController.animateTo(0,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.bounceIn);
                      },
                      child: RoadToTop(),
                    ),
                  )
                : const SizedBox.shrink()),
            Obx(() => controller.showPfImage.value
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.showPfImage.value = false;
                        },
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 10.0,
                            sigmaY: 10.0,
                          ),
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 80),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: CachedUserAvatar(
                                userId: _myUserId,
                                imageUrl: _myAvatarUrl,
                                radius: 120,
                                placeholder: const DefaultAvatar(
                                  radius: 120,
                                  backgroundColor: Colors.transparent,
                                  iconColor: Colors.white70,
                                  padding: EdgeInsets.all(36),
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
