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
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/iz_birak_subscription_service.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
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
import 'package:url_launcher/url_launcher.dart';
import '../Social/PhotoShorts/photo_shorts.dart';
import '../Story/StoryViewer/story_viewer.dart';
import '../Story/StoryHighlights/story_highlights_controller.dart';
import '../Story/StoryHighlights/story_highlight_circle.dart';
import '../Story/StoryHighlights/story_highlight_model.dart';
import '../Story/StoryHighlights/highlight_story_viewer_service.dart';
import '../Agenda/FloodListing/flood_listing.dart';
import '../../Models/social_media_model.dart';

part 'social_profile_sections_part.dart';

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

  void _setCenteredIndex(int value) {
    if (!mounted) return;
    setState(() {
      controller.centeredIndex.value = value;
    });
  }

  void _showProfileImagePreview() {
    if (!mounted || controller.avatarUrl.value.isEmpty) return;
    setState(() {
      controller.showPfImage.value = true;
      controller.centeredIndex.value = -1;
    });
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
}
