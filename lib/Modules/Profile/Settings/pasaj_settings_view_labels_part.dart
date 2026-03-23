part of 'pasaj_settings_view.dart';

String _pasajDisplayTitle(String title) {
  final translationKey = pasajTitleTranslationKey(title);
  if (translationKey.isNotEmpty) return translationKey.tr;
  return title;
}
