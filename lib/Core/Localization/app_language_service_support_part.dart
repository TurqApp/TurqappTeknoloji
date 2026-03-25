part of 'app_language_service.dart';

const Locale _appLanguageFallbackLocale = Locale('tr', 'TR');

const List<Locale> _appLanguageSupportedLocales = <Locale>[
  Locale('tr', 'TR'),
  Locale('en', 'US'),
  Locale('de', 'DE'),
  Locale('fr', 'FR'),
  Locale('it', 'IT'),
  Locale('ru', 'RU'),
];

const List<AppLanguageOption> _appLanguageOptions = <AppLanguageOption>[
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

Locale _appLanguageLocaleForCode(String? code) {
  final normalized = _appLanguageNormalizeCode(code);
  for (final option in _appLanguageOptions) {
    if (option.code == normalized) return option.locale;
  }
  return _appLanguageFallbackLocale;
}

String _appLanguageNormalizeCode(String? code) {
  if (code == null || code.isEmpty) return 'tr_TR';
  final normalized = code.replaceAll('-', '_');
  for (final option in _appLanguageOptions) {
    if (option.code == normalized) return option.code;
    if (option.locale.languageCode == normalized) return option.code;
  }
  return 'tr_TR';
}
