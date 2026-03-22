part of 'creator_content_controller.dart';

extension CreatorContentControllerVideoPart on CreatorContentController {
  Future<void> _performOpenThumbnailPicker() async {
    final vfile = selectedVideo.value;
    if (vfile == null) return;
    final ctx = Get.context;
    if (ctx == null) return;

    final duration = videoPlayerController?.value.duration ?? Duration.zero;
    final totalMs = duration.inMilliseconds.clamp(0, 60 * 60 * 1000);
    final RxDouble slider = ((totalMs / 3).toDouble()).obs;
    final Rx<Uint8List?> preview = Rx<Uint8List?>(null);
    final RxBool loading = true.obs;
    final int totalSec = ((totalMs / 1000).floor()).clamp(0, 3600);
    final int frameCount = (totalSec + 1).clamp(1, 3601);
    final List<int> stripTimes =
        List.generate(frameCount, (i) => (i * 1000).clamp(0, totalMs));
    final RxList<Uint8List?> stripThumbs =
        List<Uint8List?>.filled(frameCount, null).obs;
    final Map<int, bool> stripLoading = {};
    Timer? debounce;

    Future<void> generate(int timeMs) async {
      loading.value = true;
      try {
        final data = await vt.VideoThumbnail.thumbnailData(
          video: vfile.path,
          imageFormat: vt.ImageFormat.JPEG,
          timeMs: timeMs,
          maxWidth: 512,
          quality: 80,
        );
        preview.value = data;
      } catch (_) {
        preview.value = null;
      } finally {
        loading.value = false;
      }
    }

    await generate(slider.value.toInt());
    Timer? holdTimerLeft;
    Timer? holdTimerRight;

    Future<void> ensureStripThumb(int idx) async {
      if (idx < 0 || idx >= frameCount) return;
      if (stripThumbs[idx] != null || stripLoading[idx] == true) return;
      stripLoading[idx] = true;
      try {
        final data = await vt.VideoThumbnail.thumbnailData(
          video: vfile.path,
          imageFormat: vt.ImageFormat.JPEG,
          timeMs: stripTimes[idx],
          maxWidth: 160,
          quality: 70,
        );
        stripThumbs[idx] = data;
        stripThumbs.refresh();
      } catch (_) {
      } finally {
        stripLoading[idx] = false;
      }
    }

    void jumpToTimeMs(int timeMs) {
      final t = timeMs.clamp(0, totalMs);
      slider.value = t.toDouble();
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 120), () async {
        await generate(slider.value.toInt());
      });
      HapticFeedback.selectionClick();
    }

    await Get.bottomSheet(
      SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Obx(() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                12.ph,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                endIndent: 8,
                                color: Colors.grey,
                              )),
                              Text('post_creator.cover_title'.tr,
                                  style: TextStyles.bold16Black),
                              Expanded(
                                  child: Divider(
                                indent: 8,
                                color: Colors.grey,
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (preview.value != null)
                          Image.memory(
                            preview.value!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        if (loading.value)
                          const Center(child: CupertinoActivityIndicator()),
                        Positioned(
                          left: 8,
                          child: GestureDetector(
                            onTap: () {
                              final curSec = (slider.value / 1000).round();
                              final t = ((curSec - 1) * 1000).clamp(0, totalMs);
                              jumpToTimeMs(t.toInt());
                            },
                            onLongPressStart: (_) {
                              holdTimerLeft?.cancel();
                              holdTimerLeft = Timer.periodic(
                                const Duration(milliseconds: 120),
                                (timer) {
                                  if (Get.isDialogOpen != true &&
                                      Get.isOverlaysOpen != true) {
                                    final curSec =
                                        (slider.value / 1000).round();
                                    if (curSec <= 0) {
                                      holdTimerLeft?.cancel();
                                      return;
                                    }
                                    final t =
                                        ((curSec - 1) * 1000).clamp(0, totalMs);
                                    jumpToTimeMs(t.toInt());
                                  }
                                },
                              );
                            },
                            onLongPressEnd: (_) {
                              holdTimerLeft?.cancel();
                            },
                            onLongPressUp: () {
                              holdTimerLeft?.cancel();
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.chevron_left,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              final curSec = (slider.value / 1000).round();
                              final t = ((curSec + 1) * 1000).clamp(0, totalMs);
                              jumpToTimeMs(t.toInt());
                            },
                            onLongPressStart: (_) {
                              holdTimerRight?.cancel();
                              holdTimerRight = Timer.periodic(
                                const Duration(milliseconds: 120),
                                (timer) {
                                  final curSec = (slider.value / 1000).round();
                                  if (curSec >= totalSec) {
                                    holdTimerRight?.cancel();
                                    return;
                                  }
                                  final t =
                                      ((curSec + 1) * 1000).clamp(0, totalMs);
                                  jumpToTimeMs(t.toInt());
                                },
                              );
                            },
                            onLongPressEnd: (_) {
                              holdTimerRight?.cancel();
                            },
                            onLongPressUp: () {
                              holdTimerRight?.cancel();
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.chevron_right,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                LayoutBuilder(builder: (context, constraints) {
                  final viewportW = constraints.maxWidth;
                  final double tileW = viewportW / frameCount;
                  for (int i = 0; i < frameCount; i++) {
                    ensureStripThumb(i);
                  }
                  int dxToIndex(Offset local) {
                    final dx = local.dx.clamp(0.0, viewportW);
                    final idx = (dx / tileW).floor();
                    return idx.clamp(0, frameCount - 1);
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPressStart: (d) {
                      final idx = dxToIndex(d.localPosition);
                      jumpToTimeMs(stripTimes[idx]);
                    },
                    onLongPressMoveUpdate: (d) {
                      final idx = dxToIndex(d.localPosition);
                      jumpToTimeMs(stripTimes[idx]);
                    },
                    child: Row(
                      children: List.generate(frameCount, (i) {
                        return Expanded(
                          child: Obx(() {
                            final img = stripThumbs[i];
                            final selIdx = (totalMs == 0)
                                ? 0
                                : ((slider.value / totalMs) * (frameCount - 1))
                                    .round()
                                    .clamp(0, frameCount - 1);
                            final isSel = selIdx == i;
                            return GestureDetector(
                              onTap: () => jumpToTimeMs(stripTimes[i]),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                height: 74,
                                margin: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  border: Border.all(
                                    color: isSel
                                        ? AppColors.primaryColor
                                        : Colors.transparent,
                                    width: isSel ? 3 : 0,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primaryColor
                                                .withValues(alpha: 0.40),
                                            blurRadius: 10,
                                            spreadRadius: 0.8,
                                          ),
                                        ]
                                      : [],
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: img == null
                                    ? const Center(
                                        child: CupertinoActivityIndicator())
                                    : Image.memory(img, fit: BoxFit.cover),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                              color: Colors.black.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Get.back();
                        },
                        label: Text(
                          'common.cancel'.tr,
                          style: TextStyles.medium15Black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: preview.value == null
                            ? null
                            : () {
                                selectedThumbnail.value = preview.value;
                                HapticFeedback.lightImpact();
                                Get.back();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryColor,
                                AppColors.secondColor
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text('common.save'.tr,
                              style: TextStyles.medium15white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _performListenVideo() {
    videoPlayerController?.addListener(() {
      final controller = videoPlayerController!;
      final isNowPlaying = controller.value.isPlaying;
      final isEnded = controller.value.position >= controller.value.duration;

      if (isPlaying.value != isNowPlaying) {
        isPlaying.value = isNowPlaying;
      }

      if (isEnded && isPlaying.value) {
        isPlaying.value = false;
        controller.pause();
      }
    });
  }

  Future<void> _performPlayVideo() async {
    if (videoPlayerController != null && !isPlaying.value) {
      await AudioFocusCoordinator.instance.requestPreviewPlay(
        videoPlayerController!,
      );
      await videoPlayerController!.play();
      isPlaying.value = true;
    }
  }

  Future<void> _performPauseVideo() async {
    if (videoPlayerController != null && isPlaying.value) {
      await videoPlayerController!.pause();
      isPlaying.value = false;
    }
  }

  Future<void> _performForcePauseVideo() async {
    final controller = videoPlayerController;
    if (controller == null) return;
    await controller.pause();
    isPlaying.value = false;
  }

  Future<void> _performTogglePlayPause() async {
    isPlaying.value ? await pauseVideo() : await playVideo();
  }

  void _performBindVideoController(VideoPlayerController controller) {
    AudioFocusCoordinator.instance.registerPreviewPlayer(controller);
    rxVideoPlayerController.value = controller;
  }

  Future<void> _performReleaseVideoController() async {
    final controller = rxVideoPlayerController.value;
    if (controller == null) return;
    AudioFocusCoordinator.instance.unregisterPreviewPlayer(controller);
    await controller.pause();
    await controller.dispose();
    rxVideoPlayerController.value = null;
  }

  Future<void> _performResetComposerState() async {
    textEdit.clear();
    selectedImages.clear();
    selectedVideo.value = null;
    croppedImages.clear();
    reusedImageUrls.clear();
    reusedImageAspectRatio.value = 0.0;
    reusedVideoUrl.value = '';
    reusedVideoThumbnail.value = '';
    reusedVideoAspectRatio.value = 0.0;
    videoLookPreset.value = 'original';
    selectedThumbnail.value = null;
    pollData.value = null;
    adres.value = '';
    gif.value = '';
    isCropping.value = false;
    isPlaying.value = false;
    hasVideo.value = false;
    isProcessing.value = false;
    isFocusedOnce.value = false;
    contentNotEmpty.value = false;
    textChanged.value = false;
    waitingVideo.value = false;
    await _releaseVideoController();
  }
}
