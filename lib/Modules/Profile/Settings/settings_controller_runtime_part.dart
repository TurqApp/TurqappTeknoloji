part of 'settings_controller.dart';

extension SettingsControllerRuntimePart on SettingsController {
  Future<void> _initializeSettings() async {
    await loadEducationPreference();
    await _migrateEducationVisibility();
    await loadPasajPreferences();
  }

  Future<void> loadEducationPreference() async {
    final preferences = ensureLocalPreferenceRepository();
    final value = await preferences.getBool(_prefKey);
    educationScreenIsOn.value = value ?? true;
  }

  Future<void> toggleEducationScreen() async {
    educationScreenIsOn.value = !educationScreenIsOn.value;
    final preferences = ensureLocalPreferenceRepository();
    await preferences.setBool(_prefKey, educationScreenIsOn.value);
  }

  Future<void> setEducationScreen(bool value) async {
    educationScreenIsOn.value = value;
    final preferences = ensureLocalPreferenceRepository();
    await preferences.setBool(_prefKey, value);
  }

  Future<void> _migrateEducationVisibility() async {
    if (!educationScreenIsOn.value) {
      await setEducationScreen(true);
    }
  }

  Future<void> loadPasajPreferences() async {
    final preferences = ensureLocalPreferenceRepository();
    final storedVersion = await preferences.getInt(_pasajOrderVersionKey) ?? 0;
    final normalizedOrder = pasajTabs.toList(growable: false);
    pasajOrder.assignAll(normalizedOrder);
    if (storedVersion < _currentPasajOrderVersion) {
      await preferences.setStringList(_pasajOrderKey, normalizedOrder);
      await preferences.setInt(
        _pasajOrderVersionKey,
        _currentPasajOrderVersion,
      );
    }

    final storedHidden =
        await preferences.getStringList(_pasajVisibilityKey) ?? const [];
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
    final preferences = ensureLocalPreferenceRepository();
    final hidden = pasajTabs
        .where((title) => !(pasajVisibility[title] ?? true))
        .toList(growable: false);
    await preferences.setStringList(_pasajOrderKey, pasajOrder);
    await preferences.setStringList(_pasajVisibilityKey, hidden);
    await preferences.setInt(
      _pasajOrderVersionKey,
      _currentPasajOrderVersion,
    );
  }
}

Future<Map<String, bool>> loadPasajVisibilitySnapshot() async {
  final existing = maybeFindSettingsController();
  if (existing != null && existing.pasajVisibility.isNotEmpty) {
    return <String, bool>{
      for (final title in pasajTabs)
        title: existing.pasajVisibility[title] ?? true,
    };
  }

  final preferences = ensureLocalPreferenceRepository();
  final hidden = (await preferences.getStringList(
            userScopedKey(_settingsPasajVisibilityKeyPrefix),
          ) ??
          const <String>[])
      .map(pasajLegacyTitleToId)
      .where(pasajTabs.contains)
      .toSet();
  return <String, bool>{
    for (final title in pasajTabs) title: !hidden.contains(title),
  };
}

Future<bool> isPasajTabVisibleLocally(String tabId) async {
  if (!pasajTabs.contains(tabId)) return true;
  final snapshot = await loadPasajVisibilitySnapshot();
  return snapshot[tabId] ?? true;
}
