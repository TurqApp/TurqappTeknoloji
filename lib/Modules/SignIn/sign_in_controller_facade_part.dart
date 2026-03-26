part of 'sign_in_controller.dart';

SignInController _ensureSignInControllerFacade({
  String? tag,
  bool permanent = false,
}) =>
    _maybeFindSignInControllerFacade(tag: tag) ??
    Get.put(SignInController(), tag: tag, permanent: permanent);

SignInController? _maybeFindSignInControllerFacade({String? tag}) =>
    Get.isRegistered<SignInController>(tag: tag)
        ? Get.find<SignInController>(tag: tag)
        : null;

void _handleSignInControllerInit(SignInController controller) {
  controller._handleLifecycleInit();
}

void _handleSignInControllerClose(SignInController controller) {
  controller._handleLifecycleClose();
}
