part of 'liked_posts_controller.dart';

abstract class _LikedPostsControllerBase extends GetxController {
  final _LikedPostsControllerState _state = _LikedPostsControllerState();

  @override
  void onInit() {
    super.onInit();
    _LikedPostsControllerLifecyclePart(this as LikedPostControllers)
        .handleOnInit();
  }

  @override
  Future<void> refresh() async {
    await _LikedPostsControllerDataPart(this as LikedPostControllers)
        .refreshLikedPosts();
  }

  @override
  void onClose() {
    _LikedPostsControllerLifecyclePart(this as LikedPostControllers)
        .handleOnClose();
    super.onClose();
  }
}
