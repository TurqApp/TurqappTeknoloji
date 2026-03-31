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

const Set<String> _excludedLegacyEntries = <String>{
  'ana',
  'anal',
  'aptal',
  'mal',
  'salak',
  'gerizekalı',
  'gerizekali',
  'meme',
  'penis',
  'vajina',
  'vajinanı',
  'sperm',
  'artist',
  'yalaka',
  'azgın',
  'deli',
  'cahil',
  'bilgisiz',
  'çirkin',
  'dinsiz',
  'domuz',
  'hayvan',
  'hoşt',
  'kuru',
  'mikrop',
  'whore',
  'slut',
  'cock',
  'dick',
  'verdammt',
  'ahmak',
  'angut',
  'beyinsiz',
  'cibiliyetsiz',
  'dangalak',
  'dingil',
  'düdük',
  'gerzek',
  'idiot',
  'idiyot',
  'kaka',
  'kaypak',
  'lavuk',
  'öküz',
  'eşek',
  'ayı',
  'görgüsüz',
  'kepaze',
  'dümbük',
  'dümbüğün kızı',
  'pasaklı',
  'pısırık',
  'psikopat',
  'saçaklı',
  'fettan',
  'allahsız',
  'gavur',
  'kahpe',
  'kahpenin',
  'kahpenin feryadı',
  'puşt',
  'puşttur',
  'sürtük',
  'surtuk',
  'şırfıntı',
  'ibne',
  'hure',
  'fahişe',
  'fahise',
  'gavat',
  'kaltak',
  'kancık',
  'kancik',
  'kaşar',
  'kasar',
  'haysiyetsiz',
  'karaktersiz',
  'şerefsiz',
  'serefsiz',
  'dangoz',
  'kalas',
  'inek',
  'sapık',
  'imansız',
  'imansz',
  'benim kölemsin',
  'dadı',
  'dostundan geliyorsun',
  'eşyasın',
  'genelev kadını',
  'genelevlere düşesin',
  'kavatın kızı',
  'kızışmış',
  'kölemsin',
  'köpekler de doğuruyor',
  'kuş beyinli',
  'pavyon karısı',
  'sen bi b.. değilsin',
  'sen de kadın mısın',
  'seni ahıra dahi sokmam',
  'sokak sürtüğü',
  'sütü bozuk',
  'şirret',
  'ya çık git ya intihar et',
  'yamuk kadın',
  'kadın erkeğin elinin kiridir',
  'kadın olsaydın da elinde tutsaydın',
  'kime veriyorsun',
  'kötü kadın',
  'eksik etek',
  'ecdadını',
  'ecdadini',
  'embesil',
  'geber',
  'geberik',
  'gebermek',
  'gebermiş',
  'gebertir',
  'gerızekalı',
  'gibmek',
  'godoş',
  'hayvan herif',
  'hoşafı',
  'hödük',
  'ipne',
  'kappe',
  'kayyum',
  'liboş',
  'malafat',
  'malak',
  'manyak',
  'mezveleli',
  'mudik',
  'aşağılık kadın',
  'boğazını kesecem',
  'çürük kadın',
  'dağa kaldırırım',
  'davul olasın',
  'dayaktan öldürürüm',
  'dünyanın o...su',
  'elimde kalırsın',
  'eteğine ettiğimin karısı',
  'git o..luk yap getir',
  'gittiğim kadınlar sana ayna olurlar',
  'kafanı gözünü kıracam',
  'kanı bozuk',
  'karnını deşerim',
  'kimden peydahladın',
  'komaya sokarım',
  'kötü yola düşesin',
  'öl geber',
  'seni çizerim',
  'seni döverim',
  'seni kim naapsın',
  'seni kötü yola düşürecem',
  'seni öldürecem',
  'seni öyle bir döverim ki annen bile tanımaz',
  'seni türkiye’ye rezil edeceğim',
  'süprüntü',
  'şeyin başına vurdu',
  'ulan karı',
  'uyuz',
  'vasat karı',
  'yakalarsam seni satacam',
  'yer cücesi',
  'yeteneksiz',
  'yüzüne kezzap atarım',
  'yüzünü keserim',
};

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

final List<String> kufurler = _buildEffectiveBlockedTerms();

List<String> _buildEffectiveBlockedTerms() {
  final deduped = <String>{};
  final effective = <String>[];
  for (final value in <String>[..._kufurlerPart1, ..._kufurlerPart2]) {
    final normalizedKey = value.trim().toLowerCase();
    if (normalizedKey.isEmpty) continue;
    if (_excludedLegacyEntries.contains(normalizedKey)) continue;
    if (!deduped.add(normalizedKey)) continue;
    effective.add(value.trim());
  }
  return List<String>.unmodifiable(effective);
}
