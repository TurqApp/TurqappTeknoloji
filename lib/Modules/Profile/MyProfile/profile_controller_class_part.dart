part of 'profile_controller.dart';

class ProfileController extends _ProfileControllerBase {
  static ProfileController ensure() =>
      maybeFind() ?? Get.put(ProfileController());

  static ProfileController? maybeFind() => Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : null;
}
