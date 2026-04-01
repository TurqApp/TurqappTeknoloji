part of 'profile_contant_controller.dart';

class ProfileContactController extends GetxController {
  final _state = _ProfileContactControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleProfileContactControllerInit(this);
  }

  @override
  void onClose() {
    _handleProfileContactControllerClose(this);
    super.onClose();
  }
}
