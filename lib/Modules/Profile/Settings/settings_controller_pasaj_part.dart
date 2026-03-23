part of 'settings_controller.dart';

extension SettingsControllerPasajPart on SettingsController {
  Future<void> loadPasajPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_pasajOrderVersionKey) ?? 0;
    final normalizedOrder = pasajTabs.toList(growable: false);
    pasajOrder.assignAll(normalizedOrder);
    if (storedVersion < SettingsController._currentPasajOrderVersion) {
      await prefs.setStringList(_pasajOrderKey, normalizedOrder);
      await prefs.setInt(
        _pasajOrderVersionKey,
        SettingsController._currentPasajOrderVersion,
      );
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
    await prefs.setInt(
      _pasajOrderVersionKey,
      SettingsController._currentPasajOrderVersion,
    );
  }
}
