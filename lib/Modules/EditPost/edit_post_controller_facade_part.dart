part of 'edit_post_controller.dart';

EditPostController ensureEditPostController({
  required EditPostModel model,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindEditPostController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    EditPostController(model: model),
    tag: tag,
    permanent: permanent,
  );
}

EditPostController? maybeFindEditPostController({String? tag}) =>
    Get.isRegistered<EditPostController>(tag: tag)
        ? Get.find<EditPostController>(tag: tag)
        : null;
