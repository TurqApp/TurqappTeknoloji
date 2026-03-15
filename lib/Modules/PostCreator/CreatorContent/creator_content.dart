import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:video_player/video_player.dart';
import '../post_creator_controller.dart';
import 'creator_content_controller.dart';
import 'post_creator_model.dart';

part 'creator_content_media_part.dart';
part 'creator_content_quoted_part.dart';

class LineLimitingTextInputFormatter extends TextInputFormatter {
  final int maxLines;
  LineLimitingTextInputFormatter(this.maxLines);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final lines = newValue.text.split('\n');
    if (lines.length <= maxLines) return newValue;

    final limited = lines.take(maxLines).join('\n');
    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: limited.length),
      composing: TextRange.empty,
    );
  }
}

class CreatorContent extends StatelessWidget {
  final PostCreatorModel model;
  final bool isSelected;

  CreatorContent({super.key, required this.model, required this.isSelected});
  late final CreatorContentController controller;
  final mainController = Get.find<PostCreatorController>();
  static const Map<String, String> _videoLookLabels = <String, String>{
    'original': 'Orijinal',
    'clear': 'Temiz',
    'cinema': 'Sinematik',
    'vibe': 'Canlı',
  };
  static const Map<String, IconData> _videoLookIcons = <String, IconData>{
    'original': CupertinoIcons.circle,
    'clear': CupertinoIcons.sparkles,
    'cinema': CupertinoIcons.film,
    'vibe': CupertinoIcons.sun_max,
  };

  double get _singleImagePreviewAspect {
    final reused = controller.reusedImageAspectRatio.value;
    if (reused > 0) return reused;
    return 0.80;
  }

  @override
  Widget build(BuildContext context) {
    controller = Get.put(
      CreatorContentController(),
      tag: model.index.toString(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () {
          if (!isSelected) {
            mainController.selectedIndex.value = model.index;
          }
          controller.focus.requestFocus();
        },
        child: Obx(() {
          final userService = CurrentUserService.instance;
          final currentUser = userService.currentUserRx.value;
          final composerUserId = (currentUser?.userID ??
                  (userService.userId.isNotEmpty
                      ? userService.userId
                      : (FirebaseAuth.instance.currentUser?.uid ?? '')))
              .trim();
          final composerAvatarUrl =
              (currentUser?.avatarUrl ?? userService.avatarUrl).trim();
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sol taraf: profil ve çizgi
                Column(
                  children: [
                    // Profil fotoğrafı
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: CachedUserAvatar(
                        userId:
                            composerUserId.isNotEmpty ? composerUserId : null,
                        imageUrl: composerAvatarUrl.isNotEmpty
                            ? composerAvatarUrl
                            : null,
                        radius: 19,
                      ),
                    ),
                    7.ph,
                    // Dikey çizgi
                    if (mainController.postList.length != 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.only(top: 4, bottom: 12),
                          color: Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
                4.pw,

                Obx(() {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        textBody(),
                        SizedBox(height: 12),
                        Obx(() {
                          final hasMedia =
                              controller.croppedImages.isNotEmpty ||
                                  controller.reusedImageUrls.isNotEmpty ||
                                  controller.videoPlayerController != null ||
                                  controller.waitingVideo.value;
                          if (mainController.isQuotedPost) {
                            return const SizedBox.shrink();
                          }
                          return hasMedia
                              ? const SizedBox.shrink()
                              : buildPollPreview();
                        }),
                        Obx(() {
                          if (mainController.isQuotedPost) {
                            return _buildQuotedComposerCard();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (controller.croppedImages.isNotEmpty)
                                buildImageGridFromMemory(
                                    controller.croppedImages),
                              if (controller.croppedImages.isEmpty &&
                                  controller.reusedImageUrls.isNotEmpty)
                                buildImageGridFromUrls(
                                    controller.reusedImageUrls),
                              Stack(
                                children: [
                                  if (controller.waitingVideo.value == false &&
                                      controller.videoPlayerController != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 7),
                                      child: videoBody(),
                                    ),
                                  if (controller.waitingVideo.value)
                                    AspectRatio(
                                        aspectRatio: 1,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Shimmer.fromColors(
                                              baseColor: Colors.grey.shade300,
                                              highlightColor:
                                                  Colors.grey.shade100,
                                              child: Container(
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child:
                                                      CupertinoActivityIndicator(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  "Video İşleniyor",
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          "MontserratMedium"),
                                                )
                                              ],
                                            ),
                                          ],
                                        ))
                                ],
                              ),
                            ],
                          );
                        }),
                        Obx(() {
                          final hasMedia =
                              controller.croppedImages.isNotEmpty ||
                                  controller.reusedImageUrls.isNotEmpty ||
                                  controller.videoPlayerController != null ||
                                  controller.waitingVideo.value;
                          if (mainController.isQuotedPost) {
                            return const SizedBox.shrink();
                          }
                          return hasMedia
                              ? Padding(
                                  padding: EdgeInsets.only(
                                    top: 10,
                                    left: (controller.videoPlayerController !=
                                                null ||
                                            controller.waitingVideo.value)
                                        ? 7
                                        : 0,
                                  ),
                                  child: _buildMediaLookSelector(),
                                )
                              : const SizedBox.shrink();
                        }),
                        Obx(() {
                          final hasMedia =
                              controller.croppedImages.isNotEmpty ||
                                  controller.reusedImageUrls.isNotEmpty ||
                                  controller.videoPlayerController != null ||
                                  controller.waitingVideo.value;
                          if (mainController.isQuotedPost) {
                            return const SizedBox.shrink();
                          }
                          return hasMedia
                              ? Padding(
                                  padding: EdgeInsets.only(
                                    top: 12,
                                    left: (controller.videoPlayerController !=
                                                null ||
                                            controller.waitingVideo.value)
                                        ? 7
                                        : 0,
                                  ),
                                  child: buildPollPreview(),
                                )
                              : const SizedBox.shrink();
                        }),
                        if (controller.adres.value != "")
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.map_pin,
                                  color: Colors.red,
                                  size: 15,
                                ),
                                SizedBox(
                                  width: 3,
                                ),
                                Text(
                                  controller.adres.value,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "Montserrat"),
                                ),
                              ],
                            ),
                          ),
                        12.ph,
                      ],
                    ),
                  );
                })
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget textBody() {
    return Obx(() {
      return Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Scrollbar(
                    child: TextField(
                      focusNode: controller.focus,
                      controller: controller.textEdit,
                      textCapitalization: TextCapitalization.sentences,
                      onTap: () {
                        mainController.selectedIndex.value = model.index;
                      },
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 1,
                      maxLines: 14,
                      inputFormatters: [LineLimitingTextInputFormatter(14)],
                      readOnly: controller.waitingVideo.value,
                      onChanged: (val) {
                        controller.textChanged.value = val.trim().isNotEmpty;
                      },
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: controller.waitingVideo.value
                            ? "Lütfen bekle. Video işleniyor..."
                            : "Ne var ne yok ?",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontFamily: "MontserratMedium",
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ),
              ),
              if (mainController.postList.length > 1)
                Transform.translate(
                  offset: Offset(10, -15),
                  child: IconButton(
                    onPressed: () {
                      final indexInList =
                          mainController.postList.indexWhere((e) => e == model);
                      if (indexInList != -1) {
                        mainController.postList.removeAt(indexInList);
                        mainController.selectedIndex.value--;
                      }
                    },
                    icon: Icon(
                      CupertinoIcons.xmark,
                      color: Colors.black,
                      size: 15,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}
