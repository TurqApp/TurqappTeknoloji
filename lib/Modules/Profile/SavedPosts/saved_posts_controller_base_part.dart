part of 'saved_posts_controller.dart';

abstract class _SavedPostsControllerBase extends GetxController {
  final _SavedPostsControllerState _state = _SavedPostsControllerState();

  @override
  void onInit() {
    super.onInit();
    (this as SavedPostsController)._handleOnInit();
  }

  @override
  Future<void> refresh() async {
    await (this as SavedPostsController)._refreshSavedPosts();
  }

  @override
  void onClose() {
    (this as SavedPostsController)._handleOnClose();
    super.onClose();
  }
}
