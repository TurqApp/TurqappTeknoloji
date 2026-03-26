part of 'editor_email_controller.dart';

abstract class _EditorEmailControllerBase extends GetxController {
  final _EditorEmailControllerState _state = _EditorEmailControllerState();

  @override
  void onInit() {
    super.onInit();
    final controller = this as EditorEmailController;
    controller._seedFromCurrentSources();
    unawaited(_EditorEmailControllerRuntimeX(controller).fetchAndSetUserData());
  }

  @override
  void onClose() {
    _state.timer?.cancel();
    _state.emailController.dispose();
    _state.codeController.dispose();
    super.onClose();
  }
}
