part 'blocked_texts_words_1_part.dart';
part 'blocked_texts_words_2_part.dart';

bool kufurKontrolEt(String text) {
  final words = text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\wçğıöşüÇĞİÖŞÜ\s]'),
          '') // Türkçe karakterlere göre temizle
      .split(RegExp(r'\s+'));

  for (String word in words) {
    if (kufurler.contains(word.trim())) {
      return true;
    }
  }
  return false;
}

final List<String> kufurler = <String>[
  ..._kufurlerPart1,
  ..._kufurlerPart2,
];
