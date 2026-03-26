part of 'settings_controller.dart';

SettingsController ensureSettingsController({bool permanent = false}) =>
    maybeFindSettingsController() ??
    Get.put(SettingsController(), permanent: permanent);

SettingsController? maybeFindSettingsController() =>
    Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;
