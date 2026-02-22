import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:turqappv2/Core/NicknameWithTextLine.dart';
import 'package:turqappv2/Core/Widgets/SharedPostLabel.dart';
import 'package:turqappv2/Core/Widgets/AnimatedActionButton.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Modules/Agenda/Components/post_state_messages.dart';
import '../Common/PostContentBase.dart';
import '../Common/PostContentController.dart';
import '../Common/PostActionStyle.dart';
import 'package:turqappv2/Modules/Agenda/Common/ReshareAttribution.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/FloodListing.dart';
import 'package:turqappv2/Modules/Agenda/PostLikeListing/PostLikeListing.dart';
import 'package:turqappv2/Modules/Profile/Archives/ArchivesController.dart';
import 'package:turqappv2/Modules/Short/ShortController.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/PhotoShorts.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/ReportUser.dart';
import 'package:turqappv2/Themes/AppIcons.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';
import '../../../Core/AppSnackbar.dart';
import '../../../Core/BottomSheets/NoYesAlert.dart';
import '../../../Core/Formatters.dart';
import '../../../Core/Functions.dart';
import '../../../Core/RozetContent.dart';
import '../../../Core/Texts.dart';
import '../../EditPost/EditPost.dart';
import '../../Short/SingleShortView.dart';
import '../../Social/UrlPostMaker/UrlPostMaker.dart';
import '../../Social/PostSharers/PostSharers.dart';
import '../../SocialProfile/SocialProfile.dart';
import 'ClassicContentController.dart';

class ClassicContent extends PostContentBase {
  const ClassicContent({
    super.key,
    required super.model,
    required super.isPreview,
    required super.shouldPlay,
    bool isYenidenPaylasilanPost = false,
    super.reshareUserID,
  }) : super(
          isReshared: isYenidenPaylasilanPost,
          showComments: false,
          showArchivePost: false,
        );

  @override
  PostContentController createController() =>
      ClassicContentController(model: model);

  @override
  State<ClassicContent> createState() => _ClassicContentState();
}

