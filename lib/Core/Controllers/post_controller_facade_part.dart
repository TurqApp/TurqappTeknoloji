part of 'post_controller.dart';

PostController ensurePostController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindPostController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    PostController(),
    tag: tag,
    permanent: permanent,
  );
}

PostController? maybeFindPostController({String? tag}) {
  final isRegistered = Get.isRegistered<PostController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PostController>(tag: tag);
}
