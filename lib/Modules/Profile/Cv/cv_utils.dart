import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

bool isPresentCvYear(String year) {
  return const <String>{
    'Halen',
    'Present',
    'Aktuell',
    'Actuel',
    'Presente',
    'Настоящее время',
  }.contains(year.trim());
}

String normalizeCvLanguageValue(String value) {
  switch (normalizeSearchText(value)) {
    case 'cv.language.english':
    case 'english':
    case 'ingilizce':
      return 'cv.language.english';
    case 'cv.language.german':
    case 'german':
    case 'almanca':
      return 'cv.language.german';
    case 'cv.language.french':
    case 'french':
    case 'fransizca':
      return 'cv.language.french';
    case 'cv.language.spanish':
    case 'spanish':
    case 'ispanyolca':
      return 'cv.language.spanish';
    case 'cv.language.arabic':
    case 'arabic':
    case 'arapca':
      return 'cv.language.arabic';
    case 'cv.language.turkish':
    case 'turkish':
    case 'turkce':
      return 'cv.language.turkish';
    case 'cv.language.russian':
    case 'russian':
    case 'rusca':
      return 'cv.language.russian';
    case 'cv.language.italian':
    case 'italian':
    case 'italyanca':
      return 'cv.language.italian';
    case 'cv.language.korean':
    case 'korean':
    case 'korece':
      return 'cv.language.korean';
    default:
      return value;
  }
}
