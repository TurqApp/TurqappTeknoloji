import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Utils/bool_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

class BlockWordConfigService {
  BlockWordConfigService._();

  static final BlockWordConfigService instance = BlockWordConfigService._();
  static const String docId = 'blockWord';
  static const Duration _ttl = Duration(hours: 6);

  StreamSubscription<Map<String, dynamic>>? _sub;
  Future<void>? _loader;
  bool _enabled = true;
  Set<String> _blockedWords = const <String>{};
  Set<String> _blockedPhrases = const <String>{};
  Set<String> _allowWords = const <String>{};
  Set<String> _allowPhrases = const <String>{};
  List<RegExp> _blockedPatterns = const <RegExp>[];

  @visibleForTesting
  _BlockWordTestOverride? testOverride;

  bool get enabled => testOverride?.enabled ?? _enabled;
  Set<String> get blockedWords => testOverride?.blockedWords ?? _blockedWords;
  Set<String> get blockedPhrases =>
      testOverride?.blockedPhrases ?? _blockedPhrases;
  Set<String> get allowWords => testOverride?.allowWords ?? _allowWords;
  Set<String> get allowPhrases => testOverride?.allowPhrases ?? _allowPhrases;
  List<RegExp> get blockedPatterns =>
      testOverride?.blockedPatterns ?? _blockedPatterns;

  Future<void> ensureLoaded() {
    if (testOverride != null) return Future<void>.value();
    return _loader ??= _loadInternal();
  }

  Future<void> _loadInternal() async {
    try {
      final data = await ensureConfigRepository().getAdminConfigDoc(
        docId,
        preferCache: true,
        ttl: _ttl,
      );
      _apply(data);
    } catch (_) {}

    try {
      await _sub?.cancel();
      _sub = ensureConfigRepository()
          .watchAdminConfigDoc(
            docId,
            ttl: _ttl,
          )
          .listen(
            _apply,
            onError: (_) {},
          );
    } catch (_) {}
  }

  void _apply(Map<String, dynamic>? raw) {
    final data = raw ?? const <String, dynamic>{};
    _enabled = parseFlexibleBool(data['enabled'], fallback: true);
    final blockedEntries = _extractEntries(
      <dynamic>[
        data['words'],
        data['blockedWords'],
        data['list'],
      ],
    );
    final allowEntries = _extractEntries(
      <dynamic>[
        data['allowList'],
        data['allowWords'],
        data['whitelist'],
      ],
    );
    _blockedWords = blockedEntries.words;
    _blockedPhrases = blockedEntries.phrases;
    _allowWords = allowEntries.words;
    _allowPhrases = allowEntries.phrases;
    _blockedPatterns = _extractPatterns(
      <dynamic>[
        data['patterns'],
        data['blockedPatterns'],
        data['regex'],
      ],
    );
  }

  _EntryCollection _extractEntries(Iterable<dynamic> raws) {
    final words = <String>{};
    final phrases = <String>{};
    for (final raw in raws) {
      for (final value in _extractStringValues(raw)) {
        final clean = normalizeForPhraseMatch(value);
        if (clean.isEmpty) continue;
        if (clean.contains(' ')) {
          phrases.add(clean);
        } else {
          words.add(clean);
        }
      }
    }
    return _EntryCollection(
      words: words,
      phrases: phrases,
    );
  }

  List<RegExp> _extractPatterns(Iterable<dynamic> raws) {
    final patterns = <RegExp>[];
    for (final raw in raws) {
      for (final value in _extractStringValues(raw)) {
        final clean = value.trim();
        if (clean.isEmpty) continue;
        try {
          patterns.add(RegExp(clean, caseSensitive: false, unicode: true));
        } catch (_) {}
      }
    }
    return List<RegExp>.unmodifiable(patterns);
  }

  Iterable<String> _extractStringValues(dynamic raw) sync* {
    if (raw is Iterable) {
      for (final value in raw) {
        final text = value?.toString() ?? '';
        if (text.trim().isNotEmpty) yield text;
      }
      return;
    }
    if (raw is String) {
      final chunks = raw
          .split(RegExp(r'[\n,;]+'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty);
      yield* chunks;
    }
  }

  @visibleForTesting
  void setTestOverride({
    required bool enabled,
    Iterable<String> words = const <String>[],
    Iterable<String> phrases = const <String>[],
    Iterable<String> allowWords = const <String>[],
    Iterable<String> allowPhrases = const <String>[],
    Iterable<String> patterns = const <String>[],
  }) {
    testOverride = _BlockWordTestOverride(
      enabled: enabled,
      blockedWords: words
          .map(normalizeForPhraseMatch)
          .where((value) => value.isNotEmpty && !value.contains(' '))
          .toSet(),
      blockedPhrases: phrases
          .map(normalizeForPhraseMatch)
          .where((value) => value.isNotEmpty && value.contains(' '))
          .toSet(),
      allowWords: allowWords
          .map(normalizeForPhraseMatch)
          .where((value) => value.isNotEmpty && !value.contains(' '))
          .toSet(),
      allowPhrases: allowPhrases
          .map(normalizeForPhraseMatch)
          .where((value) => value.isNotEmpty && value.contains(' '))
          .toSet(),
      blockedPatterns: patterns
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .map((value) => RegExp(value, caseSensitive: false, unicode: true))
          .toList(growable: false),
    );
  }

  @visibleForTesting
  void clearTestOverride() {
    testOverride = null;
  }

  static String normalizeForTokenMatch(String text) => normalizeForPhraseMatch(
        text,
        collapseRepeats: false,
      );

  static String normalizeForPhraseMatch(
    String text, {
    bool collapseRepeats = false,
    bool preserveSpaces = true,
  }) {
    var normalized = normalizeSearchText(text);
    normalized = _applyLeetspeakMap(normalized);
    normalized = normalized
        .replaceAll(RegExp(r'[_\-.@#$%^&*+=~`|\\/]+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), ' ');
    if (collapseRepeats) {
      normalized = normalized.replaceAllMapped(
        RegExp(r'(.)\1{1,}'),
        (match) => match.group(1) ?? '',
      );
    }
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (!preserveSpaces) {
      normalized = normalized.replaceAll(' ', '');
    }
    return normalized;
  }

  static String _applyLeetspeakMap(String text) {
    return text
        .replaceAll('@', 'a')
        .replaceAll('4', 'a')
        .replaceAll('3', 'e')
        .replaceAll('1', 'i')
        .replaceAll('!', 'i')
        .replaceAll('0', 'o')
        .replaceAll('5', 's')
        .replaceAll(r'$', 's')
        .replaceAll('7', 't');
  }
}

class _BlockWordTestOverride {
  const _BlockWordTestOverride({
    required this.enabled,
    required this.blockedWords,
    required this.blockedPhrases,
    required this.allowWords,
    required this.allowPhrases,
    required this.blockedPatterns,
  });

  final bool enabled;
  final Set<String> blockedWords;
  final Set<String> blockedPhrases;
  final Set<String> allowWords;
  final Set<String> allowPhrases;
  final List<RegExp> blockedPatterns;
}

class _EntryCollection {
  const _EntryCollection({
    required this.words,
    required this.phrases,
  });

  final Set<String> words;
  final Set<String> phrases;
}
