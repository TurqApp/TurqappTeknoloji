part of 'my_q_r_code_controller.dart';

abstract class _MyQRCodeControllerBase extends GetxController {
  final CurrentUserService userService = CurrentUserService.instance;
  final ShortLinkService _shortLinkService = ShortLinkService();
  final RxString profileLink = ''.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited((this as MyQRCodeController)._handleOnInit());
  }
}
