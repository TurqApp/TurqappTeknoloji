import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageOption {
  const AppLanguageOption({
    required this.code,
    required this.locale,
    required this.nativeLabel,
  });

  final String code;
  final Locale locale;
  final String nativeLabel;
}

class AppLanguageService extends GetxService {
  static const String _prefKey = 'appLanguageCode';

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

  String get currentLanguageLabel {
    for (final option in options) {
      if (option.code == _currentCode.value) return option.nativeLabel;
    }
    return 'Türkçe';
  }

  Future<AppLanguageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCode.value = _normalizeCode(prefs.getString(_prefKey));
    return this;
  }

  Future<void> changeLanguage(String code) async {
    final normalized = _normalizeCode(code);
    if (_currentCode.value == normalized) return;
    _currentCode.value = normalized;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, normalized);
    await Get.updateLocale(_localeForCode(normalized));
  }

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
