part of 'following_followers_controller.dart';

class FollowingFollowersController extends GetxController {
  final _FollowingFollowersControllerState _state;

  FollowingFollowersController({
    required String userId,
    required int initialPage,
  }) : _state = _buildFollowingFollowersControllerState(
          userId: userId,
          initialPage: initialPage,
        );

  @override
  void onInit() {
    super.onInit();
    _handleFollowingFollowersControllerInit(this);
  }

  @override
  void onClose() {
    _handleFollowingFollowersControllerClose(this);
    super.onClose();
  }
}
