part of 'policies_controller.dart';

class PoliciesController extends GetxController {
  static PoliciesController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PoliciesController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static PoliciesController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<PoliciesController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PoliciesController>(tag: tag);
  }

  final _state = _PoliciesControllerState();

  @override
  void onInit() {
    super.onInit();
    _handlePoliciesInit(this);
  }

  @override
  void onClose() {
    _handlePoliciesClose(this);
    super.onClose();
  }
}
