import 'package:turqappv2/Core/Services/block_word_config_service.dart';

part 'blocked_texts_words_part.dart';

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

class BlockedTextMatch {
  const BlockedTextMatch({
    required this.displayValue,
    required this.normalizedValue,
  });

  final String displayValue;
  final String normalizedValue;
}

class _RawTokenProbe {
  const _RawTokenProbe({
    required this.rawToken,
    required this.normalizedPieces,
    required this.collapsedPieces,
  });

  final String rawToken;
  final List<String> normalizedPieces;
  final List<String> collapsedPieces;
}

Future<bool> kufurKontrolEt(String text) async {
  return (await kufurEslesmesiniBul(text)) != null;
}

Future<BlockedTextMatch?> kufurEslesmesiniBul(String text) async {
  final normalizedText = BlockWordConfigService.normalizeForPhraseMatch(text);
  if (normalizedText.isEmpty) return null;
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
  if (normalizedTokens.isEmpty) return null;

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

  final phraseMatch = _firstPhraseMatch(sanitizedNormalized, blockedPhrases) ??
      _firstPhraseMatch(sanitizedCollapsed, blockedPhrases);
  if (phraseMatch != null) {
    return BlockedTextMatch(
      displayValue: phraseMatch,
      normalizedValue: phraseMatch,
    );
  }
  final patternMatch = _firstPatternMatch(sanitizedNormalized, patterns) ??
      _firstPatternMatch(sanitizedCollapsed, patterns);
  if (patternMatch != null) {
    return BlockedTextMatch(
      displayValue: patternMatch,
      normalizedValue: patternMatch,
    );
  }

  final tokenMatch = _findBlockedTokenMatch(
    text,
    blockedWords: blockedWords,
    allowWords: allowWords,
  );
  if (tokenMatch != null) return tokenMatch;

  final candidates = <String>{
    ..._buildTokenCandidates(normalizedTokens),
    ..._buildTokenCandidates(collapsedTokens),
  };
  for (final word in candidates) {
    if (allowWords.contains(word)) continue;
    if (blockedWords.contains(word)) {
      return BlockedTextMatch(
        displayValue: word,
        normalizedValue: word,
      );
    }
  }
  return null;
}

String? _firstPhraseMatch(String text, Set<String> phrases) {
  if (text.isEmpty || phrases.isEmpty) return null;
  final padded = ' $text ';
  final sorted = phrases.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final phrase in sorted) {
    if (padded.contains(' $phrase ')) {
      return phrase;
    }
  }
  return null;
}

String? _firstPatternMatch(String text, List<RegExp> patterns) {
  if (text.isEmpty || patterns.isEmpty) return null;
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    final value = match?.group(0)?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return null;
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

BlockedTextMatch? _findBlockedTokenMatch(
  String text, {
  required Set<String> blockedWords,
  required Set<String> allowWords,
}) {
  final probes = _buildRawTokenProbes(text);
  for (final probe in probes) {
    final directMatch = _matchBlockedPieces(
          probe.rawToken,
          probe.normalizedPieces,
          blockedWords: blockedWords,
          allowWords: allowWords,
        ) ??
        _matchBlockedPieces(
          probe.rawToken,
          probe.collapsedPieces,
          blockedWords: blockedWords,
          allowWords: allowWords,
        );
    if (directMatch != null) return directMatch;
  }
  return _matchJoinedShortTokenProbes(
    probes,
    blockedWords: blockedWords,
    allowWords: allowWords,
  );
}

List<_RawTokenProbe> _buildRawTokenProbes(String text) {
  return text
      .split(RegExp(r'\s+'))
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty)
      .map(
        (rawToken) => _RawTokenProbe(
          rawToken: rawToken,
          normalizedPieces: BlockWordConfigService.normalizeForPhraseMatch(
            rawToken,
          ).split(RegExp(r'\s+')).where((piece) => piece.isNotEmpty).toList(),
          collapsedPieces: BlockWordConfigService.normalizeForPhraseMatch(
            rawToken,
            collapseRepeats: true,
          ).split(RegExp(r'\s+')).where((piece) => piece.isNotEmpty).toList(),
        ),
      )
      .toList(growable: false);
}

