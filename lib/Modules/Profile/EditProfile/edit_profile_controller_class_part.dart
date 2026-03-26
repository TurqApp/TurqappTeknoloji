part of 'edit_profile_controller.dart';

class EditProfileController extends GetxController {
  static EditProfileController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      EditProfileController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static EditProfileController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<EditProfileController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<EditProfileController>(tag: tag);
  }

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
