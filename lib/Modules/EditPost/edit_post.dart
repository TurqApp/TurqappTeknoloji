// lib/modules/EditPost/edit_post.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/Core/Services/post_caption_limits.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/EditPost/edit_post_controller.dart';

import 'edit_post_model.dart';

part 'edit_post_media_part.dart';
part 'edit_post_toolbar_part.dart';

class EditPost extends StatefulWidget {
  final PostsModel post;

  const EditPost({super.key, required this.post});

  @override
  State<EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  late final EditPostModel model;
  late final EditPostController controller;
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    model = EditPostModel.fromMap(widget.post.toMap(), widget.post.docID);
    _controllerTag = 'edit_post_${widget.post.docID}_${identityHashCode(this)}';
    controller = EditPostController.ensure(
      model: model,
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    final existing = EditPostController.maybeFind(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<EditPostController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return !controller.bekle.value
              ? Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 15, right: 15),
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const AppBackButton(
                                          icon: Icons.arrow_back,
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            controller.setData();
                                          },
                                          child: Text(
                                            'common.save'.tr,
                                            style: TextStyle(
                                              color: Colors.blueAccent,
                                              fontSize: 15,
                                              fontFamily: 'MontserratMedium',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'common.edit'.tr,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontFamily: 'MontserratBold',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 150,
                                    maxHeight: 150,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: controller.text,
                                    maxLength:
                                        PostCaptionLimits.forCurrentUser(),
                                    buildCounter: (
                                      BuildContext context, {
                                      required int currentLength,
                                      required bool isFocused,
                                      required int? maxLength,
                                    }) {
                                      return null;
                                    },
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(
                                        PostCaptionLimits.forCurrentUser(),
                                      ),
                                    ],
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'post_creator.text_hint'.tr,
                                      hintStyle: const TextStyle(
                                        color: Colors.grey,
                                        fontFamily: 'MontserratMedium',
                                        fontSize: 15,
                                      ),
                                      counterText: '',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'MontserratMedium',
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Obx(() {
                                  final address = controller.adres.value;
                                  if (address.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return GestureDetector(
                                    onTap: () {
                                      controller.goToLocationMap();
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.map_pin,
                                            color: Colors.red,
                                          ),
                                          Flexible(
                                            child: Text(
                                              address,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                Obx(() {
                                  return Stack(
                                    children: [
                                      if (controller.waitingVideo.value)
                                        AspectRatio(
                                          aspectRatio: 1,
                                          child: Shimmer.fromColors(
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
                                              child:
                                                  const CupertinoActivityIndicator(
                                                      color: Colors.black),
                                            ),
                                          ),
                                        ),
                                      Obx(() {
                                        final vpc =
                                            controller.rxVideoController.value;
                                        if (vpc == null)
                                          return const SizedBox();

                                        final bool isInit;
                                        final Size videoSize;
                                        final Widget playerWidget;

                                        if (vpc is HLSVideoAdapter) {
                                          isInit = vpc.value.isInitialized;
                                          videoSize = vpc.value.size;
                                          playerWidget = vpc.buildPlayer();
                                        } else if (vpc
                                            is VideoPlayerController) {
                                          isInit = vpc.value.isInitialized;
                                          videoSize = vpc.value.size;
                                          playerWidget = VideoPlayer(vpc);
                                        } else {
                                          return const SizedBox();
                                        }

                                        if (!isInit) return const SizedBox();

                                        return AspectRatio(
                                          aspectRatio: 1,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Stack(
                                              children: [
                                                SizedBox.expand(
                                                  child: FittedBox(
                                                    fit: BoxFit.cover,
                                                    clipBehavior: Clip.hardEdge,
                                                    child: SizedBox(
                                                      width: videoSize.width,
                                                      height: videoSize.height,
                                                      child: playerWidget,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 4,
                                                  right: 4,
                                                  child: Obx(() {
                                                    final playing = controller
                                                        .isPlaying.value;
                                                    return IconButton(
                                                      iconSize: 40,
                                                      color: Colors.white,
                                                      icon: Icon(
                                                        playing
                                                            ? CupertinoIcons
                                                                .pause_circle_fill
                                                            : CupertinoIcons
                                                                .play_circle_fill,
                                                      ),
                                                      onPressed: () {
                                                        if (playing) {
                                                          vpc.pause();
                                                        } else {
                                                          vpc.play();
                                                        }
                                                      },
                                                    );
                                                  }),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: IconButton(
                                                    iconSize: 28,
                                                    color: Colors.white,
                                                    icon: const Icon(
                                                        CupertinoIcons
                                                            .xmark_circle_fill),
                                                    onPressed: () {
                                                      controller.removeVideo();
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                }),
                                Obx(() {
                                  // Eğer yeni seçilmiş resim varsa göster, yoksa kaldır
                                  if (controller.imageUrls.isNotEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: _buildContentFromUrls(
                                            controller.imageUrls),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                                Obx(() {
                                  // Eğer yeni seçilmiş resim varsa göster, yoksa kaldır
                                  if (controller.selectedImages.isNotEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: _buildContentFromFiles(
                                            controller.selectedImages),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    toolbar()
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: CupertinoActivityIndicator(color: Colors.black),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Center(
                      child: Text(
                        'edit_post.updating'.tr,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    )
                  ],
                );
        }),
      ),
    );
  }
}
