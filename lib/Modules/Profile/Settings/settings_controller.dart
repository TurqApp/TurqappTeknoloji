import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';

part 'settings_controller_runtime_part.dart';

class SettingsController extends GetxController {
  static SettingsController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SettingsController(), permanent: permanent);
  }

  static SettingsController? maybeFind() {
    final isRegistered = Get.isRegistered<SettingsController>();
    if (!isRegistered) return null;
    return Get.find<SettingsController>();
  }

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
