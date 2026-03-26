part of 'recommended_user_content_controller.dart';

class RecommendedUserContentController extends GetxController {
  final _state = _RecommendedUserContentControllerState();

  RecommendedUserContentController({required String userID}) {
    this.userID = userID;
  }

  @override
  void onInit() {
    super.onInit();
    getTakipStatus();
  }

  Future<void> getTakipStatus() => _loadRecommendedUserFollowStatus(this);

  Future<void> follow() => _toggleRecommendedUserFollow(this);
}
