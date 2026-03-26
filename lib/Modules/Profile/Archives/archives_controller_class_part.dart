part of 'archives_controller.dart';

class ArchiveController extends GetxController {
  final _state = _ArchiveControllerState();

  static ArchiveController ensure({bool permanent = false}) =>
      ensureArchiveController(permanent: permanent);

  static ArchiveController? maybeFind() => maybeFindArchiveController();

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
