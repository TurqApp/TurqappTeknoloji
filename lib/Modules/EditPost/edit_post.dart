// lib/modules/EditPost/edit_post.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/EditPost/edit_post_controller.dart';

import 'edit_post_model.dart';

class EditPost extends StatelessWidget {
  final PostsModel post;
  final EditPostModel model;
  final EditPostController controller;

  EditPost({super.key, required this.post})
      : model = EditPostModel.fromMap(post.toMap(), post.docID),
        controller = Get.put(
          EditPostController(
            model: EditPostModel.fromMap(post.toMap(), post.docID),
          ),
          tag: post.docID,
        );

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
                                    maxLength: 1000,
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

  Widget toolbar() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (controller.videoUrl.value == "")
                      PullDownButton(
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            onTap: () {
                              controller.pickImageCamera(
                                  source: ImageSource.camera);
                            },
                            title: 'profile_photo.camera'.tr,
                            icon: CupertinoIcons.camera,
                          ),
                          PullDownMenuItem(
                            onTap: () {
                              controller.pickImageGallery();
                            },
                            title: 'profile_photo.gallery'.tr,
                            icon: CupertinoIcons.photo,
                          ),
                        ],
                        buttonBuilder: (context, showMenu) => CupertinoButton(
                          onPressed: showMenu,
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.photo_on_rectangle,
                            color: Colors.black,
                            size: 25,
                          ),
                        ),
                      ),
                    if (controller.videoUrl.value == "" &&
                        controller.rxVideoController.value == null)
                      PullDownButton(
                        itemBuilder: (context) => [
                          PullDownMenuItem(
                            onTap: () {
                              controller.pickVideo(source: ImageSource.camera);
                            },
                            title: 'profile_photo.camera'.tr,
                            icon: CupertinoIcons.camera,
                          ),
                          PullDownMenuItem(
                            onTap: () {
                              controller.pickVideo(source: ImageSource.gallery);
                            },
                            title: 'profile_photo.gallery'.tr,
                            icon: CupertinoIcons.photo,
                          ),
                        ],
                        buttonBuilder: (context, showMenu) => CupertinoButton(
                          onPressed: showMenu,
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.play_circle,
                            color: Colors.black,
                            size: 25,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: controller.goToLocationMap,
                      icon: const Icon(
                        CupertinoIcons.map_pin_ellipse,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: controller.showCommentOptions,
                      icon: const Icon(
                        CupertinoIcons.ellipses_bubble,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildImageGrid() {
    // Önce URL'lere bak
    if (controller.imageUrls.isNotEmpty) {
      return _buildGridFromUrls(controller.imageUrls);
    }
    // Yoksa File listesinden
    if (controller.selectedImages.isNotEmpty) {
      return _buildGridFromFiles(controller.selectedImages);
    }
    return const SizedBox.shrink();
  }

  Widget _buildGridFromUrls(List<String> urls) {
    final outerRadius = BorderRadius.circular(12);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: outerRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContentFromUrls(urls),
    );
  }

  Widget _buildContentFromUrls(List<String> urls) {
    switch (urls.length) {
      case 1:
        return AspectRatio(
          aspectRatio: 1,
          child: _buildUrlTile(urls, 0, BorderRadius.circular(12)),
        );
      case 2:
        return _buildTwoUrlGrid(urls);
      case 3:
        return _buildThreeUrlGrid(urls);
      default:
        return _buildFourUrlGrid(urls);
    }
  }

  Widget _buildTwoUrlGrid(List<String> urls) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size, // 1:1 kare
          child: Row(
            children: [
              Expanded(
                child: _buildUrlTile(
                  urls,
                  0,
                  const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                child: _buildUrlTile(
                  urls,
                  1,
                  const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThreeUrlGrid(List<String> urls) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size, // Kare yapı
          child: Row(
            children: [
              // Sol büyük kare
              Expanded(
                flex: 1,
                child: _buildUrlTile(
                  urls,
                  0,
                  const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              // Sağda iki küçük kare
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildUrlTile(
                        urls,
                        1,
                        const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Expanded(
                      child: _buildUrlTile(
                        urls,
                        2,
                        const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFourUrlGrid(List<String> urls) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: min(urls.length, 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemBuilder: (context, index) {
        final radius = _getGridRadius(index);
        return _buildUrlTile(urls, index, radius);
      },
    );
  }

  Widget _buildUrlTile(List<String> urls, int index, BorderRadius radius) {
    final url = urls[index];
    return Stack(
      children: [
        // Ağ görseli
        ClipRRect(
          borderRadius: radius,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => const CupertinoActivityIndicator(),
          ),
        ),
        // Silme butonu
        Positioned(
          top: 4,
          left: 4,
          child: GestureDetector(
            onTap: () => controller.removeImageUrl(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration:
                  BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.xmark_circle_fill,
                  size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridFromFiles(List<File> files) {
    final outerRadius = BorderRadius.circular(12);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: outerRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContentFromFiles(files),
    );
  }

  Widget _buildContentFromFiles(List<File> files) {
    switch (files.length) {
      case 1:
        return AspectRatio(
          aspectRatio: 1,
          child: _buildFileTile(files, 0, BorderRadius.circular(12)),
        );
      case 2:
        return _buildTwoFileGrid(files);
      case 3:
        return _buildThreeFileGrid(files);
      default:
        return _buildFourFileGrid(files);
    }
  }

  Widget _buildTwoFileGrid(List<File> files) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size, // kare (1:1)
          child: Row(
            children: [
              Expanded(
                child: _buildFileTile(
                  files,
                  0,
                  const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                child: _buildFileTile(
                  files,
                  1,
                  const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThreeFileGrid(List<File> files) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size, // kare
          child: Row(
            children: [
              // Sol büyük kare
              Expanded(
                flex: 1,
                child: _buildFileTile(
                  files,
                  0,
                  const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              // Sağdaki iki küçük kare
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildFileTile(
                        files,
                        1,
                        const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Expanded(
                      child: _buildFileTile(
                        files,
                        2,
                        const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFourFileGrid(List<File> files) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: min(files.length, 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemBuilder: (context, index) {
        final radius = _getGridRadius(index);
        return _buildFileTile(files, index, radius);
      },
    );
  }

  Widget _buildFileTile(List<File> files, int index, BorderRadius radius) {
    final file = files[index];
    return Stack(
      children: [
        ClipRRect(
          borderRadius: radius,
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: GestureDetector(
            onTap: () => controller.removeSelectedImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration:
                  BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.xmark_circle_fill,
                  size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  BorderRadius _getGridRadius(int index) {
    switch (index) {
      case 0:
        return const BorderRadius.only(topLeft: Radius.circular(12));
      case 1:
        return const BorderRadius.only(topRight: Radius.circular(12));
      case 2:
        return const BorderRadius.only(bottomLeft: Radius.circular(12));
      case 3:
        return const BorderRadius.only(bottomRight: Radius.circular(12));
      default:
        return BorderRadius.zero;
    }
  }
}
