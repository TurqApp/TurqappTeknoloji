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
