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

  @visibleForTesting
  _BlockWordTestOverride? testOverride;

  bool get enabled => testOverride?.enabled ?? _enabled;
  Set<String> get blockedWords => testOverride?.blockedWords ?? _blockedWords;

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
    _blockedWords = _extractBlockedWords(data);
  }

  Set<String> _extractBlockedWords(Map<String, dynamic> data) {
    final values = <String>{
      ..._extractStringValues(data['words']),
      ..._extractStringValues(data['blockedWords']),
      ..._extractStringValues(data['list']),
    };
    final normalized = <String>{};
    for (final value in values) {
      final clean = _normalizeToken(value);
      if (clean.isEmpty || clean.contains(' ')) continue;
      normalized.add(clean);
    }
    return normalized;
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
  }) {
    testOverride = _BlockWordTestOverride(
      enabled: enabled,
      blockedWords: words
          .map(_normalizeToken)
          .where((value) => value.isNotEmpty && !value.contains(' '))
          .toSet(),
    );
  }

  @visibleForTesting
  void clearTestOverride() {
    testOverride = null;
  }

  static String normalizeForTokenMatch(String text) => _normalizeToken(text);

  static String _normalizeToken(String text) {
    return normalizeSearchText(text)
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _BlockWordTestOverride {
  const _BlockWordTestOverride({
    required this.enabled,
    required this.blockedWords,
  });

  final bool enabled;
  final Set<String> blockedWords;
}
