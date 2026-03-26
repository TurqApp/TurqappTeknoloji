part of 'editor_email_controller.dart';

class EditorEmailController extends GetxController {
  final _EditorEmailControllerState _state = _EditorEmailControllerState();

  @override
  void onInit() {
    super.onInit();
    _seedFromCurrentSources();
    unawaited(_EditorEmailControllerRuntimeX(this).fetchAndSetUserData());
  }

  @override
  void onClose() {
    _timer?.cancel();
    emailController.dispose();
    codeController.dispose();
    super.onClose();
  }
}
