part of 'app_language_service.dart';

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
