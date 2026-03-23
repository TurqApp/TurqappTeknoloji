import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../upload_constants.dart';

part 'media_compression_service_core_part.dart';
part 'media_compression_service_batch_part.dart';

enum CompressionQuality {
  ultra(95, 'compression_quality.ultra'),
  high(85, 'compression_quality.high'),
  medium(70, 'compression_quality.medium'),
  low(50, 'compression_quality.low');

  const CompressionQuality(this.value, this.labelKey);
  final int value;
  final String labelKey;
  String get label => labelKey.tr;
}

class CompressionResult {
  final Uint8List compressedData;
  final int originalSize;
  final int compressedSize;
  final double compressionRatio;
  final int width;
  final int height;
  final String format;

  CompressionResult({
    required this.compressedData,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    required this.width,
    required this.height,
    required this.format,
  });

  double get spaceSavedPercent => (1 - compressionRatio) * 100;
  String get spaceSavedText =>
      '${spaceSavedPercent.toStringAsFixed(1)}% tasarruf';
}

class MediaCompressionService {
  /// Compress image with smart quality adjustment
  static Future<CompressionResult> compressImage({
    required File imageFile,
    CompressionQuality? targetQuality,
    int? maxWidth,
    int? maxHeight,
    bool autoQuality = true,
  }) =>
      _performCompressImage(
        imageFile: imageFile,
        targetQuality: targetQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        autoQuality: autoQuality,
      );

  /// Compress multiple images efficiently
  static Future<List<CompressionResult>> compressImages({
    required List<File> imageFiles,
    CompressionQuality? quality,
    Function(int current, int total)? onProgress,
  }) =>
      _performCompressImages(
        imageFiles: imageFiles,
        quality: quality,
        onProgress: onProgress,
      );

  /// Calculate optimal quality based on image characteristics
  static int _calculateOptimalQuality(int originalSize, int width, int height) {
    final pixels = width * height;
    final bytesPerPixel = originalSize / pixels;

    // High-detail images (photos) can use lower quality
    if (bytesPerPixel > 3) {
      if (originalSize > 5 * 1024 * 1024) return 70; // 5MB+
      if (originalSize > 2 * 1024 * 1024) return 75; // 2MB+
      return 80;
    }

    if (pixels > 2000000) return 85; // 2MP+
    if (pixels > 1000000) return 90; // 1MP+

    return UploadConstants.defaultImageQuality;
  }

  /// Get compression preview without actually compressing
  static Future<Map<String, dynamic>> getCompressionPreview(File imageFile) =>
      _performGetCompressionPreview(imageFile);

  /// Smart batch compression with size target
  static Future<List<CompressionResult>> smartBatchCompress({
    required List<File> imageFiles,
    required int targetTotalSize,
    Function(int current, int total, String status)? onProgress,
  }) =>
      _performSmartBatchCompress(
        imageFiles: imageFiles,
        targetTotalSize: targetTotalSize,
        onProgress: onProgress,
      );

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes B';
    }
  }
}