BlockedTextMatch? _matchBlockedPieces(
  String rawToken,
  List<String> pieces, {
  required Set<String> blockedWords,
  required Set<String> allowWords,
}) {
  for (final piece in pieces) {
    final matched = _firstBlockedCandidate(
      piece,
      blockedWords: blockedWords,
      allowWords: allowWords,
    );
    if (matched == null) continue;
    return BlockedTextMatch(
      displayValue: _cleanBlockedDisplay(rawToken),
      normalizedValue: matched,
    );
  }
  final joinedMatch = _firstJoinedShortMatch(
    pieces,
    blockedWords: blockedWords,
    allowWords: allowWords,
  );
  if (joinedMatch == null) return null;
  return BlockedTextMatch(
    displayValue: _cleanBlockedDisplay(rawToken),
    normalizedValue: joinedMatch,
  );
}

String? _firstBlockedCandidate(
  String token, {
  required Set<String> blockedWords,
  required Set<String> allowWords,
}) {
  if (token.isEmpty || allowWords.contains(token)) return null;
  if (blockedWords.contains(token)) return token;
  for (final stem in _expandStemCandidates(token)) {
    if (allowWords.contains(stem)) continue;
    if (blockedWords.contains(stem)) return stem;
  }
  return null;
}

String? _firstJoinedShortMatch(
  List<String> pieces, {
  required Set<String> blockedWords,
  required Set<String> allowWords,
}) {
  if (pieces.length < 2) return null;
  for (var start = 0; start < pieces.length; start++) {
    if (pieces[start].length > 2) continue;
    final buffer = StringBuffer();
    for (var end = start; end < pieces.length && end < start + 6; end++) {
      final piece = pieces[end];
      if (piece.length > 2) break;
      buffer.write(piece);
      final joined = buffer.toString();
      if (joined.length < 3) continue;
      final matched = _firstBlockedCandidate(
        joined,
        blockedWords: blockedWords,
        allowWords: allowWords,
      );
      if (matched != null) return matched;
    }
  }
  return null;
}

BlockedTextMatch? _matchJoinedShortTokenProbes(
  List<_RawTokenProbe> probes, {
  required Set<String> blockedWords,
  required Set<String> allowWords,
}) {
  for (var start = 0; start < probes.length; start++) {
    final normalizedPieces = probes[start].normalizedPieces;
    final collapsedPieces = probes[start].collapsedPieces;
    if (normalizedPieces.length != 1 && collapsedPieces.length != 1) continue;
    final startToken = normalizedPieces.length == 1
        ? normalizedPieces.first
        : collapsedPieces.first;
    if (startToken.length > 2) continue;
    final normalizedBuffer = StringBuffer();
    final collapsedBuffer = StringBuffer();
    for (var end = start; end < probes.length && end < start + 6; end++) {
      final normalizedEndPieces = probes[end].normalizedPieces;
      final collapsedEndPieces = probes[end].collapsedPieces;
      if (normalizedEndPieces.length != 1 ||
          normalizedEndPieces.first.length > 2) {
        break;
      }
      if (collapsedEndPieces.length != 1 ||
          collapsedEndPieces.first.length > 2) {
        break;
      }
      normalizedBuffer.write(normalizedEndPieces.first);
      collapsedBuffer.write(collapsedEndPieces.first);
      final normalizedJoined = normalizedBuffer.toString();
      final collapsedJoined = collapsedBuffer.toString();
      final matched = _firstBlockedCandidate(
            normalizedJoined,
            blockedWords: blockedWords,
            allowWords: allowWords,
          ) ??
          _firstBlockedCandidate(
            collapsedJoined,
            blockedWords: blockedWords,
            allowWords: allowWords,
          );
      if (matched == null) continue;
      return BlockedTextMatch(
        displayValue: probes
            .sublist(start, end + 1)
            .map((probe) => _cleanBlockedDisplay(probe.rawToken))
            .join(' '),
        normalizedValue: matched,
      );
    }
  }
  return null;
}

String _cleanBlockedDisplay(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
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
