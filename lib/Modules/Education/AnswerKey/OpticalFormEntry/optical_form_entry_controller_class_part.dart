part of 'optical_form_entry_controller.dart';

class OpticalFormEntryController extends GetxController {
  final _state = _OpticalFormEntryControllerState();

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
