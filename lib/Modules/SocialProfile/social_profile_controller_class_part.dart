part of 'social_profile_controller.dart';

class SocialProfileController extends GetxController {
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
