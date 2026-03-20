import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';

class SettingsController extends GetxController {
  RxBool educationScreenIsOn = true.obs;
  final pasajOrder = pasajTabs.obs;
  final pasajVisibility = <String, bool>{}.obs;

  static const _prefKeyPrefix = "educationScreenIsOn";
  static const _pasajOrderKeyPrefix = "pasajOrder";
  static const _pasajVisibilityKeyPrefix = "pasajVisibility";
  static const _pasajOrderVersionKeyPrefix = "pasajOrderVersion";
  static const _currentPasajOrderVersion = 4;

  String get _activeUid {
    return activeUserScope();
  }

  String get _prefKey => '$_prefKeyPrefix:$_activeUid';
  String get _pasajOrderKey => '$_pasajOrderKeyPrefix:$_activeUid';
  String get _pasajVisibilityKey => '$_pasajVisibilityKeyPrefix:$_activeUid';
  String get _pasajOrderVersionKey => '$_pasajOrderVersionKeyPrefix:$_activeUid';

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
    final storedVersion = prefs.getInt(_pasajOrderVersionKey) ?? 0;
    final normalizedOrder = pasajTabs.toList(growable: false);
    pasajOrder.assignAll(normalizedOrder);
    if (storedVersion < _currentPasajOrderVersion) {
      await prefs.setStringList(_pasajOrderKey, normalizedOrder);
      await prefs.setInt(_pasajOrderVersionKey, _currentPasajOrderVersion);
    }

    final storedHidden = prefs.getStringList(_pasajVisibilityKey) ?? const [];
    final normalizedHidden = storedHidden
        .map(pasajLegacyTitleToId)
        .where(pasajTabs.contains)
        .toSet();
    pasajVisibility.assignAll({
      for (final title in pasajTabs) title: !normalizedHidden.contains(title),
    });
  }

  Future<void> setPasajTabVisibility(String title, bool isVisible) async {
    pasajVisibility[title] = isVisible;
    pasajVisibility.refresh();
    await _persistPasajPrefs();
  }

  Future<void> reorderPasajTabs(int oldIndex, int newIndex) async {
    pasajOrder.assignAll(pasajTabs);
  }

  Future<void> movePasajTabUp(int index) async {
    pasajOrder.assignAll(pasajTabs);
  }

  Future<void> movePasajTabDown(int index) async {
    pasajOrder.assignAll(pasajTabs);
  }

  Future<void> _persistPasajPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = pasajTabs
        .where((title) => !(pasajVisibility[title] ?? true))
        .toList(growable: false);
    await prefs.setStringList(_pasajOrderKey, pasajOrder);
    await prefs.setStringList(_pasajVisibilityKey, hidden);
    await prefs.setInt(_pasajOrderVersionKey, _currentPasajOrderVersion);
  }
}
