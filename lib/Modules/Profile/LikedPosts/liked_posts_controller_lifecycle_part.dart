part of 'liked_posts_controller_library.dart';

extension _LikedPostsControllerLifecyclePart on LikedPostControllers {
  void handleOnInit() => _bindAuth();

  void handleOnClose() {
    _likedSub?.cancel();
    _authSub?.cancel();
    pageController.dispose();
  }
}
