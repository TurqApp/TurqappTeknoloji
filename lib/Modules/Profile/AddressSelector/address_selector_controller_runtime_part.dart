part of 'address_selector_controller.dart';

AddressSelectorController? _maybeFindAddressSelectorController() {
  final isRegistered = Get.isRegistered<AddressSelectorController>();
  if (!isRegistered) return null;
  return Get.find<AddressSelectorController>();
}

AddressSelectorController _ensureAddressSelectorController({
  bool permanent = false,
}) {
  final existing = _maybeFindAddressSelectorController();
  if (existing != null) return existing;
  return Get.put(
    AddressSelectorController(),
    permanent: permanent,
  );
}

void _handleAddressSelectorControllerInit(
    AddressSelectorController controller) {
  controller.addressController.addListener(() {
    controller.currentLength.value = controller.addressController.text.length;
  });

  final current = CurrentUserService.instance.currentUser;
  if (current != null && isCurrentUserId(current.userID)) {
    controller.addressController.text = current.adres;
  }

  controller._userRepository
      .getUserRaw(CurrentUserService.instance.effectiveUserId)
      .then((data) {
    controller.addressController.text =
        ((data ?? const {})['adres'] ?? '').toString();
  });
}

void _handleAddressSelectorControllerClose(
  AddressSelectorController controller,
) {
  controller.addressController.dispose();
}

Future<void> _setAddressSelectorData(
    AddressSelectorController controller) async {
  await controller._userRepository.updateUserFields(
    CurrentUserService.instance.effectiveUserId,
    {'adres': controller.addressController.text},
  );
  ensureProfileManifestSyncService().scheduleCurrentUserSync(
    reason: 'address_update',
  );

  Get.back();
}
