part of 'social_profile_controller.dart';

abstract class _SocialProfileControllerBase extends GetxController {
  _SocialProfileControllerBase({required String userID})
      : _shellState = _SocialProfileShellState(userID: userID);

  final _SocialProfileShellState _shellState;

  @override
  void onInit() {
    super.onInit();
    (this as SocialProfileController)._handleLifecycleInit();
  }

  @override
  void onClose() {
    (this as SocialProfileController)._handleLifecycleClose();
    super.onClose();
  }
}
