part of 'edit_profile_controller.dart';

class EditProfileController extends GetxController {
  final _state = _EditProfileControllerState();

  final userService = CurrentUserService.instance;
  final UserRepository _userRepository = UserRepository.ensure();

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
