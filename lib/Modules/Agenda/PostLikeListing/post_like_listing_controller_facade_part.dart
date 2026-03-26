part of 'post_like_listing_controller.dart';

PostLikeListingController ensurePostLikeListingController({
  required String tag,
}) {
  final existing = maybeFindPostLikeListingController(tag: tag);
  if (existing != null) return existing;
  return Get.put(PostLikeListingController(postID: tag), tag: tag);
}

PostLikeListingController? maybeFindPostLikeListingController({
  required String tag,
}) {
  final isRegistered = Get.isRegistered<PostLikeListingController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PostLikeListingController>(tag: tag);
}

extension PostLikeListingControllerFacadePart on PostLikeListingController {
  void onSearchChanged(String value) =>
      _PostLikeListingControllerRuntimePart(this).onSearchChanged(value);

  Future<void> getLikes() =>
      _PostLikeListingControllerRuntimePart(this).getLikes();
}
