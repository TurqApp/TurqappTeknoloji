import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String scoped(String key) => userScopedKey(key);

  tearDown(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('defaults education visibility to enabled for guest scope', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = SettingsController();

    await controller.loadEducationPreference();
    await controller.loadPasajPreferences();

    expect(controller.educationScreenIsOn.value, isTrue);
    expect(controller.pasajOrder, pasajTabs);
    expect(
        controller.pasajVisibility.values.every((visible) => visible), isTrue);
  });

  test('loads persisted education visibility from preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      scoped('educationScreenIsOn'): false,
    });
    final controller = SettingsController();

    await controller.loadEducationPreference();

    expect(controller.educationScreenIsOn.value, isFalse);
  });

  test('toggleEducationScreen persists the new value', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = SettingsController();
    await controller.loadEducationPreference();

    await controller.toggleEducationScreen();

    final prefs = await SharedPreferences.getInstance();
    expect(controller.educationScreenIsOn.value, isFalse);
    expect(prefs.getBool(scoped('educationScreenIsOn')), isFalse);
  });

  test('legacy pasaj visibility values are normalized on load', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      scoped('pasajVisibility'): <String>['Market', 'Burslar'],
    });
    final controller = SettingsController();

    await controller.loadPasajPreferences();

    expect(controller.pasajVisibility[PasajTabIds.market], isFalse);
    expect(controller.pasajVisibility[PasajTabIds.scholarships], isFalse);
    expect(controller.pasajVisibility[PasajTabIds.jobFinder], isTrue);
  });
}
