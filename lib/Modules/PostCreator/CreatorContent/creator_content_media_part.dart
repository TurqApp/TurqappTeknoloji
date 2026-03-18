part of 'creator_content.dart';

extension CreatorContentMediaPart on CreatorContent {
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
              Positioned.fill(
                child: Obx(() {
                  final cover = controller.selectedThumbnail.value;
                  final isPlaying = controller.isPlaying.value;
                  if (isPlaying) return const SizedBox.shrink();
                  if (cover != null) {
                    return FittedBox(
                      fit: fit,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: Image.memory(cover, fit: BoxFit.cover),
                      ),
                    );
                  }
                  final reusedThumb = controller.reusedVideoThumbnail.value;
                  if (reusedThumb.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return FittedBox(
                    fit: fit,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: CachedNetworkImage(
                        imageUrl: reusedThumb,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Obx(() {
                  if (controller.selectedThumbnail.value == null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    child: const Icon(
                      CupertinoIcons.photo,
                      color: Colors.white,
                      size: 18,
                    ),
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
                    controller.reusedVideoUrl.value = '';
                    controller.reusedVideoThumbnail.value = '';
                    controller.reusedVideoAspectRatio.value = 0.0;
                    controller.reusedImageUrls.clear();
                    controller.videoLookPreset.value = 'original';
                    controller.isPlaying.value = false;
                    controller.hasVideo.value = false;
                    controller.hasVideo.refresh();
                    controller.selectedThumbnail.value = null;
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(80),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 15,
                    ),
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
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              controller.selectedImages.clear();
              controller.croppedImages.clear();
              controller.reusedImageUrls.clear();
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

  Widget _buildMediaLookSelector() {
    return Obx(() {
      final presets = CreatorContentController.supportedVideoLookPresets;
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EC)),
        ),
        child: Row(
          children: [
            ...presets.asMap().entries.map((entry) {
              final index = entry.key;
              final preset = entry.value;
              final isSelected = controller.videoLookPreset.value == preset;
              final label = CreatorContent._videoLookLabels[preset] ?? preset;
              final icon = CreatorContent._videoLookIcons[preset] ??
                  CupertinoIcons.circle;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == presets.length - 1 ? 0 : 8,
                  ),
                  child: GestureDetector(
                    onTap: () => controller.setVideoLookPreset(preset),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? Colors.black
                              : const Color(0xFFE2E5EA),
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4B5563),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                                fontSize: 12,
                                fontFamily: isSelected
                                    ? "MontserratBold"
                                    : "MontserratMedium",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildImageContentFromMemory(List<Uint8List?> images) {
    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: _singleImagePreviewAspect,
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
                            topRight: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: _buildMemoryImage(
                          images[2]!,
                          radius: const BorderRadius.only(
                            bottomRight: Radius.circular(12),
                          ),
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

  Widget buildImageGridFromUrls(List<String> imageUrls) {
    final urls =
        imageUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    final outerRadius = BorderRadius.circular(12);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: outerRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildImageContentFromUrls(urls),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              controller.reusedImageUrls.clear();
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

  Widget _buildImageContentFromUrls(List<String> images) {
    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: _singleImagePreviewAspect,
          child: _buildNetworkImage(
            images[0],
            radius: BorderRadius.circular(12),
          ),
        );
      case 2:
        return Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 1),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildNetworkImage(
                    images[0],
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
                  child: _buildNetworkImage(
                    images[1],
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
                  child: _buildNetworkImage(
                    images[0],
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
                        child: _buildNetworkImage(
                          images[1],
                          radius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: _buildNetworkImage(
                          images[2],
                          radius: const BorderRadius.only(
                            bottomRight: Radius.circular(12),
                          ),
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
                        child:
                            _buildNetworkImage(img, radius: BorderRadius.zero),
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
                        child:
                            _buildNetworkImage(img, radius: BorderRadius.zero),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
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

  Widget _buildNetworkImage(String imageUrl, {required BorderRadius radius}) {
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(color: Colors.grey[200]),
        errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
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
