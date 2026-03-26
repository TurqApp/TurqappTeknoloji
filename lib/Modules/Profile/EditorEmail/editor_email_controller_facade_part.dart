part of 'editor_email_controller.dart';

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
