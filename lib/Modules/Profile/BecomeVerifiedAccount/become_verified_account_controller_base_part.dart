part of 'become_verified_account_controller.dart';

abstract class _BecomeVerifiedAccountControllerBase extends GetxController {
  final _state = _BecomeVerifiedAccountControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleBecomeVerifiedAccountInit(this as BecomeVerifiedAccountController);
  }

  @override
  void onClose() {
    _handleBecomeVerifiedAccountClose(this as BecomeVerifiedAccountController);
    super.onClose();
  }
}
