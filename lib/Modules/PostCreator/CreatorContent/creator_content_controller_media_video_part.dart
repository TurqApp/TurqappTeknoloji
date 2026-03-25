part of 'creator_content.dart';

extension CreatorContentMediaVideoPart on CreatorContent {
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
                child: _buildMediaLookPreview(
                  controller.videoLookPreset.value,
                  FittedBox(
                    fit: fit,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: VideoPlayer(videoCtrl),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Obx(() {
                  final cover = controller.selectedThumbnail.value;
                  final isPlaying = controller.isPlaying.value;
                  if (isPlaying) return const SizedBox.shrink();
                  if (cover != null) {
                    return _buildMediaLookPreview(
                      controller.videoLookPreset.value,
                      FittedBox(
                        fit: fit,
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: Image.memory(cover, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  }
                  final reusedThumb = controller.reusedVideoThumbnail.value;
                  if (reusedThumb.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _buildMediaLookPreview(
                    controller.videoLookPreset.value,
                    FittedBox(
                      fit: fit,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: CachedNetworkImage(
                          imageUrl: reusedThumb,
                          fit: BoxFit.cover,
                        ),
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
                    child: Text(
                      'post_creator.cover_selected'.tr,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
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

  Widget _buildMediaLookSelector() {
    return Obx(() {
      final presets = kCreatorSupportedVideoLookPresets;
      const spacing = 5.0;
      return Row(
        children: presets.asMap().entries.map((entry) {
          final index = entry.key;
          final preset = entry.value;
          final isSelected = controller.videoLookPreset.value == preset;
          final labelKey = _videoLookLabelKeys[preset] ?? '';
          final label = labelKey.isNotEmpty ? labelKey.tr : preset;
          final icon = _videoLookIcons[preset] ?? CupertinoIcons.circle;
          final shellColors = isSelected
              ? const <Color>[Color(0xFF1C1C1E), Color(0xFF111113)]
              : const <Color>[Color(0xFFFFFFFF), Color(0xFFF6F7F9)];
          final previewColors = isSelected
              ? const <Color>[Color(0xFF2B2B2E), Color(0xFF161618)]
              : const <Color>[Color(0xFFF3F4F6), Color(0xFFE8EBF0)];
          final borderColor =
              isSelected ? const Color(0xFF1C1C1E) : const Color(0xFFE2E5EA);
          final glowColor =
              isSelected ? const Color(0x22000000) : const Color(0x11000000);
          final textColor = isSelected ? Colors.white : const Color(0xFF25282C);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == presets.length - 1 ? 0 : spacing,
              ),
              child: GestureDetector(
                onTap: () => controller.setVideoLookPreset(preset),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: shellColors,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 1.3 : 1,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: glowColor,
                        blurRadius: isSelected ? 22 : 12,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: SizedBox(
                          height: 25,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: previewColors,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  width: preset == 'bright' ? 20 : 14,
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: (isSelected
                                            ? Colors.white
                                            : const Color(0xFFCFD5DD))
                                        .withValues(
                                      alpha: preset == 'bright' ? 0.94 : 0.76,
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  height: 5,
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: <Color>[
                                        (isSelected
                                                ? Colors.white
                                                : const Color(0xFFBFC7D0))
                                            .withValues(alpha: 0.92),
                                        (isSelected
                                                ? Colors.white
                                                : const Color(0xFFBFC7D0))
                                            .withValues(alpha: 0.18),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                              Center(
                                child: Icon(
                                  icon,
                                  size: 10,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 7.6,
                            fontFamily: isSelected
                                ? 'MontserratBold'
                                : 'MontserratSemiBold',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
