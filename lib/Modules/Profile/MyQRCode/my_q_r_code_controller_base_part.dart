part of 'my_q_r_code_controller.dart';

abstract class _MyQRCodeControllerBase extends GetxController {
  @override
  void onInit() {
    super.onInit();
    unawaited((this as MyQRCodeController)._handleOnInit());
  }
}
