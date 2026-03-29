part of 'webp_upload_service.dart';

Future<Uint8List?> _performToWebpFromFile(
  File file, {
  required int quality,
}) async {
  try {
    final compressed = await FlutterImageCompress.compressWithFile(
      file.path,
      format: CompressFormat.webp,
      quality: quality,
    );
    return compressed == null ? null : Uint8List.fromList(compressed);
  } catch (e) {
    debugPrint('[WebP] file compress failed: $e');
    return null;
  }
}

Future<Uint8List?> _performToWebpFromBytes(
  Uint8List bytes, {
  required int quality,
  required int maxWidth,
  required int maxHeight,
}) async {
  try {
    Uint8List sourceBytes = Uint8List.fromList(bytes);
    final decoded = img.decodeImage(sourceBytes);
    if (decoded != null &&
        (decoded.width > maxWidth || decoded.height > maxHeight)) {
      final scale = math.min(
        maxWidth / decoded.width,
        maxHeight / decoded.height,
      );
      final resized = img.copyResize(
        decoded,
        width: math.max(1, (decoded.width * scale).round()),
        height: math.max(1, (decoded.height * scale).round()),
        interpolation: img.Interpolation.cubic,
      );
      sourceBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 92));
    }
    final compressed = await FlutterImageCompress.compressWithList(
      sourceBytes,
      format: CompressFormat.webp,
      quality: quality,
    );
    return Uint8List.fromList(compressed);
  } catch (e) {
    debugPrint('[WebP] bytes compress failed: $e');
    return null;
  }
}
