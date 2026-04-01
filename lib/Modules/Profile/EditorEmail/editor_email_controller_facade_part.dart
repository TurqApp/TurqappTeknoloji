part of 'editor_email_controller_library.dart';

EditorEmailController ensureEditorEmailController({bool permanent = false}) {
  final existing = maybeFindEditorEmailController();
  if (existing != null) return existing;
  return Get.put(
    EditorEmailController(),
    permanent: permanent,
  );
}

EditorEmailController? maybeFindEditorEmailController() {
  final isRegistered = Get.isRegistered<EditorEmailController>();
  if (!isRegistered) return null;
  return Get.find<EditorEmailController>();
}

extension EditorEmailControllerFacadePart on EditorEmailController {
  void _seedFromCurrentSources() =>
      _EditorEmailControllerRuntimeX(this).seedFromCurrentSources();

  Future<void> fetchAndSetUserData() =>
      _EditorEmailControllerRuntimeX(this).fetchAndSetUserData();

  Future<void> sendEmailCode() =>
      _EditorEmailControllerRuntimeX(this).sendEmailCode();

  Future<void> verifyAndConfirmEmail() =>
      _EditorEmailControllerRuntimeX(this).verifyAndConfirmEmail();
}
