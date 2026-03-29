part of 'social_profile_followers_controller.dart';

abstract class _SocialProfileFollowersControllerBase extends GetxController {
  _SocialProfileFollowersControllerBase({
    required int initialPage,
    required String userID,
  }) {
    _configureSocialProfileFollowersController(
      this as SocialProfileFollowersController,
      initialPage: initialPage,
      userID: userID,
    );
  }

  final _state = _SocialProfileFollowersControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleSocialProfileFollowersControllerOnInit(
      this as SocialProfileFollowersController,
    );
  }

  @override
  void onClose() {
    _handleSocialProfileFollowersControllerOnClose(
      this as SocialProfileFollowersController,
    );
    super.onClose();
  }
}

class SocialProfileFollowersController
    extends _SocialProfileFollowersControllerBase {
  SocialProfileFollowersController({
    required super.initialPage,
    required super.userID,
  });
}
