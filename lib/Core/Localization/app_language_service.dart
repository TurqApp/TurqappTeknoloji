import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_language_service_models_part.dart';
part 'app_language_service_runtime_part.dart';
part 'app_language_service_support_part.dart';

class AppLanguageService extends GetxService {
  static const String _prefKey = 'appLanguageCode';

  static AppLanguageService ensure({bool permanent = true}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AppLanguageService(), permanent: permanent);
  }

  static AppLanguageService? maybeFind() {
    final isRegistered = Get.isRegistered<AppLanguageService>();
    if (!isRegistered) return null;
    return Get.find<AppLanguageService>();
  }

  static Future<AppLanguageService> ensureInitialized() async {
    final existing = maybeFind();
    if (existing != null) return existing;
    final service = await AppLanguageService().init();
    return Get.put(service, permanent: true);
  }

  static Locale get fallbackLocale => _appLanguageFallbackLocale;
  static List<Locale> get supportedLocales => _appLanguageSupportedLocales;
  static List<AppLanguageOption> get options => _appLanguageOptions;

  final RxString _currentCode = 'tr_TR'.obs;

  String get currentCode => _currentCode.value;
  Locale get currentLocale => _localeForCode(_currentCode.value);

  static Locale _localeForCode(String? code) => _appLanguageLocaleForCode(code);

  static String _normalizeCode(String? code) => _appLanguageNormalizeCode(code);
}
