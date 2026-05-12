part of 'story_maker_controller.dart';

extension StoryMakerControllerMediaPart on StoryMakerController {
  Future<void> _resumeSelectedMusicPreview() async {
    try {
      if (_audioPlayer.state == PlayerState.disposed ||
          selectedMusic.value == null ||
          music.value.trim().isEmpty) {
        return;
      }
      await AudioFocusCoordinator.instance.requestAudioPlayerPlay(_audioPlayer);
      await _audioPlayer.resume();
      isMusicPlaying.value = true;
    } catch (e) {
      debugPrint("resumeSelectedMusicPreview error: $e");
      isMusicPlaying.value = false;
    }
  }

  void applySharedPostSeedIfNeeded({
    required String mediaUrl,
    required bool isVideo,
    required double aspectRatio,
    required String sourceUserId,
    required String sourceDisplayName,
  }) {
    final cleanMediaUrl = mediaUrl.trim();
    final cleanSourceUserId = sourceUserId.trim();
    final cleanSourceDisplayName = sourceDisplayName.trim();
    if (cleanMediaUrl.isEmpty) return;

    final fingerprint = [
      cleanMediaUrl,
      isVideo,
      aspectRatio.toStringAsFixed(6),
      cleanSourceUserId,
      cleanSourceDisplayName,
    ].join('::');
    if (_sharedPostSeedFingerprint == fingerprint) return;
    _sharedPostSeedFingerprint = fingerprint;

    elements.clear();
    color.value = Colors.transparent;
    music.value = '';
    selectedMusic.value = null;
    _zIndexCounter = 0;
    _history.clear();
    _historyIndex = -1;
    canUndo.value = false;
    canRedo.value = false;

    final placement = _computeBackgroundPlacement(aspectRatio);
    elements.add(
      StoryElement(
        type: isVideo ? StoryElementType.video : StoryElementType.image,
        content: cleanMediaUrl,
        width: placement.width,
        height: placement.height,
        position: placement.position,
        rotation: 0,
        zIndex: ++_zIndexCounter,
        isMuted: false,
        aspectRatio: placement.width / placement.height,
        mediaLookPreset: 'original',
      ),
    );

    if (cleanSourceUserId.isNotEmpty && cleanSourceDisplayName.isNotEmpty) {
      _addSourceProfileBadge(
        userId: cleanSourceUserId,
        displayName: cleanSourceDisplayName,
      );
    }

    _normalizeLayerOrdering();
    elements.refresh();
    _saveState();
  }

  ({double width, double height, Offset position}) _computeBackgroundPlacement(
    double rawAspectRatio,
  ) {
    final safeAspectRatio = rawAspectRatio.isFinite && rawAspectRatio > 0
        ? rawAspectRatio
        : (9 / 16);
    final screenW = Get.width;
    final playgroundHeight = _availablePlaygroundHeight();
    final screenAspectRatio = screenW / playgroundHeight;

    double width;
    double height;
    if (safeAspectRatio > screenAspectRatio) {
      width = screenW;
      height = width / safeAspectRatio;
    } else {
      height = playgroundHeight;
      width = height * safeAspectRatio;
    }

    final dx = (screenW - width) / 2;
    final dy = (playgroundHeight - height) / 2;
    return (width: width, height: height, position: Offset(dx, dy));
  }

  void _addSourceProfileBadge({
    required String userId,
    required String displayName,
  }) {
    const height = 36.0;
    final width = (Get.width * 0.62).clamp(170.0, 260.0).toDouble();
    final playgroundHeight = _availablePlaygroundHeight();

    elements.add(
      StoryElement(
        type: StoryElementType.sticker,
        content: 'Kimden: $displayName',
        width: width,
        height: height,
        position: Offset(14, playgroundHeight - height - 14),
        rotation: 0,
        zIndex: ++_zIndexCounter,
        aspectRatio: width / height,
        stickerType: 'source_profile',
        stickerData: userId,
        textColor: 0xFFFFFFFF,
        textBgColor: 0x5C000000,
        hasTextBg: true,
        textAlign: 'left',
        fontSize: 14,
        fontFamily: 'MontserratMedium',
        mediaLookPreset: 'original',
      ),
    );
  }

