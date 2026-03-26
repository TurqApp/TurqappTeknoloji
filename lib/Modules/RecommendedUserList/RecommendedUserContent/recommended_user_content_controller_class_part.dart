part of 'recommended_user_content_controller.dart';

class RecommendedUserContentController
    extends _RecommendedUserContentControllerBase {
  RecommendedUserContentController({required super.userID});

  Future<void> getTakipStatus() => _loadRecommendedUserFollowStatus(this);

  Future<void> follow() => _toggleRecommendedUserFollow(this);
}
