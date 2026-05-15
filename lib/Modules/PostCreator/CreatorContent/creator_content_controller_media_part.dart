part of 'creator_content_controller.dart';

extension CreatorContentControllerMediaPart on CreatorContentController {
  Future<void> _performPickImage() async {
    if (selectedVideo.value != null || reusedVideoUrl.value.isNotEmpty) {
      UploadValidationService.showValidationError(
          'post_creator.photo_with_video_forbidden'.tr);
      return;
    }

    final postCreator = ensurePostCreatorController();
    final isSeries = postCreator.postList.length > 1;
    final existingCount = selectedImages.length;
    final maxImages = UploadConstants.maxImagesPerPost;
    final existingReusedCount = reusedImageUrls.length;
    final remaining = maxImages - existingCount - existingReusedCount;
    if (remaining <= 0) {
      UploadValidationService.showValidationError(
          'post_creator.max_photo_count'.trParams({'count': '$maxImages'}));
      return;
    }

    final ctx = Get.context;
    if (ctx == null) return;
    final files = await AppImagePickerService.pickImages(
      ctx,
      maxAssets: remaining,
    );
    if (files.isEmpty) return;

    final currentImageCount = selectedImages.length + reusedImageUrls.length;
    final newImageCount = files.length;
    final totalCount = currentImageCount + newImageCount;

    if (!isSeries && totalCount > maxImages) {
      UploadValidationService.showValidationError(
          'post_creator.max_photo_add'.trParams({
        'count': '$maxImages',
        'current': '$currentImageCount',
        'adding': '$newImageCount',
      }));
      return;
    }

    for (int i = 0; i < files.length; i++) {
      final validation = await UploadValidationService.validateImage(files[i]);
      if (!validation.isValid) {
        UploadValidationService.showValidationError(
            'post_creator.photo_validation_prefix'.trParams({
          'index': '${i + 1}',
          'error': validation.errorMessage ?? '',
        }));
        return;
      }
    }

    final hadVideo =
        selectedVideo.value != null || reusedVideoUrl.value.trim().isNotEmpty;
    if (hadVideo) {
      await _releaseVideoController();
      selectedVideo.value = null;
      reusedVideoUrl.value = '';
      reusedVideoThumbnail.value = '';
      reusedVideoAspectRatio.value = 0.0;
      selectedThumbnail.value = null;
      isPlaying.value = false;
      hasVideo.value = false;
      hasVideo.refresh();
    }

    final existingImages = selectedImages.toList();
    final allImages = [...existingImages, ...files];

    if (!isSeries) {
      final totalSizeValidation = UploadValidationService.validateTotalPostSize(
          allImages, const <File>[]);
      if (!totalSizeValidation.isValid) {
        UploadValidationService.showValidationError(
            totalSizeValidation.errorMessage!);
        return;
      }
    }

    isProcessing.value = true;
    reusedImageUrls.clear();

    try {
      final optimalQuality =
          const NetworkRuntimeService().getOptimalCompressionQuality();
      final compressionResults = await MediaCompressionService.compressImages(
        imageFiles: files,
        quality: optimalQuality,
        onProgress: (current, total) {},
      );

      if (isSeries) {
        var insertCursor = postCreator.selectedIndex.value;

        for (int i = 0; i < compressionResults.length; i++) {
          final result = compressionResults[i];
          CreatorContentController targetController;

          if (i == 0) {
            targetController = this;
          } else {
            final newModel = postCreator.insertComposerItemAfter(insertCursor);
            insertCursor++;
            final newTag = newModel.index.toString();
            targetController = ensureCreatorContentController(tag: newTag);
          }

          await targetController._replaceWithSingleImage(
            file: files[i],
            compressedData: result.compressedData,
          );
        }
      } else {
        int newCompressedTotal = 0;
        for (final r in compressionResults) {
          newCompressedTotal += r.compressedSize;
        }
        int existingCompressed = 0;
        for (final b in croppedImages) {
          if (b != null) existingCompressed += b.length;
        }
        final validation = UploadValidationService.validateCompressedTotals(
          imagesBytes: newCompressedTotal,
          videoBytes: 0,
          existingCompressedBytes: existingCompressed,
        );
        if (!validation.isValid) {
          UploadValidationService.showValidationError(validation.errorMessage!);
          isProcessing.value = false;
          return;
        }

        selectedImages.addAll(files);
        _enforceImageCap();

        for (final result in compressionResults) {
          croppedImages.add(result.compressedData);
        }
        _enforceImageCap();
      }

      final totalOriginal =
          compressionResults.fold(0, (sum, r) => sum + r.originalSize);
      final totalCompressed =
          compressionResults.fold(0, (sum, r) => sum + r.compressedSize);
      final savingsPercent =
          ((1 - (totalCompressed / totalOriginal)) * 100).toStringAsFixed(1);

      if (kDebugMode) {
        debugPrint('[Creator] Images added: count=${compressionResults.length} '
            'originalTotal=${UploadConstants.formatBytes(totalOriginal)} -> '
            '${UploadConstants.formatBytes(totalCompressed)} (%$savingsPercent saved)');
      }

      FocusScope.of(Get.context!).unfocus();
    } catch (e) {
      for (var file in files) {
        final bytes = await file.readAsBytes();
        croppedImages.add(bytes);
      }
      _enforceImageCap();

      AppSnackbar(
        'post_creator.warning_title'.tr,
        'post_creator.photos_compression_failed'.tr,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
      );
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _performReplaceWithSingleImage({
    required File file,
    required Uint8List compressedData,
  }) async {
    await _releaseVideoController();
    gif.value = '';
    selectedVideo.value = null;
    reusedVideoUrl.value = '';
    reusedVideoThumbnail.value = '';
    reusedVideoAspectRatio.value = 0.0;
    selectedThumbnail.value = null;
    isPlaying.value = false;
    hasVideo.value = false;
    hasVideo.refresh();
    reusedImageUrls.clear();
    reusedImageAspectRatio.value = 0.0;
    selectedImages
      ..clear()
      ..add(file);
    croppedImages
      ..clear()
      ..add(compressedData);
    _enforceImageCap();
  }

  Future<void> _performPickImageFromCamera({
    required ImageSource source,
  }) async {
    final ctx = Get.context;
    if (ctx == null) return;
    final file = await AppImagePickerService.pickSingleImage(
      ctx,
      source: source,
    );
    if (file == null) return;
    await _processPickedImage(file);
  }

  Future<void> _performProcessPickedImage(File file) async {
    isProcessing.value = true;
    final validation = await UploadValidationService.validateImage(file);
    if (!validation.isValid) {
      UploadValidationService.showValidationError(validation.errorMessage!);
      isProcessing.value = false;
      return;
    }

    gif.value = '';
    await _releaseVideoController();
    selectedVideo.value = null;
    reusedVideoUrl.value = '';
    reusedVideoThumbnail.value = '';
    reusedVideoAspectRatio.value = 0.0;
    reusedImageUrls.clear();
    videoLookPreset.value = 'original';
    isPlaying.value = false;
    hasVideo.value = false;
    hasVideo.refresh();

    try {
      selectedImages
        ..clear()
        ..add(file);
      croppedImages.clear();
      _enforceImageCap();

      final compressionResult = await MediaCompressionService.compressImage(
        imageFile: file,
        targetQuality:
            const NetworkRuntimeService().getOptimalCompressionQuality(),
      );

      if (kDebugMode) {
        final saved = ((1 -
                    (compressionResult.compressedSize /
                        compressionResult.originalSize)) *
                100)
            .toStringAsFixed(1);
        debugPrint('[Creator] Camera image compressed: '
            'original=${UploadConstants.formatBytes(compressionResult.originalSize)} -> '
            '${compressionResult.format} ${UploadConstants.formatBytes(compressionResult.compressedSize)} '
            '(%$saved saved) size=${compressionResult.width}x${compressionResult.height}');
      }

      int existingCompressed = 0;
      for (final b in croppedImages) {
        if (b != null) existingCompressed += b.length;
      }
      int currentVideo = 0;
      if (selectedVideo.value != null) {
        currentVideo = await selectedVideo.value!.length();
      }
      final validation2 = UploadValidationService.validateCompressedTotals(
        imagesBytes: compressionResult.compressedSize,
        videoBytes: currentVideo,
        existingCompressedBytes: existingCompressed,
      );
      if (!validation2.isValid) {
        UploadValidationService.showValidationError(validation2.errorMessage!);
        return;
      }

      croppedImages.add(compressionResult.compressedData);
      _enforceImageCap();

      AppSnackbar(
        'post_creator.success_title'.tr,
        'post_creator.photo_added'
            .trParams({'saved': compressionResult.spaceSavedText}),
        backgroundColor: Colors.green.withValues(alpha: 0.8),
      );
    } catch (e) {
      final bytes = await file.readAsBytes();
      croppedImages.add(bytes);
      _enforceImageCap();

      AppSnackbar(
        'post_creator.warning_title'.tr,
        'post_creator.photo_added_no_compress'.tr,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
      );
    } finally {
      isProcessing.value = false;
    }

    FocusScope.of(Get.context!).unfocus();
  }

  Future<void> _performPickVideo({required ImageSource source}) async {
    final postCreator = ensurePostCreatorController();
    final isSeries = postCreator.postList.length > 1;

    if (source != ImageSource.gallery &&
        !isSeries &&
        (selectedVideo.value != null || reusedVideoUrl.value.isNotEmpty)) {
      UploadValidationService.showValidationError('post_creator.max_video_count'
          .trParams({'count': '${UploadConstants.maxVideosPerPost}'}));
      return;
    }

    if (source == ImageSource.gallery) {
      final ctx = Get.context;
      if (ctx == null) return;
      final files = await AppImagePickerService.pickVideos(
        ctx,
        maxAssets: 20,
      );
      if (files.isEmpty) return;

      if (isSeries || files.length > 1) {
        var insertCursor = postCreator.selectedIndex.value;
        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          CreatorContentController targetController;

          if (i == 0) {
            targetController = this;
          } else {
            final newModel = postCreator.insertComposerItemAfter(insertCursor);
            insertCursor++;
            final newTag = newModel.index.toString();
            targetController = ensureCreatorContentController(tag: newTag);
          }

          await targetController._replaceWithSingleVideo(file);
        }
        return;
      }

      await _processPickedVideo(files.first);
      return;
    } else {
      final ctx = Get.context;
      if (ctx == null) return;
      final file = await AppImagePickerService.pickSingleVideoFromSource(
        ctx,
        source: source,
      );
      if (file == null) return;
      await _processPickedVideo(file);
    }
  }

  Future<void> _performProcessPickedVideo(File file) async {
    waitingVideo.value = false;
    isProcessing.value = true;

    final validation = await UploadValidationService.validateVideo(file);
    if (!validation.isValid) {
      isProcessing.value = false;
      UploadValidationService.showValidationError(validation.errorMessage!);
      return;
    }

    final currentImages = selectedImages.toList();
    final totalSizeValidation =
        UploadValidationService.validateTotalPostSize(currentImages, [file]);
    if (!totalSizeValidation.isValid) {
      isProcessing.value = false;
      UploadValidationService.showValidationError(
          totalSizeValidation.errorMessage!);
      return;
    }

    gif.value = '';
    selectedImages.clear();
    croppedImages.clear();
    await _releaseVideoController();
    selectedVideo.value = null;
    reusedVideoUrl.value = '';
    reusedVideoThumbnail.value = '';
    reusedVideoAspectRatio.value = 0.0;
    reusedImageUrls.clear();
    isPlaying.value = false;
    hasVideo.value = false;
    hasVideo.refresh();
    selectedThumbnail.value = null;
    videoLookPreset.value = 'original';

    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    _bindVideoController(controller);

    selectedVideo.value = file;
    hasVideo.value = true;
    isPlaying.value = false;
    _listenVideo();
    hasVideo.refresh();

    isProcessing.value = false;

    if (kDebugMode) {
      final metadata = validation.metadata;
      final duration = metadata?['duration'] ?? 0;
      final size = UploadConstants.formatBytes(await file.length());
      debugPrint('[Creator] Video added: size=$size, duration=${duration}s');
    }
  }

  Future<void> _performReplaceWithSingleVideo(File file) async {
    waitingVideo.value = false;
    isProcessing.value = true;

    final validation = await UploadValidationService.validateVideo(file);
    if (!validation.isValid) {
      isProcessing.value = false;
      UploadValidationService.showValidationError(validation.errorMessage!);
      return;
    }

    gif.value = '';
    selectedImages.clear();
    croppedImages.clear();
    await _releaseVideoController();
    selectedVideo.value = null;
    reusedVideoUrl.value = '';
    reusedVideoThumbnail.value = '';
    reusedVideoAspectRatio.value = 0.0;
    reusedImageUrls.clear();
    isPlaying.value = false;
    hasVideo.value = false;
    hasVideo.refresh();
    selectedThumbnail.value = null;
    videoLookPreset.value = 'original';

    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    _bindVideoController(controller);

    selectedVideo.value = file;
    hasVideo.value = true;
    isPlaying.value = false;
    _listenVideo();
    hasVideo.refresh();
    isProcessing.value = false;
  }

  Future<void> _performSetReusedVideoSource({
    required String videoUrl,
    required double aspectRatio,
    required String thumbnail,
  }) async {
    final url = videoUrl.trim();
    if (url.isEmpty) return;

    waitingVideo.value = false;
    isProcessing.value = true;

    gif.value = '';
    selectedImages.clear();
    croppedImages.clear();
    reusedImageUrls.clear();
    await _releaseVideoController();
    selectedVideo.value = null;
    isPlaying.value = false;
    hasVideo.value = false;
    selectedThumbnail.value = null;

    reusedVideoUrl.value = url;
    reusedVideoThumbnail.value = thumbnail.trim();
    reusedVideoAspectRatio.value = aspectRatio > 0 ? aspectRatio : 0.0;
    reusedImageAspectRatio.value = 0.0;
    videoLookPreset.value = 'original';

    final uri = Uri.tryParse(url);
    if (uri == null) {
      isProcessing.value = false;
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    await controller.initialize();
    _bindVideoController(controller);
    hasVideo.value = true;
    isPlaying.value = false;
    _listenVideo();
    hasVideo.refresh();
    isProcessing.value = false;
  }

  Future<void> _performSetReusedImageSources(
    List<String> imageUrls, {
    required double aspectRatio,
  }) async {
    final isThread = ensurePostCreatorController().postList.length > 1;
    final uniqueUrls =
        imageUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (uniqueUrls.isEmpty) return;
    final limitedUrls = isThread ? [uniqueUrls.first] : uniqueUrls;

    waitingVideo.value = false;
    isProcessing.value = true;

    gif.value = '';
    await _releaseVideoController();
    selectedVideo.value = null;
    isPlaying.value = false;
    hasVideo.value = false;
    selectedThumbnail.value = null;
    reusedVideoUrl.value = '';
    reusedVideoThumbnail.value = '';
    reusedVideoAspectRatio.value = 0.0;
    videoLookPreset.value = 'original';
    reusedImageAspectRatio.value = aspectRatio > 0 ? aspectRatio : 0.0;
    selectedImages.clear();
    croppedImages.clear();
    reusedImageUrls.assignAll(limitedUrls);
    isProcessing.value = false;
  }

  void _performSetVideoLookPreset(String preset) {
    if (!kCreatorSupportedVideoLookPresets.contains(preset)) {
      return;
    }
    videoLookPreset.value = preset;
  }

  Future<void> _performOpenCustomCameraCapture() async {
    final result = await Get.to<ChatCameraCaptureResult>(
      () => const ChatCameraCaptureView(),
      transition: Transition.fadeIn,
    );
    if (result == null) return;

    if (result.mode == ChatCameraMode.photo) {
      await _processPickedImage(result.file);
      return;
    }

    final prepared = await _preparePickedPostCameraVideo(result.file);
    if (prepared == null) return;
    await _processPickedVideo(prepared);
  }

  Future<File?> _preparePickedPostCameraVideo(File videoFile) async {
    final durationOk = await _validatePickedPostCameraVideoDuration(videoFile);
    if (!durationOk) return null;

    final originalBytes = await videoFile.length();
    final maxBytes =
        await UploadValidationService.currentMaxVideoSizeBytesAsync();
    if (originalBytes <= maxBytes) {
      debugPrint(
        '[CreatorCameraVideo] camera_compress_skip '
        'reason=within_limit '
        'size=${UploadConstants.formatBytes(originalBytes)} '
        'max=${UploadConstants.formatBytes(maxBytes)}',
      );
      return videoFile;
    }

    File output = videoFile;
    final qualities = <VideoQuality>[
      VideoQuality.Res1280x720Quality,
      VideoQuality.MediumQuality,
      VideoQuality.LowQuality,
    ];
    for (final quality in qualities) {
      try {
        final compressed = await VideoCompress.compressVideo(
          videoFile.path,
          quality: quality,
          includeAudio: true,
          deleteOrigin: false,
        );
        if (compressed?.file != null) {
          final compressedFile = compressed!.file!;
          final compressedBytes = await compressedFile.length();
          if (compressedBytes < await output.length()) {
            output = compressedFile;
          }
          debugPrint(
            '[CreatorCameraVideo] camera_compress_pass '
            'quality=$quality '
            'original=${UploadConstants.formatBytes(originalBytes)} '
            'compressed=${UploadConstants.formatBytes(compressedBytes)} '
            'best=${UploadConstants.formatBytes(await output.length())} '
            'usedCompressed=${output.path == compressedFile.path}',
          );
          if (compressedBytes <= maxBytes) {
            output = compressedFile;
            break;
          }
        }
      } catch (e) {
        debugPrint(
          '[CreatorCameraVideo] camera_compress_failed '
          'quality=$quality error=$e',
        );
      }
    }

    final validation = await UploadValidationService.validateVideo(output);
    if (!validation.isValid) {
      final finalBytes = await output.length();
      debugPrint(
        '[CreatorCameraVideo] rejected_after_compress '
        'size=${UploadConstants.formatBytes(finalBytes)} '
        'error=${validation.errorMessage}',
      );
      UploadValidationService.showValidationError(validation.errorMessage!);
      return null;
    }

    return output;
  }

  Future<bool> _validatePickedPostCameraVideoDuration(File videoFile) async {
    final controller = VideoPlayerController.file(videoFile);
    try {
      await controller.initialize();
      final durationSeconds = controller.value.duration.inSeconds;
      final maxSeconds =
          await UploadValidationService.currentMaxVideoLengthSecondsAsync();
      if (durationSeconds > maxSeconds) {
        debugPrint(
          '[CreatorCameraVideo] rejected_duration '
          'max=${maxSeconds}s current=${durationSeconds}s',
        );
        UploadValidationService.showValidationError(
          'upload_validation.video_duration_too_long'.trParams({
            'max': '$maxSeconds',
            'current': '$durationSeconds',
          }),
        );
        return false;
      }
      return true;
    } catch (e) {
      UploadValidationService.showValidationError(
        'upload_validation.video_analysis_failed'.trParams({'error': '$e'}),
      );
      return false;
    } finally {
      await controller.dispose();
    }
  }

  void _performEnforceImageCap() {
    final max = UploadConstants.maxImagesPerPost;
    if (selectedImages.length > max) {
      selectedImages.assignAll(selectedImages.take(max).toList());
    }
    if (croppedImages.length > max) {
      croppedImages.assignAll(croppedImages.take(max).toList());
    }
  }

  Future<void> _performGoToLocationMap() async {
    Get.to(() => LocationFinderView(
          submitButtonTitle: 'post_creator.use_address'.tr,
          backAdres: (v) {
            adres.value = v;
          },
          backLatLong: (_) {},
        ));
  }
}
