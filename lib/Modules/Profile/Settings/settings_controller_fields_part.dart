part of 'settings_controller.dart';

const String _settingsPrefKeyPrefix = 'educationScreenIsOn';
const String _settingsPasajOrderKeyPrefix = 'pasajOrder';
const String _settingsPasajVisibilityKeyPrefix = 'pasajVisibility';
const String _settingsPasajOrderVersionKeyPrefix = 'pasajOrderVersion';
const int _currentPasajOrderVersion = 4;

class _SettingsControllerState {
  final RxBool educationScreenIsOn = true.obs;
  final RxList<String> pasajOrder = pasajTabs.obs;
  final RxMap<String, bool> pasajVisibility = <String, bool>{}.obs;
}

extension SettingsControllerFieldsPart on SettingsController {
  RxBool get educationScreenIsOn => _state.educationScreenIsOn;
  RxList<String> get pasajOrder => _state.pasajOrder;
  RxMap<String, bool> get pasajVisibility => _state.pasajVisibility;

  String get _activeUid => activeUserScope();
  String get _prefKey => '$_settingsPrefKeyPrefix:$_activeUid';
  String get _pasajOrderKey => '$_settingsPasajOrderKeyPrefix:$_activeUid';
  String get _pasajVisibilityKey =>
      '$_settingsPasajVisibilityKeyPrefix:$_activeUid';
  String get _pasajOrderVersionKey =>
      '$_settingsPasajOrderVersionKeyPrefix:$_activeUid';
}
