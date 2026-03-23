part of 'settings_controller.dart';

extension SettingsControllerEducationPart on SettingsController {
  Future<void> _initializeSettings() async {
    await loadEducationPreference();
    await _migrateEducationVisibility();
    await loadPasajPreferences();
  }

  Future<void> loadEducationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefKey);
    educationScreenIsOn.value = value ?? true;
  }

  Future<void> toggleEducationScreen() async {
    educationScreenIsOn.value = !educationScreenIsOn.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, educationScreenIsOn.value);
  }

  Future<void> setEducationScreen(bool value) async {
    educationScreenIsOn.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  Future<void> _migrateEducationVisibility() async {
    if (!educationScreenIsOn.value) {
      await setEducationScreen(true);
    }
  }
}
