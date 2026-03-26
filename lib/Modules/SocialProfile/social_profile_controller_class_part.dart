part of 'social_profile_controller.dart';

class SocialProfileController extends GetxController {
  static SocialProfileController ensure({
    required String userID,
    String? tag,
    bool permanent = false,
  }) =>
      _ensureSocialProfileController(
          userID: userID, tag: tag, permanent: permanent);

  static SocialProfileController? maybeFind({String? tag}) =>
      _maybeFindSocialProfileController(tag: tag);

  final _SocialProfileShellState _shellState;

  SocialProfileController({required String userID})
      : _shellState = _SocialProfileShellState(userID: userID);

  @override
  void onInit() {
    super.onInit();
    _handleLifecycleInit();
  }

  @override
  void onClose() {
    _handleLifecycleClose();
    super.onClose();
  }
}
