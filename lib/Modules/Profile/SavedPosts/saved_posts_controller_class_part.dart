part of 'saved_posts_controller.dart';

class SavedPostsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final _SavedPostsControllerState _state = _SavedPostsControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  Future<void> refresh() async {
    await _refreshSavedPosts();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
