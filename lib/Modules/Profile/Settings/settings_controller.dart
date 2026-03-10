import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';

class SettingsController extends GetxController {
  RxBool educationScreenIsOn = true.obs;
  final pasajOrder = pasajTabs.obs;
  final pasajVisibility = <String, bool>{}.obs;

  static const _prefKey = "educationScreenIsOn";
  static const _pasajOrderKey = "pasajOrder";
  static const _pasajVisibilityKey = "pasajVisibility";

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadEducationPreference();
    await _migrateEducationVisibility();
    await loadPasajPreferences();
  }

  /// SharedPreferences'tan değeri oku
  Future<void> loadEducationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefKey);
    educationScreenIsOn.value = value ?? true; // default: true
  }

  Future<void> toggleEducationScreen() async {
    educationScreenIsOn.value = !educationScreenIsOn.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, educationScreenIsOn.value);
  }

  /// Direkt set etmek istersen (manuel)
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

  Future<void> loadPasajPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final storedOrder = prefs.getStringList(_pasajOrderKey) ?? const [];
    final normalizedOrder = <String>[
      ...storedOrder.where(pasajTabs.contains),
      ...pasajTabs.where((title) => !storedOrder.contains(title)),
    ];
    pasajOrder.assignAll(normalizedOrder);

    final storedHidden = prefs.getStringList(_pasajVisibilityKey) ?? const [];
    pasajVisibility.assignAll({
      for (final title in pasajTabs) title: !storedHidden.contains(title),
    });
  }

  Future<void> setPasajTabVisibility(String title, bool isVisible) async {
    pasajVisibility[title] = isVisible;
    pasajVisibility.refresh();
    await _persistPasajPrefs();
  }

  Future<void> reorderPasajTabs(int oldIndex, int newIndex) async {
    final items = pasajOrder.toList();
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    pasajOrder.assignAll(items);
    await _persistPasajPrefs();
  }

  Future<void> _persistPasajPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = pasajTabs
        .where((title) => !(pasajVisibility[title] ?? true))
        .toList(growable: false);
    await prefs.setStringList(_pasajOrderKey, pasajOrder);
    await prefs.setStringList(_pasajVisibilityKey, hidden);
  }
}
