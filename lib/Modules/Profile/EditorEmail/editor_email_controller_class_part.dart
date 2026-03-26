part of 'editor_email_controller.dart';

class EditorEmailController extends GetxController {
  static EditorEmailController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      EditorEmailController(),
      permanent: permanent,
    );
  }

  static EditorEmailController? maybeFind() {
    final isRegistered = Get.isRegistered<EditorEmailController>();
    if (!isRegistered) return null;
    return Get.find<EditorEmailController>();
  }

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
