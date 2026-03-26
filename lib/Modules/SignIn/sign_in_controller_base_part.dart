part of 'sign_in_controller.dart';

mixin _SignInControllerBasePart on GetxController {
  final _controllers = _SignInTextControllers();
  final _focuses = _SignInFocusNodes();
  final _state = _SignInStateFields();

  @override
  void onInit() {
    super.onInit();
    _handleSignInControllerInit(this as SignInController);
  }

  @override
  void onClose() {
    _handleSignInControllerClose(this as SignInController);
    super.onClose();
  }
}
