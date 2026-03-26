part of 'post_content_controller.dart';

abstract class _PostContentControllerBase extends GetxController {
  _PostContentControllerBase({
    required PostsModel model,
    required bool enableLegacyCommentSync,
    required bool scrollFeedToTopOnReshare,
  }) : _shellState = _PostContentShellState(
          model: model,
          enableLegacyCommentSync: enableLegacyCommentSync,
          scrollFeedToTopOnReshare: scrollFeedToTopOnReshare,
        );

  final _PostContentShellState _shellState;

  @override
  void onInit() {
    super.onInit();
    (this as PostContentController)._handlePostContentInit();
  }

  @override
  void onClose() {
    (this as PostContentController)._handlePostContentClose();
    super.onClose();
  }

  void onPostInitialized() {}

  void onPostFrameBound() {}

  Future<void> onReshareRemoved(
    String? uid, {
    String? targetPostId,
  }) async {}
}
