part of 'following_followers_controller.dart';

class FollowingFollowersController extends _FollowingFollowersControllerBase {
  FollowingFollowersController({
    required String userId,
    required int initialPage,
  }) : super(
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
