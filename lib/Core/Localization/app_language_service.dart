import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';

part 'app_language_service_models_part.dart';
part 'app_language_service_runtime_part.dart';
part 'app_language_service_support_part.dart';
part 'app_language_service_facade_part.dart';

class AppLanguageService extends GetxService {
  static const String _prefKey = 'appLanguageCode';

  static Locale get fallbackLocale => _appLanguageFallbackLocale;
  static List<Locale> get supportedLocales => _appLanguageSupportedLocales;
  static List<AppLanguageOption> get options => _appLanguageOptions;

  final RxString _currentCode = 'tr_TR'.obs;

  String get currentCode => _currentCode.value;
  Locale get currentLocale => _localeForCode(_currentCode.value);
  Future<void> changeLanguage(String code) => _changeLanguage(code);

  static Locale _localeForCode(String? code) => _appLanguageLocaleForCode(code);

  static String _normalizeCode(String? code) => _appLanguageNormalizeCode(code);
}
