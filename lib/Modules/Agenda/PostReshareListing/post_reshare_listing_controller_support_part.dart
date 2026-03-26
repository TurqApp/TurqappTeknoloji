part of 'post_reshare_listing_controller.dart';

PostReshareListingController _ensurePostReshareListingController({
  required String tag,
}) {
  final existing = _maybeFindPostReshareListingController(tag: tag);
  if (existing != null) return existing;
  return Get.put(PostReshareListingController(postID: tag), tag: tag);
}

PostReshareListingController? _maybeFindPostReshareListingController({
  required String tag,
}) {
  final isRegistered = Get.isRegistered<PostReshareListingController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PostReshareListingController>(tag: tag);
}

_PostReshareListingControllerState _buildPostReshareListingControllerState({
  required String postID,
}) {
  return _PostReshareListingControllerState(postID: postID);
}

void _handlePostReshareListingOnInit(PostReshareListingController controller) {
  _PostReshareListingControllerRuntimePart.onInit(controller);
}

void _handlePostReshareListingOnClose(PostReshareListingController controller) {
  _PostReshareListingControllerRuntimePart.onClose(controller);
}

void _ensurePostReshareQuotesLoaded(PostReshareListingController controller) {
  _PostReshareListingControllerRuntimePart.ensureQuotesLoaded(controller);
}

Future<void> _loadMorePostReshares(
  PostReshareListingController controller, {
  bool initial = false,
}) {
  return _PostReshareListingControllerRuntimePart.loadMoreReshares(
    controller,
    initial: initial,
  );
}

Future<void> _loadMorePostQuotes(
  PostReshareListingController controller, {
  bool initial = false,
}) {
  return _PostReshareListingControllerRuntimePart.loadMoreQuotes(
    controller,
    initial: initial,
  );
}
