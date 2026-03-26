part of 'policies_controller.dart';

abstract class _PoliciesControllerBase extends GetxController {
  final _state = _PoliciesControllerState();

  @override
  void onInit() {
    super.onInit();
    _handlePoliciesInit(this as PoliciesController);
  }

  @override
  void onClose() {
    _handlePoliciesClose(this as PoliciesController);
    super.onClose();
  }
}
