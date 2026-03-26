part of 'social_profile_followers_controller.dart';

class SocialProfileFollowersController extends GetxController {
  final _state = _SocialProfileFollowersControllerState();

  SocialProfileFollowersController({
    required int initialPage,
    required String userID,
  }) {
    _configureSocialProfileFollowersController(
      this,
      initialPage: initialPage,
      userID: userID,
    );
  }

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
