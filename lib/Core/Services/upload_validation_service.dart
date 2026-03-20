import 'dart:io';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:turqappv2/Core/Services/media_compression_service.dart';
import 'package:video_player/video_player.dart';
import '../upload_constants.dart';

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.metadata,
  });

  factory ValidationResult.success({Map<String, dynamic>? metadata}) {
    return ValidationResult(isValid: true, metadata: metadata);
  }

  factory ValidationResult.error(String message) {
    return ValidationResult(isValid: false, errorMessage: message);
  }
}

class UploadValidationService {
  /// Validate individual image file
  static Future<ValidationResult> validateImage(File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > UploadConstants.maxImageSizeBytes) {
        return ValidationResult.error('upload_validation.image_size_too_large'
            .trParams({
          'max': UploadConstants.getMaxImageSizeText(),
          'current': UploadConstants.formatBytes(fileSize),
        }));
      }

      // Check image dimensions
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
        'format': _getImageFormat(imageFile.path),
      });
    } catch (e) {
      return ValidationResult.error(
          'upload_validation.image_analysis_failed'.trParams({
        'error': '$e',
      }));
    }
  }

  /// Validate individual video file
  static Future<ValidationResult> validateVideo(File videoFile) async {
    try {
      // Check file size
      final fileSize = await videoFile.length();
      if (fileSize > UploadConstants.maxVideoSizeBytes) {
        return ValidationResult.error('upload_validation.video_size_too_large'
            .trParams({
          'max': UploadConstants.getMaxVideoSizeText(),
          'current': UploadConstants.formatBytes(fileSize),
        }));
      }

      // Check video properties
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      final duration = controller.value.duration;
      final aspectRatio = controller.value.aspectRatio;

      // Calculate approximate dimensions
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

      // Check duration
      if (duration.inSeconds > UploadConstants.maxVideoLengthSeconds) {
        return ValidationResult.error('upload_validation.video_duration_too_long'
            .trParams({
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

  /// Validate total post size (all media combined)
  static ValidationResult validateTotalPostSize(
      List<File> images, List<File> videos) {
    int totalSize = 0;

    // Calculate total size
    for (final image in images) {
      totalSize += image.lengthSync();
    }

    for (final video in videos) {
      totalSize += video.lengthSync();
    }

    if (totalSize > UploadConstants.maxTotalPostSizeBytes) {
      return ValidationResult.error('upload_validation.total_size_too_large'
          .trParams({
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

  /// Validate post counts
  static ValidationResult validatePostCounts(int imageCount, int videoCount) {
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

  /// Comprehensive validation for entire post
  static Future<ValidationResult> validatePost({
    required List<File> images,
    required List<File> videos,
    String? text,
  }) async {
    // Check counts first
    final countValidation = validatePostCounts(images.length, videos.length);
    if (!countValidation.isValid) {
      return countValidation;
    }

    // Check if post has any content
    if (images.isEmpty &&
        videos.isEmpty &&
        (text == null || text.trim().isEmpty)) {
      return ValidationResult.error(
          'upload_validation.empty_post'.tr);
    }

    // Validate individual images
    for (int i = 0; i < images.length; i++) {
      final imageValidation = await validateImage(images[i]);
      if (!imageValidation.isValid) {
        return ValidationResult.error(
            'upload_validation.image_error'.trParams({
              'index': '${i + 1}',
              'message': imageValidation.errorMessage ?? '',
            }));
      }
    }

    // Validate individual videos
    for (int i = 0; i < videos.length; i++) {
      final videoValidation = await validateVideo(videos[i]);
      if (!videoValidation.isValid) {
        return ValidationResult.error(
            'upload_validation.video_error'.trParams({
              'index': '${i + 1}',
              'message': videoValidation.errorMessage ?? '',
            }));
      }
    }

    // Validate total size
    final totalSizeValidation = validateTotalPostSize(images, videos);
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

  /// Show validation error with user-friendly message
  static void showValidationError(String message) {
    AppSnackbar(
      'upload_validation.error_title'.tr,
      message,
      backgroundColor: Colors.red.withValues(alpha: 0.8),
    );
  }

  /// Get image format from file path
  static String _getImageFormat(String path) {
    final extension = path.split('.').last.toLowerCase();
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

  /// Validate totals using already-compressed sizes (centralized)
  static ValidationResult validateCompressedTotals({
    required int imagesBytes,
    required int videoBytes,
    int existingCompressedBytes = 0,
  }) {
    final total = imagesBytes + videoBytes + existingCompressedBytes;
    if (total > UploadConstants.maxTotalPostSizeBytes) {
      return ValidationResult.error(
        'Toplam içerik boyutu çok büyük! Sıkıştırma sonrası: '
        '${UploadConstants.formatBytes(total)} / '
        '${UploadConstants.getMaxTotalSizeText()}',
      );
    }
    return ValidationResult.success(metadata: {'total': total});
  }

  /// Estimate compressed size for images (heavy: performs actual compression preview)
  static Future<int> estimateCompressedImagesTotal(List<File> images,
      {int quality = 85}) async {
    int total = 0;
    for (final imgFile in images) {
      try {
        final preview =
            await MediaCompressionService.getCompressionPreview(imgFile);
        if (preview['previews'] is List) {
          final list = preview['previews'] as List;
          Map<String, dynamic>? pick;
          for (final item in list) {
            if ((item as Map)['quality'] == quality) {
              pick = Map<String, dynamic>.from(item);
              break;
            }
          }
          pick ??= Map<String, dynamic>.from(list.last);
          total += (pick['size'] as int);
        }
      } catch (_) {
        // Fallback: assume 60% of original
        final size = await imgFile.length();
        total += (size * 0.6).round();
      }
    }
    return total;
  }

  /// Validate with compression estimate (uses preview; heavier)
  static Future<ValidationResult> validateWithCompressionEstimate({
    required List<File> newImages,
    required int existingCompressedBytes,
    int newVideoBytes = 0,
    int previewQuality = 85,
  }) async {
    final imagesBytes =
        await estimateCompressedImagesTotal(newImages, quality: previewQuality);
    return validateCompressedTotals(
      imagesBytes: imagesBytes,
      videoBytes: newVideoBytes,
      existingCompressedBytes: existingCompressedBytes,
    );
  }
}
