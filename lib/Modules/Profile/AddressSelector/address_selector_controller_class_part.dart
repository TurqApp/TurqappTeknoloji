part of 'address_selector_controller.dart';

class AddressSelectorController extends GetxController {
  static AddressSelectorController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      AddressSelectorController(),
      permanent: permanent,
    );
  }

  static AddressSelectorController? maybeFind() {
    final isRegistered = Get.isRegistered<AddressSelectorController>();
    if (!isRegistered) return null;
    return Get.find<AddressSelectorController>();
  }

  final TextEditingController addressController = TextEditingController();
  final currentLength = 0.obs;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    addressController.addListener(() {
      currentLength.value = addressController.text.length;
    });

    final current = CurrentUserService.instance.currentUser;
    if (current != null && isCurrentUserId(current.userID)) {
      addressController.text = current.adres;
    }

    _userRepository
        .getUserRaw(CurrentUserService.instance.effectiveUserId)
        .then((data) {
      addressController.text = ((data ?? const {})["adres"] ?? "").toString();
    });
  }

  @override
  void onClose() {
    addressController.dispose();
    super.onClose();
  }

  Future<void> setData() async {
    await _userRepository.updateUserFields(
      CurrentUserService.instance.effectiveUserId,
      {"adres": addressController.text},
    );

    Get.back();
  }
}
