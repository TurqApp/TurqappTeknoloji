part of 'upload_validation_service.dart';

ValidationResult _performValidateCompressedTotals({
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

Future<int> _performEstimateCompressedImagesTotal(
  List<File> images, {
  int quality = 85,
}) async {
  var total = 0;
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
      final size = await imgFile.length();
      total += (size * 0.6).round();
    }
  }
  return total;
}

Future<ValidationResult> _performValidateWithCompressionEstimate({
  required List<File> newImages,
  required int existingCompressedBytes,
  int newVideoBytes = 0,
  int previewQuality = 85,
}) async {
  final imagesBytes =
      await UploadValidationService.estimateCompressedImagesTotal(
    newImages,
    quality: previewQuality,
  );
  return UploadValidationService.validateCompressedTotals(
    imagesBytes: imagesBytes,
    videoBytes: newVideoBytes,
    existingCompressedBytes: existingCompressedBytes,
  );
}
