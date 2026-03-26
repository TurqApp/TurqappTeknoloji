part of 'sign_in_controller.dart';

class SignInController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static SignInController ensure({String? tag, bool permanent = false}) =>
      _ensureSignInControllerFacade(tag: tag, permanent: permanent);

  static SignInController? maybeFind({String? tag}) =>
      _maybeFindSignInControllerFacade(tag: tag);

  final _controllers = _SignInTextControllers();
  final _focuses = _SignInFocusNodes();
  final _state = _SignInStateFields();

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