class _ClassicContentState extends State<ClassicContent>
    with PostContentBaseState<ClassicContent> {
  static const PostActionStyle _actionStyle = PostActionStyle.classic();
  final arsivController = Get.put(ArchiveController());
  final ShortController shortsController = Get.find<ShortController>();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFullscreen = false;

  @override
  bool get enableBufferedAutoplay => false;

  static const double _contentAspectRatio = 0.80;

  @override
  void onPostInitialized() {
    _pageController.addListener(() {
      final next = _pageController.page?.round() ?? 0;
      if (next != _currentPage) {
        setState(() => _currentPage = next);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClassicContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPlay != oldWidget.shouldPlay &&
        videoController?.value.isInitialized == true) {
      if (widget.shouldPlay) {
        videoController!
          ..setLooping(true)
          ..play();
      } else {
        videoController?.pause();
      }
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    try {
      controller.getLikes();
      controller.getSaved();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Gizli, arşivli veya silindi ise videoyu durdur
    if (controller.gizlendi.value ||
        controller.arsiv.value ||
        controller.silindi.value) {
      videoController?.pause();
    }
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.gizlendi.value)
            gonderiGizlendi(context)
          else if (controller.arsiv.value)
            gonderiArsivlendi(context)
          else if (controller.silindi.value)
            AnimatedOpacity(
              opacity: controller.silindiOpacity.value,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              child: gonderiSilindi(context),
            )
          else
            widget.model.img.isNotEmpty
                ? imgBody(context)
                : (widget.model.hasPlayableVideo
                    ? videoBody(context)
                    : textOnlyBody(context))
        ],
      );
    });
  }

  Widget textOnlyBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        headerUserInfoBar(),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onDoubleTap: () => controller.like(),
            onTap: () {
              if (widget.model.floodCount > 1) {
                Get.to(() => FloodListing(mainModel: widget.model));
              }
            },
            child: Stack(
              children: [
                Positioned(
                  left: 15,
                  top: 0,
                  child: Text(
                    '“',
                    style: TextStyle(
                      fontSize: 56,
                      height: 1,
                      color: Colors.black.withOpacity(0.06),
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: NicknameWithTextLine(
                    nickname: controller.nickname.value,
                    metin: widget.model.metin.trim(),
                    onNicknameTap: () {
                      if (widget.model.userID !=
                          FirebaseAuth.instance.currentUser!.uid) {
                        videoController?.pause();

                        Get.to(() => SocialProfile(userID: widget.model.userID))
                            ?.then((v) {
                          videoController?.play();
                        });
                      }
                    },
                    userID: widget.model.userID,
                    onAnyTap: () {},
                    inlineExpand: true,
                    collapsedMaxLines: 7,
                    showNickname: false,
                    padding: EdgeInsets.zero,
                    showEllipsisOverlay: false,
                  ),
                ),
                Positioned(
                  right: 15,
                  bottom: 0,
                  child: Text(
                    '"',
                    style: TextStyle(
                      fontSize: 56,
                      height: 1,
                      color: Colors.black.withOpacity(0.06),
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                // SharedPostLabel - text içeriğinin sol altına
                if (widget.model.originalUserID.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 15,
                    child: SharedPostLabel(
                      originalUserID: widget.model.originalUserID,
                      // sharedAsPost removed
                      fontSize: 12,
                      textColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Reshare attribution (single instance - fixed triple rendering bug)
        if (widget.isReshared)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/reshare.webp",
                    height: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  ReshareAttribution(
                    controller: controller,
                    model: widget.model,
                    explicitReshareUserId: widget.reshareUserID,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              commentButton(context),
              likeButton(),
              saveButton(),
              reshareButton(),
              statButton(),
              sendButton(),
            ],
          ),
        ),
        3.ph,
      ],
    );
  }

  Widget imgBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          return headerUserInfoBar();
        }),
        if (widget.model.img.length == 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () {
                final visibleList = agendaController.agendaList
                    .where((val) =>
                        val.deletedPost == false &&
                        val.arsiv == false &&
                        val.gizlendi == false &&
                        val.img.isNotEmpty)
                    .toList();

                if (widget.isPreview) {
                  Get.to(() => PhotoShorts(
                        fetchedList: visibleList,
                        startModel: widget.model,
                      ));
                } else {
                  if (widget.model.floodCount > 1) {
                    Get.to(() => FloodListing(mainModel: widget.model));
                  } else {
                    Get.to(() => PhotoShorts(
                          fetchedList: visibleList,
                          startModel: widget.model,
                        ));
                  }
                }
              },
              onDoubleTap: () {
                controller.like();
              },
              child: AspectRatio(
                aspectRatio: widget.model.aspectRatio.toDouble(),
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    SizedBox.expand(
                        child: CachedNetworkImage(
                      imageUrl: widget.model.img.first,
                      fit: BoxFit.cover,
                    )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.model.floodCount > 1)
                              Texts.colorfulFlood,
                            // SharedPostLabel - resmin sol altına
                            if (widget.model.originalUserID.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: SharedPostLabel(
                                  originalUserID: widget.model.originalUserID,
                                  // sharedAsPost removed
                                  fontSize: 12,
                                  textColor: Colors.red,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () {
                final visibleList = agendaController.agendaList
                    .where((val) =>
                        val.deletedPost == false &&
                        val.arsiv == false &&
                        val.gizlendi == false &&
                        val.img.isNotEmpty)
                    .toList();

                if (widget.isPreview) {
                  Get.to(() => PhotoShorts(
                        fetchedList: visibleList,
                        startModel: widget.model,
                      ));
                } else {
                  if (widget.model.floodCount > 1) {
                    Get.to(FloodListing(mainModel: widget.model));
                  } else {
                    Get.to(() => PhotoShorts(
                          fetchedList: visibleList,
                          startModel: widget.model,
                        ));
                  }
                }
              },
              onDoubleTap: () {
                controller.like();
              },
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.model.img.length,
                      itemBuilder: (context, index) {
                        final img = widget.model.img[index];
                        return CachedNetworkImage(
                            imageUrl: img, fit: BoxFit.cover);
                      },
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.model.floodCount > 1)
                              Texts.colorfulFlood,
                            SharedPostLabel(
                              originalUserID: widget.model.originalUserID,
                              // sharedAsPost removed
                              fontSize: 12,
                              textColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            List.generate(widget.model.img.length, (index) {
                          bool isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 6 : 5,
                            height: isActive ? 6 : 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? Colors.white : Colors.white54,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              commentButton(context),
              likeButton(),
              saveButton(),
              reshareButton(),
              statButton(),
              sendButton(),
            ],
          ),
        ),
        Obx(() {
          return NicknameWithTextLine(
            nickname: controller.nickname.value,
            metin: widget.model.metin,
            onNicknameTap: () {
              if (widget.model.userID !=
                  FirebaseAuth.instance.currentUser!.uid) {
                videoController?.pause();

                Get.to(() => SocialProfile(userID: widget.model.userID))
                    ?.then((v) {
                  videoController?.play();
                });
              }
            },
            userID: widget.model.userID,
            onAnyTap: () {
              videoController?.pause();
            },
            inlineExpand: true,
            collapsedMaxLines: 1,
            showEllipsisOverlay: false,
          );
        }),
        3.ph,
      ],
    );
  }

  Widget videoBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            if (videoController != null)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: _contentAspectRatio,
                    child: Container(
                      color: Colors.black,
                    ),
                  ),

                  // 2. Video Player üstte ve tam örtülü
                  GestureDetector(
                    onTap: null,
                    onDoubleTap: () {
                      controller.like();
                    },
                    // Klasik görünümde uzun basınca pause olmasın
                    child: AspectRatio(
                      aspectRatio: _contentAspectRatio,
                      child: _isFullscreen
                          ? const SizedBox.shrink()
                          : videoController!.buildPlayer(
                              key: ValueKey(
                                  'classic-${widget.model.docID}-${videoController.hashCode}'),
                              aspectRatio: _contentAspectRatio,
                              useAspectRatio: false,
                            ),
                    ),
                  ),
                ],
              )
            else
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: _contentAspectRatio,
                    child: Container(
                      color: Colors.black,
                      child: widget.model.thumbnail.isEmpty
                          ? null
                          : Image.network(
                              widget.model.thumbnail,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox.shrink();
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                    ),
                  ),
                  // OriginalUserAttribution for video thumbnail
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.model.floodCount > 1) Texts.colorfulFlood,
                          SharedPostLabel(
                            originalUserID: widget.model.originalUserID,
                            // sharedAsPost removed
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // Süre göstergesi + Replay — sadece video state değiştiğinde rebuild
            if (videoController != null)
              ValueListenableBuilder<HLSVideoValue>(
                valueListenable: videoValueNotifier,
                builder: (_, v, __) {
                  if (!v.isInitialized) return const SizedBox.shrink();
                  final remaining = v.duration - v.position;
                  final safeRemaining =
                      remaining.isNegative ? Duration.zero : remaining;
                  final isEnded = remaining.inMilliseconds <= 0;
                  return Stack(
                    children: [
                      Positioned(
                        top: 50,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDuration(safeRemaining),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: "Montserrat",
                            ),
                          ),
                        ),
                      ),
                      if (isEnded)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                iconSize: 48,
                                color: Colors.white,
                                onPressed: () {
                                  videoController!
                                    ..seekTo(Duration.zero)
                                    ..play();
                                },
                                icon: const Icon(AppIcons.playFilled,
                                    color: Colors.white, size: 32),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

            if (videoController != null && widget.model.floodCount > 1)
              Positioned(
                bottom: 0,
                left: 0,
                child: Texts.colorfulFloodForVideo,
              ),

            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  agendaController.isMuted.toggle();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Obx(() => Icon(
                        agendaController.isMuted.value
                            ? CupertinoIcons.volume_off
                            : CupertinoIcons.volume_up,
                        color: Colors.white,
                        size: 20,
                      )),
                ),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: headerUserInfoWhite(),
            ),
          ],
        ),
        // Alt-sol: yeniden paylaşıldı etiketi (video)
        if (widget.isReshared)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/reshare.webp",
                    height: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  ReshareAttribution(
                    controller: controller,
                    model: widget.model,
                    explicitReshareUserId: widget.reshareUserID,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
          ),
        // OriginalUserAttribution for video
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.model.floodCount > 1) Texts.colorfulFlood,
              SharedPostLabel(
                originalUserID: widget.model.originalUserID,
                // sharedAsPost removed
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            commentButton(context),
            likeButton(),
            reshareButton(),
            saveButton(),
            statButton(),
            sendButton(),
          ],
        ),
        Obx(() {
          return NicknameWithTextLine(
            nickname: controller.nickname.value,
            metin: widget.model.metin,
            onNicknameTap: () {
              videoController?.pause();
              if (widget.model.userID !=
                  FirebaseAuth.instance.currentUser!.uid) {
                Get.to(() => SocialProfile(userID: widget.model.userID))
                    ?.then((v) {
                  videoController?.play();
                });
              }
            },
            userID: widget.model.userID,
            onAnyTap: () {
              videoController?.pause();
            },
            inlineExpand: true,
            collapsedMaxLines: 1,
            showEllipsisOverlay: false,
          );
        }),
      ],
    );
  }

  Widget headerUserInfoBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (widget.model.userID !=
                  FirebaseAuth.instance.currentUser!.uid) {
                videoController?.pause();
                Get.to(() => SocialProfile(userID: widget.model.userID))
                    ?.then((v) {
                  videoController?.play();
                });
              }
            },
            child: Obx(() => controller.pfImage.isNotEmpty
                ? CachedUserAvatar(
                    userId: widget.model.userID,
                    imageUrl: controller.pfImage.value,
                    radius: 19, // 38px diameter / 2
                  )
                : const SizedBox.shrink()),
          ),
          7.pw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                if (widget.model.userID !=
                                    FirebaseAuth.instance.currentUser!.uid) {
                                  videoController?.pause();
                                  Get.to(() => SocialProfile(
                                      userID: widget.model.userID))?.then((v) {
                                    videoController?.play();
                                  });
                                }
                              },
                              child: Text(
                                controller.fullName.value.replaceAll("  ", " "),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                          ),
                          RozetContent(size: 13, userID: widget.model.userID),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, right: 12),
                            child: Text(
                              controller.editTime.value != 0
                                  ? "${timeAgoMetin(controller.editTime.value)} düzenlendi"
                                  : timeAgoMetin(
                                      widget.model.izBirakYayinTarihi != 0
                                          ? widget.model.izBirakYayinTarihi
                                          : widget.model.timeStamp),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.isFollowing.value == false &&
                        widget.model.userID !=
                            FirebaseAuth.instance.currentUser!.uid)
                      Transform.translate(
                        offset: Offset(0, 5),
                        child: Obx(() => TextButton(
                              onPressed: controller.followLoading.value
                                  ? null
                                  : () {
                                      controller.followUser();
                                    },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: controller.followLoading.value
                                  ? Container(
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          border:
                                              Border.all(color: Colors.black)),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.black),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Texts.followMeButtonBlack,
                            )),
                      ),
                    7.pw,
                    pulldownmenu(Colors.black),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.model.konum != ""
                          ? widget.model.konum
                          : "@${controller.nickname.value}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: "Montserrat",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget headerUserInfoWhite() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (widget.model.userID !=
                  FirebaseAuth.instance.currentUser!.uid) {
                videoController?.pause();
                Get.to(() => SocialProfile(userID: widget.model.userID))
                    ?.then((v) {
                  videoController?.play();
                });
              }
            },
            child: Obx(() => controller.pfImage.isNotEmpty
                ? CachedUserAvatar(
                    userId: widget.model.userID,
                    imageUrl: controller.pfImage.value,
                    radius: 19, // 38px diameter / 2
                  )
                : const SizedBox.shrink()),
          ),
          7.pw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                if (widget.model.userID !=
                                    FirebaseAuth.instance.currentUser!.uid) {
                                  videoController?.pause();
                                  Get.to(() => SocialProfile(
                                      userID: widget.model.userID))?.then((v) {
                                    videoController?.play();
                                  });
                                }
                              },
                              child: Text(
                                controller.fullName.value.replaceAll("  ", " "),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                          ),
                          RozetContent(size: 12, userID: widget.model.userID),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, right: 12),
                            child: Text(
                              controller.editTime.value != 0
                                  ? "${timeAgoMetin(controller.editTime.value)} düzenlendi"
                                  : timeAgoMetin(
                                      widget.model.izBirakYayinTarihi != 0
                                          ? widget.model.izBirakYayinTarihi
                                          : widget.model.timeStamp),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.isFollowing.value == false)
                      Transform.translate(
                        offset: Offset(0, 5),
                        child: Obx(() => TextButton(
                              onPressed: controller.followLoading.value
                                  ? null
                                  : () {
                                      controller.followUser();
                                    },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: controller.followLoading.value
                                  ? Container(
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          border:
                                              Border.all(color: Colors.white)),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Texts.followMeButtonWhite,
                            )),
                      ),
                    7.pw,
                    pulldownmenu(Colors.white),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.model.konum != ""
                          ? widget.model.konum
                          : "@${controller.nickname.value}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: "Montserrat",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget pulldownmenu(Color color) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () async {
            videoController?.pause();

            // Dinamik paylaşım zinciri: eğer bu post zaten bir paylaşım ise ana kaynağı koru
            String finalOriginalUserID;
            String finalOriginalPostID;

            if (widget.model.originalUserID.isNotEmpty) {
              // Bu post zaten bir paylaşım, ana kaynağı koru
              finalOriginalUserID = widget.model.originalUserID;
              finalOriginalPostID =
                  widget.model.originalPostID;
            } else {
              // İlk kez paylaşılıyor, bu postun sahibi ana kaynak olacak
              finalOriginalUserID = widget.model.userID;
              finalOriginalPostID = widget.model.docID;
            }

            Get.to(() => UrlPostMaker(
                  video: widget.model.playbackUrl,
                  aspectRatio: widget.model.aspectRatio.toDouble(),
                  imgs: widget.model.img,
                  thumbnail: widget.model.thumbnail,
                  originalUserID: finalOriginalUserID,
                  originalPostID: finalOriginalPostID,
                  sharedAsPost: true,
                ))?.then((_) {
              videoController?.play();
            });
          },
          title: 'Gönderi olarak yayınla',
          icon: CupertinoIcons.add_circled,
        ),
        if (widget.model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => PostSharers(postID: widget.model.docID))?.then((_) {
                videoController?.play();
              });
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
            videoController?.pause();
            controller.gizle();
          },
          title: 'Gizle',
          icon: CupertinoIcons.eye_slash,
        ),
        if (widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
            FirebaseAuth.instance.currentUser!.uid ==
                "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2")
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => EditPost(post: widget.model))?.then((_) {
                videoController?.play();
              });
            },
            title: 'Düzenle',
            icon: CupertinoIcons.pencil_circle,
          ),
        PullDownMenuItem(
          onTap: () {
            Clipboard.setData(
              ClipboardData(
                text: "https://www.turqapp.com/posts/${widget.model.docID}",
              ),
            );

            AppSnackbar("Kopyalandı", "Bağlantı linki panoya kopyalandı");
            print(widget.model.docID);
          },
          title: 'Linki Kopyala',
          icon: CupertinoIcons.doc_on_doc,
        ),
        PullDownMenuItem(
          onTap: () {
            Share.share("https://www.turqapp.com/posts/${widget.model.docID}");
          },
          title: 'Paylaş',
          icon: CupertinoIcons.share,
        ),
        if (widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
            FirebaseAuth.instance.currentUser!.uid ==
                "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2")
          PullDownMenuItem(
            onTap: () {
              // 2) Videoyu durdur
              videoController?.pause();

              // 3) Alert’i göster ve kapandıktan sonra silinme durumuna göre videoyu devam ettir
              noYesAlert(
                title: "Gönderiyi Sil",
                message: "Bu gönderiyi silmek istediğinizden emin misiniz?",
                yesText: "Gönderiyi Sil",
                cancelText: "Vazgeç",
                onYesPressed: () {
                  controller.sil();
                },
              ).then((_) {
                // Eğer silinmediyse videoyu tekrar başlat
                if (!controller.silindi.value) {
                  videoController?.play();
                }
              });
            },
            title: 'Sil',
            icon: CupertinoIcons.trash,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == false &&
            (widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
                FirebaseAuth.instance.currentUser!.uid ==
                    "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2"))
          PullDownMenuItem(
            onTap: () {
              controller.arsivle();
              videoController?.pause();
            },
            title: "Arşivle",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == true &&
            (widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
                FirebaseAuth.instance.currentUser!.uid ==
                    "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2"))
          PullDownMenuItem(
            onTap: () {
              controller.arsivdenCikart();
              videoController?.play();
            },
            title: "Arşivden Çıkart",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => ReportUser(
                  userID: widget.model.userID,
                  postID: widget.model.docID,
                  commentID: ""))?.then((_) {
                videoController?.play();
              });
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
        alignment: Alignment.center, minimumSize: Size(0, 0),
        child: Icon(Icons.more_vert, color: color, size: 22),
      ),
    );
  }

  Widget reshareButton() {
    return Obx(() {
      final bool canReshare = widget.model.paylasGizliligi != 2;
      final bool isReshared = controller.yenidenPaylasildiMi.value;
      final Color displayColor =
          canReshare ? (isReshared ? Colors.green : Colors.black) : Colors.grey;

      return AnimatedActionButton(
        enabled: canReshare,
        semanticsLabel: 'Yeniden paylaş',
        onTap: canReshare ? controller.reshare : null,
        child: _iconAction(
          icon: _actionStyle.reshareIcon ?? Icons.repeat,
          iconSize: _actionStyle.iconSize,
          color: displayColor,
          label: NumberFormatter.format(controller.retryCount.value),
          labelColor: displayColor,
        ),
      );
    });
  }

  Widget commentButton(BuildContext context) {
    return Obx(() {
      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final bool hasCommented = controller.comments.contains(currentUserId);
      final bool canInteract = widget.model.yorum;
      final Color displayColor = canInteract
          ? (hasCommented ? Colors.pink : Colors.black)
          : Colors.grey;

      return AnimatedActionButton(
        enabled: canInteract,
        semanticsLabel: 'Yorumlar',
        onTap: canInteract
            ? () {
                videoController?.pause();
                controller.showPostCommentsBottomSheet(
                  onClosed: () => videoController?.play(),
                );
              }
            : null,
        child: _iconAction(
          icon: hasCommented
              ? CupertinoIcons.bubble_left_fill
              : CupertinoIcons.bubble_left,
          color: displayColor,
          label: NumberFormatter.format(controller.commentCount.value),
          labelColor: displayColor,
          iconSize: 18,
        ),
      );
    });
  }

  Widget likeButton() {
    return Obx(() {
      final bool isLiked =
          controller.likes.contains(FirebaseAuth.instance.currentUser!.uid);
      final Color displayColor = isLiked ? Colors.blueAccent : Colors.black;

      return AnimatedActionButton(
        enabled: true,
        semanticsLabel: 'Beğeniler',
        onTap: controller.like,
        onLongPress: () {
          videoController?.pause();
          Get.bottomSheet(
            Container(
              height: Get.height / 2,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(18),
                  topLeft: Radius.circular(18),
                ),
              ),
              child: PostLikeListing(postID: widget.model.docID),
            ),
          ).then((_) {
            videoController?.play();
          });
        },
        child: _iconAction(
          icon: isLiked
              ? CupertinoIcons.hand_thumbsup_fill
              : CupertinoIcons.hand_thumbsup,
          iconSize: 18,
          color: displayColor,
          label: NumberFormatter.format(controller.likeCount.value),
          labelColor: displayColor,
        ),
      );
    });
  }

  Widget saveButton() {
    return Obx(() {
      final bool isSaved = controller.saved.value == true;
      final Color displayColor = isSaved ? Colors.orange : Colors.black;

      return AnimatedActionButton(
        enabled: true,
        semanticsLabel: 'Kaydet',
        onTap: controller.save,
        child: _iconAction(
          icon:
              isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
          iconSize: 18,
          color: displayColor,
          label: NumberFormatter.format(controller.savedCount.value),
          labelColor: displayColor,
        ),
      );
    });
  }

  Widget statButton() {
    return Theme(
      data: Theme.of(Get.context!).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart,
                  color: Colors.black, size: 20), // İstatistik ikonu
              2.pw,
              Text(
                NumberFormatter.format(controller.statsCount.value),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ],
          )),
    );
  }

  Widget sendButton() {
    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Paylaş',
      onTap: controller.sendPost,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
      child: Icon(
        CupertinoIcons.paperplane,
        color: Colors.black,
        size: _actionStyle.sendIconSize,
      ),
    );
  }

  Widget gonderiGizlendi(BuildContext context) {
    return PostHiddenMessage(
      onUndo: () {
        controller.gizlemeyiGeriAl();
        videoController?.play();
      },
      videoController: videoController,
    );
  }

  Widget gonderiArsivlendi(BuildContext context) {
    return PostArchivedMessage(
      onUndo: () {
        controller.arsivdenCikart();
        videoController?.play();
      },
      videoController: videoController,
    );
  }

  Widget gonderiSilindi(BuildContext context) {
    return const PostDeletedMessage();
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    String? label,
    Color? labelColor,
    double? iconSize,
  }) {
    return _actionContent(
      leading:
          Icon(icon, color: color, size: iconSize ?? _actionStyle.iconSize),
      label: label,
      labelColor: labelColor ?? color,
    );
  }

  Widget _actionContent({
    required Widget leading,
    String? label,
    Color? labelColor,
  }) {
    return ActionButtonContent(
      leading: leading,
      label: label,
      labelStyle: _actionStyle.textStyle.copyWith(
        color: labelColor ?? _actionStyle.textStyle.color,
      ),
      gap: 2,
    );
  }

  String _formatDuration(Duration position) {
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
