import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_language_service_models_part.dart';
part 'app_language_service_runtime_part.dart';

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

  static const Locale fallbackLocale = Locale('tr', 'TR');
  static const List<Locale> supportedLocales = <Locale>[
    Locale('tr', 'TR'),
    Locale('en', 'US'),
    Locale('de', 'DE'),
    Locale('fr', 'FR'),
    Locale('it', 'IT'),
    Locale('ru', 'RU'),
  ];

  static const List<AppLanguageOption> options = <AppLanguageOption>[
    AppLanguageOption(
      code: 'tr_TR',
      locale: Locale('tr', 'TR'),
      nativeLabel: 'Türkçe',
    ),
    AppLanguageOption(
      code: 'en_US',
      locale: Locale('en', 'US'),
      nativeLabel: 'English',
    ),
    AppLanguageOption(
      code: 'de_DE',
      locale: Locale('de', 'DE'),
      nativeLabel: 'Deutsch',
    ),
    AppLanguageOption(
      code: 'fr_FR',
      locale: Locale('fr', 'FR'),
      nativeLabel: 'Français',
    ),
    AppLanguageOption(
      code: 'it_IT',
      locale: Locale('it', 'IT'),
      nativeLabel: 'Italiano',
    ),
    AppLanguageOption(
      code: 'ru_RU',
      locale: Locale('ru', 'RU'),
      nativeLabel: 'Русский',
    ),
  ];

  final RxString _currentCode = 'tr_TR'.obs;

  String get currentCode => _currentCode.value;
  Locale get currentLocale => _localeForCode(_currentCode.value);

  static Locale _localeForCode(String? code) {
    final normalized = _normalizeCode(code);
    for (final option in options) {
      if (option.code == normalized) return option.locale;
    }
    return fallbackLocale;
  }

  static String _normalizeCode(String? code) {
    if (code == null || code.isEmpty) return 'tr_TR';
    final normalized = code.replaceAll('-', '_');
    for (final option in options) {
      if (option.code == normalized) return option.code;
      if (option.locale.languageCode == normalized) return option.code;
    }
    return 'tr_TR';
  }
}
