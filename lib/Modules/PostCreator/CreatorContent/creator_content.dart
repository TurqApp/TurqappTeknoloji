import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:video_player/video_player.dart';
import '../post_creator_controller.dart';
import 'creator_content_controller.dart';
import 'post_creator_model.dart';

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
  final user = Get.find<FirebaseMyStore>();
  late final CreatorContentController controller;
  final mainController = Get.find<PostCreatorController>();

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
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sol taraf: profil ve çizgi
                Column(
                  children: [
                    // Profil fotoğrafı
                    ClipOval(
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: user.pfImage.value != ""
                            ? CachedNetworkImage(
                                imageUrl: user.pfImage.value,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: CupertinoActivityIndicator(),
                              ),
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
                          final hasMedia = controller.croppedImages.isNotEmpty ||
                              controller.videoPlayerController != null ||
                              controller.waitingVideo.value;
                          return hasMedia
                              ? const SizedBox.shrink()
                              : buildPollPreview();
                        }),
                        if (controller.croppedImages.isNotEmpty)
                          buildImageGridFromMemory(controller.croppedImages),
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
                                        highlightColor: Colors.grey.shade100,
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
                                            padding: const EdgeInsets.all(8.0),
                                            child: CupertinoActivityIndicator(
                                              color: Colors.black,
                                            ),
                                          ),
                                          Text(
                                            "Video İşleniyor",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium"),
                                          )
                                        ],
                                      ),
                                    ],
                                  ))
                          ],
                        ),
                        Obx(() {
                          final hasMedia = controller.croppedImages.isNotEmpty ||
                              controller.videoPlayerController != null ||
                              controller.waitingVideo.value;
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

  Widget buildPollPreview() {
    return Obx(() {
      final poll = controller.pollData.value;
      if (poll == null || poll.isEmpty) return const SizedBox.shrink();
      final options = (poll['options'] is List) ? poll['options'] as List : [];
      if (options.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(options.length, (i) {
            final text = (options[i]['text'] ?? '').toString();
            final label = '${String.fromCharCode(65 + i)}) ';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '$label$text',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontFamily: "MontserratMedium",
                ),
              ),
            );
          }),
        ),
      );
    });
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

  Widget videoBody() {
    return Obx(() {
      final videoCtrl = controller.videoPlayerController;
      if (!controller.hasVideo.value ||
          videoCtrl == null ||
          !videoCtrl.value.isInitialized) {
        return const SizedBox.shrink();
      }

      final videoValue = videoCtrl.value;
      final width = videoValue.size.width;
      final height = videoValue.size.height;

      double originalAspect = width / height;
      double aspectRatio = originalAspect;
      BoxFit fit = BoxFit.contain;

      if (originalAspect < 0.75) {
        aspectRatio = 1;
        fit = BoxFit.cover;
      } else if (originalAspect < 1) {
        aspectRatio = 3 / 4;
        fit = BoxFit.cover;
      } else if (originalAspect == 1) {
        aspectRatio = 1;
        fit = BoxFit.cover;
      }

      return AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: FittedBox(
                  fit: fit,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: VideoPlayer(videoCtrl),
                  ),
                ),
              ),
              // Show chosen cover frame over the video when not playing
              Positioned.fill(
                child: Obx(() {
                  final cover = controller.selectedThumbnail.value;
                  final isPlaying = controller.isPlaying.value;
                  if (cover == null || isPlaying) return const SizedBox.shrink();
                  return FittedBox(
                    fit: fit,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Image.memory(cover, fit: BoxFit.cover),
                    ),
                  );
                }),
              ),
              // Show a small badge if a custom thumbnail is selected
              Positioned(
                top: 8,
                left: 8,
                child: Obx(() {
                  if (controller.selectedThumbnail.value == null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(120),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Kapak seçildi',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  );
                }),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () async {
                    if (controller.videoPlayerController == null) return;

                    if (controller.videoPlayerController!.value.isPlaying) {
                      await controller.pauseVideo();
                    } else {
                      await controller.playVideo();
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(80),
                      shape: BoxShape.circle,
                    ),
                    child: Obx(() => Icon(
                          controller.isPlaying.value
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          color: Colors.white,
                          size: 18,
                        )),
                  ),
                ),
              ),
              // Cover select button
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    await controller.openThumbnailPicker();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(80),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.photo, color: Colors.white, size: 18),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    await videoCtrl.pause();
                    await videoCtrl.dispose();
                    controller.rxVideoPlayerController.value = null;
                    controller.selectedVideo.value = null;
                    controller.isPlaying.value = false;
                    controller.hasVideo.value = false;
                    controller.hasVideo.refresh();
                    controller.selectedThumbnail.value = null; // clear custom cover
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(80),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.xmark,
                        color: Colors.white, size: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildImageGridFromMemory(List<Uint8List?> images) {
    images = images.where((e) => e != null).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    final outerRadius = BorderRadius.circular(12);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: outerRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildImageContentFromMemory(images),
        ),

        // Sağ üst köşedeki çarpı butonu
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              // Görselleri temizle
              final tag = Get.find<PostCreatorController>()
                  .selectedIndex
                  .value
                  .toString();
              final controller = Get.find<CreatorContentController>(tag: tag);
              controller.selectedImages.clear();
              controller.croppedImages.clear();
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContentFromMemory(List<Uint8List?> images) {
    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: 1,
          child:
              _buildMemoryImage(images[0]!, radius: BorderRadius.circular(12)),
        );

      case 2:
        return Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 1),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildMemoryImage(
                    images[0]!,
                    radius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 1),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildMemoryImage(
                    images[1]!,
                    radius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case 3:
        return AspectRatio(
          aspectRatio: 1,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 1),
                  child: _buildMemoryImage(
                    images[0]!,
                    radius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: _buildMemoryImage(
                          images[1]!,
                          radius: const BorderRadius.only(
                              topRight: Radius.circular(12)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: _buildMemoryImage(
                          images[2]!,
                          radius: const BorderRadius.only(
                              bottomRight: Radius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 4:
      default:
        return buildFourImageGridFromMemory(images);
    }
  }

  Widget buildFourImageGridFromMemory(List<Uint8List?> images) {
    return Column(
      children: [
        Row(
          children: List.generate(2, (index) {
            final img = images[index];
            return Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: _getRadius(index),
                    child: Image.memory(img!, fit: BoxFit.cover),
                  ),
                ),
              ),
            );
          }),
        ),
        Row(
          children: List.generate(2, (index) {
            final img = images[index + 2];
            return Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: _getRadius(index + 2),
                    child: Image.memory(img!, fit: BoxFit.cover),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMemoryImage(Uint8List data, {required BorderRadius radius}) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: Image.memory(
          data,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  BorderRadius _getRadius(int index) {
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
