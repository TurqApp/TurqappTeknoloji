part of 'social_profile_followers_controller.dart';

class SocialProfileFollowersController extends GetxController {
  final _state = _SocialProfileFollowersControllerState();

  static SocialProfileFollowersController ensure({
    required int initialPage,
    required String userID,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureSocialProfileFollowersController(
        initialPage: initialPage,
        userID: userID,
        tag: tag,
        permanent: permanent,
      );

  static SocialProfileFollowersController? maybeFind({String? tag}) =>
      _maybeFindSocialProfileFollowersController(tag: tag);

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
