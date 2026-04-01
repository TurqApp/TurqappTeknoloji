part of 'scholarships_controller.dart';

abstract class _ScholarshipsControllerBase extends GetxController {
  final _state = _ScholarshipsControllerState();

  @override
  void onInit() {
    super.onInit();
    (this as ScholarshipsController)._handleOnInit();
  }

  @override
  void onClose() {
    (this as ScholarshipsController)._handleOnClose();
    super.onClose();
  }
}
