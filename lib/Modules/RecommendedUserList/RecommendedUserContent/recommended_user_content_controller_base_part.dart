part of 'recommended_user_content_controller.dart';

abstract class _RecommendedUserContentControllerBase extends GetxController {
  _RecommendedUserContentControllerBase({required String userID})
      : _state = _RecommendedUserContentControllerState() {
    _state.userID = userID;
  }

  final _RecommendedUserContentControllerState _state;

  @override
  void onInit() {
    super.onInit();
    unawaited((this as RecommendedUserContentController).getTakipStatus());
  }
}

class RecommendedUserContentController
    extends _RecommendedUserContentControllerBase {
  RecommendedUserContentController({required super.userID});

  Future<void> getTakipStatus() => _loadRecommendedUserFollowStatus(this);

  Future<void> follow() => _toggleRecommendedUserFollow(this);
}
