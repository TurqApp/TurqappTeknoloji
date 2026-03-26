part of 'share_grid_controller.dart';

ShareGridController ensureShareGridController({
  required String postType,
  required String postID,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindShareGridController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ShareGridController(postType: postType, postID: postID),
    tag: tag,
    permanent: permanent,
  );
}

ShareGridController? maybeFindShareGridController({String? tag}) {
  final isRegistered = Get.isRegistered<ShareGridController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ShareGridController>(tag: tag);
}
