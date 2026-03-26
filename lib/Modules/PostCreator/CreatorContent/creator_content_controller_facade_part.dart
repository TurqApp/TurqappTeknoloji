part of 'creator_content_controller.dart';

CreatorContentController ensureCreatorContentController({
  String? tag,
  bool permanent = false,
}) =>
    _ensureCreatorContentController(tag: tag, permanent: permanent);

CreatorContentController? maybeFindCreatorContentController({String? tag}) =>
    _maybeFindCreatorContentController(tag: tag);

CreatorContentController _ensureCreatorContentController({
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindCreatorContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CreatorContentController(),
    tag: tag,
    permanent: permanent,
  );
}

CreatorContentController? _maybeFindCreatorContentController({String? tag}) =>
    Get.isRegistered<CreatorContentController>(tag: tag)
        ? Get.find<CreatorContentController>(tag: tag)
        : null;
