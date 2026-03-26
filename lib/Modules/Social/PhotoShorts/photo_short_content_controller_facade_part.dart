part of 'photo_short_content_controller.dart';

PhotoShortsContentController ensurePhotoShortsContentController({
  required PostsModel model,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindPhotoShortsContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    PhotoShortsContentController(model: model),
    tag: tag,
    permanent: permanent,
  );
}

PhotoShortsContentController? maybeFindPhotoShortsContentController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<PhotoShortsContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PhotoShortsContentController>(tag: tag);
}
