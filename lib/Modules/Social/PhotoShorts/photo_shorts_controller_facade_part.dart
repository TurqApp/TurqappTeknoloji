part of 'photo_shorts_controller.dart';

PhotoShortsController ensurePhotoShortsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindPhotoShortsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    PhotoShortsController(),
    tag: tag,
    permanent: permanent,
  );
}

PhotoShortsController? maybeFindPhotoShortsController({String? tag}) {
  final isRegistered = Get.isRegistered<PhotoShortsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PhotoShortsController>(tag: tag);
}
