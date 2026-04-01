part of 'upload_validation_service.dart';

Future<ValidationResult> _performValidateImage(File imageFile) async {
  try {
    final fileSize = await imageFile.length();
    if (fileSize > UploadConstants.maxImageSizeBytes) {
      return ValidationResult.error(
          'upload_validation.image_size_too_large'.trParams({
        'max': UploadConstants.getMaxImageSizeText(),
        'current': UploadConstants.formatBytes(fileSize),
      }));
    }

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      return ValidationResult.error(
          'upload_validation.unsupported_image_format'.tr);
    }

    return ValidationResult.success(metadata: {
      'width': image.width,
      'height': image.height,
      'size': fileSize,
      'format': UploadValidationService._getImageFormat(imageFile.path),
    });
  } catch (e) {
    return ValidationResult.error(
        'upload_validation.image_analysis_failed'.trParams({
      'error': '$e',
    }));
  }
}

Future<ValidationResult> _performValidateVideo(File videoFile) async {
  try {
    final fileSize = await videoFile.length();
    if (fileSize > UploadValidationService.currentMaxVideoSizeBytes) {
      return ValidationResult.error(
          'upload_validation.video_size_too_large'.trParams({
        'max': UploadValidationService.currentMaxVideoSizeText,
        'current': UploadConstants.formatBytes(fileSize),
      }));
    }

    final controller = VideoPlayerController.file(videoFile);
    await controller.initialize();

    final duration = controller.value.duration;
    final aspectRatio = controller.value.aspectRatio;

    int width = 1920;
    int height = 1080;

    if (aspectRatio > 0) {
      if (aspectRatio > 1) {
        height = (width / aspectRatio).round();
      } else {
        width = (height * aspectRatio).round();
      }
    }

    await controller.dispose();

    if (duration.inSeconds > UploadConstants.maxVideoLengthSeconds) {
      return ValidationResult.error(
          'upload_validation.video_duration_too_long'.trParams({
        'max': '${UploadConstants.maxVideoLengthSeconds}',
        'current': '${duration.inSeconds}',
      }));
    }

    return ValidationResult.success(metadata: {
      'width': width,
      'height': height,
      'duration': duration.inSeconds,
      'size': fileSize,
      'aspectRatio': aspectRatio,
    });
  } catch (e) {
    return ValidationResult.error(
        'upload_validation.video_analysis_failed'.trParams({
      'error': '$e',
    }));
  }
}

ValidationResult _performValidateTotalPostSize(
  List<File> images,
  List<File> videos,
) {
  var totalSize = 0;

  for (final image in images) {
    totalSize += image.lengthSync();
  }

  for (final video in videos) {
    totalSize += video.lengthSync();
  }

  if (totalSize > UploadConstants.maxTotalPostSizeBytes) {
    return ValidationResult.error(
        'upload_validation.total_size_too_large'.trParams({
      'max': UploadConstants.getMaxTotalSizeText(),
      'current': UploadConstants.formatBytes(totalSize),
    }));
  }

  return ValidationResult.success(metadata: {
    'totalSize': totalSize,
    'imageCount': images.length,
    'videoCount': videos.length,
  });
}

ValidationResult _performValidatePostCounts(int imageCount, int videoCount) {
  if (imageCount > 0 && videoCount > 0) {
    return ValidationResult.error(
        'Aynı gönderide hem fotoğraf hem video seçilemez. En fazla 4 fotoğraf veya 1 video seçin.');
  }

  if (imageCount > UploadConstants.maxImagesPerPost) {
    return ValidationResult.error(
        'Çok fazla fotoğraf! Maksimum ${UploadConstants.maxImagesPerPost} fotoğraf ekleyebilirsiniz.');
  }

  if (videoCount > UploadConstants.maxVideosPerPost) {
    return ValidationResult.error(
        'Çok fazla video! Maksimum ${UploadConstants.maxVideosPerPost} video ekleyebilirsiniz.');
  }

  return ValidationResult.success();
}

Future<ValidationResult> _performValidatePost({
  required List<File> images,
  required List<File> videos,
  String? text,
  int? maxTextLength,
}) async {
  final countValidation =
      UploadValidationService.validatePostCounts(images.length, videos.length);
  if (!countValidation.isValid) {
    return countValidation;
  }

  if (images.isEmpty &&
      videos.isEmpty &&
      (text == null || text.trim().isEmpty)) {
    return ValidationResult.error('upload_validation.empty_post'.tr);
  }

  if (maxTextLength != null) {
    final textValidation = UploadValidationService.validateTextLength(
      text,
      maxLength: maxTextLength,
    );
    if (!textValidation.isValid) {
      return textValidation;
    }
  }

  for (var i = 0; i < images.length; i++) {
    final imageValidation =
        await UploadValidationService.validateImage(images[i]);
    if (!imageValidation.isValid) {
      return ValidationResult.error('upload_validation.image_error'.trParams({
        'index': '${i + 1}',
        'message': imageValidation.errorMessage ?? '',
      }));
    }
  }

  for (var i = 0; i < videos.length; i++) {
    final videoValidation =
        await UploadValidationService.validateVideo(videos[i]);
    if (!videoValidation.isValid) {
      return ValidationResult.error('upload_validation.video_error'.trParams({
        'index': '${i + 1}',
        'message': videoValidation.errorMessage ?? '',
      }));
    }
  }

  final totalSizeValidation =
      UploadValidationService.validateTotalPostSize(images, videos);
  if (!totalSizeValidation.isValid) {
    return totalSizeValidation;
  }

  return ValidationResult.success(metadata: {
    'imageCount': images.length,
    'videoCount': videos.length,
    'hasText': text != null && text.trim().isNotEmpty,
    'totalSize': totalSizeValidation.metadata?['totalSize'] ?? 0,
  });
}

ValidationResult _performValidateTextLength(
  String? text, {
  required int maxLength,
}) {
  final normalized = (text ?? '').trim();
  if (normalized.isEmpty) {
    return ValidationResult.success(metadata: <String, dynamic>{
      'textLength': 0,
      'maxTextLength': maxLength,
    });
  }

  final currentLength = normalized.characters.length;
  if (currentLength > maxLength) {
    return ValidationResult.error(
      'upload_validation.text_too_long'.trParams(<String, String>{
        'max': '$maxLength',
        'current': '$currentLength',
      }),
    );
  }

  return ValidationResult.success(metadata: <String, dynamic>{
    'textLength': currentLength,
    'maxTextLength': maxLength,
  });
}

void _performShowValidationError(String message) {
  AppSnackbar(
    'upload_validation.error_title'.tr,
    message,
    backgroundColor: Colors.red.withValues(alpha: 0.8),
  );
}

String _performGetImageFormat(String path) {
  final extension = normalizeLowercase(path.split('.').last);
  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return 'JPEG';
    case 'png':
      return 'PNG';
    case 'webp':
      return 'WebP';
    case 'gif':
      return 'GIF';
    default:
      return 'settings.diagnostics.unknown'.tr;
  }
}
