part of 'pasaj_settings_view.dart';

extension PasajSettingsViewLifecyclePart on _PasajSettingsViewState {
  void _handleInitState() {
    final existingController = SettingsController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = SettingsController.ensure();
      _ownsController = true;
    }
  }

  void _handleDispose() {
    if (_ownsController &&
        identical(SettingsController.maybeFind(), controller)) {
      Get.delete<SettingsController>(force: true);
    }
  }
}
