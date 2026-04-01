part of 'media_compression_service.dart';

Future<List<CompressionResult>> _performCompressImages({
  required List<File> imageFiles,
  CompressionQuality? quality,
  Function(int current, int total)? onProgress,
}) async {
  final results = <CompressionResult>[];

  int totalOriginal = 0;
  int totalCompressed = 0;
  for (int i = 0; i < imageFiles.length; i++) {
    onProgress?.call(i + 1, imageFiles.length);

    final result = await MediaCompressionService.compressImage(
      imageFile: imageFiles[i],
      targetQuality: quality,
    );

    results.add(result);

    if (kDebugMode) {
      debugPrint(
        '[ImageCompression] (#${i + 1}/${imageFiles.length}) '
        'src=${imageFiles[i].path.split('/').last} '
        'original=${MediaCompressionService._formatBytes(result.originalSize)} -> '
        '${result.format} ${MediaCompressionService._formatBytes(result.compressedSize)} '
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
    debugPrint(
      '[ImageCompression] Batch summary: '
      'original=${MediaCompressionService._formatBytes(totalOriginal)} -> '
      '${MediaCompressionService._formatBytes(totalCompressed)} (%$saved saved), '
      'count=${imageFiles.length}',
    );
  }

  return results;
}

Future<Map<String, dynamic>> _performGetCompressionPreview(
    File imageFile) async {
  final originalBytes = await imageFile.readAsBytes();
  final image = img.decodeImage(originalBytes);

  if (image == null) {
    return <String, dynamic>{'error': 'Invalid image format'};
  }

  const qualities = <int>[95, 85, 70, 50];
  final previews = <Map<String, dynamic>>[];

  for (final quality in qualities) {
    var srcW = image.width;
    var srcH = image.height;
    var outW = srcW;
    var outH = srcH;
    if (srcW > UploadConstants.maxImageWidth ||
        srcH > UploadConstants.maxImageHeight) {
      final scale = math.min(
        UploadConstants.maxImageWidth / srcW,
        UploadConstants.maxImageHeight / srcH,
      );
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
      compressed = Uint8List.fromList(
        img.encodeJpg(resized, quality: quality),
      );
      format = 'JPEG';
    }

    previews.add(<String, dynamic>{
      'quality': quality,
      'size': compressed.length,
      'sizeText': MediaCompressionService._formatBytes(compressed.length),
      'format': format,
      'compressionRatio': compressed.length / originalBytes.length,
      'savings': ((1 - (compressed.length / originalBytes.length)) * 100)
          .toStringAsFixed(1),
    });
  }

  return <String, dynamic>{
    'original': <String, dynamic>{
      'size': originalBytes.length,
      'sizeText': MediaCompressionService._formatBytes(originalBytes.length),
      'width': image.width,
      'height': image.height,
    },
    'previews': previews,
  };
}

Future<List<CompressionResult>> _performSmartBatchCompress({
  required List<File> imageFiles,
  required int targetTotalSize,
  Function(int current, int total, String status)? onProgress,
}) async {
  final results = <CompressionResult>[];
  int currentTotalSize = 0;
  final targetPerImage = targetTotalSize ~/ imageFiles.length;

  for (int i = 0; i < imageFiles.length; i++) {
    onProgress?.call(i + 1, imageFiles.length, 'Sıkıştırılıyor...');

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

    final result = await MediaCompressionService.compressImage(
      imageFile: imageFiles[i],
      targetQuality: quality,
    );

    results.add(result);
    currentTotalSize += result.compressedSize;

    onProgress?.call(
      i + 1,
      imageFiles.length,
      'Tamamlandı: ${MediaCompressionService._formatBytes(currentTotalSize)} / ${MediaCompressionService._formatBytes(targetTotalSize)}',
    );
  }

  return results;
}
