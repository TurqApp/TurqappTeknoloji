part of 'edit_profile_controller.dart';

abstract class _EditProfileControllerBase extends GetxController {
  final _state = _EditProfileControllerState();

  final userService = CurrentUserService.instance;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    (this as EditProfileController)._handleLifecycleInit();
  }

  @override
  void onClose() {
    (this as EditProfileController)._handleLifecycleClose();
    super.onClose();
  }
}
