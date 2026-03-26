part of 'deneme_turleri_listesi_controller.dart';

DenemeTurleriListesiController ensureDenemeTurleriListesiController({
  required String tag,
  required String sinavTuru,
  bool permanent = false,
}) {
  final existing = maybeFindDenemeTurleriListesiController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    DenemeTurleriListesiController(sinavTuru: sinavTuru),
    tag: tag,
    permanent: permanent,
  );
}

DenemeTurleriListesiController? maybeFindDenemeTurleriListesiController({
  required String tag,
}) {
  final isRegistered =
      Get.isRegistered<DenemeTurleriListesiController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<DenemeTurleriListesiController>(tag: tag);
}
