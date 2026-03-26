part of 'settings_controller.dart';

class SettingsController extends GetxController {
  final _state = _SettingsControllerState();

  @override
  void onInit() {
    super.onInit();
    _initializeSettings();
  }
}
