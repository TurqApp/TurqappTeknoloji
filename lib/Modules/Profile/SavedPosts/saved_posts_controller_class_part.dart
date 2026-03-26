part of 'saved_posts_controller.dart';

class SavedPostsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  static SavedPostsController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      SavedPostsController(),
      permanent: permanent,
    );
  }

  static SavedPostsController? maybeFind() {
    final isRegistered = Get.isRegistered<SavedPostsController>();
    if (!isRegistered) return null;
    return Get.find<SavedPostsController>();
  }

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
