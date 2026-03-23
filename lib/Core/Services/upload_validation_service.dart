import 'dart:io';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:turqappv2/Core/Services/media_compression_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:video_player/video_player.dart';
import '../upload_constants.dart';

part 'upload_validation_service_media_part.dart';
part 'upload_validation_service_estimate_part.dart';

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
  static Future<ValidationResult> validateImage(File imageFile) =>
      _performValidateImage(imageFile);

  /// Validate individual video file
  static Future<ValidationResult> validateVideo(File videoFile) =>
      _performValidateVideo(videoFile);

  /// Validate total post size (all media combined)
  static ValidationResult validateTotalPostSize(
    List<File> images,
    List<File> videos,
  ) =>
      _performValidateTotalPostSize(images, videos);

  /// Validate post counts
  static ValidationResult validatePostCounts(int imageCount, int videoCount) =>
      _performValidatePostCounts(imageCount, videoCount);

  /// Comprehensive validation for entire post
  static Future<ValidationResult> validatePost({
    required List<File> images,
    required List<File> videos,
    String? text,
  }) =>
      _performValidatePost(
        images: images,
        videos: videos,
        text: text,
      );

  /// Show validation error with user-friendly message
  static void showValidationError(String message) =>
      _performShowValidationError(message);

  /// Get image format from file path
  static String _getImageFormat(String path) => _performGetImageFormat(path);

  /// Validate totals using already-compressed sizes (centralized)
  static ValidationResult validateCompressedTotals({
    required int imagesBytes,
    required int videoBytes,
    int existingCompressedBytes = 0,
  }) =>
      _performValidateCompressedTotals(
        imagesBytes: imagesBytes,
        videoBytes: videoBytes,
        existingCompressedBytes: existingCompressedBytes,
      );

  /// Estimate compressed size for images (heavy: performs actual compression preview)
  static Future<int> estimateCompressedImagesTotal(
    List<File> images, {
    int quality = 85,
  }) =>
      _performEstimateCompressedImagesTotal(
        images,
        quality: quality,
      );

  /// Validate with compression estimate (uses preview; heavier)
  static Future<ValidationResult> validateWithCompressionEstimate({
    required List<File> newImages,
    required int existingCompressedBytes,
    int newVideoBytes = 0,
    int previewQuality = 85,
  }) =>
      _performValidateWithCompressionEstimate(
        newImages: newImages,
        existingCompressedBytes: existingCompressedBytes,
        newVideoBytes: newVideoBytes,
        previewQuality: previewQuality,
      );
}
