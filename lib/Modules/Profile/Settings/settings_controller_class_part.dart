part of 'settings_controller.dart';

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
  String get _pasajOrderVersionKey =>
      '$_pasajOrderVersionKeyPrefix:$_activeUid';

  @override
  void onInit() {
    super.onInit();
    _initializeSettings();
  }
}
