part of 'recommended_user_content_controller.dart';

class RecommendedUserContentController extends GetxController {
  static RecommendedUserContentController ensure({
    required String userID,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureRecommendedUserContentController(
        userID: userID,
        tag: tag,
        permanent: permanent,
      );

  static RecommendedUserContentController? maybeFind({String? tag}) =>
      _maybeFindRecommendedUserContentController(tag: tag);

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
