part of 'archives_controller.dart';

abstract class _ArchiveControllerBase extends GetxController {
  final _ArchiveControllerState _state = _ArchiveControllerState();

  @override
  void onInit() {
    super.onInit();
    _ArchiveControllerLifecyclePart(this as ArchiveController).handleOnInit();
  }

  @override
  void onClose() {
    _ArchiveControllerLifecyclePart(this as ArchiveController).handleOnClose();
    super.onClose();
  }
}
