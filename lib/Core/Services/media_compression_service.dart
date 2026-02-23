import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../upload_constants.dart';

enum CompressionQuality {
  ultra(95, 'Ultra'),
  high(85, 'Yüksek'),
  medium(70, 'Orta'),
  low(50, 'Düşük');

  const CompressionQuality(this.value, this.label);
  final int value;
  final String label;
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
  }) async {
    final originalBytes = await imageFile.readAsBytes();
    final originalSize = originalBytes.length;

    // Decode image
    final image = img.decodeImage(originalBytes);
    if (image == null) {
      throw Exception('Invalid image format');
    }

    // Compute target dimensions (keep aspect ratio) to not exceed limits
    var srcW = image.width;
    var srcH = image.height;
    final maxW = maxWidth ?? UploadConstants.maxImageWidth;
    final maxH = maxHeight ?? UploadConstants.maxImageHeight;
    int outW = srcW;
    int outH = srcH;
    if (srcW > maxW || srcH > maxH) {
      final scale = math.min(maxW / srcW, maxH / srcH);
      outW = math.max(1, (srcW * scale).round());
      outH = math.max(1, (srcH * scale).round());
    }

    // Determine optimal quality
    int quality = targetQuality?.value ?? UploadConstants.defaultImageQuality;

    if (autoQuality) {
      quality = _calculateOptimalQuality(originalSize, outW, outH);
    }

    // Prefer WebP using flutter_image_compress; fallback to JPEG
    Uint8List compressedData;
    String format = 'WEBP';
    try {
      final data = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        quality: quality,
        format: CompressFormat.webp,
        minWidth: outW,
        minHeight: outH,
      );
      if (data == null) throw Exception('compressWithFile returned null');
      compressedData = data;
    } catch (_) {
      // Fallback to pure-dart JPEG
      final resized = img.copyResize(
        image,
        width: outW,
        height: outH,
        interpolation: img.Interpolation.cubic,
      );
      compressedData =
          Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      format = 'JPEG';
    }

    // If still too large, reduce quality further
    if (compressedData.length > UploadConstants.maxImageSizeBytes &&
        quality > 30) {
      quality = math.max(30, quality - 15);
      try {
        final data = await FlutterImageCompress.compressWithFile(
          imageFile.path,
          quality: quality,
          format: CompressFormat.webp,
          minWidth: outW,
          minHeight: outH,
        );
        if (data == null) throw Exception('compressWithFile returned null');
        compressedData = data;
        format = 'WEBP';
      } catch (_) {
        final resized = img.copyResize(
          image,
          width: outW,
          height: outH,
          interpolation: img.Interpolation.cubic,
        );
        compressedData =
            Uint8List.fromList(img.encodeJpg(resized, quality: quality));
        format = 'JPEG';
      }
    }

    return CompressionResult(
      compressedData: compressedData,
      originalSize: originalSize,
      compressedSize: compressedData.length,
      compressionRatio: compressedData.length / originalSize,
      width: outW,
      height: outH,
      format: format,
    );
  }

  /// Compress multiple images efficiently
  static Future<List<CompressionResult>> compressImages({
    required List<File> imageFiles,
    CompressionQuality? quality,
    Function(int current, int total)? onProgress,
  }) async {
    final results = <CompressionResult>[];

    int totalOriginal = 0;
    int totalCompressed = 0;
    for (int i = 0; i < imageFiles.length; i++) {
      onProgress?.call(i + 1, imageFiles.length);

      final result = await compressImage(
        imageFile: imageFiles[i],
        targetQuality: quality,
      );

      results.add(result);

      if (kDebugMode) {
        debugPrint(
          '[ImageCompression] (#${i + 1}/${imageFiles.length}) '
          'src=${imageFiles[i].path.split('/').last} '
          'original=${_formatBytes(result.originalSize)} -> '
          '${result.format} ${_formatBytes(result.compressedSize)} '
          '(${((1 - result.compressionRatio) * 100).toStringAsFixed(1)}% saved) '
          'size=${result.width}x${result.height}',
        );
      }

      totalOriginal += result.originalSize;
      totalCompressed += result.compressedSize;
    }

    if (kDebugMode && imageFiles.isNotEmpty) {
      final saved =
          ((1 - (totalCompressed / totalOriginal)) * 100).toStringAsFixed(1);
      debugPrint('[ImageCompression] Batch summary: '
          'original=${_formatBytes(totalOriginal)} -> '
          '${_formatBytes(totalCompressed)} (%$saved saved), '
          'count=${imageFiles.length}');
    }

    return results;
  }

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
  static Future<Map<String, dynamic>> getCompressionPreview(
      File imageFile) async {
    final originalBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(originalBytes);

    if (image == null) {
      return {'error': 'Invalid image format'};
    }

    final qualities = [95, 85, 70, 50];
    final previews = <Map<String, dynamic>>[];

    for (final quality in qualities) {
      // Compute target dims
      var srcW = image.width;
      var srcH = image.height;
      var outW = srcW;
      var outH = srcH;
      if (srcW > UploadConstants.maxImageWidth ||
          srcH > UploadConstants.maxImageHeight) {
        final scale = math.min(UploadConstants.maxImageWidth / srcW,
            UploadConstants.maxImageHeight / srcH);
        outW = math.max(1, (srcW * scale).round());
        outH = math.max(1, (srcH * scale).round());
      }

      Uint8List compressed;
      String format = 'WEBP';
      try {
        final data = await FlutterImageCompress.compressWithList(
          originalBytes,
          quality: quality,
          format: CompressFormat.webp,
          minWidth: outW,
          minHeight: outH,
        );
        compressed = data;
      } catch (_) {
        final resized = img.copyResize(
          image,
          width: outW,
          height: outH,
          interpolation: img.Interpolation.cubic,
        );
        compressed =
            Uint8List.fromList(img.encodeJpg(resized, quality: quality));
        format = 'JPEG';
      }

      previews.add({
        'quality': quality,
        'size': compressed.length,
        'sizeText': _formatBytes(compressed.length),
        'format': format,
        'compressionRatio': compressed.length / originalBytes.length,
        'savings': ((1 - (compressed.length / originalBytes.length)) * 100)
            .toStringAsFixed(1),
      });
    }

    return {
      'original': {
        'size': originalBytes.length,
        'sizeText': _formatBytes(originalBytes.length),
        'width': image.width,
        'height': image.height,
      },
      'previews': previews,
    };
  }

  /// Smart batch compression with size target
  static Future<List<CompressionResult>> smartBatchCompress({
    required List<File> imageFiles,
    required int targetTotalSize,
    Function(int current, int total, String status)? onProgress,
  }) async {
    final results = <CompressionResult>[];
    int currentTotalSize = 0;
    final targetPerImage = targetTotalSize ~/ imageFiles.length;

    for (int i = 0; i < imageFiles.length; i++) {
      onProgress?.call(i + 1, imageFiles.length, 'Sıkıştırılıyor...');

      // Adjust quality based on remaining budget
      final remainingFiles = imageFiles.length - i;
      final remainingBudget = targetTotalSize - currentTotalSize;
      final budgetPerRemainingFile =
          remainingBudget ~/ math.max(1, remainingFiles);

      CompressionQuality quality = CompressionQuality.high;
      if (budgetPerRemainingFile < targetPerImage * 0.5) {
        quality = CompressionQuality.low;
      } else if (budgetPerRemainingFile < targetPerImage * 0.8) {
        quality = CompressionQuality.medium;
      }

      final result = await compressImage(
        imageFile: imageFiles[i],
        targetQuality: quality,
      );

      results.add(result);
      currentTotalSize += result.compressedSize;

      onProgress?.call(i + 1, imageFiles.length,
          'Tamamlandı: ${_formatBytes(currentTotalSize)} / ${_formatBytes(targetTotalSize)}');
    }

    return results;
  }

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
