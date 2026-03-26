part of 'post_content_controller.dart';

class PostContentController extends _PostContentControllerBase {
  PostContentController({
    required super.model,
    super.enableLegacyCommentSync = false,
    super.scrollFeedToTopOnReshare = false,
  });

  Future<void> onReshareAdded(
    String? uid, {
    String? targetPostId,
  }) async {
    await _performOnReshareAdded(uid, targetPostId: targetPostId);
  }

  @override
  void onInit() {
    super.onInit();
    _handlePostContentInit();
  }

  @override
  void onClose() {
    _handlePostContentClose();
    super.onClose();
  }
}
