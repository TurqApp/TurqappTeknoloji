import 'package:turqappv2/Core/Services/block_word_config_service.dart';

part 'blocked_texts_words_1_part.dart';
part 'blocked_texts_words_2_part.dart';

final Set<String> _staticBlockedWords = kufurler
    .map(
      BlockWordConfigService.normalizeForTokenMatch,
    )
    .where((value) => value.isNotEmpty && !value.contains(' '))
    .toSet();

final Set<String> _staticBlockedPhrases = kufurler
    .map(
      (value) => BlockWordConfigService.normalizeForPhraseMatch(
        value,
        collapseRepeats: false,
      ),
    )
    .where((value) => value.isNotEmpty && value.contains(' '))
    .toSet();

const Set<String> _suffixUnsafeRoots = <String>{
  'am',
  'ana',
  'anal',
  'aq',
  'oc',
  'mk',
};

const List<String> _turkishSuffixes = <String>[
  'larindan',
  'lerinden',
  'larina',
  'lerine',
  'larini',
  'lerini',
  'lari',
  'leri',
  'lardan',
  'lerden',
  'siniz',
  'sunuz',
  'siniz',
  'imiz',
  'umuz',
  'iniz',
  'unuz',
  'mizin',
  'mizin',
  'nizin',
  'nuzun',
  'daki',
  'deki',
  'taki',
  'teki',
  'dan',
  'den',
  'tan',
  'ten',
  'dir',
  'dur',
  'tir',
  'tur',
  'lik',
  'luk',
  'siz',
  'siz',
  'suz',
  'leri',
  'lari',
  'nin',
  'nun',
  'nin',
  'nun',
  'sin',
  'sun',
  'miz',
  'muz',
  'niz',
  'nuz',
  'ini',
  'unu',
  'lari',
  'leri',
  'lar',
  'ler',
  'na',
  'ne',
  'ni',
  'nu',
  'yi',
  'yu',
  'ya',
  'ye',
  'da',
  'de',
  'ta',
  'te',
  'im',
  'in',
  'um',
  'un',
  'si',
  'su',
  'm',
  'n',
  'i',
  'u',
  'a',
  'e',
];

Future<bool> kufurKontrolEt(String text) async {
  final normalizedText = BlockWordConfigService.normalizeForPhraseMatch(text);
  if (normalizedText.isEmpty) return false;
  final collapsedText = BlockWordConfigService.normalizeForPhraseMatch(
    text,
    collapseRepeats: true,
  );
  final normalizedTokens = normalizedText
      .split(RegExp(r'\s+'))
      .map((word) => word.trim())
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  final collapsedTokens = collapsedText
      .split(RegExp(r'\s+'))
      .map((word) => word.trim())
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (normalizedTokens.isEmpty) return false;

  await BlockWordConfigService.instance.ensureLoaded();
  final blockedWords = <String>{
    ..._staticBlockedWords,
    if (BlockWordConfigService.instance.enabled)
      ...BlockWordConfigService.instance.blockedWords,
  };
  final blockedPhrases = <String>{
    ..._staticBlockedPhrases,
    if (BlockWordConfigService.instance.enabled)
      ...BlockWordConfigService.instance.blockedPhrases,
  };
  final allowWords = BlockWordConfigService.instance.enabled
      ? BlockWordConfigService.instance.allowWords
      : const <String>{};
  final allowPhrases = BlockWordConfigService.instance.enabled
      ? BlockWordConfigService.instance.allowPhrases
      : const <String>{};
  final patterns = BlockWordConfigService.instance.enabled
      ? BlockWordConfigService.instance.blockedPatterns
      : const <RegExp>[];

  final sanitizedNormalized = _maskAllowList(
    normalizedText,
    allowWords: allowWords,
    allowPhrases: allowPhrases,
  );
  final sanitizedCollapsed = _maskAllowList(
    collapsedText,
    allowWords: allowWords,
    allowPhrases: allowPhrases,
  );

  if (_containsPhraseMatch(sanitizedNormalized, blockedPhrases) ||
      _containsPhraseMatch(sanitizedCollapsed, blockedPhrases)) {
    return true;
  }
  if (_containsPatternMatch(sanitizedNormalized, patterns) ||
      _containsPatternMatch(sanitizedCollapsed, patterns)) {
    return true;
  }

  final candidates = <String>{
    ..._buildTokenCandidates(normalizedTokens),
    ..._buildTokenCandidates(collapsedTokens),
  };

  for (final word in candidates) {
    if (allowWords.contains(word)) continue;
    if (blockedWords.contains(word)) {
      return true;
    }
  }
  return false;
}

bool _containsPhraseMatch(String text, Set<String> phrases) {
  if (text.isEmpty || phrases.isEmpty) return false;
  final padded = ' $text ';
  for (final phrase in phrases) {
    if (padded.contains(' $phrase ')) {
      return true;
    }
  }
  return false;
}

bool _containsPatternMatch(String text, List<RegExp> patterns) {
  if (text.isEmpty || patterns.isEmpty) return false;
  for (final pattern in patterns) {
    if (pattern.hasMatch(text)) return true;
  }
  return false;
}

String _maskAllowList(
  String text, {
  required Set<String> allowWords,
  required Set<String> allowPhrases,
}) {
  if (text.isEmpty) return text;
  var masked = ' $text ';
  final phraseList = allowPhrases.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final phrase in phraseList) {
    masked = masked.replaceAll(' $phrase ', ' ');
  }
  final wordList = allowWords.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final word in wordList) {
    masked = masked.replaceAll(' $word ', ' ');
  }
  return masked.replaceAll(RegExp(r'\s+'), ' ').trim();
}

Set<String> _buildTokenCandidates(List<String> tokens) {
  final candidates = <String>{};
  for (final token in tokens) {
    candidates.add(token);
    candidates.addAll(_expandStemCandidates(token));
  }
  candidates.addAll(_buildJoinedShortTokenCandidates(tokens));
  return candidates;
}

Set<String> _expandStemCandidates(String token) {
  final candidates = <String>{token};
  if (token.length < 4 || _suffixUnsafeRoots.contains(token)) {
    return candidates;
  }
  final queue = <String>[token];
  final visited = <String>{token};
  var depth = 0;
  while (queue.isNotEmpty && depth < 2) {
    final levelSize = queue.length;
    for (var i = 0; i < levelSize; i++) {
      final current = queue.removeAt(0);
      for (final suffix in _turkishSuffixes) {
        if (!current.endsWith(suffix)) continue;
        final stem = current.substring(0, current.length - suffix.length);
        if (stem.length < 3 || !visited.add(stem)) continue;
        candidates.add(stem);
        queue.add(stem);
      }
    }
    depth++;
  }
  return candidates;
}

Set<String> _buildJoinedShortTokenCandidates(List<String> tokens) {
  final candidates = <String>{};
  if (tokens.length < 2) return candidates;
  for (var start = 0; start < tokens.length; start++) {
    if (tokens[start].length > 2) continue;
    final buffer = StringBuffer();
    for (var end = start; end < tokens.length && end < start + 6; end++) {
      final token = tokens[end];
      if (token.length > 2) break;
      buffer.write(token);
      final joined = buffer.toString();
      if (joined.length >= 3) {
        candidates.add(joined);
        candidates.addAll(_expandStemCandidates(joined));
      }
    }
  }
  return candidates;
}

final List<String> kufurler = <String>[
  ..._kufurlerPart1,
  ..._kufurlerPart2,
];
