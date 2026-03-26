part of 'editor_phone_number_controller.dart';

class EditorPhoneNumberController extends GetxController {
  final _state = _EditorPhoneNumberControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleEditorPhoneOnInit(this);
  }

  @override
  void onClose() {
    _disposeEditorPhoneController(this);
    super.onClose();
  }
}
