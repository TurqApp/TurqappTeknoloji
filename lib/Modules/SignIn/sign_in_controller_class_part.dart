part of 'sign_in_controller.dart';

class SignInController extends GetxController
    with GetSingleTickerProviderStateMixin, _SignInControllerBasePart {
  static SignInController ensure({String? tag, bool permanent = false}) =>
      _ensureSignInControllerFacade(tag: tag, permanent: permanent);

  static SignInController? maybeFind({String? tag}) =>
      _maybeFindSignInControllerFacade(tag: tag);

  @override
  void onInit() {
    super.onInit();
    _handleSignInControllerInit(this);
  }

  @override
  void onClose() {
    _handleSignInControllerClose(this);
    super.onClose();
  }
}
