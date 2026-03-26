part of 'post_content_controller.dart';

class PostContentController extends GetxController {
  static PostContentController ensure({
    required String tag,
    required PostContentController Function() create,
  }) =>
      _ensurePostContentController(tag: tag, create: create);

  static PostContentController? maybeFind({required String tag}) =>
      _maybeFindPostContentController(tag: tag);

  static void invalidateUserProfileCache(String userId) =>
      _invalidatePostContentControllerUserProfileCache(userId);
  static void clearUserProfileCache() =>
      _clearPostContentControllerUserProfileCache();
  static void clearReshareUsersCache() =>
      _clearPostContentControllerReshareUsersCache();

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

  RxInt get editTime => _shellState.controllerState.editTime;
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
