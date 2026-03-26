part of 'archives_controller.dart';

class ArchiveController extends GetxController {
  static ArchiveController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ArchiveController());
  }

  static ArchiveController? maybeFind() {
    final isRegistered = Get.isRegistered<ArchiveController>();
    if (!isRegistered) return null;
    return Get.find<ArchiveController>();
  }

  final _state = _ArchiveControllerState();

  @override
  void onInit() {
    super.onInit();
    _ArchiveControllerLifecyclePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _ArchiveControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }
}
