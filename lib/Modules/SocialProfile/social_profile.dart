import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Helpers/RoadToTop/road_to_top.dart';
import 'package:turqappv2/Core/Helpers/show_map_sheet.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/iz_birak_subscription_service.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';
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
import 'package:url_launcher/url_launcher.dart';
import '../Social/PhotoShorts/photo_shorts.dart';
import '../Story/StoryViewer/story_viewer.dart';
import '../Story/StoryHighlights/story_highlights_controller.dart';
import '../Story/StoryHighlights/story_highlight_circle.dart';
import '../Story/StoryHighlights/story_highlight_model.dart';
import '../Story/StoryHighlights/highlight_story_viewer_service.dart';
import '../Agenda/FloodListing/flood_listing.dart';
import '../../Models/social_media_model.dart';

class SocialProfile extends StatefulWidget {
  final String userID;
  const SocialProfile({super.key, required this.userID});

  @override
  State<SocialProfile> createState() => _SocialProfileState();
}

class _SocialProfileState extends State<SocialProfile> {
  late SocialProfileController controller;
  final ScrollController scrollController = ScrollController();
  final userService = CurrentUserService.instance;
  final chatListingController = Get.put(ChatListingController());
  final ShortLinkService _shortLinkService = ShortLinkService();

  String get _myUserId => userService.currentUserRx.value?.userID ?? '';
  bool _isBlockedByMe(String otherUserId) {
    final blocked =
        userService.currentUserRx.value?.blockedUsers ?? const <String>[];
    return blocked.contains(otherUserId);
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
    controller = Get.put(
      SocialProfileController(userID: widget.userID),
      tag: widget.userID,
    );
    // Story Highlights controller
    Get.put(
      StoryHighlightsController(userId: widget.userID),
      tag: 'highlights_${widget.userID}',
    );
    scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenCenterY = screenHeight / 2;

    // Yukarı butonu görünürlüğü
    final shouldShowScrollToTop = scrollController.offset > 500;
    if (controller.showScrollToTop.value != shouldShowScrollToTop) {
      controller.showScrollToTop.value = shouldShowScrollToTop;
    }

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      controller.getPosts(initial: false);
      controller.getPhotos(initial: false);
    }

    for (int i = 0; i < controller.allPosts.length; i++) {
      final key = controller.getPostKey(i);
      final context = key.currentContext;
      if (context == null) continue;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) continue;

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final widgetTop = position.dy;
      final widgetBottom = position.dy + size.height;

      final centerYInViewport = screenCenterY;

