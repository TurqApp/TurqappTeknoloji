import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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
    _syncFromCurrentUser();
    _userWorker = ever(userService.currentUserRx, (_) {
      _syncFromCurrentUser();
    });
  }

  void _syncFromCurrentUser() {
    final current = userService.currentUser;
    isEmailVisible.value = current?.mailIzin == true;
    isCallVisible.value = current?.aramaIzin == true;
  }

  Future<void> toggleEmailVisibility() async {
    final next = !isEmailVisible.value;
    isEmailVisible.value = next;
    await userService.updateFields({
      "mailIzin": next,
      "preferences.mailIzin": next,
    });
  }

  Future<void> toggleCallVisibility() async {
    final next = !isCallVisible.value;
    isCallVisible.value = next;
    await userService.updateFields({
      "aramaIzin": next,
      "preferences.aramaIzin": next,
    });
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    super.onClose();
  }
}
