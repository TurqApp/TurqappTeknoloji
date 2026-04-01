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
  AppLanguageOption('tr_TR', Locale('tr', 'TR'), 'Türkçe'),
  AppLanguageOption('en_US', Locale('en', 'US'), 'English'),
  AppLanguageOption('de_DE', Locale('de', 'DE'), 'Deutsch'),
  AppLanguageOption('fr_FR', Locale('fr', 'FR'), 'Français'),
  AppLanguageOption('it_IT', Locale('it', 'IT'), 'Italiano'),
  AppLanguageOption('ru_RU', Locale('ru', 'RU'), 'Русский'),
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
