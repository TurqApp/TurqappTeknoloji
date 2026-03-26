part of 'address_selector_controller.dart';

abstract class _AddressSelectorControllerBase extends GetxController {
  final _state = _AddressSelectorControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleAddressSelectorControllerInit(this as AddressSelectorController);
  }

  @override
  void onClose() {
    _handleAddressSelectorControllerClose(this as AddressSelectorController);
    super.onClose();
  }
}
