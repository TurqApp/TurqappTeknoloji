import 'dart:ui';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Ads/AdmobKare.dart';
import 'package:turqappv2/Core/BottomSheets/NoYesAlert.dart';
import 'package:turqappv2/Core/EmptyRow.dart';
import 'package:turqappv2/Core/Formatters.dart';
import 'package:turqappv2/Core/Helpers/RoadToTop/RoadToTop.dart';
import 'package:turqappv2/Core/Helpers/ShowMapSheet.dart';
import 'package:turqappv2/Core/RedirectionLink.dart';
import 'package:turqappv2/Core/RozetContent.dart';
import 'package:turqappv2/Core/Services/ConversationId.dart';
import 'package:turqappv2/Models/PostsModel.dart';
import 'package:turqappv2/Modules/Agenda/AgendaContent/AgendaContent.dart';
import 'package:turqappv2/Modules/Profile/AboutProfile/AboutProfile.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/FollowingFollowers.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/ReportUser.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfileController.dart';
import 'package:turqappv2/Services/FirebaseMyStore.dart';
import 'package:turqappv2/Themes/AppFonts.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';
import '../../Core/Helpers/SeenCountLabel.dart';
import '../Chat/Chat.dart';
import '../Chat/ChatListing/ChatListingController.dart';
import '../Profile/SocialMediaLinks/SocialMediaContent.dart';
import '../Short/SingleShortView.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Social/PhotoShorts/PhotoShorts.dart';
import '../Story/StoryViewer/StoryViewer.dart';
import '../Agenda/FloodListing/FloodListing.dart';

class SocialProfile extends StatefulWidget {
  final String userID;
  SocialProfile({super.key, required this.userID});

  @override
  State<SocialProfile> createState() => _SocialProfileState();
}

class _SocialProfileState extends State<SocialProfile> {
  late SocialProfileController controller;
  final ScrollController scrollController = ScrollController();
  final user = Get.find<FirebaseMyStore>();
  final chatListingController = Get.put(ChatListingController());

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SocialProfileController(userID: widget.userID),
      tag: widget.userID,
    );
    scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenCenterY = screenHeight / 2;

    // Yukarı butonu görünürlüğü
    if (scrollController.offset > 500) {
      controller.showScrollToTop.value = true;
    } else {
      controller.showScrollToTop.value = false;
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
                      if (!user.blockedUsers.contains(widget.userID))
                        Expanded(
                          child: (controller.gizliHesap.value &&
                                  controller.takipEdiyorum.value == false &&
                                  widget.userID != user.userID.value)
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
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipOval(
                            child: controller.pfImage.value.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: controller.pfImage.value,
                                    fit: BoxFit.cover,
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
                    if (model.img.isNotEmpty)
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
                            color: Colors.white,
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
                              color: Colors.black.withOpacity(0.6),
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
                              height: 20, color: Colors.white),
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
                              height: 20, color: Colors.white),
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
                    SizedBox(width: 4),
                    if (widget.userID != "")
                      RozetContent(size: 15, userID: widget.userID),
                  ],
                ),
              ),
              SizedBox(width: 12),
              PullDownButton(
                itemBuilder: (context) => [
                  PullDownMenuItem(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              "https://www.turqapp.com/users/${widget.userID}",
                        ),
                      );

                      AppSnackbar(
                          "Kopyalandı", "Bağlantı linki panoya kopyalandı");
                    },
                    title: 'Profil linkini kopyala',
                    icon: CupertinoIcons.doc_on_doc,
                  ),
                  PullDownMenuItem(
                    onTap: () {
                      Share.share(
                          "https://www.turqapp.com/posts/${widget.userID}");
                    },
                    title: 'Paylaş',
                    icon: CupertinoIcons.share,
                  ),
                  if (!user.blockedUsers.contains(widget.userID))
                    PullDownMenuItem(
                      onTap: () {
                        controller.centeredIndex.value = -1;
                        controller.block();
                      },
                      title: 'Engelle',
                      icon: CupertinoIcons.xmark_circle,
                    ),
                  if (user.blockedUsers.contains(widget.userID))
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
                buttonBuilder: (context, showMenu) => CupertinoButton(
                  onPressed: showMenu,
                  padding: EdgeInsets.zero,
                  child: Icon(
                    CupertinoIcons.ellipsis_vertical,
                    color: Colors.black,
                    size: 25,
                  ),
                ),
              ),
            ],
          ),
          imageAndFollowButtons(),
          const SizedBox(height: 12),
          textInfoBody(),
          if (controller.socialMediaList.isNotEmpty &&
              !user.blockedUsers.contains(widget.userID))
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 7),
              child: socialMediaLinks(),
            ),
          Padding(padding: const EdgeInsets.only(top: 10), child: counters()),
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
                  widget.userID != user.userID.value;
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
              if (mounted && controller.pfImage.value.isNotEmpty) {
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
          if (controller.complatedCheck.value &&
              !user.blockedUsers.contains(widget.userID))
            followButtons()
          else if (controller.complatedCheck.value &&
              user.blockedUsers.contains(widget.userID))
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
                    print("SOHBET VARMIS");
                  } else {
                    final chatId = buildConversationId(
                      user.userID.value,
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
                    print("SOHBET YOKMUS");
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
                                top: Radius.circular(16)),
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
                                          vertical: 14, horizontal: 12),
                                      backgroundColor:
                                          Colors.grey.withAlpha(50),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(CupertinoIcons.mail,
                                            color: Colors.black),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            controller.email.value,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontFamily: 'MontserratBold',
                                                fontSize: 15,
                                                color: Colors.black),
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
                                          vertical: 14, horizontal: 12),
                                      backgroundColor:
                                          Colors.grey.withAlpha(50),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(CupertinoIcons.phone,
                                            color: Colors.black),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            '+90${controller.phoneNumber.value}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontFamily: 'MontserratBold',
                                                fontSize: 15,
                                                color: Colors.black),
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
          //
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
                      user.blockedUsers.contains(widget.userID)
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
                      user.blockedUsers.contains(widget.userID)
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
                      user.blockedUsers.contains(widget.userID)
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
                    user.blockedUsers.contains(widget.userID)
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
                      user.blockedUsers.contains(widget.userID)
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
                    bottom: 4,
                    right: 4,
                    child: Icon(
                      model.hasPlayableVideo
                          ? CupertinoIcons.play_circle_fill
                          : CupertinoIcons.photo,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: Colors.black.withOpacity(0.15),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          kalanText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ),
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
                imageUrl: controller.pfImage.value,
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
            imageUrl: controller.pfImage.value,
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

  // Profil border'ını hikaye durumuna göre belirle
  Border? _getProfileBorder() {
    final hasStories = controller.storyUserModel != null &&
        controller.storyUserModel!.stories.isNotEmpty;

    if (hasStories) {
      return null; // Gradient kullanacağız
    } else {
      return null; // Border yok
    }
  }

  // Profil gradient'ını hikaye durumuna göre belirle
  Gradient? _getProfileGradient() {
    final hasStories = controller.storyUserModel != null &&
        controller.storyUserModel!.stories.isNotEmpty;

    if (hasStories) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF00BCD4), // Turkuaz
          Color(0xFF0097A7), // Koyu turkuaz
        ],
      );
    } else {
      return null; // Gradient yok
    }
  }
}
