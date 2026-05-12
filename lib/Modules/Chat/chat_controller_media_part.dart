part of 'chat_controller.dart';

extension ChatControllerMediaPart on ChatController {
  static const List<int> _chatThumbnailCandidateMs = <int>[0, 33, 67, 100];

  Future<double?> _chatThumbnailQualityScore(Uint8List data) async {
    try {
      final codec = await ui.instantiateImageCodec(
        data,
        targetWidth: 24,
        targetHeight: 24,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      if (bytes.isEmpty) return null;

      double sum = 0;
      double sumSquares = 0;
      int count = 0;
      for (int i = 0; i + 3 < bytes.length; i += 4) {
        final r = bytes[i].toDouble();
        final g = bytes[i + 1].toDouble();
        final b = bytes[i + 2].toDouble();
        final luma = (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
        sum += luma;
        sumSquares += luma * luma;
        count++;
      }
      if (count == 0) return null;
      final mean = sum / count;
      final variance = (sumSquares / count) - (mean * mean);
      if (mean < 14) return mean - 1000;
      return variance + (mean * 0.15);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _generateChatThumbnail(String videoPath) async {
    Uint8List? bestData;
    double bestScore = double.negativeInfinity;

    for (final ms in _chatThumbnailCandidateMs) {
      final data = await vt.VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: vt.ImageFormat.JPEG,
        timeMs: ms,
        maxWidth: 300,
        quality: 75,
      );
      if (data == null || data.isEmpty) continue;
      final score = await _chatThumbnailQualityScore(data);
      if (score != null && score >= 18) return data;
      if (score != null && score > bestScore) {
        bestScore = score;
        bestData = data;
      } else {
        bestData ??= data;
      }
    }

    return bestData;
  }

  Future<void> pickImage() async {
    final ctx = Get.context;
    if (ctx == null) return;
    _recordMediaAction('pick_image');
    _clearMediaFailure();
    if (IntegrationMediaTestHarness.consumeFailure(
      IntegrationMediaFailureKind.photosDenied,
    )) {
      _recordMediaFailure('photos_denied');
      return;
    }
    if (IntegrationMediaTestHarness.consumeFailure(
      IntegrationMediaFailureKind.pickerCancelled,
    )) {
      _recordMediaFailure('picker_cancelled');
      return;
    }
    if (IntegrationMediaTestHarness.consumeFailure(
      IntegrationMediaFailureKind.pickerFailed,
    )) {
      _recordMediaFailure('picker_failed');
      return;
    }
    final harnessSelection =
        IntegrationMediaTestHarness.takeGalleryImageSelection();
    if (harnessSelection != null) {
      images.value = harnessSelection;
      pendingVideo.value = null;
      selection.value = harnessSelection.isEmpty ? 0 : 1;
      return;
    }
    final files = await AppImagePickerService.pickImages(ctx, maxAssets: 10);
    if (files.isEmpty) {
      if (lastMediaFailureCode.value.isEmpty) {
        _recordMediaFailure('picker_empty');
      }
      return;
    }

    for (final f in files) {
      final r = await OptimizedNSFWService.checkImage(f);
      if (r.isNSFW) {
        _recordMediaFailure('nsfw_image');
        AppSnackbar(
          "Yükleme Başarısız!",
          "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
        return;
      }
    }

    images.value = files;
    pendingVideo.value = null;
    selection.value = 1;
  }

  Future<void> pickCameraImage() async {
    _recordMediaAction('pick_camera_image');
    _clearMediaFailure();
    final harnessPhoto = IntegrationMediaTestHarness.takeCameraPhoto();
    if (harnessPhoto == null &&
        IntegrationMediaTestHarness.consumeFailure(
          IntegrationMediaFailureKind.cameraDenied,
        )) {
      _recordMediaFailure('camera_denied');
      return;
    }
    if (harnessPhoto != null) {
      images.value = [harnessPhoto];
      pendingVideo.value = null;
      selection.value = 1;
      return;
    }
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (pickedFile == null) {
      _recordMediaFailure('picker_empty');
      return;
    }

    final file = File(pickedFile.path);
    final r = await OptimizedNSFWService.checkImage(file);
    if (r.isNSFW) {
      _recordMediaFailure('nsfw_camera_image');
      AppSnackbar(
        "Yükleme Başarısız!",
        "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
        backgroundColor: Colors.red.withValues(alpha: 0.7),
      );
      return;
    }

    images.value = [file];
    pendingVideo.value = null;
    selection.value = 1;
  }

  Future<void> uploadImageToStorage() async {
    if (images.isEmpty) return;
    _recordMediaAction('upload_image');
    _clearMediaFailure();
    isUploading.value = true;
    uploadPercent.value = 1;
    final storage = AppFirebaseStorage.instance;
    final uuid = Uuid();

    final downloadUrls = <String>[];

    try {
      if (IntegrationMediaTestHarness.consumeFailure(
        IntegrationMediaFailureKind.imageUploadFailed,
      )) {
        throw StateError('image_upload_failed');
      }
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        File fileToUpload = image;

        try {
          final tempDir = Directory.systemTemp.path;
          final targetPath =
              '$tempDir/chat_img_${DateTime.now().millisecondsSinceEpoch}_$i.webp';
          final compressed = await FlutterImageCompress.compressAndGetFile(
            image.path,
            targetPath,
            quality: 82,
            minWidth: 1440,
            minHeight: 1440,
            keepExif: false,
            format: CompressFormat.webp,
          );
          if (compressed != null) {
            fileToUpload = File(compressed.path);
          }
        } catch (_) {}

        final fileName = uuid.v4();
        final ref = storage.ref().child(
              'ChatAssets/$chatID/$fileName${DateTime.now().millisecondsSinceEpoch}.webp',
            );

        final bytes = await fileToUpload.readAsBytes();
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(
            contentType: "image/webp",
            cacheControl: 'public, max-age=31536000, immutable',
          ),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final percent =
              (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          uploadPercent.value = percent;
        });

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      uploadPercent.value = 0;
      isUploading.value = false;
      selection.value = 0;
      images.clear();

      await sendMessage(imageUrls: downloadUrls);
    } catch (e) {
      uploadPercent.value = 0;
      isUploading.value = false;
      images.clear();
      _recordMediaFailure('image_upload_failed', detail: '$e');
      AppSnackbar(
        'common.error'.tr,
        'chat.image_upload_failed_with_error'.trParams({
          'error': e.toString(),
        }),
      );
    }
  }

  Future<void> pickVideo() async {
    _recordMediaAction('pick_video');
    _clearMediaFailure();
    if (IntegrationMediaTestHarness.consumeFailure(
      IntegrationMediaFailureKind.photosDenied,
    )) {
      _recordMediaFailure('photos_denied');
      return;
    }
    if (IntegrationMediaTestHarness.consumeFailure(
      IntegrationMediaFailureKind.pickerCancelled,
    )) {
      _recordMediaFailure('picker_cancelled');
      return;
    }
    if (IntegrationMediaTestHarness.consumeFailure(
      IntegrationMediaFailureKind.pickerFailed,
    )) {
      _recordMediaFailure('picker_failed');
      return;
    }
    final harnessVideo = IntegrationMediaTestHarness.takeGalleryVideo();
    if (harnessVideo != null) {
      if (!await _validatePickedChatVideo(harnessVideo, source: 'harness')) {
        return;
      }
      images.clear();
      pendingVideo.value = harnessVideo;
      selection.value = 1;
      return;
    }
    final XFile? pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (pickedFile == null) {
      _recordMediaFailure('picker_empty');
      return;
    }
    final videoFile = File(pickedFile.path);
    if (!await _validatePickedChatVideo(videoFile, source: 'gallery')) {
      return;
    }
    images.clear();
    pendingVideo.value = videoFile;
    selection.value = 1;
  }

  Future<void> pickCameraVideo() async {
    _recordMediaAction('pick_camera_video');
    _clearMediaFailure();
    final harnessVideo = IntegrationMediaTestHarness.takeCameraCaptureResult();
    if (harnessVideo == null &&
        IntegrationMediaTestHarness.consumeFailure(
          IntegrationMediaFailureKind.cameraDenied,
        )) {
      _recordMediaFailure('camera_denied');
      return;
    }
    if (harnessVideo != null) {
      final prepared = await _preparePickedChatCameraVideo(
        harnessVideo,
        source: 'camera_harness',
      );
      if (prepared == null) {
        return;
      }
      images.clear();
      pendingVideo.value = prepared;
      selection.value = 1;
      return;
    }
    await openCustomCameraCapture();
  }

  Future<void> openCustomCameraCapture() async {
    _recordMediaAction('open_custom_camera_capture');
    _clearMediaFailure();
    final harnessCapture =
        IntegrationMediaTestHarness.takeCameraCaptureResult();
    if (harnessCapture == null &&
        IntegrationMediaTestHarness.consumeFailure(
          IntegrationMediaFailureKind.cameraDenied,
        )) {
      _recordMediaFailure('camera_denied');
      return;
    }
    if (harnessCapture != null) {
      images.value = [harnessCapture];
      pendingVideo.value = null;
      selection.value = 1;
      return;
    }
    final result = await Get.to<ChatCameraCaptureResult>(
      () => const ChatCameraCaptureView(),
      transition: Transition.fadeIn,
    );
    if (result == null) {
      _recordMediaFailure('picker_empty');
      return;
    }

    if (result.mode == ChatCameraMode.photo) {
      final file = result.file;
      final r = await OptimizedNSFWService.checkImage(file);
      if (r.isNSFW) {
        _recordMediaFailure('nsfw_camera_image');
        AppSnackbar(
          "Yükleme Başarısız!",
          "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
        return;
      }
      images.value = [file];
      pendingVideo.value = null;
      selection.value = 1;
      return;
    }

    final prepared = await _preparePickedChatCameraVideo(
      result.file,
      source: 'custom_camera',
    );
    if (prepared == null) {
      return;
    }
    images.clear();
    pendingVideo.value = prepared;
    selection.value = 1;
  }

  Future<File?> _preparePickedChatCameraVideo(
    File videoFile, {
    required String source,
  }) async {
    final durationOk = await _validatePickedChatVideoDuration(
      videoFile,
      source: source,
    );
    if (!durationOk) return null;

    final originalBytes = await videoFile.length();
    File output = videoFile;
    try {
      final compressed = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.Res1280x720Quality,
        includeAudio: true,
        deleteOrigin: false,
      );
      if (compressed?.file != null) {
        final compressedFile = compressed!.file!;
        final compressedBytes = await compressedFile.length();
        if (compressedBytes < originalBytes) {
          output = compressedFile;
        }
        debugPrint(
          '[ChatVideoPick] camera_720p_compress '
          'source=$source '
          'original=${UploadConstants.formatBytes(originalBytes)} '
          'compressed=${UploadConstants.formatBytes(compressedBytes)} '
          'usedCompressed=${output.path == compressedFile.path}',
        );
      }
    } catch (e) {
      debugPrint('[ChatVideoPick] camera_720p_compress_failed source=$source error=$e');
    }

    final finalBytes = await output.length();
    if (finalBytes > UploadConstants.maxChatCameraVideoSizeBytes) {
      debugPrint(
        '[ChatVideoPick] rejected_camera_size '
        'source=$source '
        'max=${UploadConstants.formatBytes(UploadConstants.maxChatCameraVideoSizeBytes)} '
        'current=${UploadConstants.formatBytes(finalBytes)}',
      );
      _showChatVideoLimitError(
        maxBytes: UploadConstants.maxChatCameraVideoSizeBytes,
        currentSize: finalBytes,
      );
      _recordMediaFailure('camera_video_size_too_large');
      return null;
    }

    return output;
  }

  Future<bool> _validatePickedChatVideo(
    File videoFile, {
    required String source,
  }) async {
    final fileSize = await videoFile.length();
    if (fileSize > UploadConstants.maxChatVideoSizeBytes) {
      debugPrint(
        '[ChatVideoPick] rejected_size '
        'source=$source '
        'path=${videoFile.path.split('/').last} '
        'max=${UploadConstants.formatBytes(UploadConstants.maxChatVideoSizeBytes)} '
        'current=${UploadConstants.formatBytes(fileSize)}',
      );
      _showChatVideoLimitError(currentSize: fileSize);
      _recordMediaFailure('video_size_too_large');
      return false;
    }

    return _validatePickedChatVideoDuration(videoFile, source: source);
  }

  Future<bool> _validatePickedChatVideoDuration(
    File videoFile, {
    required String source,
  }) async {
    final controller = VideoPlayerController.file(videoFile);
    try {
      await controller.initialize();
      final durationSeconds = controller.value.duration.inSeconds;
      if (durationSeconds > UploadConstants.maxChatVideoLengthSeconds) {
        debugPrint(
          '[ChatVideoPick] rejected_duration '
          'source=$source '
          'path=${videoFile.path.split('/').last} '
          'max=${UploadConstants.maxChatVideoLengthSeconds}s '
          'current=${durationSeconds}s',
        );
        _showChatVideoLimitError(currentDurationSeconds: durationSeconds);
        _recordMediaFailure('video_duration_too_long');
        return false;
      }
      return true;
    } catch (e) {
      _recordMediaFailure('video_analysis_failed', detail: '$e');
      UploadValidationService.showValidationError(
        'upload_validation.video_analysis_failed'.trParams({'error': '$e'}),
      );
      return false;
    } finally {
      await controller.dispose();
    }
  }

  void _showChatVideoLimitError({
    int? maxBytes,
    int? currentSize,
    int? currentDurationSeconds,
  }) {
    final suffix = currentSize != null
        ? 'Mevcut boyut: ${UploadConstants.formatBytes(currentSize)}'
        : 'Mevcut süre: ${currentDurationSeconds ?? 0} sn';
    UploadValidationService.showValidationError(
      'Video maksimum ${UploadConstants.formatBytes(maxBytes ?? UploadConstants.maxChatVideoSizeBytes)} '
      've ${UploadConstants.maxChatVideoLengthSeconds} sn olabilir. '
      '$suffix',
    );
  }

  Future<void> uploadPendingVideoToStorage() async {
    final file = pendingVideo.value;
    if (file == null) return;
    _recordMediaAction('upload_video');
    await _processAndSendVideo(file);
    pendingVideo.value = null;
    selection.value = 0;
  }

  void clearPendingMedia() {
    images.clear();
    pendingVideo.value = null;
    selection.value = 0;
  }

  Future<void> _processAndSendVideo(File videoFile) async {
    _clearMediaFailure();
    isUploading.value = true;
    uploadPercent.value = 1;
    final uuid = Uuid();
    final storage = AppFirebaseStorage.instance;

    try {
      if (IntegrationMediaTestHarness.consumeFailure(
        IntegrationMediaFailureKind.videoUploadFailed,
      )) {
        throw StateError('video_upload_failed');
      }
      final nsfw = await OptimizedNSFWService.checkVideo(videoFile);
      if (nsfw.isNSFW) {
        isUploading.value = false;
        uploadPercent.value = 0;
        _recordMediaFailure('nsfw_video');
        AppSnackbar(
          "Yükleme Başarısız!",
          "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        );
        return;
      }

      File fileToUpload = videoFile;
      try {
        final compressed = await VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        if (compressed?.file != null) {
          fileToUpload = compressed!.file!;
        }
      } catch (_) {}

      Uint8List? thumbBytes;
      try {
        thumbBytes = await _generateChatThumbnail(videoFile.path);
      } catch (_) {}

      final videoFileName = uuid.v4();
      final videoRef = storage.ref().child(
            'ChatAssets/$chatID/videos/$videoFileName.mp4',
          );
      final videoUpload = videoRef.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: 'video/mp4',
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      );
      videoUpload.snapshotEvents.listen((snapshot) {
        uploadPercent.value =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      });
      final videoSnapshot = await videoUpload;
      final videoDownloadUrl = await videoSnapshot.ref.getDownloadURL();

      var thumbUrl = "";
      if (thumbBytes != null) {
        try {
          thumbUrl = await WebpUploadService.uploadBytesAsWebp(
            bytes: thumbBytes,
            storagePathWithoutExt:
                'ChatAssets/$chatID/videos/${videoFileName}_thumb',
          );
        } catch (_) {}
      }

      uploadPercent.value = 0;
      isUploading.value = false;

      await sendMessage(
        videoUrl: videoDownloadUrl,
        videoThumbnail: thumbUrl,
      );
    } catch (error) {
      uploadPercent.value = 0;
      isUploading.value = false;
      _recordMediaFailure('video_upload_failed', detail: '$error');
      AppSnackbar('common.error'.tr, 'chat.video_upload_failed'.tr);
    }
  }

  Future<void> startVoiceRecording() async {
    try {
      _recordMediaAction('start_voice_recording');
      _clearMediaFailure();
      if (IntegrationMediaTestHarness.consumeFailure(
        IntegrationMediaFailureKind.microphoneDenied,
      )) {
        _recordMediaFailure('microphone_denied');
        AppSnackbar(
          'chat.microphone_permission_required'.tr,
          'chat.microphone_permission_denied'.tr,
        );
        return;
      }
      final harnessPermission =
          IntegrationMediaTestHarness.takeVoicePermission();
      final hasPermission =
          harnessPermission ?? await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _recordMediaFailure('microphone_denied');
        AppSnackbar(
          'chat.microphone_permission_required'.tr,
          'chat.microphone_permission_denied'.tr,
        );
        return;
      }
      if (IntegrationMediaTestHarness.isActive) {
        final dir = Directory.systemTemp;
        final path = '${dir.path}/${Uuid().v4()}.m4a';
        await File(path).writeAsBytes(const <int>[0, 1, 2, 3], flush: true);
        _recordingPath = path;
        isRecording.value = true;
        recordingDuration.value = 1;
        return;
      }
      final dir = Directory.systemTemp;
      final path = '${dir.path}/${Uuid().v4()}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _recordingPath = path;
      isRecording.value = true;
      recordingDuration.value = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingDuration.value++;
      });
    } catch (_) {
      isRecording.value = false;
      _recordMediaFailure('voice_record_start_failed');
      AppSnackbar('common.error'.tr, 'chat.voice_record_start_failed'.tr);
    }
  }

