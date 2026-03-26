part of 'optical_form_entry_controller.dart';

class OpticalFormEntryController extends GetxController {
  static OpticalFormEntryController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      OpticalFormEntryController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static OpticalFormEntryController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<OpticalFormEntryController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<OpticalFormEntryController>(tag: tag);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();
  final search = TextEditingController();
  final focusNode = FocusNode();
  final searchText = ''.obs;
  final model = Rx<OpticalFormModel?>(null);
  final fullName = ''.obs;
  final avatarUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
