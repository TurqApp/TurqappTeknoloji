import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/texts.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Widgets/shared_post_label.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/post_interaction_service.dart';
import 'package:turqappv2/Themes/app_fonts.dart';
import 'package:turqappv2/Core/sizes.dart';
import '../../../Core/BottomSheets/no_yes_alert.dart';
import '../../../Core/formatters.dart';
import '../../../Core/rozet_content.dart';
import '../../SocialProfile/ReportUser/report_user.dart';
import '../hashtag_text_post.dart';
import '../PostSharers/post_sharers.dart';
import '../../PostCreator/post_creator.dart';
import 'photo_short_content_controller.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';
import '../../../Services/post_count_manager.dart';

class PhotoShortContent extends StatefulWidget {
  final PostsModel model;
  const PhotoShortContent({super.key, required this.model});

  @override
  State<PhotoShortContent> createState() => _PhotoShortContentState();
}

class _PhotoShortContentState extends State<PhotoShortContent> {
  static const List<String> _flagReasons = <String>[
    'Uyuşturucu',
    'Kumar',
    'Çıplaklık',
    'Dolandırıcılık',
    'Şiddet',
    'Spam',
    'Diğer',
  ];
  static final RxSet<String> _flaggedPostIds = <String>{}.obs;
  late final PhotoShortsContentController controller;
  late final PageController _pageController;
  int _currentPage = 0;
  @override
  void initState() {
    super.initState();
    controller = Get.put(
      PhotoShortsContentController(model: widget.model),
      tag: widget.model.userID,
    );
    controller.fetchUserData(widget.model.userID);
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox.expand(
        child: Stack(
          children: [
            SizedBox.expand(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.model.img.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return PinchZoom(
                    child: GestureDetector(
                      onTap: () {
                        controller.fullScreen.value =
                            !controller.fullScreen.value;
                      },
                      onDoubleTap: () {
                        controller.toggleLike();
                      },
                      child: CachedNetworkImage(
                        memCacheHeight: 2000,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        imageUrl: widget.model.img[index],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Üst progress bar kaldırıldı; yalnızca altta nokta bar kullanılıyor
            // Üstte kullanıcı bilgileri (geri, profil, menü vs.) görünür
            if (!controller.fullScreen.value)
              SafeArea(child: userInfoBar(context)),

            // Üstte nokta bar (üstteki çizgiler yerine)
            if (widget.model.img.length > 1 && !controller.fullScreen.value)
              Positioned(
                top: MediaQuery.of(context).padding.top + 52,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.model.img.length, (i) {
                    final bool isActive = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: isActive ? 10 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            if (controller.gizlendi.value) gonderiGizlendi(context),
            if (controller.arsiv.value) gonderiArsivlendi(context),
            Obx(() => controller.silindi.value
                ? AnimatedOpacity(
                    opacity: controller.silindiOpacity.value,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: gonderiSilindi(context),
                  )
                : const SizedBox.shrink()),

            // OriginalUserAttribution for PhotoShortContent
            if (!controller.fullScreen.value)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 70),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.model.floodCount > 1) Texts.colorfulFlood,
                      SharedPostLabel(
                        originalUserID: widget.model.originalUserID,
                        fontSize: 12,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget userInfoBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: Container(
                    width: 45,
                    height: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withAlpha(80),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        CupertinoIcons.arrow_left,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                if (widget.model.floodCount > 1)
                  TextButton(
                    onPressed: () {
                      Get.to(() => FloodListing(mainModel: widget.model));
                    },
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.blue],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        "${widget.model.floodCount.toString()} FLOOD",
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                          color: Colors
                              .white, // Burada renk önemli değil çünkü shader kaplıyor
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipOval(
                              child: SizedBox(
                                width: 35,
                                height: 35,
                                child: Obx(
                                  () => controller.avatarUrl.value != ""
                                      ? GestureDetector(
                                          onTap: () {
                                            if (widget.model.userID !=
                                                FirebaseAuth.instance
                                                    .currentUser!.uid) {
                                              Get.to(
                                                () => SocialProfile(
                                                  userID: widget.model.userID,
                                                ),
                                              );
                                            }
                                          },
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                controller.avatarUrl.value,
                                            fit: BoxFit.cover,
                                            memCacheHeight: 100,
                                          ),
                                        )
                                      : const Center(
                                          child: CupertinoActivityIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (widget.model.userID !=
                                              FirebaseAuth
                                                  .instance.currentUser!.uid) {
                                            Get.to(
                                              () => SocialProfile(
                                                userID: widget.model.userID,
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          controller.fullName.value,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: AppFontFamilies.mbold,
                                          ),
                                        ),
                                      ),
                                      RozetContent(
                                        size: 14,
                                        userID: widget.model.userID,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    controller.nickname.value,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontFamily: AppFontFamilies.mregular,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 7),
                            if (!controller.takipEdiyorum.value &&
                                widget.model.userID !=
                                    FirebaseAuth.instance.currentUser!.uid &&
                                controller.avatarUrl.value != "")
                              Transform.translate(
                                offset: Offset(15, 0),
                                child: Obx(() {
                                  final isLoading =
                                      controller.followLoading.value;
                                  return ScaleTap(
                                    enabled: !isLoading,
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            controller.toggleFollowStatus(
                                              widget.model.userID,
                                            );
                                          },
                                    child: Container(
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          border:
                                              Border.all(color: Colors.white)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                "Takip Et",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily:
                                                        AppFontFamilies.mmedium,
                                                    fontSize: FontSizes.size12),
                                              ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            Transform.translate(
                              offset: Offset(15, -2),
                              child: pulldownmenu(context),
                            ),
                            SizedBox(
                              width: 12,
                            ),
                          ],
                        ),
                      ),
                      HashtagTextVideoPost(
                        text: widget.model.metin,
                        color: Colors.white,
                        volume: (bool) {
                          ///gerek yok
                        },
                      ),
                    ],
                  ),
                ),
                butonlar(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget butonlar(BuildContext context) {
    final int commentVisibility = widget.model.yorumVisibility;
    final int reshareVisibility = widget.model.paylasimVisibility;
    final currentUser = CurrentUserService.instance.currentUser;
    final bool isOwner =
        CurrentUserService.instance.userId == widget.model.userID;
    final bool isVerified = currentUser?.hesapOnayi ?? false;
    final bool isFollowing = controller.takipEdiyorum.value;
    final String rozet =
        (currentUser?.rozet ?? '').trim().toLowerCase().replaceAll('ı', 'i');
    final bool isBlackBadge = rozet == 'siyah' || rozet == 'black';
    final bool canComment = isOwner ||
        commentVisibility == 0 ||
        (commentVisibility == 1 && isVerified) ||
        (commentVisibility == 2 && isFollowing);
    final bool canReshare = isOwner ||
        reshareVisibility == 0 ||
        (reshareVisibility == 1 && isVerified) ||
        (reshareVisibility == 2 && isFollowing);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Yorum Butonu
        Expanded(
          child: TextButton(
            onPressed:
                canComment ? controller.showPostCommentsBottomSheet : null,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: SizedBox(
              height: 35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.bubble_right,
                    color:
                        canComment ? Colors.white : Colors.grey.withAlpha(80),
                    size: 23,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.format(controller.commentCount.value),
                    style: TextStyle(
                      color: canComment ? Colors.white : Colors.grey,
                      fontSize: 14,
                      fontFamily: AppFontFamilies.mmedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        /// Beğen Butonu
        Expanded(
          child: TextButton(
            onPressed: () async {
              controller.toggleLike();
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: SizedBox(
              height: 23,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    controller.likes.contains(
                      FirebaseAuth.instance.currentUser!.uid,
                    )
                        ? CupertinoIcons.hand_thumbsup_fill
                        : CupertinoIcons.hand_thumbsup,
                    color: controller.likes.contains(
                      FirebaseAuth.instance.currentUser!.uid,
                    )
                        ? Colors.blueAccent
                        : Colors.white,
                    size: 23,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.format(controller.likeCount.value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: AppFontFamilies.mmedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: TextButton(
            onPressed: canReshare ? controller.toggleReshare : null,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: SizedBox(
              height: 35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/icons/reshare.webp",
                    height: 25,
                    color: canReshare
                        ? (controller.isReshared.value
                            ? Colors.green
                            : Colors.white)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.format(controller.retryCount.value),
                    style: TextStyle(
                      color: canReshare
                          ? (controller.isReshared.value
                              ? Colors.green
                              : Colors.white)
                          : Colors.grey,
                      fontSize: 14,
                      fontFamily: AppFontFamilies.mmedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: TextButton(
            onPressed: controller.toggleSave,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  controller.isSaved.value
                      ? CupertinoIcons.bookmark_fill
                      : CupertinoIcons.bookmark,
                  color:
                      controller.isSaved.value ? Colors.orange : Colors.white,
                  size: 23,
                ),
                SizedBox(width: 4),
                Text(
                  NumberFormatter.format(controller.savedCount.value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: AppFontFamilies.mmedium,
                  ),
                ),
              ],
            ),
          ),
        ),

        /// Görüntüleme Butonu (Sadece bilgi, işlem yok)
        Expanded(
          child: TextButton(
            onPressed: null,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: SizedBox(
              height: 35,
              child: Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/icons/statsyeni.svg",
                        height: 30,
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        NumberFormatter.format(PostCountManager.instance
                            .getStatsCount(controller.model.docID)
                            .value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: AppFontFamilies.mmedium,
                        ),
                      ),
                    ],
                  )),
            ),
          ),
        ),

        Expanded(
          child: isBlackBadge
              ? PullDownButton(
                  itemBuilder: (context) {
                    final alreadyFlagged =
                        _flaggedPostIds.contains(widget.model.docID);
                    if (alreadyFlagged) return [];
                    return _flagReasons
                        .map(
                          (reason) => PullDownMenuItem(
                            onTap: () async {
                              try {
                                final result =
                                    await Get.put(PostInteractionService())
                                        .flagPostWithReason(
                                  widget.model.docID,
                                  reason: reason,
                                );
                                if (result.isOk) {
                                  _flaggedPostIds.add(widget.model.docID);
                                  if (mounted) setState(() {});
                                }
                                if (result.accepted) {
                                  AppSnackbar(
                                      'İşaretle', 'İşaretleme kaydedildi.');
                                } else if (result.alreadyFlagged) {
                                  AppSnackbar('Bilgi',
                                      'Bu gönderiyi zaten işaretlediniz.');
                                } else {
                                  AppSnackbar(
                                      'Hata', 'İşaretleme başarısız oldu.');
                                }
                              } catch (_) {
                                AppSnackbar(
                                    'Hata', 'İşaretleme başarısız oldu.');
                              }
                            },
                            title: reason,
                          ),
                        )
                        .toList();
                  },
                  buttonBuilder: (context, showMenu) => TextButton(
                    onPressed: _flaggedPostIds.contains(widget.model.docID)
                        ? null
                        : showMenu,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      color: _flaggedPostIds.contains(widget.model.docID)
                          ? Colors.grey
                          : Colors.amber,
                      size: 23,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: controller.sendPost,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.paperplane,
                        color: Colors.white,
                        size: 23,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget pulldownmenu(BuildContext context) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () async {
            // Dinamik paylaşım zinciri: eğer bu post zaten bir paylaşım ise ana kaynağı koru
            String finalOriginalUserID;
            String finalOriginalPostID;

            if (widget.model.originalUserID.isNotEmpty) {
              // Bu post zaten bir paylaşım, ana kaynağı koru
              finalOriginalUserID = widget.model.originalUserID;
              finalOriginalPostID = widget.model.originalPostID;
            } else {
              // İlk kez paylaşılıyor, bu postun sahibi ana kaynak olacak
              finalOriginalUserID = widget.model.userID;
              finalOriginalPostID = widget.model.docID;
            }

            Get.to(() => PostCreator(
                  sharedVideoUrl: widget.model.playbackUrl,
                  sharedAspectRatio: widget.model.aspectRatio.toDouble(),
                  sharedThumbnail: widget.model.thumbnail,
                  originalUserID: finalOriginalUserID,
                  originalPostID: finalOriginalPostID,
                  sharedAsPost: true,
                ))?.then((_) {});
          },
          title: 'Gönderi olarak yayınla',
          icon: CupertinoIcons.add_circled,
        ),
        if (widget.model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              Get.to(() => PostSharers(postID: widget.model.docID));
            },
            title: 'Gönderi olarak paylaşanlar',
            icon: CupertinoIcons.person_2,
          ),
        PullDownMenuItem(
          onTap: () {
            controller.sendPost();
          },
          title: 'Gönder',
          icon: CupertinoIcons.paperplane,
        ),
        PullDownMenuItem(
          onTap: () {
            controller.gizle();
          },
          title: 'Gizle',
          icon: CupertinoIcons.eye_slash,
        ),
        if (controller.canSendAdminPush)
          PullDownMenuItem(
            onTap: () {
              controller.sendAdminPushForPost();
            },
            title: 'Push',
            icon: CupertinoIcons.bell,
          ),
        PullDownMenuItem(
          onTap: () async {
            final previewImage = widget.model.thumbnail.trim().isNotEmpty
                ? widget.model.thumbnail.trim()
                : (widget.model.img.isNotEmpty
                    ? widget.model.img.first.trim()
                    : null);
            final url = await ShortLinkService().getPostPublicUrl(
              postId: widget.model.docID,
              desc: widget.model.metin,
              imageUrl: previewImage,
            );
            await Clipboard.setData(ClipboardData(text: url));

            AppSnackbar("Kopyalandı", "Bağlantı linki panoya kopyalandı");
            print(widget.model.docID);
          },
          title: 'Linki Kopyala',
          icon: CupertinoIcons.doc_on_doc,
        ),
        PullDownMenuItem(
          onTap: () async {
            await ShareActionGuard.run(() async {
              final previewImage = widget.model.thumbnail.trim().isNotEmpty
                  ? widget.model.thumbnail.trim()
                  : (widget.model.img.isNotEmpty
                      ? widget.model.img.first.trim()
                      : null);
              final url = await ShortLinkService().getPostPublicUrl(
                postId: widget.model.docID,
                desc: widget.model.metin,
                imageUrl: previewImage,
              );
              await ShareLinkService.shareUrl(
                url: url,
                title: 'TurqApp Gönderisi',
                subject: 'TurqApp Gönderisi',
              );
            });
          },
          title: 'Paylaş',
          icon: CupertinoIcons.share_up,
        ),
        if (widget.model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              noYesAlert(
                title: "Gönderiyi Sil",
                message: "Bu gönderiyi silmek istediğinizden emin misiniz?",
                yesText: "Gönderiyi Sil",
                cancelText: "Vazgeç",
                onYesPressed: () {
                  controller.sil();
                },
              ).then((_) {});
            },
            title: 'Sil',
            icon: CupertinoIcons.trash,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == false &&
            widget.model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              controller.arsivle();
            },
            title: "Arşivle",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == true &&
            widget.model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              controller.arsivdenCikart();
            },
            title: "Arşivden Çıkart",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              Get.to(() => ReportUser(
                  userID: widget.model.userID,
                  postID: widget.model.docID,
                  commentID: ""))?.then((_) {});
            },
            title: 'Şikayet Et',
            icon: CupertinoIcons.info,
            isDestructive: true,
          ),
      ],
      buttonBuilder: (context, showMenu) => CupertinoButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.6,
        alignment: Alignment.center,
        minimumSize: Size(0, 0),
        child: Icon(Icons.more_vert, color: Colors.white, size: 22),
      ),
    );
  }

  Widget gonderiGizlendi(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal,
                      color: Colors.green,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                const Text(
                  "Gönderi Gizlendi",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Divider(
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  height: 7,
                ),
                const Text(
                  "Bu gönderi gizlendi. Bunun gibi gönderileri akışında daha altlarda göreceksin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Montserrat"),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    controller.gizlemeyiGeriAl();
                  },
                  child: const Text(
                    "Geri Al",
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratMedium"),
                  ),
                )
              ],
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sonraki Gönderiye Geç",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Icon(
                    CupertinoIcons.arrow_down,
                    color: Colors.white,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget gonderiArsivlendi(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal,
                      color: Colors.green,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                const Text(
                  "Gönderi Arşivlendi",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Divider(color: Colors.white),
                ),
                SizedBox(
                  height: 7,
                ),
                const Text(
                  "Bu gönderiyi arşivlediniz.\nArtık kimseye bu gönderi gözükmeyecektir.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Montserrat"),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    controller.arsivdenCikart();
                  },
                  child: const Text(
                    "Geri Al",
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratMedium"),
                  ),
                )
              ],
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sonraki Gönderiye Geç",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Icon(
                    CupertinoIcons.arrow_down,
                    color: Colors.white,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget gonderiSilindi(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal,
                      color: Colors.green,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                const Text(
                  "Gönderi Sildiniz",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Divider(color: Colors.white),
                ),
                SizedBox(
                  height: 7,
                ),
                const Text(
                  "Bu gönderi artık yayında değil.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Montserrat"),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sonraki Gönderiye Geç",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Icon(
                    CupertinoIcons.arrow_down,
                    color: Colors.white,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