  Future<void> stopVoiceRecording() async {
    _recordingTimer?.cancel();
    String? path;
    try {
      path = await _audioRecorder.stop();
    } catch (_) {
      path = null;
    }
    path ??= _recordingPath;
    isRecording.value = false;
    final durationMs = recordingDuration.value * 1000;
    recordingDuration.value = 0;

    if (path == null || path.isEmpty) return;

    isUploading.value = true;
    uploadPercent.value = 1;
    try {
      _recordMediaAction('upload_audio');
      _clearMediaFailure();
      if (IntegrationMediaTestHarness.consumeFailure(
        IntegrationMediaFailureKind.audioUploadFailed,
      )) {
        throw StateError('audio_upload_failed');
      }
      final file = File(path);
      final storage = AppFirebaseStorage.instance;
      final fileName = Uuid().v4();
      final ref = storage.ref().child('ChatAssets/$chatID/voice/$fileName.m4a');
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'audio/mp4',
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      );
      uploadTask.snapshotEvents.listen((snapshot) {
        uploadPercent.value =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      });
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      uploadPercent.value = 0;
      isUploading.value = false;

      await sendMessage(audioUrl: downloadUrl, audioDurationMs: durationMs);
      _recordingPath = null;
    } catch (error) {
      uploadPercent.value = 0;
      isUploading.value = false;
      _recordMediaFailure('audio_upload_failed', detail: '$error');
      AppSnackbar('common.error'.tr, 'chat.voice_message_upload_failed'.tr);
    }
  }

  Future<void> cancelVoiceRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    isRecording.value = false;
    recordingDuration.value = 0;
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      _recordingPath = null;
    }
  }

  Future<void> selectContact() async {
    if (!await FlutterContacts.requestPermission()) {
      return;
    }
    final contact = await FlutterContacts.openExternalPick();
    if (contact != null) {
      sendMessage(
        kisiAdSoyad: contact.displayName,
        kisiTelefon: contact.phones.first.number,
      );
    }
  }
}
