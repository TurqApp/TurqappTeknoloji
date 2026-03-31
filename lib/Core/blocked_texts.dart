import 'package:turqappv2/Core/Services/block_word_config_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

part 'blocked_texts_words_1_part.dart';
part 'blocked_texts_words_2_part.dart';

final Set<String> _staticBlockedWords = kufurler
    .map(BlockWordConfigService.normalizeForTokenMatch)
    .where((value) => value.isNotEmpty && !value.contains(' '))
    .toSet();

Future<bool> kufurKontrolEt(String text) async {
  final tokens = normalizeSearchText(text)
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .split(RegExp(r'\s+'))
      .map((word) => word.trim())
      .where((word) => word.isNotEmpty);

  if (tokens.isEmpty) return false;

  await BlockWordConfigService.instance.ensureLoaded();
  final blockedWords = <String>{
    ..._staticBlockedWords,
    if (BlockWordConfigService.instance.enabled)
      ...BlockWordConfigService.instance.blockedWords,
  };

  for (final word in tokens) {
    if (blockedWords.contains(word)) {
      return true;
    }
  }
  return false;
}

final List<String> kufurler = <String>[
  ..._kufurlerPart1,
  ..._kufurlerPart2,
];
