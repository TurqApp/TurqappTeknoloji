part of 'post_reshare_listing_controller.dart';

const int _postReshareListingPageSize = 20;

PostReshareListingController ensurePostReshareListingController({
  required String tag,
}) =>
    _ensurePostReshareListingController(tag: tag);

PostReshareListingController? maybeFindPostReshareListingController({
  required String tag,
}) =>
    _maybeFindPostReshareListingController(tag: tag);

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

extension PostReshareListingControllerSupportPart
    on PostReshareListingController {
  void ensureQuotesLoaded() =>
      _PostReshareListingControllerRuntimePart.ensureQuotesLoaded(this);

  Future<void> loadMoreReshares({bool initial = false}) {
    return _PostReshareListingControllerRuntimePart.loadMoreReshares(
      this,
      initial: initial,
    );
  }

  Future<void> loadMoreQuotes({bool initial = false}) {
    return _PostReshareListingControllerRuntimePart.loadMoreQuotes(
      this,
      initial: initial,
    );
  }
}
