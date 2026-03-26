part of 'social_profile_followers_controller.dart';

abstract class _SocialProfileFollowersControllerBase extends GetxController {
  _SocialProfileFollowersControllerBase({
    required int initialPage,
    required String userID,
  }) {
    _configureSocialProfileFollowersController(
      this,
      initialPage: initialPage,
      userID: userID,
    );
  }

  final _state = _SocialProfileFollowersControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleSocialProfileFollowersControllerOnInit(this);
  }

  @override
  void onClose() {
    _handleSocialProfileFollowersControllerOnClose(this);
    super.onClose();
  }
}
