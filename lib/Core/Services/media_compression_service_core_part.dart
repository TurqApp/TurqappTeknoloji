part of 'media_compression_service.dart';

Future<CompressionResult> _performCompressImage({
  required File imageFile,
  CompressionQuality? targetQuality,
  int? maxWidth,
  int? maxHeight,
  required bool autoQuality,
}) async {
  final originalBytes = await imageFile.readAsBytes();
  final originalSize = originalBytes.length;

  final image = img.decodeImage(originalBytes);
  if (image == null) {
    throw Exception('Invalid image format');
  }

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

  int quality = targetQuality?.value ?? UploadConstants.defaultImageQuality;
  if (autoQuality) {
    quality = MediaCompressionService._calculateOptimalQuality(
      originalSize,
      outW,
      outH,
    );
  }

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
    final resized = img.copyResize(
      image,
      width: outW,
      height: outH,
      interpolation: img.Interpolation.cubic,
    );
    compressedData = Uint8List.fromList(
      img.encodeJpg(resized, quality: quality),
    );
    format = 'JPEG';
  }

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
      compressedData = Uint8List.fromList(
        img.encodeJpg(resized, quality: quality),
      );
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
