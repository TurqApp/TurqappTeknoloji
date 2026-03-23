part of 'pasaj_settings_view.dart';

extension PasajSettingsViewLifecyclePart on _PasajSettingsViewState {
  @override
  void initState() {
    super.initState();
    final existingController = SettingsController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = SettingsController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(SettingsController.maybeFind(), controller)) {
      Get.delete<SettingsController>(force: true);
    }
    super.dispose();
  }
}
