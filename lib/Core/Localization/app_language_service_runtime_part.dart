part of 'app_language_service.dart';

extension AppLanguageServiceRuntimePart on AppLanguageService {
  String get currentLanguageLabel {
    for (final option in AppLanguageService.options) {
      if (option.code == _currentCode.value) return option.nativeLabel;
    }
    return 'Türkçe';
  }

  Future<AppLanguageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCode.value = AppLanguageService._normalizeCode(
        prefs.getString(AppLanguageService._prefKey));
    return this;
  }

  Future<void> changeLanguage(String code) async {
    final normalized = AppLanguageService._normalizeCode(code);
    if (_currentCode.value == normalized) return;
    _currentCode.value = normalized;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppLanguageService._prefKey, normalized);
    await Get.updateLocale(AppLanguageService._localeForCode(normalized));
  }
}
