part of 'language_settings_view.dart';

extension LanguageSettingsViewLabelsPart on LanguageSettingsView {
  String _localizedLanguageTitle(String code, String fallback) {
    return switch (code) {
      'tr_TR' => 'language.option.tr'.tr,
      'en_US' => 'language.option.en'.tr,
      'de_DE' => 'language.option.de'.tr,
      'fr_FR' => 'language.option.fr'.tr,
      'it_IT' => 'language.option.it'.tr,
      'ru_RU' => 'language.option.ru'.tr,
      _ => fallback,
    };
  }
}
