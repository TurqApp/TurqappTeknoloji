import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'typesense_post_service_cache_part.dart';
part 'typesense_post_service_query_part.dart';

dynamic _cloneCachedPostCardResultValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _cloneCachedPostCardResultValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map(_cloneCachedPostCardResultValue).toList(growable: false);
  }
  return value;
}

Map<String, dynamic> _cloneCachedPostCardResultCard(
  Map<String, dynamic> source,
) {
  return source.map(
    (key, value) => MapEntry(key, _cloneCachedPostCardResultValue(value)),
  );
}

Map<String, Map<String, dynamic>> _cloneCachedPostCardResultCards(
  Map<String, Map<String, dynamic>> source,
) {
  return source.map(
    (key, value) => MapEntry(key, _cloneCachedPostCardResultCard(value)),
  );
}

class _CachedPostCardsResult {
  _CachedPostCardsResult({
    required Map<String, Map<String, dynamic>> cards,
    required this.cachedAt,
  }) : cards = _cloneCachedPostCardResultCards(cards);

  final Map<String, Map<String, dynamic>> cards;
  final DateTime cachedAt;

  bool get isFresh =>
      DateTime.now().difference(cachedAt) < TypesensePostService._ttl;
}

class TypesensePostService {
  TypesensePostService._();

  static TypesensePostService? _instance;
  static TypesensePostService? maybeFind() => _instance;

  static TypesensePostService ensure() =>
      maybeFind() ?? (_instance = TypesensePostService._());

  static TypesensePostService get instance => ensure();
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
    List<String> ids, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _performGetPostCardsByIds(
        ids,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<void> syncPostById(String postId) => _performSyncPostById(postId);

  Future<void> invalidatePostId(String postId) =>
      _performInvalidatePostId(postId);

  Future<void> invalidateAll() => _performInvalidateAll();

  _CachedPostCardsResult? _getFromMemory(String cacheKey) =>
      _performGetFromMemory(cacheKey);

  Future<_CachedPostCardsResult?> _getFromPrefs(String cacheKey) =>
      _performGetFromPrefs(cacheKey);

  Future<void> _store(
    String cacheKey,
    Map<String, Map<String, dynamic>> cards,
  ) =>
      _performStore(
        cacheKey,
        cards,
      );

  String _cardsCacheKey(List<String> ids) {
    final sorted = [...ids]..sort();
    return sorted.join('|');
  }

  String _prefsKey(String cacheKey) => '$_prefsPrefix:$cacheKey';
}
