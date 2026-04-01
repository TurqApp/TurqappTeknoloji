part of 'short_content_controller.dart';

ShortContentController ensureShortContentController({
  required String postID,
  required PostsModel model,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindShortContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ShortContentController(postID: postID, model: model),
    tag: tag,
    permanent: permanent,
  );
}

ShortContentController? maybeFindShortContentController({String? tag}) {
  final isRegistered = Get.isRegistered<ShortContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ShortContentController>(tag: tag);
}
