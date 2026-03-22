part of 'edit_post_controller.dart';

extension EditPostControllerMediaPart on EditPostController {
  void removeVideo() {
    rxVideoController.value?.dispose();
    rxVideoController.value = null;
    videoUrl.value = '';
    thumbnail.value = '';
    model.video = '';
    model.thumbnail = '';
    _newVideoSelected = false;
    _videoRemoved = true;
  }

  Future<void> pickVideo({required ImageSource source}) async {
    File? file;
    if (source == ImageSource.gallery) {
      final ctx = Get.context;
      if (ctx == null) return;
      file = await AppImagePickerService.pickSingleVideo(ctx);
      if (file == null) return;
    } else {
      final picked = await picker.pickVideo(source: source);
      if (picked == null) return;
      file = File(picked.path);
    }

    selectedImages.clear();
    removeVideo();
    isPlaying.value = false;
    waitingVideo.value = true;
    _newVideoSelected = true;
    _videoRemoved = false;

    final nsfw = await OptimizedNSFWService.checkVideo(file);
    if (nsfw.isNSFW) {
      AppSnackbar(
        'edit_profile.upload_failed_title'.tr,
        'edit_profile.upload_failed_body'.tr,
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      waitingVideo.value = false;
      return;
    }

    double targetMbps = 5.0;
    try {
      final net = NetworkAwarenessService.ensure();
      targetMbps = net.settings.mobileTargetMbps;
    } catch (_) {}
    final compressed = await VideoCompressionService.compressForNetwork(
      file,
      targetMbps: targetMbps,
    );

    final tempDir = await getTemporaryDirectory();
    final thumbPath = p.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_thumb.jpg',
    );
    await VideoEditorBuilder(videoPath: compressed.path).generateThumbnail(
      positionMs: 0,
      quality: 80,
      outputPath: thumbPath,
    );
    thumbnail.value = thumbPath;
    model.thumbnail = thumbPath;

    waitingVideo.value = true;
    videoUrl.value = compressed.path;

    final fileCtrl = VideoPlayerController.file(compressed);
    await fileCtrl.initialize();
    fileCtrl.setLooping(true);
    fileCtrl.addListener(() {
      isPlaying.value = fileCtrl.value.isPlaying;
    });

    rxVideoController.value = fileCtrl;
    waitingVideo.value = false;
  }

  void removeImageUrl(int index) {
    if (index >= 0 && index < imageUrls.length) {
      imageUrls.removeAt(index);
    }
  }

  void removeSelectedImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  Future<void> pickImageGallery() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final files = await AppImagePickerService.pickImages(ctx, maxAssets: 10);
    if (files.isEmpty) return;

    isPlaying.value = false;

    for (final file in files) {
      final result = await OptimizedNSFWService.checkImage(file);
      if (result.isNSFW) {
        AppSnackbar(
          'edit_profile.upload_failed_title'.tr,
          'edit_profile.upload_failed_body'.tr,
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
        selectedImages.clear();
        imageUrls.clear();
        FocusScope.of(Get.context!).unfocus();
        return;
      }
    }

    imageUrls.clear();
    selectedImages
      ..clear()
      ..addAll(files);

    FocusScope.of(Get.context!).unfocus();
  }

  Future<void> pickImageCamera({required ImageSource source}) async {
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    isPlaying.value = false;

    final file = File(picked.path);
    final result = await OptimizedNSFWService.checkImage(file);
    if (result.isNSFW) {
      AppSnackbar(
        'edit_profile.upload_failed_title'.tr,
        'edit_profile.upload_failed_body'.tr,
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      selectedImages.clear();
      imageUrls.clear();
    } else {
      imageUrls.clear();
      selectedImages
        ..clear()
        ..add(file);
    }

    FocusScope.of(Get.context!).unfocus();
  }
}