  Future<void> pickImage() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final file = await AppImagePickerService.pickSingleImage(ctx);
    if (file == null) return;
    final nsfw = await OptimizedNSFWService.checkImage(file);
    if (nsfw.errorMessage != null) {
      AppSnackbar(
        'common.error'.tr,
        'tests.nsfw_check_failed'.tr,
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      return;
    }
    if (nsfw.isNSFW) {
      AppSnackbar(
        'post_creator.upload_failed_title'.tr,
        'post_creator.upload_failed_body'.tr,
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      return;
    }

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final imgW = frame.image.width.toDouble();
    final imgH = frame.image.height.toDouble();

    final screenW = Get.width;
    final screenH = Get.height;

    final imgAspectRatio = imgW / imgH;
    final screenAspectRatio = screenW / screenH;

    double width;
    double height;
    if (imgAspectRatio > screenAspectRatio) {
      width = screenW;
      height = width / imgAspectRatio;
    } else {
      height = screenH;
      width = height * imgAspectRatio;
    }

    final dx = (screenW - width) / 2;
    final playgroundHeight = _availablePlaygroundHeight();
    final dy = (playgroundHeight - height) / 2;

    elements.add(
      StoryElement(
        type: StoryElementType.image,
        content: file.path,
        width: width,
        height: height,
        position: Offset(dx, dy),
        rotation: 0,
        zIndex: ++_zIndexCounter,
        aspectRatio: double.parse((imgW / imgH).toStringAsFixed(4)),
        mediaLookPreset: 'original',
      ),
    );

    _normalizeLayerOrdering();
    _saveState();
  }

  Future<void> pickVideo() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final picked = await AppImagePickerService.pickSingleVideo(ctx);
    if (picked == null) return;

    final videoFile = File(picked.path);
    final tempController = VideoPlayerController.file(videoFile);
    try {
      await tempController.initialize();
    } catch (e) {
      await tempController.dispose();
      UploadValidationService.showValidationError(
        'upload_validation.video_analysis_failed'.trParams({'error': '$e'}),
      );
      return;
    }
    final videoSize = tempController.value.size;
    final durationSeconds = tempController.value.duration.inSeconds;

    final screenW = Get.width;
    final screenH = Get.height;
    final videoAspectRatio = videoSize.width / videoSize.height;
    final screenAspectRatio = screenW / screenH;

    double width;
    double height;
    if (videoAspectRatio > screenAspectRatio) {
      width = screenW;
      height = width / videoAspectRatio;
    } else {
      height = screenH;
      width = height * videoAspectRatio;
    }

    final dx = (screenW - width) / 2;
    final playgroundHeight = _availablePlaygroundHeight();
    final dy = (playgroundHeight - height) / 2;

    await tempController.dispose();

    final aspectRatio = double.parse(videoAspectRatio.toStringAsFixed(4));
    final element = StoryElement(
      type: StoryElementType.video,
      content: videoFile.path,
      width: width,
      height: height,
      position: Offset(dx, dy),
      rotation: 0,
      zIndex: ++_zIndexCounter,
      isMuted: false,
      aspectRatio: aspectRatio,
      mediaLookPreset: 'original',
      videoDurationSeconds: durationSeconds,
      videoTrimStartSeconds: 0,
    );
    elements.removeWhere((e) => e.type == StoryElementType.video);
    elements.add(element);

    _normalizeLayerOrdering();
    _saveState();

    debugPrint(
      '[StoryMakerVideoPick] visual_ready '
      'path=${videoFile.path.split('/').last} '
      'mode=direct_video '
      'duration=${durationSeconds}s '
      'aspect=${aspectRatio.toStringAsFixed(4)}',
    );

    final nsfwVideo = await OptimizedNSFWService.checkVideo(videoFile);
    if (nsfwVideo.isNSFW) {
      elements.removeWhere((e) => e.id == element.id);
      elements.refresh();
      _saveState();
      AppSnackbar(
        'post_creator.upload_failed_title'.tr,
        'post_creator.upload_failed_body'.tr,
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
    }
  }

  bool _isStoryVideoSizeValid(int fileSize) {
    return fileSize <= UploadConstants.maxStoryVideoSizeBytes;
  }

  void _showStoryVideoSizeError(int fileSize) {
    AppSnackbar(
      'common.error'.tr,
      'upload_validation.video_size_too_large'.trParams({
        'max': UploadConstants.formatBytes(
          UploadConstants.maxStoryVideoSizeBytes,
        ),
        'current': UploadConstants.formatBytes(fileSize),
      }),
      backgroundColor: Colors.red.withValues(alpha: 0.7),
    );
  }

  bool _isStoryVideoDurationValid(Map<String, dynamic>? metadata) {
    final duration = metadata?['duration'];
    final durationSeconds = duration is num ? duration.toInt() : 0;
    return durationSeconds <= UploadConstants.maxStoryVideoLengthSeconds;
  }

  void _showStoryVideoDurationError(Map<String, dynamic>? metadata) {
    final duration = metadata?['duration'];
    final durationSeconds = duration is num ? duration.toInt() : 0;
    AppSnackbar(
      'common.error'.tr,
      'upload_validation.video_duration_too_long'.trParams({
        'max': '${UploadConstants.maxStoryVideoLengthSeconds}',
        'current': '$durationSeconds',
      }),
      backgroundColor: Colors.red.withValues(alpha: 0.7),
    );
  }

  Future<String> _generateStoryVideoPosterPath(File videoFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = await vt.VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 720,
        quality: 82,
      );
      return path?.trim() ?? '';
    } catch (e) {
      debugPrint('[StoryMakerVideoPoster] failed: $e');
      return '';
    }
  }

  Future<File> _prepareStoryVideoForPublish(
    File videoFile, {
    int trimStartSeconds = 0,
  }) async {
    var output = await _trimStoryVideoToLimitIfNeeded(
      videoFile,
      startSeconds: trimStartSeconds,
    );
    output = await _compressStoryVideoToSizeIfNeeded(output);
    return output;
  }

  Future<File> _trimStoryVideoToLimitIfNeeded(
    File videoFile, {
    int startSeconds = 0,
  }) async {
    final playerDurationSeconds =
        await _readStoryVideoDurationSeconds(videoFile);
    final nativeDurationSeconds =
        await _readStoryVideoNativeDurationSeconds(videoFile);
    final durationSeconds = nativeDurationSeconds > 0
        ? nativeDurationSeconds
        : playerDurationSeconds;
    final maxSeconds = UploadConstants.maxStoryVideoLengthSeconds;
    final maxStart = max(0, durationSeconds - maxSeconds);
    final safeStart = startSeconds.clamp(0, maxStart).toInt();
    if (durationSeconds <= 0 ||
        (durationSeconds <= maxSeconds && safeStart == 0)) {
      return videoFile;
    }
    final trimDuration = min(maxSeconds, durationSeconds - safeStart);
    if (trimDuration <= 0) return videoFile;
    final trimEndSeconds = max(0, durationSeconds - safeStart - trimDuration);

    try {
      debugPrint(
        '[StoryMakerVideoTrim] start path=${videoFile.path.split('/').last} '
        'duration=${durationSeconds}s player=${playerDurationSeconds}s '
        'native=${nativeDurationSeconds}s requestedStart=${startSeconds}s '
        'start=${safeStart}s '
        'target=${trimDuration}s trimEnd=${trimEndSeconds}s max=${maxSeconds}s',
      );
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false,
        startTime: safeStart,
        duration: trimEndSeconds,
        includeAudio: true,
      );
      final outputPath = (info?.path ?? '').trim();
      if (outputPath.isEmpty) return videoFile;
      final outputFile = File(outputPath);
      if (!outputFile.existsSync()) return videoFile;

      final trimmedDurationSeconds =
          await _readStoryVideoDurationSeconds(outputFile);
      debugPrint(
        '[StoryMakerVideoTrim] done '
        'duration=${trimmedDurationSeconds}s '
        'size=${UploadConstants.formatBytes(await outputFile.length())}',
      );
      return outputFile;
    } catch (e) {
      debugPrint('[StoryMakerVideoTrim] failed: $e');
      return videoFile;
    }
  }

  Future<int> _readStoryVideoNativeDurationSeconds(File videoFile) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      final durationMs = info.duration ?? 0;
      if (durationMs <= 0) return 0;
      return max(1, (durationMs / 1000).floor());
    } catch (e) {
      debugPrint('[StoryMakerVideoTrim] native duration read failed: $e');
      return 0;
    }
  }

  Future<File> _compressStoryVideoToSizeIfNeeded(File videoFile) async {
    final maxBytes = UploadConstants.maxStoryVideoSizeBytes;
    if (await videoFile.length() <= maxBytes) return videoFile;

    final qualities = <VideoQuality>[
      VideoQuality.HighestQuality,
      VideoQuality.Res1280x720Quality,
      VideoQuality.MediumQuality,
      VideoQuality.LowQuality,
    ];

    var bestFile = videoFile;
    var bestSize = await videoFile.length();
    final durationSeconds = await _readStoryVideoDurationSeconds(videoFile);
    final minAcceptableBytes = _minAcceptableStoryVideoBytes(durationSeconds);
    for (final quality in qualities) {
      try {
        debugPrint(
          '[StoryMakerVideoCompress] start quality=$quality '
          'duration=${durationSeconds}s size=${UploadConstants.formatBytes(bestSize)}',
        );
        final info = await VideoCompress.compressVideo(
          videoFile.path,
          quality: quality,
          deleteOrigin: false,
          includeAudio: true,
        );
        final outputPath = (info?.path ?? '').trim();
        if (outputPath.isEmpty) continue;
        final outputFile = File(outputPath);
        if (!outputFile.existsSync()) continue;
        final outputSize = await outputFile.length();
        debugPrint(
          '[StoryMakerVideoCompress] done quality=$quality '
          'size=${UploadConstants.formatBytes(outputSize)}',
        );
        if (outputSize < minAcceptableBytes) {
          debugPrint(
            '[StoryMakerVideoCompress] rejected_too_small quality=$quality '
            'size=${UploadConstants.formatBytes(outputSize)} '
            'min=${UploadConstants.formatBytes(minAcceptableBytes)}',
          );
          continue;
        }
        if (outputSize < bestSize) {
          bestFile = outputFile;
          bestSize = outputSize;
        }
        if (outputSize <= maxBytes) return outputFile;
      } catch (e) {
        debugPrint(
            '[StoryMakerVideoCompress] failed quality=$quality error=$e');
      }
    }

    return bestFile;
  }

  int _minAcceptableStoryVideoBytes(int durationSeconds) {
    final seconds = min(
      durationSeconds > 0
          ? durationSeconds
          : UploadConstants.maxStoryVideoLengthSeconds,
      UploadConstants.maxStoryVideoLengthSeconds,
    ).clamp(1, UploadConstants.maxStoryVideoLengthSeconds);
    return max(2 * 1024 * 1024, seconds * 45 * 1024);
  }

  Future<int> _readStoryVideoDurationSeconds(File videoFile) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      return controller.value.duration.inSeconds;
    } catch (e) {
      debugPrint('[StoryMakerVideoTrim] duration read failed: $e');
      return 0;
    } finally {
      await controller?.dispose();
    }
  }

  void selectMusic() async {
    final hadPreviewPlaying = isMusicPlaying.value;
    pauseMusic();
    final track = await Get.to<MusicModel>(() => SpotifySelector());
    if (track == null || track.audioUrl.isEmpty) {
      if (hadPreviewPlaying) {
        await _resumeSelectedMusicPreview();
      }
      return;
    }

    final hasAnyUnmutedVideo =
        elements.any((e) => e.type == StoryElementType.video && !e.isMuted);
    bool muteVideosDecision = false;
    if (hasAnyUnmutedVideo) {
      await noYesAlert(
        title: 'story.video_audio_title'.tr,
        message: 'story.music_mute_videos_message'.tr,
        yesText: 'story.music_mute_videos_yes'.tr,
        cancelText: 'common.no'.tr,
        onYesPressed: () {
          muteVideosDecision = true;
        },
      );
    }
    if (muteVideosDecision) {
      for (var e in elements) {
        if (e.type == StoryElementType.video) {
          e.isMuted = true;
        }
      }
      elements.refresh();
    }

    try {
      if (_audioPlayer.state != PlayerState.disposed) {
        await _audioPlayer.stop();
      }
    } catch (e) {
      print("selectMusic stop error (ignored): $e");
    }

    try {
      if (_audioPlayer.state != PlayerState.disposed) {
        await AudioFocusCoordinator.instance.requestAudioPlayerPlay(
          _audioPlayer,
        );
        final playablePath = await StoryMusicLibraryService.instance
            .resolvePlayablePath(track.audioUrl);
        if (playablePath.isNotEmpty) {
          await _audioPlayer.play(DeviceFileSource(playablePath));
        } else {
          await _audioPlayer.play(UrlSource(track.audioUrl));
        }
        isMusicPlaying.value = true;
        unawaited(StoryMusicLibraryService.instance.warmTrack(track));
        selectedMusic.value = track;
        music.value = track.audioUrl;
        elements.refresh();
      }
    } catch (e) {
      debugPrint("selectMusic play error: $e");
      isMusicPlaying.value = false;
    }
  }

  void pauseMusic() {
    try {
      if (_audioPlayer.state != PlayerState.disposed) {
        _audioPlayer.pause();
      }
    } catch (e) {
      print("pauseMusic error (ignored): $e");
    }
    isMusicPlaying.value = false;
  }

  void stopMusic() {
    try {
      if (_audioPlayer.state != PlayerState.disposed) {
        _audioPlayer.stop();
      }
    } catch (e) {
      print("stopMusic error (ignored): $e");
    }
    isMusicPlaying.value = false;
  }
}