      if (widgetTop <= centerYInViewport && widgetBottom >= centerYInViewport) {
        if (controller.centeredIndex.value != i) {
          setState(() {
            controller.centeredIndex.value = i;
          });
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return Stack(
            children: [
              RefreshIndicator(
                  backgroundColor: Colors.black,
                  color: Colors.white,
                  onRefresh: () async {
                    await controller.refreshAll();
                  },
                  child: Column(
                    children: [
                      if (!_isBlockedByMe(widget.userID))
                        Expanded(
                          child: (controller.gizliHesap.value &&
                                  controller.takipEdiyorum.value == false &&
                                  widget.userID != _myUserId)
                              ? Column(
                                  children: [
                                    header(),
                                    const SizedBox(height: 25),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              CupertinoIcons.lock_fill,
                                              color: Colors.pinkAccent,
                                              size: 35,
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              "Bu hesap gizli",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              "Gönderileri görmek için takip et.",
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 13,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : controller.postSelection.value == 0
                                  ? () {
                                      // Normal postlar ve yeniden paylaşılanları birleştir
                                      final List<Map<String, dynamic>>
                                          combinedPosts = [];

                                      // Normal postları ekle
                                      for (final post in controller.allPosts) {
                                        combinedPosts.add({
                                          'post': post,
                                          'isReshare': false,
                                          'timestamp': post.timeStamp,
                                        });
                                      }

                                      // Yeniden paylaşılanları ekle
                                      for (final reshare
                                          in controller.reshares) {
                                        combinedPosts.add({
                                          'post': reshare,
                                          'isReshare': true,
                                          'timestamp': reshare.timeStamp,
                                        });
                                      }

                                      // Zaman damgasına göre sırala (en yeni en üstte)
                                      combinedPosts.sort((a, b) =>
                                          (b['timestamp'] as num).compareTo(
                                              a['timestamp'] as num));

                                      return NotificationListener<
                                          ScrollNotification>(
                                        onNotification: (notification) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback(
                                            (_) => _onScroll(),
                                          );
                                          return false;
                                        },
                                        child: ListView.builder(
                                          controller: scrollController,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(
                                                  parent:
                                                      BouncingScrollPhysics()),
                                          itemCount: combinedPosts.length + 1,
                                          itemBuilder: (context, index) {
                                            if (index == 0) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: Column(
                                                  children: [
                                                    header(),
                                                    if (combinedPosts.isEmpty)
                                                      EmptyRow(
                                                          text:
                                                              "Sonuç Bulunamadı"),
                                                  ],
                                                ),
                                              );
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
                                            final isCentered = controller
                                                    .centeredIndex.value ==
                                                actualIndex;

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 5),
                                              child: Column(
                                                children: [
                                                  AgendaContent(
                                                    key: itemKey,
                                                    model: model,
                                                    isPreview: false,
                                                    shouldPlay: !controller
                                                            .showPfImage
                                                            .value &&
                                                        isCentered,
                                                    isYenidenPaylasilanPost:
                                                        isReshare,
                                                    reshareUserID: isReshare
                                                        ? controller.userID
                                                        : null,
                                                  ),
                                                  SizedBox(
                                                    height: 2,
                                                    child: Divider(
                                                      color: Colors.grey
                                                          .withAlpha(50),
                                                    ),
                                                  ),
                                                  if ((actualIndex + 1) % 4 ==
                                                      0)
                                                    const Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 8.0),
                                                      child: AdmobKare(
                                                          key: ValueKey(
                                                              'socialprof-ad-slot')),
                                                    ),
                                                  if (combinedPosts.isNotEmpty &&
                                                      combinedPosts.length <
                                                          4 &&
                                                      actualIndex ==
                                                          combinedPosts.length -
                                                              1)
                                                    const Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 8.0),
                                                      child: AdmobKare(
                                                          key: ValueKey(
                                                              'socialprof-ad-end')),
                                                    ),
                                                  const SizedBox(height: 12),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }()
                                  : controller.postSelection.value == 1
                                      ? buildVideoGrid()
                                      : controller.postSelection.value == 2
                                          ? buildPhotoGrid()
                                          : controller.postSelection.value == 3
                                              ? buildReshares()
                                              : controller.postSelection
                                                          .value ==
                                                      4
                                                  ? buildMarkets(context)
                                                  : controller.postSelection
                                                              .value ==
                                                          5
                                                      ? buildIzbiraklar(context)
                                                      : Column(
                                                          children: [header()]),
                        )
                      else
                        Column(
                          children: [
                            header(),
                            SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.xmark_shield,
                                      color: Colors.pinkAccent,
                                      size: 35,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "Bu kullanıcıyı engellediniz",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      // Profil resmi önizleme overlay’i (Column içinde değil, dış Stack’te gösterilecek)
                    ],
                  )),
              if (controller.showPfImage.value)
                Positioned.fill(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.showPfImage.value = false;
                        },
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipOval(
                            child: controller.avatarUrl.value.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: controller.avatarUrl.value,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 300,
                                    memCacheHeight: 600,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.person,
                                        size: 100,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.person,
                                        size: 100,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      size: 100,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Yukarı butonu
              if (controller.showScrollToTop.value)
                Positioned(
                  right: 15,
                  bottom: 20,
                  child: GestureDetector(
                    onTap: () {
                      scrollController.animateTo(0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut);
                    },
                    child: const RoadToTop(),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget buildReshares() {
    final hasVideos = controller.reshares.isNotEmpty;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(child: header()),
        if (hasVideos)
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0.5,
              crossAxisSpacing: 0.5,
              childAspectRatio: 9 / 16, // Dikey videolar için ideal oran
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final model = controller.reshares[index];
              return GestureDetector(
                onTap: () {
                  if (model.hasPlayableVideo) {
                    Get.to(
                      () => SingleShortView(
                        startList: controller.reshares
                            .where((val) => val.hasPlayableVideo)
                            .toList(),
                        startModel: model,
                      ),
                    );
                  } else {
                    Get.to(
                      () => PhotoShorts(
                        fetchedList: controller.reshares
                            .where((val) => val.img.isNotEmpty)
                            .toList(),
                        startModel: model,
                      ),
                    );
                  }
                },
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: model.thumbnail != ""
                            ? model.thumbnail
                            : model.img.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.grey,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    if (model.hasPlayableVideo)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    if (!model.hasPlayableVideo && model.img.isNotEmpty)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          CupertinoIcons.photo,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            "assets/icons/statsyeni.svg",
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                          SizedBox(
                            width: 3,
                          ),
                          SeenCountLabel(model.docID)
                        ],
                      ),
                    )
                  ],
                ),
              );
            }, childCount: controller.reshares.length),
          )
        else
          SliverToBoxAdapter(
              child: Center(child: EmptyRow(text: "Yeniden paylaşım yok"))),
      ],
    );
  }

  Widget buildPhotoGrid() {
    final visiblePosts = controller.photos;
    final childCount =
        visiblePosts.length + (controller.isLoadingPhoto.value ? 1 : 0);

    if (visiblePosts.isEmpty) {
      return Column(
        children: [
          header(),
          Center(
            child: EmptyRow(text: "Hiç fotoğraf bulunamadı."),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(child: header()),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 0.5,
            crossAxisSpacing: 0.5,
            childAspectRatio: 0.8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // En son item ve loading ise göster
              if (index == visiblePosts.length &&
                  controller.isLoadingPhoto.value) {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              }

              final model = visiblePosts[index];
              return GestureDetector(
                onTap: () {
                  if (model.floodCount > 1 && model.flood == false) {
                    Get.to(() => FloodListing(mainModel: model));
                  } else {
                    Get.to(() => PhotoShorts(
                        fetchedList: visiblePosts, startModel: model));
                  }
                },
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: model.img.first,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                      ),
                    ),
                    if (model.img.length > 1)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          CupertinoIcons.photo_on_rectangle,
                          color: Colors.white,
                          size: 20,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Row(
                        children: [
                          SvgPicture.asset("assets/icons/statsyeni.svg",
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn)),
                          SizedBox(width: 3),
                          SeenCountLabel(model.docID)
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
            childCount: childCount,
          ),
        ),
      ],
    );
  }

  Widget buildVideoGrid() {
    final visibleVideos =
        controller.allPosts.where((post) => post.hasPlayableVideo).toList();
    final childCount =
        visibleVideos.length + (controller.isLoadingPosts.value ? 1 : 0);

    if (visibleVideos.isEmpty) {
      return Column(
        children: [
          header(),
          Center(
            child: EmptyRow(text: "Hiç video bulunamadı."),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: scrollController,
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: header()),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            childAspectRatio: 0.6,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == visibleVideos.length &&
                  controller.isLoadingPosts.value) {
                // Grid'in sonunda loading göstergesi
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              }

              final model = visibleVideos[index];
              return GestureDetector(
                onTap: () {
                  if (model.floodCount > 1 && model.flood == false) {
                    Get.to(() => FloodListing(mainModel: model));
                  } else {
                    Get.to(() => SingleShortView(
                        startList: visibleVideos, startModel: model));
                  }
                },
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: model.thumbnail,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                        placeholder: (context, url) => const Center(
                          child: CupertinoActivityIndicator(color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: CupertinoActivityIndicator(color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Icon(
                        CupertinoIcons.play_circle_fill,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Row(
                        children: [
                          SvgPicture.asset("assets/icons/statsyeni.svg",
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn)),
                          SizedBox(width: 3),
                          SeenCountLabel(model.docID)
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
            childCount: childCount,
          ),
        ),
      ],
    );
  }

  Widget header() {
    return Obx(() {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size(35, 35),
                      ),
                      child: Icon(
                        CupertinoIcons.arrow_left,
                        color: Colors.black,
                        size: 25,
                      ),
                    ),
                    6.pw,
                    GestureDetector(
                      onTap: () {
                        if (mounted) {
                          setState(() {
                            controller.centeredIndex.value = -1;
                          });
                        }
                        Get.to(() => AboutProfile(userID: widget.userID))
                            ?.then((_) {
                          controller.centeredIndex.value = 0;
                        });
                      },
                      child: Text(
                        controller.nickname.value,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: AppFontFamilies.mbold,
                        ),
                      ),
                    ),
                    if (widget.userID.isNotEmpty) ...[
                      RozetContent(
                        size: 15,
                        userID: widget.userID,
                        leftSpacing: 6,
                        rozetValue: controller.rozet.value,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12),
              PullDownButton(
                itemBuilder: (context) => [
                  PullDownMenuItem(
                    onTap: () async {
                      final nick =
                          controller.nickname.value.trim().toLowerCase();
                      final safeSlug = nick.isEmpty ? widget.userID : nick;
                      final result = await _shortLinkService.upsertUser(
                        userId: widget.userID,
                        slug: safeSlug,
                        title: '@${controller.nickname.value} - TurqApp',
                        desc: 'TurqApp profilini görüntüle',
                        imageUrl: controller.avatarUrl.value,
                      );
                      final link =
                          (result['url'] ?? '').toString().trim().isNotEmpty
                              ? (result['url'] ?? '').toString().trim()
                              : 'https://turqapp.com/u/$safeSlug';
                      await Clipboard.setData(ClipboardData(text: link));
                      AppSnackbar(
                          "Kopyalandı", "Bağlantı linki panoya kopyalandı");
                    },
                    title: 'Profil linkini kopyala',
                    icon: CupertinoIcons.doc_on_doc,
                  ),
                  PullDownMenuItem(
                    onTap: () async {
                      await ShareActionGuard.run(() async {
                        final nick =
                            controller.nickname.value.trim().toLowerCase();
                        final safeSlug = nick.isEmpty ? widget.userID : nick;
                        final result = await _shortLinkService.upsertUser(
                          userId: widget.userID,
                          slug: safeSlug,
                          title: '@${controller.nickname.value} - TurqApp',
                          desc: 'TurqApp profilini görüntüle',
                          imageUrl: controller.avatarUrl.value,
                        );
                        final link =
                            (result['url'] ?? '').toString().trim().isNotEmpty
                                ? (result['url'] ?? '').toString().trim()
                                : 'https://turqapp.com/u/$safeSlug';
                        await ShareLinkService.shareUrl(
                          url: link,
                          title: '@${controller.nickname} - TurqApp',
                          subject: 'TurqApp Profili',
                        );
                      });
                    },
                    title: 'Paylaş',
                    icon: CupertinoIcons.share_up,
                  ),
                  if (!_isBlockedByMe(widget.userID))
                    PullDownMenuItem(
                      onTap: () {
                        controller.centeredIndex.value = -1;
                        controller.block();
                      },
                      title: 'Engelle',
                      icon: CupertinoIcons.xmark_circle,
                    ),
                  if (_isBlockedByMe(widget.userID))
                    PullDownMenuItem(
                      onTap: () {
                        controller.centeredIndex.value = -1;
                        controller.unblock();
                      },
                      title: "Engeli Kaldır",
                      icon: CupertinoIcons.xmark_circle,
                    ),
                  PullDownMenuItem(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          controller.centeredIndex.value = -1;
                        });
                      }
                      Get.to(
                        () => ReportUser(
                          userID: widget.userID,
                          postID: "",
                          commentID: "",
                        ),
                      )?.then((v) {
                        if (mounted) {
                          setState(() {
                            controller.centeredIndex.value = 0;
                          });
                        }
                        controller.getUserData();
                      });
                    },
                    title: 'Şikayet Et',
                    icon: CupertinoIcons.shield,
                  ),
                ],
                buttonBuilder: (context, showMenu) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: showMenu,
                  child: const AppIconSurface(
                    child: Icon(
                      CupertinoIcons.ellipsis_vertical,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          imageAndFollowButtons(),
          const SizedBox(height: 12),
          textInfoBody(),
          if (!_isBlockedByMe(widget.userID)) _buildLinksAndHighlightsRow(),
          Padding(padding: const EdgeInsets.only(top: 0), child: counters()),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: postButtons(context),
          ),
          Divider(
            height: 0,
            color: Colors.grey.withAlpha(50),
          ),
          4.ph,
        ],
      );
    });
  }

  Widget imageAndFollowButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final isPrivateBlocked = controller.gizliHesap.value &&
                  controller.takipEdiyorum.value == false &&
                  widget.userID != _myUserId;
              if (isPrivateBlocked) {
                AppSnackbar("Gizli hesap",
                    "Hikayeleri görmek için önce takip etmeniz gerekir.");
                return;
              }

              // Hikaye kontrolü ve güvenli açma
              if (controller.storyUserModel != null &&
                  controller.storyUserModel!.stories.isNotEmpty) {
                try {
                  if (mounted) {
                    setState(() {
                      controller.centeredIndex.value = -1;
                    });
                  }
                  Get.to(() => StoryViewer(
                      startedUser: controller.storyUserModel!,
                      storyOwnerUsers: [controller.storyUserModel!]));
                } catch (e) {
                  print('Story açma hatası: $e');
                  // Hata durumunda hiçbir şey yapma
                }
              }
              // Hikaye yoksa hiçbir şey yapma
            },
            onLongPress: () {
              HapticFeedback.lightImpact();
              // Profil fotoğrafı var mı kontrol et
              if (mounted && controller.avatarUrl.value.isNotEmpty) {
                setState(() {
                  controller.showPfImage.value = true;
                  controller.centeredIndex.value = -1;
                });
              }
            },
            child: _buildProfileImageWithBorder(),
          ),

          const SizedBox(width: 12),

          // --- Takip / Engelleme butonları ---
          if (controller.complatedCheck.value && !_isBlockedByMe(widget.userID))
            followButtons()
          else if (controller.complatedCheck.value &&
              _isBlockedByMe(widget.userID))
            unblockButton(),
        ],
      ),
    );
  }

  Widget textInfoBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "${controller.firstName.value} ${controller.lastName.value}",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
          if (controller.meslek.value != "")
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                controller.meslek.value,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          if (controller.bio.value != "")
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                controller.bio.value,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "Montserrat",
                ),
              ),
            ),
          if (controller.adres.value != "")
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: GestureDetector(
                onTap: () {
                  showMapsSheetWithAdres(controller.adres.value);
                },
                child: Text(
                  controller.adres.value,
                  style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 12,
                    fontFamily: "Montserrat",
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget followButtons() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => TextButton(
                      onPressed: controller.followLoading.value
                          ? null
                          : () {
                              if (controller.takipEdiyorum.value == false) {
                                controller.toggleFollowStatus();
                              } else {
                                noYesAlert(
                                    title: "Takipten Çık",
                                    message:
                                        "${controller.nickname.value} kullanıcısını takipten çıkmak istediğinizden emin misiniz ?",
                                    yesText: "Takipten Çık",
                                    onYesPressed: () {
                                      if (mounted) {
                                        setState(() {
                                          controller.centeredIndex.value = -1;
                                        });
                                      }
                                      controller.toggleFollowStatus();
                                    });
                              }
                            },
                      style: TextButton.styleFrom(
                        backgroundColor: controller.takipEdiyorum.value
                            ? Colors.grey.withAlpha(50)
                            : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: SizedBox(
                        height: 30,
                        child: Center(
                          child: controller.followLoading.value
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      controller.takipEdiyorum.value
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  controller.takipEdiyorum.value
                                      ? "Takiptesin"
                                      : "Takip Et",
                                  style: TextStyle(
                                    color: controller.takipEdiyorum.value
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 13,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                        ),
                      ),
                    )),
              ),
              SizedBox(width: 12),
              Expanded(
                  child: TextButton(
                onPressed: () {
                  final sohbet = chatListingController.list.firstWhereOrNull(
                    (val) => val.userID == widget.userID,
                  );
                  controller.centeredIndex.value = -1;

                  if (sohbet != null) {
                    Get.to(
                      () => ChatView(
                        chatID: sohbet.chatID,
                        userID: widget.userID,
                        isNewChat: false,
                        openKeyboard: true,
                      ),
                    );
                  } else {
                    final chatId = buildConversationId(
                      _myUserId,
                      widget.userID,
                    );
                    Get.to(
                      () => ChatView(
                        chatID: chatId,
                        userID: widget.userID,
                        isNewChat: true,
                        openKeyboard: true,
                      ),
                    )?.then((_) {
                      chatListingController.getList();
                    });
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.withAlpha(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: SizedBox(
                  height: 30,
                  child: Center(
                    child: Text(
                      "Mesaj",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                ),
              )),
              // İletişim butonunu aynı sıraya taşı (opsiyonel olarak görünür)
              Obx(() {
                final showEmail = controller.mailIzin.value &&
                    controller.email.value.isNotEmpty;
                final showCall = controller.aramaIzin.value &&
                    controller.phoneNumber.value.isNotEmpty;
                final canContact = showEmail || showCall;
                return canContact
                    ? const SizedBox(width: 12)
                    : const SizedBox.shrink();
              }),
              Obx(() {
                final showEmail = controller.mailIzin.value &&
                    controller.email.value.isNotEmpty;
                final showCall = controller.aramaIzin.value &&
                    controller.phoneNumber.value.isNotEmpty;
                final canContact = showEmail || showCall;
                if (!canContact) return const SizedBox.shrink();
                return Expanded(
                  child: TextButton(
                    onPressed: () async {
                      Get.bottomSheet(
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(100),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: const Text(
                                    "İletişim Seçenekleri",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                ),
                                if (showEmail)
                                  TextButton(
                                    onPressed: () async {
                                      final mail = controller.email.value;
                                      final uri = Uri.parse('mailto:$mail');
                                      await launchUrl(uri);
                                      Get.back();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 12,
                                      ),
                                      backgroundColor:
                                          Colors.grey.withAlpha(50),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.mail,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            controller.email.value,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'MontserratBold',
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (showEmail && showCall)
                                  const SizedBox(height: 10),
                                if (showCall)
                                  TextButton(
                                    onPressed: () async {
                                      final tel = controller.phoneNumber.value;
                                      final uri = Uri.parse('tel:0$tel');
                                      await launchUrl(uri);
                                      Get.back();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 12,
                                      ),
                                      backgroundColor:
                                          Colors.grey.withAlpha(50),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.phone,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            '+90${controller.phoneNumber.value}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'MontserratBold',
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        isScrollControlled: true,
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.withAlpha(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const SizedBox(
                      height: 30,
                      child: Center(
                        child: Text(
                          'İletişim',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget unblockButton() {
    return Expanded(
      child: TextButton(
        onPressed: () {
          controller.unblock();
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.grey.withAlpha(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: SizedBox(
          height: 30,
          child: Center(
            child: Text(
              "Engeli Kaldır",
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinksAndHighlightsRow() {
    final tag = 'highlights_${widget.userID}';
    if (!Get.isRegistered<StoryHighlightsController>(tag: tag)) {
      return const SizedBox.shrink();
    }
    final hlController = Get.find<StoryHighlightsController>(tag: tag);
    return Obx(() {
      final mixedItems = <Map<String, dynamic>>[];
      for (final social in controller.socialMediaList) {
        mixedItems.add({
          'type': 'link',
          'createdAt': int.tryParse(social.docID) ?? 0,
          'data': social,
        });
      }
      for (final hl in hlController.highlights) {
        mixedItems.add({
          'type': 'highlight',
          'createdAt': hl.createdAt.millisecondsSinceEpoch,
          'data': hl,
        });
      }
      if (mixedItems.isEmpty) return const SizedBox.shrink();
      mixedItems.sort(
          (a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));

      return Padding(
        padding: const EdgeInsets.only(top: 7, bottom: 4),
        child: SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: mixedItems.length,
            itemBuilder: (context, index) {
              final item = mixedItems[index];
              if (item['type'] == 'link') {
                final social = item['data'] as SocialMediaModel;
                return Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: SizedBox(
                    width: 70,
                    child: GestureDetector(
                      onTap: () {
                        launchUrl(Uri.parse(social.url));
                      },
                      child: SocialMediaContent(model: social),
                    ),
                  ),
                );
              }
              final hl = item['data'] as StoryHighlightModel;
              return Padding(
                padding: const EdgeInsets.only(right: 18),
                child: StoryHighlightCircle(
                  highlight: hl,
                  onTap: () => HighlightStoryViewerService.openHighlight(
                    userId: widget.userID,
                    highlight: hl,
                  ),
                  onLongPress: () {
                    final myUid = FirebaseAuth.instance.currentUser?.uid;
                    if (widget.userID == myUid) {
                      noYesAlert(
                        title: "Öne Çıkarılanı Kaldır",
                        message:
                            "Bu öne çıkarılanı kaldırmak istediğinizden emin misiniz?",
                        cancelText: "Vazgeç",
                        yesText: "Kaldır",
                        onYesPressed: () {
                          hlController.deleteHighlight(hl.id);
                        },
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget socialMediaLinks() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: controller.socialMediaList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: SizedBox(
              width: 70,
              child: GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      controller.centeredIndex.value = -1;
                    });
                  }
                  RedirectionLink()
                      .goToLink(controller.socialMediaList[index].url);
                },
                onLongPress: () {
                  controller.showSocialMediaLinkDelete(
                    controller.socialMediaList[index].docID,
                  );
                },
                child: SocialMediaContent(
                  model: controller.socialMediaList[index],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget counters() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (mounted) {
                setState(() {
                  controller.postSelection.value = 0;
                });
              }
            },
            child: Container(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _isBlockedByMe(widget.userID)
                          ? "0"
                          : NumberFormatter.format(
                              controller.totalPosts.toInt(),
                            ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    Text(
                      "Gönderi",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (mounted) {
                setState(() {
                  controller.centeredIndex.value = -1;
                });
              }
              Get.to(() =>
                      FollowingFollowers(selection: 0, userId: widget.userID))
                  ?.then((_) {
                controller.centeredIndex.value = 0;
              });
            },
            child: Container(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _isBlockedByMe(widget.userID)
                          ? "0"
                          : NumberFormatter.format(
                              controller.totalFollower.toInt(),
                            ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    Text(
                      "Takipci",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (mounted) {
                setState(() {
                  controller.centeredIndex.value = -1;
                });
              }
              Get.to(() =>
                      FollowingFollowers(selection: 1, userId: widget.userID))
                  ?.then((_) {
                if (mounted) {
                  setState(() {
                    controller.centeredIndex.value = 0;
                  });
                }
              });
            },
            child: Container(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _isBlockedByMe(widget.userID)
                          ? "0"
                          : NumberFormatter.format(
                              controller.totalFollowing.toInt(),
                            ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    Text(
                      "Takip",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _isBlockedByMe(widget.userID)
                        ? "0"
                        : NumberFormatter.format(
                            controller.totalLikes.value.toInt(),
                          ),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  Text(
                    "Beğeni",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (mounted) {
                setState(() {
                  controller.postSelection.value = 4;
                });
              }
            },
            child: Container(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _isBlockedByMe(widget.userID)
                          ? "0"
                          : NumberFormatter.format(
                              controller.totalMarket.toInt(),
                            ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    Text(
                      "İlan",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget postButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(0);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.tag,
                        color: controller.postSelection.value == 0
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 0 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(3);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.repeat,
                        color: controller.postSelection.value == 3
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 3 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(1);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: controller.postSelection.value == 1
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 1 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(2);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.photo_outlined,
                        color: controller.postSelection.value == 2
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 2 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(5);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: controller.postSelection.value == 5
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 5 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.setPostSelection(4);
                },
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: controller.postSelection.value == 4
                            ? Colors.pink
                            : Colors.black,
                        size: controller.postSelection.value == 4 ? 30 : 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildMarkets(BuildContext context) {
    return ListView(children: [header(), EmptyRow(text: "İlan Yok")]);
  }

  Widget buildIzbiraklar(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(child: header()),
        if (controller.scheduledPosts.isNotEmpty)
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0.5,
              crossAxisSpacing: 0.5,
              childAspectRatio: 9 / 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final model = controller.scheduledPosts[index];
              final hedef = DateTime.fromMillisecondsSinceEpoch(
                  model.izBirakYayinTarihi.toInt());
              final kalanText = kacGunKaldiFormatter(hedef);
              final isPublished = DateTime.now().millisecondsSinceEpoch >=
                  hedef.millisecondsSinceEpoch;

              return Stack(
                children: [
                  SizedBox.expand(
                    child: CachedNetworkImage(
                      imageUrl: model.thumbnail.isNotEmpty
                          ? model.thumbnail
                          : (model.img.isNotEmpty ? model.img.first : ''),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                          child:
                              CupertinoActivityIndicator(color: Colors.grey)),
                      errorWidget: (context, url, error) => const Center(
                          child:
                              CupertinoActivityIndicator(color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      model.hasPlayableVideo
                          ? CupertinoIcons.play_circle_fill
                          : CupertinoIcons.photo,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  if (!isPublished)
                    Positioned.fill(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),
                  if (!isPublished)
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.62),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                kalanText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              await IzBirakSubscriptionService.ensure()
                                  .subscribe(model.docID);
                              AppSnackbar(
                                'İz Bırak',
                                'Yayın tarihinde bildirim alacaksınız.',
                              );
                            },
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.add,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }, childCount: controller.scheduledPosts.length),
          )
        else
          SliverToBoxAdapter(
              child: Center(child: EmptyRow(text: "İz bırak gönderisi yok"))),
        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }

  // Profil fotoğrafını hikaye durumuna göre border ile oluştur
  Widget _buildProfileImageWithBorder() {
    final hasStories = controller.storyUserModel != null &&
        controller.storyUserModel!.stories.isNotEmpty;

    if (hasStories) {
      // Hikaye varsa gradient border
      return Container(
        width: 91, // 85 + 6 padding
        height: 91,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00BCD4), // Turkuaz
              Color(0xFF0097A7), // Koyu turkuaz
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ClipOval(
            child: SizedBox(
              width: 85,
              height: 85,
              child: CachedNetworkImage(
                imageUrl: controller.avatarUrl.value,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                    child: CupertinoActivityIndicator(color: Colors.black)),
              ),
            ),
          ),
        ),
      );
    } else {
      // Hikaye yoksa sadece resim (border yok)
      return ClipOval(
        child: SizedBox(
          width: 85,
          height: 85,
          child: CachedNetworkImage(
            imageUrl: controller.avatarUrl.value,
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) =>
                Center(child: CupertinoActivityIndicator(color: Colors.black)),
          ),
        ),
      );
    }
  }
}
