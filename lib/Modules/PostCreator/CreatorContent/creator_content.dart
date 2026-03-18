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

  double get _threadPickerWidthFactor {
    if (mainController.postList.length <= 1 || isSelected) return 1.0;
    return 0.5;
  }

  Widget _buildThreadPickerPreview(Widget child) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: _threadPickerWidthFactor,
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
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
            final position = mainController.postList.indexWhere(
              (post) => post.index == model.index,
            );
            if (position != -1) {
              mainController.selectedIndex.value = position;
            }
          }
          controller.focus.requestFocus();
        },
        child: Obx(() {
          final userService = CurrentUserService.instance;
          final currentUser = userService.currentUserRx.value;
          final threadIndex = mainController.postList.indexWhere(
            (post) => post.index == model.index,
          );
          final isFirstInThread = threadIndex <= 0;
          final isLastInThread =
              threadIndex == -1 ||
              threadIndex == mainController.postList.length - 1;
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
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (mainController.postList.length > 1)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 2,
                            margin: EdgeInsets.only(
                              top: isFirstInThread ? 44 : 0,
                              bottom: isLastInThread ? 12 : 0,
                            ),
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: CachedUserAvatar(
                              userId: composerUserId.isNotEmpty
                                  ? composerUserId
                                  : null,
                              imageUrl: composerAvatarUrl.isNotEmpty
                                  ? composerAvatarUrl
                                  : null,
                              radius: 19,
                            ),
                          ),
                          7.ph,
                        ],
                      ),
                    ),
                  ],
                ),
                4.pw,

                Expanded(
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
                        if (mainController.isQuotedPost ||
                            mainController.postList.length > 1) {
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
                              _buildThreadPickerPreview(
                                buildImageGridFromMemory(
                                  controller.croppedImages,
                                ),
                              ),
                            if (controller.croppedImages.isEmpty &&
                                controller.reusedImageUrls.isNotEmpty)
                              _buildThreadPickerPreview(
                                buildImageGridFromUrls(
                                  controller.reusedImageUrls,
                                ),
                              ),
                            _buildThreadPickerPreview(
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
                      12.ph,
                    ],
                  ),
                )
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
                        final position = mainController.postList.indexWhere(
                          (post) => post.index == model.index,
                        );
                        if (position != -1) {
                          mainController.selectedIndex.value = position;
                        }
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
                        if (indexInList == 0) {
                          for (final post in mainController.postList) {
                            if (Get.isRegistered<CreatorContentController>(
                              tag: post.index.toString(),
                            )) {
                              Get.delete<CreatorContentController>(
                                tag: post.index.toString(),
                                force: true,
                              );
                            }
                          }
                          mainController.postList.assignAll(
                            [PostCreatorModel(index: 0, text: "")],
                          );
                          mainController.resetComposerItemIndexSeed(1);
                          mainController.selectedIndex.value = 0;
                        } else {
                          if (Get.isRegistered<CreatorContentController>(
                            tag: model.index.toString(),
                          )) {
                            Get.delete<CreatorContentController>(
                              tag: model.index.toString(),
                              force: true,
                            );
                          }
                          mainController.postList.removeAt(indexInList);
                          final nextPosition = (indexInList - 1).clamp(
                            0,
                            mainController.postList.length - 1,
                          );
                          mainController.selectedIndex.value = nextPosition;
                        }
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
