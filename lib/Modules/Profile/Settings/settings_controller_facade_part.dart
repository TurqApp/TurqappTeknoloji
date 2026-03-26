part of 'settings_controller.dart';

SettingsController ensureSettingsController({bool permanent = false}) {
  final existing = maybeFindSettingsController();
  if (existing != null) return existing;
  return Get.put(SettingsController(), permanent: permanent);
}

SettingsController? maybeFindSettingsController() {
  final isRegistered = Get.isRegistered<SettingsController>();
  if (!isRegistered) return null;
  return Get.find<SettingsController>();
}
