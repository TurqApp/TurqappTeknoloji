part of 'url_post_maker_controller.dart';

UrlPostMakerController ensureUrlPostMakerController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindUrlPostMakerController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    UrlPostMakerController(),
    tag: tag,
    permanent: permanent,
  );
}

UrlPostMakerController? maybeFindUrlPostMakerController({String? tag}) {
  final isRegistered = Get.isRegistered<UrlPostMakerController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<UrlPostMakerController>(tag: tag);
}
