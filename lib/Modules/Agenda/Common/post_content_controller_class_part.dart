part of 'post_content_controller.dart';

class PostContentController extends GetxController {
  final _PostContentShellState _shellState;

  PostContentController({
    required PostsModel model,
    bool enableLegacyCommentSync = false,
    bool scrollFeedToTopOnReshare = false,
  }) : _shellState = _PostContentShellState(
          model: model,
          enableLegacyCommentSync: enableLegacyCommentSync,
          scrollFeedToTopOnReshare: scrollFeedToTopOnReshare,
        );

  @protected
  void onPostInitialized() {}
  @protected
  void onPostFrameBound() {}
  @protected
  Future<void> onReshareAdded(String? uid, {String? targetPostId}) async =>
      _performOnReshareAdded(uid, targetPostId: targetPostId);
  @protected
  Future<void> onReshareRemoved(String? uid, {String? targetPostId}) async {}

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
