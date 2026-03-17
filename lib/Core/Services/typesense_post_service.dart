import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CachedPostCardsResult {
  const _CachedPostCardsResult({
    required this.cards,
    required this.cachedAt,
  });

  final Map<String, Map<String, dynamic>> cards;
  final DateTime cachedAt;

  bool get isFresh =>
      DateTime.now().difference(cachedAt) < TypesensePostService._ttl;
}

class TypesensePostService {
  TypesensePostService._();

  static final TypesensePostService instance = TypesensePostService._();
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsPrefix = 'typesense_post_cards_v1';

  final List<({String label, FirebaseFunctions fn})> _targets =
      <({String label, FirebaseFunctions fn})>[
    (label: 'default', fn: FirebaseFunctions.instance),
    (
      label: 'us-central1',
      fn: FirebaseFunctions.instanceFor(region: 'us-central1'),
    ),
    (
      label: 'europe-west1',
      fn: FirebaseFunctions.instanceFor(region: 'europe-west1'),
    ),
  ];
  final Map<String, _CachedPostCardsResult> _memory =
      <String, _CachedPostCardsResult>{};
  SharedPreferences? _prefs;

  Future<Map<String, Map<String, dynamic>>> getPostCardsByIds(
    List<String> ids,
  {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cleaned = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <String, Map<String, dynamic>>{};

    final cacheKey = _cardsCacheKey(cleaned);
    if (!forceRefresh && preferCache) {
      final memoryHit = _getFromMemory(cacheKey);
      if (memoryHit != null) return memoryHit.cards;

      final diskHit = await _getFromPrefs(cacheKey);
      if (diskHit != null) return diskHit.cards;
    }
    if (cacheOnly) return const <String, Map<String, dynamic>>{};

    Object? lastError;
    for (final target in _targets) {
      try {
        final response =
            await target.fn.httpsCallable('f15_getPostCardsByIdsCallable').call(
          <String, dynamic>{'ids': cleaned},
        );
        final data = Map<String, dynamic>.from(response.data as Map? ?? {});
        final hits = (data['hits'] as List<dynamic>?) ?? const <dynamic>[];
        final out = <String, Map<String, dynamic>>{};
        for (final rawHit in hits) {
          final hitMap = rawHit is Map ? Map<String, dynamic>.from(rawHit) : null;
          if (hitMap == null) continue;
          final id = (hitMap['id'] ?? hitMap['docID'] ?? '').toString().trim();
          if (id.isEmpty) continue;
          out[id] = hitMap;
        }
        await _store(cacheKey, out);
        return out;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('typesense_post_cards_failed');
  }

  Future<void> syncPostById(String postId) async {
    final cleaned = postId.trim();
    if (cleaned.isEmpty) return;
    await invalidatePostId(cleaned);

    Object? lastError;
    for (final target in _targets) {
      try {
        debugPrint(
          '[TypesensePostService] syncPostById start postId=$cleaned target=${target.label}',
        );
        await target.fn.httpsCallable('f15_syncPostToTypesenseCallable').call(
          <String, dynamic>{'postId': cleaned},
        );
        debugPrint(
          '[TypesensePostService] syncPostById success postId=$cleaned target=${target.label}',
        );
        return;
      } catch (e) {
        debugPrint(
          '[TypesensePostService] syncPostById failed postId=$cleaned target=${target.label} error=$e',
        );
        lastError = e;
      }
    }

    debugPrint(
      '[TypesensePostService] syncPostById giving up postId=$cleaned error=$lastError',
    );
    throw lastError ?? Exception('typesense_post_sync_failed');
  }

  Future<void> invalidatePostId(String postId) async {
    final cleaned = postId.trim();
    if (cleaned.isEmpty) return;
    _memory.removeWhere((cacheKey, _) => cacheKey.split('|').contains(cleaned));
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs.getKeys().where((key) {
      if (!key.startsWith('$_prefsPrefix:')) return false;
      final scopedKey = key.substring('$_prefsPrefix:'.length);
      return scopedKey.split('|').contains(cleaned);
    }).toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> invalidateAll() async {
    _memory.clear();
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('$_prefsPrefix:'))
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  _CachedPostCardsResult? _getFromMemory(String cacheKey) {
    final cached = _memory[cacheKey];
    if (cached == null) return null;
    if (!cached.isFresh) {
      _memory.remove(cacheKey);
      return null;
    }
    return cached;
  }

  Future<_CachedPostCardsResult?> _getFromPrefs(String cacheKey) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs?.getString(_prefsKey(cacheKey));
      if (raw == null || raw.isEmpty) return null;
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      final cachedAtMs = (data['cachedAt'] as num?)?.toInt() ?? 0;
      final cardsRaw = data['cards'];
      if (cachedAtMs <= 0 || cardsRaw is! Map) return null;
      final cards = <String, Map<String, dynamic>>{};
      cardsRaw.forEach((key, value) {
        if (value is Map) {
          cards[key.toString()] = Map<String, dynamic>.from(
            value.cast<dynamic, dynamic>(),
          );
        }
      });
      final cached = _CachedPostCardsResult(
        cards: cards,
        cachedAt: DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
      );
      if (!cached.isFresh) {
        await _prefs?.remove(_prefsKey(cacheKey));
        return null;
      }
      _memory[cacheKey] = cached;
      return cached;
    } catch (_) {
      return null;
    }
  }

  Future<void> _store(
    String cacheKey,
    Map<String, Map<String, dynamic>> cards,
  ) async {
    final cached = _CachedPostCardsResult(
      cards: Map<String, Map<String, dynamic>>.from(cards),
      cachedAt: DateTime.now(),
    );
    _memory[cacheKey] = cached;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(
        _prefsKey(cacheKey),
        jsonEncode(<String, dynamic>{
          'cachedAt': cached.cachedAt.millisecondsSinceEpoch,
          'cards': cards,
        }),
      );
    } catch (_) {}
  }

  String _cardsCacheKey(List<String> ids) {
    final sorted = [...ids]..sort();
    return sorted.join('|');
  }

  String _prefsKey(String cacheKey) => '$_prefsPrefix:$cacheKey';
}
