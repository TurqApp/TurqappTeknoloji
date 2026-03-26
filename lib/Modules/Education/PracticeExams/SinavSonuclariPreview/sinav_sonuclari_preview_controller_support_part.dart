part of 'sinav_sonuclari_preview_controller.dart';

SinavSonuclariPreviewController _ensureSinavSonuclariPreviewController({
  required String tag,
  required SinavModel model,
  bool permanent = false,
}) {
  final existing = _maybeFindSinavSonuclariPreviewController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SinavSonuclariPreviewController(model: model),
    tag: tag,
    permanent: permanent,
  );
}

SinavSonuclariPreviewController? _maybeFindSinavSonuclariPreviewController({
  required String tag,
}) {
  final isRegistered =
      Get.isRegistered<SinavSonuclariPreviewController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SinavSonuclariPreviewController>(tag: tag);
}
