part of 'profile_contant_controller.dart';

class ProfileContactController extends GetxController {
  static ProfileContactController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ProfileContactController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static ProfileContactController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ProfileContactController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ProfileContactController>(tag: tag);
  }

  var isEmailVisible = false.obs;
  var isCallVisible = false.obs;
  final userService = CurrentUserService.instance;
  Worker? _userWorker;

  @override
  void onInit() {
    super.onInit();
    _handleProfileContactControllerInit(this);
  }

  Future<void> toggleEmailVisibility() => _toggleProfileEmailVisibility(this);

  Future<void> toggleCallVisibility() => _toggleProfileCallVisibility(this);

  @override
  void onClose() {
    _handleProfileContactControllerClose(this);
    super.onClose();
  }
}
