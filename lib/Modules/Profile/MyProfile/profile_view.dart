import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Helpers/RoadToTop/road_to_top.dart';
import 'package:turqappv2/Core/Helpers/show_map_sheet.dart';
import 'package:turqappv2/Core/Helpers/seen_count_label.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/AgendaContent/agenda_content.dart';
import 'package:turqappv2/Services/post_delete_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';
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
import 'package:turqappv2/Modules/Profile/SavedPosts/saved_posts.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_content.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings.dart';
import 'package:turqappv2/Ads/admob_kare.dart';

import '../../../Core/dummy_data.dart';
import '../../../Core/functions.dart';
import '../../../Core/text_styles.dart';
import '../../Agenda/agenda_controller.dart';
import '../../Explore/explore_controller.dart';
import '../../Short/short_controller.dart';
import '../../Story/StoryMaker/story_maker.dart';
import '../../Story/StoryRow/story_row_controller.dart';
import '../../Story/StoryRow/story_user_model.dart';
import '../SocialMediaLinks/social_media_links_controller.dart';

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

  String get _myUserId => userService.currentUserRx.value?.userID ?? '';
  String get _myNickname => userService.currentUserRx.value?.nickname ?? '';
  String get _myAvatarUrl => userService.avatarUrl;
  String get _myFirstName => userService.currentUserRx.value?.firstName ?? '';
  String get _myLastName => userService.currentUserRx.value?.lastName ?? '';
  String get _myRozet => userService.currentUserRx.value?.rozet ?? '';
  String get _myMeslek => userService.currentUserRx.value?.meslekKategori ?? '';
  String get _myBio => userService.currentUserRx.value?.bio ?? '';
  String get _myAdres => userService.currentUserRx.value?.adres ?? '';
  int get _myTotalPosts => userService.currentUserRx.value?.counterOfPosts ?? 0;
  int get _myTotalLikes => userService.currentUserRx.value?.counterOfLikes ?? 0;
  int get _myTotalMarket => 0;
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
    controller.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      socialMediaController.getData();
    });
  }

  void _refreshUserState() {
    userService.forceRefresh();
    StoryRowController.refreshStoriesGlobally();
  }

  void _onScroll() {
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

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      final pos = box.localToGlobal(Offset.zero);
      final top = pos.dy;
      final bottom = pos.dy + box.size.height;

      if (top <= centerY && bottom >= centerY) {
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
              Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await controller.refreshAll();
                        socialMediaController.getData();
                      },
                      child: controller.postSelection.value == 0
                          ? () {
                              // Normal postlar ve yeniden paylaşılanları birleştir
                              final List<Map<String, dynamic>> combinedPosts =
                                  [];

                              // Normal postları ekle
                              for (final post in controller.allPosts) {
                                combinedPosts.add({
                                  'post': post,
                                  'isReshare': false,
                                  'timestamp': post.timeStamp,
                                });
                              }

                              // Yeniden paylaşılanları ekle
                              for (final reshare in controller.reshares) {
                                combinedPosts.add({
                                  'post': reshare,
                                  'isReshare': true,
                                  'timestamp': reshare.timeStamp,
                                });
                              }

                              // Zaman damgasına göre sırala (en yeni en üstte)
                              combinedPosts.sort((a, b) =>
                                  (b['timestamp'] as num)
                                      .compareTo(a['timestamp'] as num));

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
                                        itemCount: combinedPosts.length +
                                            2, // +2 header ve bottom space
                                        itemBuilder: (context, index) {
                                          if (index == 0) {
                                            return header();
                                          }

                                          // EN ALTA GELİNCE 50PX LİK BOŞLUK EKLE
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
                                          final isCentered =
                                              controller.centeredIndex.value ==
                                                  actualIndex;

                                          return Padding(
                                            padding: EdgeInsets.only(bottom: 5),
                                            child: Column(
                                              children: [
                                                Obx(() {
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
                                              : Column(children: [header()]),
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
              if (controller.showPfImage.value)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        controller.showPfImage.value = false;
                      },
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 10.0, // Yatay bulanıklık yoğunluğu
                          sigmaY: 10.0, // Dikey bulanıklık yoğunluğu
                        ),
                        child: Container(
                          // İstediğiniz opaklık oranını buradan ayarlayabilirsiniz
                          color: Colors.white.withValues(alpha: 0.2),
                          // Tam ekran kaplaması istiyorsanız genişlik/yükseklik verin:
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
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _myAvatarUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 300,
                                memCacheHeight: 600,
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                )
            ],
          );
        }),
      ),
    );
  }

  Widget buildPhotoGrid() {
    var templist = controller.photos
        .where((val) =>
            val.img.isNotEmpty &&
            !val.deletedPost &&
            !val.arsiv &&
            !val.gizlendi)
        .toList();

    return CustomScrollView(
      controller: controller.scrollController,
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: header()),
        if (templist.isNotEmpty)
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0.5,
              crossAxisSpacing: 0.5,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final model = templist[index];
              return GestureDetector(
                onTap: () async {
                  try {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await FirebaseFirestore.instance
                          .collection('Posts')
                          .doc(model.docID)
                          .collection('viewers')
                          .doc(uid)
                          .set({
                        'timeStamp': DateTime.now().millisecondsSinceEpoch
                      });
                    }
                  } catch (_) {}
                  if (model.floodCount > 1 && model.flood == false) {
                    Get.to(() => FloodListing(mainModel: model));
                  } else {
                    Get.to(() =>
                        PhotoShorts(fetchedList: templist, startModel: model));
                  }
                },
                onLongPress: () {
                  Get.dialog(
                    CupertinoAlertDialog(
                      title: Text("Gönderi hakkında",
                          style: TextStyles.bold15Black,
                          textAlign: TextAlign.center),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Bu gönderi için ne yapmak istiyorsunuz?",
                          style: TextStyles.medium15Black,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () {
                            Get.back();
                            arsivle(model);
                          },
                          child: const Text("Arşivle",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () {
                            Get.back();
                            Get.to(() => EditPost(post: model));
                          },
                          child: const Text("Düzenle",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            final store = Get.find<ProfileController>();
                            store.allPosts
                                .removeWhere((e) => e.docID == model.docID);
                            store.photos
                                .removeWhere((e) => e.docID == model.docID);
                            await PostDeleteService.instance.softDelete(model);
                          },
                          isDestructiveAction: true,
                          child: const Text("Sil",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () => Get.back(),
                          child: const Text("Vazgeç",
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                      ],
                    ),
                    barrierDismissible: true,
                  );
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
                          3.pw,
                          SeenCountLabel(model.docID),
                        ],
                      ),
                    )
                  ],
                ),
              );
            }, childCount: templist.length),
          )
        else
          SliverToBoxAdapter(child: EmptyRow(text: "Fotoğraf Yok")),
      ],
    );
  }

  Widget buildVideoGrid() {
    var templist = controller.videos
        .where((val) =>
            val.hasPlayableVideo &&
            !val.deletedPost &&
            !val.arsiv &&
            !val.gizlendi)
        .toList();

    return CustomScrollView(
      controller: controller.scrollController,
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: header()),
        if (templist.isNotEmpty)
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0.5,
              crossAxisSpacing: 0.5,
              childAspectRatio: 9 / 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final model = templist[index];
              return GestureDetector(
                onTap: () async {
                  try {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await FirebaseFirestore.instance
                          .collection('Posts')
                          .doc(model.docID)
                          .collection('viewers')
                          .doc(uid)
                          .set({
                        'timeStamp': DateTime.now().millisecondsSinceEpoch
                      });
                    }
                  } catch (_) {}
                  if (model.floodCount > 1 && model.flood == false) {
                    Get.to(() => FloodListing(mainModel: model));
                  } else {
                    Get.to(() => SingleShortView(
                        startList: templist, startModel: model));
                  }
                },
                onLongPress: () {
                  Get.dialog(
                    CupertinoAlertDialog(
                      title: Text("Gönderi hakkında",
                          style: TextStyles.bold15Black,
                          textAlign: TextAlign.center),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Bu gönderi için ne yapmak istiyorsunuz?",
                          style: TextStyles.medium15Black,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () {
                            Get.back();
                            arsivle(model);
                          },
                          child: const Text("Arşivle",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () {
                            Get.back();
                            Get.to(() => EditPost(post: model));
                          },
                          child: const Text("Düzenle",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            final store = Get.find<ProfileController>();
                            // Remove from allPosts and videos
                            store.allPosts
                                .removeWhere((e) => e.docID == model.docID);
                            store.videos
                                .removeWhere((e) => e.docID == model.docID);
                            // Soft delete
                            await PostDeleteService.instance.softDelete(model);
                          },
                          isDestructiveAction: true,
                          child: const Text("Sil",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () => Get.back(),
                          child: const Text("Vazgeç",
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                      ],
                    ),
                    barrierDismissible: true,
                  );
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
                      child: Icon(CupertinoIcons.play_circle_fill,
                          color: Colors.white, size: 20),
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
                          3.pw,
                          SeenCountLabel(model.docID),
                        ],
                      ),
                    )
                  ],
                ),
              );
            }, childCount: templist.length),
          )
        else
          SliverToBoxAdapter(
            child: Center(child: EmptyRow(text: "Video Yok")),
          ),
      ],
    );
  }

  Future<void> arsivle(PostsModel model) async {
    // Firestore güncelle
    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(model.docID)
        .update({
      "arsiv": true,
    });

    // Sayaç: görünür bir kök post ise counterOfPosts -= 1 (kendi profilim)
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final isVisible = (model.timeStamp <= nowMs) && !model.flood;
      if (isVisible) {
        final me = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (me.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(me)
              .update({'counterOfPosts': FieldValue.increment(-1)});
        }
      }
    } catch (_) {}

    // Tüm ilgili store ve listeleri güncelle
    final shortController = Get.find<ShortController>();
    final index = shortController.shorts.indexOf(model);
    if (index >= 0) shortController.shorts[index].arsiv = true;
    final exploreController = Get.find<ExploreController>();

    final index3 = exploreController.explorePosts.indexOf(model);
    if (index3 >= 0) exploreController.explorePosts[index3].arsiv = true;

    final index4 = exploreController.explorePhotos.indexOf(model);
    if (index4 >= 0) exploreController.explorePhotos[index4].arsiv = true;

    final index5 = exploreController.exploreVideos.indexOf(model);
    if (index5 >= 0) exploreController.exploreVideos[index5].arsiv = true;

    if (Get.isRegistered<AgendaController>()) {
      final store8 = Get.find<AgendaController>();
      final index8 = store8.agendaList.indexOf(model);
      if (index8 >= 0) store8.agendaList[index8].arsiv = true;
    }

    final store9 = Get.find<ProfileController>();
    final index9 = store9.allPosts.indexOf(model);
    if (index9 >= 0) store9.allPosts[index9].arsiv = true;

    final store10 = Get.find<ProfileController>();
    final index10 = store10.videos.indexOf(model);
    if (index10 >= 0) store10.videos[index10].arsiv = true;

    final store11 = Get.find<ProfileController>();
    final index11 = store11.photos.indexOf(model);
    if (index11 >= 0) store11.photos[index11].arsiv = true;

    controller.photos.refresh();
    controller.videos.refresh();
    controller.allPosts.refresh();
  }

  Widget buildReshares() {
    final hasVideos = controller.reshares.isNotEmpty;

    return CustomScrollView(
      controller: controller.scrollController,
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                onLongPress: () {
                  noYesAlert(
                      title: "Gönderiyi kaldır",
                      message:
                          "Bu gönderiyi yeniden paylaşılan gönderiler arasından silmek istediğinizden emin misiniz ?",
                      onYesPressed: () {
                        final store = Get.find<ProfileController>();
                        final index = store.reshares.indexOf(model);
                        if (index >= 0) store.reshares.removeAt(index);
                        PostDeleteService.instance.softDelete(model);
                      });
                },
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: model.thumbnail != ""
                            ? model.thumbnail
                            : model.img.first,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
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
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                          3.pw,
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

  Widget header() {
    return Obx(() {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.pausetheall.value = true;
                          Get.to(() => AboutProfile(
                              userID: FirebaseAuth
                                  .instance.currentUser!.uid))?.then((_) {
                            controller.pausetheall.value = true;
                          });
                        },
                        child: Text(
                          _myNickname,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontFamily: AppFontFamilies.mbold,
                          ),
                        ),
                      ),
                      4.pw,
                      if (_myUserId.isNotEmpty)
                        RozetContent(size: 15, userID: _myUserId),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    controller.pausetheall.value = true;
                    Get.to(() => MyQRCode())?.then((_) {
                      controller.pausetheall.value = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Icon(
                    CupertinoIcons.qrcode,
                    color: AppColors.textBlack,
                    size: 25,
                  ),
                ),
                12.pw,
                TextButton(
                  onPressed: () {
                    controller.pausetheall.value = true;
                    Get.to(() => SavedPosts())?.then((_) {
                      controller.pausetheall.value = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Icon(
                    CupertinoIcons.bookmark,
                    color: AppColors.textBlack,
                    size: 23,
                  ),
                ),
                12.pw,
                TextButton(
                  onPressed: () {
                    controller.pausetheall.value = true;
                    Get.to(() => SettingsView())?.then((_) {
                      controller.pausetheall.value = false;
                      _refreshUserState();
                    }); //burada videolari durdur
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Icon(
                    CupertinoIcons.gear,
                    color: AppColors.textBlack,
                    size: 25,
                  ),
                ),
              ],
            ),
          ),
          imageAndFollowButtons(),
          12.ph,
          textInfoBody(),
          if (socialMediaController.list.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 0, top: 7),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      final myUserID = FirebaseAuth.instance.currentUser!.uid;

                      // Kendi Story'un var mı?
                      if (_hasMyStories) {
                        try {
                          // Kendi modelini güncel listede tekrar bul, referanslar karışmasın
                          final myStoryUser = storyOwnerUsers.firstWhereOrNull(
                              (u) =>
                                  u.userID == myUserID && u.stories.isNotEmpty);

                          if (myStoryUser != null &&
                              myStoryUser.stories.isNotEmpty) {
                            Get.to(() => StoryViewer(
                                  startedUser: myStoryUser,
                                  storyOwnerUsers: [myStoryUser],
                                ));
                          } else {
                            // Story bulunamadı, oluşturma ekranına git
                            controller.pausetheall.value = true;
                            Get.to(() => StoryMaker())?.then((_) {
                              controller.pausetheall.value = false;
                              _refreshUserState();
                            });
                          }
                        } catch (e) {
                          print('ProfileView Story açma hatası: $e');
                          // Hata durumunda oluşturma ekranına git
                          controller.pausetheall.value = true;
                          Get.to(() => StoryMaker())?.then((_) {
                            controller.pausetheall.value = false;
                            _refreshUserState();
                          });
                        }
                      } else {
                        // Story yok, oluşturma ekranına git
                        controller.pausetheall.value = true;
                        Get.to(() => StoryMaker())?.then((_) {
                          controller.pausetheall.value = false;
                          _refreshUserState();
                        });
                      }
                    },
                    onLongPress: () {
                      controller.showPfImage.value = true;
                    },
                    child: _buildProfileImageWithBorder(),
                  ),
                  Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          controller.pausetheall.value = true;
                          Get.to(() => StoryMaker())?.then((_) {
                            controller.pausetheall.value = false;
                            _refreshUserState();
                          });
                        },
                        child: Container(
                          width: 25,
                          height: 25,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: Colors.green),
                          child: Icon(
                            CupertinoIcons.add,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ))
                ],
              ),
              12.pw,
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.pausetheall.value = true;
                          Get.to(() => EditProfile())?.then((_) {
                            controller.pausetheall.value = false;
                            _refreshUserState();
                          });
                        },
                        child: Container(
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Düzenle",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                    ),
                    12.pw,
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.pausetheall.value = true;
                          Get.to(() => MyStatisticView())?.then((v) {
                            controller.pausetheall.value = false;
                          });
                        },
                        child: Container(
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "İstatistikler",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
                "$_myFirstName $_myLastName",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratBold",
                ),
              ),
              4.pw,
              if (_myRozet.isEmpty)
                GestureDetector(
                  onTap: () {
                    controller.pausetheall.value = true;
                    Get.to(() => BecomeVerifiedAccount())?.then((_) {
                      controller.pausetheall.value = false;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: Colors.blueAccent,
                        size: 15,
                      ),
                      4.pw,
                      Text(
                        "Onaylı Hesap Ol",
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      )
                    ],
                  ),
                )
            ],
          ),
          if (_myMeslek.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                _myMeslek,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          if (_myBio.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.pausetheall.value = true;
                Get.to(() => BiographyMaker())?.then((_) {
                  controller.pausetheall.value = false;
                  _refreshUserState();
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  _myBio,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "Montserrat",
                  ),
                ),
              ),
            ),
          if (_myAdres.isNotEmpty)
            GestureDetector(
              onTap: () {
                showMapsSheetWithAdres(_myAdres);
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  _myAdres,
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

  Widget socialMediaLinks() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: socialMediaController.list.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: SizedBox(
              width: 70,
              child: GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse(socialMediaController.list[index].url));
                },
                onLongPress: () {
                  controller.showSocialMediaLinkDelete(
                    socialMediaController.list[index].docID,
                  );
                },
                child: SocialMediaContent(
                  model: socialMediaController.list[index],
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
              controller.postSelection.value = 0;
            },
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      NumberFormatter.format(_myTotalPosts),
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
              controller.pausetheall.value = true;
              Get.to(() => FollowingFollowers(
                  selection: 0,
                  userId: FirebaseAuth.instance.currentUser!.uid))?.then((_) {
                controller.pausetheall.value = false;
              });
            },
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      NumberFormatter.format(controller.followerCount.value),
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
              controller.pausetheall.value = true;
              Get.to(() => FollowingFollowers(
                  selection: 1,
                  userId: FirebaseAuth.instance.currentUser!.uid))?.then((v) {
                controller.pausetheall.value = false;
              });
            },
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      NumberFormatter.format(controller.followingCount.value),
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
            decoration: const BoxDecoration(color: Colors.white),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    NumberFormatter.format(_myTotalLikes),
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
              controller.postSelection.value = 4;
            },
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      NumberFormatter.format(_myTotalMarket),
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
                      Icon(Icons.photo_outlined,
                          color: controller.postSelection.value == 2
                              ? Colors.pink
                              : Colors.black,
                          size: controller.postSelection.value == 2 ? 30 : 25),
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
                        Icons.access_time_outlined,
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
    final screenSize = MediaQuery.of(context).size;
    final itemWidth = screenSize.width / 2; // örneğin 2 sütun varsa
    final itemHeight = screenSize.height * 0.43; // veya başka uygun oran
    final aspectRatio = itemWidth / itemHeight;
    return ListView(
      children: [
        header(),
        const Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Text(
                "AlSat",
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  "Almak da satmak da artık çok daha kolay.\nYakında buradayız!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dummyAds.length,
            itemBuilder: (context, index) {
              final item = dummyAds[index];
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      child: AspectRatio(
                        aspectRatio: 1 / 1.2,
                        child: Image.asset(
                          "assets/dummy/${item.imageAsset}.webp",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          Text(
                            item.category,
                            style: const TextStyle(
                              color: Colors.pink,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                          Row(
                            children: [
                              if (item.discount != null) ...[
                                // İndirimli fiyat
                                Text(
                                  calculateDiscountedPrice(
                                    item.price,
                                    item.discount!,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                                6.pw,
                                // Eski fiyat (üstü çizili)
                                Expanded(
                                  child: Text(
                                    item.price,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: "MontserratMedium",
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Sadece normal fiyat
                                Text(
                                  item.price,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              ],
                            ],
                          ),
                          4.ph,
                          Text(
                            item.shortDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildIzbiraklar(BuildContext context) {
    return CustomScrollView(
      controller: controller.scrollController,
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

              return GestureDetector(
                onTap: () {}, // izlenemez
                onLongPress: () {
                  Get.dialog(
                    CupertinoAlertDialog(
                      title: Text("İz Bırak Gönderi",
                          style: TextStyles.bold15Black,
                          textAlign: TextAlign.center),
                      content: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Bu gönderi için ne yapmak istersiniz?",
                          style: TextStyles.medium15Black,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () {
                            Get.back();
                            Get.to(() => EditPost(post: model));
                          },
                          child: const Text("Düzenle",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () async {
                            Get.back();
                            controller.scheduledPosts
                                .removeWhere((e) => e.docID == model.docID);
                            await PostDeleteService.instance.softDelete(model);
                          },
                          isDestructiveAction: true,
                          child: const Text("Sil",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                        CupertinoDialogAction(
                          onPressed: () => Get.back(),
                          child: const Text("Vazgeç",
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ),
                      ],
                    ),
                    barrierDismissible: true,
                  );
                },
                child: Stack(
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
                    // sağ altta ikon (video/foto) play_circle stilinde
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
                    // bulanıklaştırma ve kalan gün etiketi
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
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
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
                ),
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
    final hasStories = _hasMyStories;

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
          child: CachedUserAvatar(
            userId: userService.userId,
            radius: 42.5,
          ),
        ),
      );
    } else {
      // Hikaye yoksa sadece resim (border yok)
      return CachedUserAvatar(
        userId: userService.userId,
        radius: 42.5,
      );
    }
  }
}
