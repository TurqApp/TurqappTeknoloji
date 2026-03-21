part of 'creator_content.dart';

const Map<String, String> _videoLookLabelKeys = <String, String>{
  'original': 'post_creator.look.original',
  'clear': 'post_creator.look.clear',
  'cinema': 'post_creator.look.cinema',
  'vibe': 'post_creator.look.vibe',
  'bright': 'post_creator.look.bright',
};

const Map<String, IconData> _videoLookIcons = <String, IconData>{
  'original': CupertinoIcons.circle,
  'clear': CupertinoIcons.sparkles,
  'cinema': CupertinoIcons.film,
  'vibe': CupertinoIcons.sun_max,
  'bright': CupertinoIcons.sun_max_fill,
};

class _LookPalette {
  final List<Color> idleShell;
  final List<Color> activeShell;
  final List<Color> preview;
  final Color borderSoft;
  final Color borderStrong;
  final Color glow;
  final Color text;

  const _LookPalette({
    required this.idleShell,
    required this.activeShell,
    required this.preview,
    required this.borderSoft,
    required this.borderStrong,
    required this.glow,
    required this.text,
  });
}

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
          child: _buildMediaLookPreview(
            controller.videoLookPreset.value,
            _buildImageContentFromMemory(images),
          ),
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
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: presets.map((preset) {
            final isSelected = controller.videoLookPreset.value == preset;
            final labelKey = _videoLookLabelKeys[preset] ?? '';
            final label = labelKey.isNotEmpty ? labelKey.tr : preset;
            final icon = _videoLookIcons[preset] ?? CupertinoIcons.circle;
            final palette = _lookPalette(preset);
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => controller.setVideoLookPreset(preset),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 92,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          isSelected ? palette.activeShell : palette.idleShell,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? palette.borderStrong
                          : palette.borderSoft,
                      width: isSelected ? 1.3 : 1,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color:
                            isSelected ? palette.glow : const Color(0x11000000),
                        blurRadius: isSelected ? 22 : 12,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 42,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: palette.preview,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  width: preset == 'bright' ? 34 : 24,
                                  margin: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha: preset == 'bright' ? 0.94 : 0.76,
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  height: 10,
                                  margin: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: <Color>[
                                        Colors.white.withValues(alpha: 0.92),
                                        Colors.white.withValues(alpha: 0.18),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                              Center(
                                child: Icon(
                                  icon,
                                  size: 16,
                                  color: palette.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 11.5,
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
            );
          }).toList(),
        ),
      );
    });
  }

  _LookPalette _lookPalette(String preset) {
    switch (preset) {
      case 'clear':
        return const _LookPalette(
          idleShell: <Color>[Color(0xFFFFFFFF), Color(0xFFF3FAFF)],
          activeShell: <Color>[Color(0xFFF7FBFF), Color(0xFFEAF5FF)],
          preview: <Color>[Color(0xFFFFFFFF), Color(0xFFD8EEFF)],
          borderSoft: Color(0xFFE0EDF7),
          borderStrong: Color(0xFFB8D7F2),
          glow: Color(0x1A52A7E8),
          text: Color(0xFF1B425E),
        );
      case 'cinema':
        return const _LookPalette(
          idleShell: <Color>[Color(0xFF26262E), Color(0xFF1A1A21)],
          activeShell: <Color>[Color(0xFF1B1B22), Color(0xFF2C2C35)],
          preview: <Color>[Color(0xFF403B2F), Color(0xFF13151C)],
          borderSoft: Color(0xFF3C3D49),
          borderStrong: Color(0xFF4A4A58),
          glow: Color(0x22000000),
          text: Colors.white,
        );
      case 'vibe':
        return const _LookPalette(
          idleShell: <Color>[Color(0xFFFFF7F1), Color(0xFFFFECD9)],
          activeShell: <Color>[Color(0xFFFFF3E7), Color(0xFFFFE2CF)],
          preview: <Color>[Color(0xFFFF8F5A), Color(0xFFFFD76A)],
          borderSoft: Color(0xFFFFD4B4),
          borderStrong: Color(0xFFFFC59A),
          glow: Color(0x22FF8744),
          text: Color(0xFF6E3316),
        );
      case 'bright':
        return const _LookPalette(
          idleShell: <Color>[Color(0xFFF8FEFF), Color(0xFFEEFAFF)],
          activeShell: <Color>[Color(0xFFF4FEFF), Color(0xFFE1F6FF)],
          preview: <Color>[Color(0xFFFFFFFF), Color(0xFFC5F0FF)],
          borderSoft: Color(0xFFCDEEFF),
          borderStrong: Color(0xFF8EDBFF),
          glow: Color(0x2431C8FF),
          text: Color(0xFF0E4660),
        );
      default:
        return const _LookPalette(
          idleShell: <Color>[Color(0xFFFFFFFF), Color(0xFFF8F8F8)],
          activeShell: <Color>[Color(0xFFF3F5F7), Color(0xFFECEFF3)],
          preview: <Color>[Color(0xFFF8F8F8), Color(0xFFE9ECF1)],
          borderSoft: Color(0xFFE8EAED),
          borderStrong: Color(0xFFE2E5E9),
          glow: Color(0x12000000),
          text: Color(0xFF25282C),
        );
    }
  }

  Widget _buildMediaLookPreview(String preset, Widget child) {
    if (preset == 'original') return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.matrix(_lookMatrix(preset)),
          child: child,
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: _lookOverlayGradient(preset),
            ),
          ),
        ),
      ],
    );
  }

  List<double> _lookMatrix(String preset) {
    switch (preset) {
      case 'clear':
        return const <double>[
          1.06,
          0,
          0,
          0,
          8,
          0,
          1.06,
          0,
          0,
          8,
          0,
          0,
          1.08,
          0,
          10,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'cinema':
        return const <double>[
          1.10,
          0,
          0,
          0,
          -10,
          0,
          1.02,
          0,
          0,
          -14,
          0,
          0,
          0.92,
          0,
          -20,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'vibe':
        return const <double>[
          1.08,
          0,
          0,
          0,
          4,
          0,
          1.08,
          0,
          0,
          2,
          0,
          0,
          1.04,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'bright':
        return const <double>[
          1.18,
          0,
          0,
          0,
          22,
          0,
          1.16,
          0,
          0,
          24,
          0,
          0,
          1.24,
          0,
          32,
          0,
          0,
          0,
          1,
          0,
        ];
      default:
        return const <double>[
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
    }
  }

  Gradient _lookOverlayGradient(String preset) {
    switch (preset) {
      case 'clear':
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
            Colors.white.withValues(alpha: 0.06),
          ],
        );
      case 'cinema':
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(alpha: 0.18),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.14),
          ],
        );
      case 'vibe':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0x1AF97316),
            Color(0x00000000),
            Color(0x1406B6D4),
          ],
        );
      case 'bright':
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.24),
            const Color(0x1200C2FF),
            Colors.white.withValues(alpha: 0.10),
          ],
        );
      default:
        return const LinearGradient(
          colors: <Color>[Colors.transparent, Colors.transparent],
        );
    }
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
          child: _buildMediaLookPreview(
            controller.videoLookPreset.value,
            _buildImageContentFromUrls(urls),
          ),
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
