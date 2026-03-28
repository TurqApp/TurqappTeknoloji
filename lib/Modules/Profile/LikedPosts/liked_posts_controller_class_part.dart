part of 'liked_posts_controller_library.dart';

class LikedPostControllers extends _LikedPostsControllerBase {
  static bool isSeriesPost(PostsModel post) => _isLikedPostsSeriesPost(post);
}
