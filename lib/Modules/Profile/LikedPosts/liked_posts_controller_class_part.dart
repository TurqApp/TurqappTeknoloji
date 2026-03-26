part of 'liked_posts_controller.dart';

class LikedPostControllers extends GetxController {
  static bool isSeriesPost(PostsModel post) => post.floodCount > 1;

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _LikedPostsControllerState();

  final UserPostLinkService _linkService = UserPostLinkService.ensure();

  @override
  void onInit() {
    super.onInit();
    _LikedPostsControllerLifecyclePart(this).handleOnInit();
  }

  @override
  Future<void> refresh() async {
    await _LikedPostsControllerDataPart(this).refreshLikedPosts();
  }

  @override
  void onClose() {
    _LikedPostsControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }
}
