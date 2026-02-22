import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  RxBool educationScreenIsOn = true.obs;

  static const _prefKey = "educationScreenIsOn";

  @override
  void onInit() {
    super.onInit();
    loadEducationPreference();
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
}
