import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Services/app_cloud_functions.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

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

class _CachedMotorCandidatesResult {
  const _CachedMotorCandidatesResult({
    required this.result,
    required this.cachedAt,
  });

  final TypesenseMotorCandidatesResult result;
  final DateTime cachedAt;

  bool get isFresh =>
      DateTime.now().difference(cachedAt) <
      TypesensePostService._motorCandidatesTtl;
}

class TypesenseMotorCandidatesResult {
  const TypesenseMotorCandidatesResult({
    required this.surface,
    required this.ownedMinutes,
    required this.limit,
    required this.page,
    required this.found,
    required this.outOf,
    required this.searchTimeMs,
    required this.hits,
  });

  final String surface;
  final List<int> ownedMinutes;
  final int limit;
  final int page;
  final int found;
  final int outOf;
  final int searchTimeMs;
  final List<Map<String, dynamic>> hits;
}

class TypesensePostService {
  TypesensePostService._();

  static TypesensePostService? _instance;
  static TypesensePostService? maybeFind() => _instance;

  static TypesensePostService ensure() =>
      maybeFind() ?? (_instance = TypesensePostService._());

  static TypesensePostService get instance => ensure();
  static const Duration _ttl = Duration(minutes: 15);
  static const Duration _motorCandidatesTtl = Duration(seconds: 12);
  static const String _prefsPrefix = 'typesense_post_cards_v1';

  final List<({String label, FirebaseFunctions fn})> _targets =
      <({String label, FirebaseFunctions fn})>[
    (label: 'default', fn: AppCloudFunctions.instance),
    (
      label: 'us-central1',
      fn: AppCloudFunctions.instanceFor(region: 'us-central1'),
    ),
    (
      label: 'europe-west1',
      fn: AppCloudFunctions.instanceFor(region: 'europe-west1'),
    ),
  ];
  final Map<String, _CachedPostCardsResult> _memory =
      <String, _CachedPostCardsResult>{};
  final Map<String, _CachedMotorCandidatesResult> _motorCandidatesMemory =
      <String, _CachedMotorCandidatesResult>{};
  final Map<String, Future<TypesenseMotorCandidatesResult>>
      _motorCandidatesInFlight =
      <String, Future<TypesenseMotorCandidatesResult>>{};
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

  Future<TypesenseMotorCandidatesResult> fetchMotorCandidates({
    required String surface,
    required List<int> ownedMinutes,
    int limit = 40,
    int page = 1,
    int? nowMs,
    int? cutoffMs,
    String locationCity = '',
    bool randomize = false,
    int randomWindowDays = 4,
  }) =>
      _performFetchMotorCandidates(
        surface: surface,
        ownedMinutes: ownedMinutes,
        limit: limit,
        page: page,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        locationCity: locationCity,
        randomize: randomize,
        randomWindowDays: randomWindowDays,
      );

  Future<void> primeMotorCandidates({
    required String surface,
    required List<int> ownedMinutes,
    int limit = 40,
    int page = 1,
    int? nowMs,
    int? cutoffMs,
    String locationCity = '',
    bool randomize = false,
    int randomWindowDays = 4,
  }) =>
      _performPrimeMotorCandidates(
        surface: surface,
        ownedMinutes: ownedMinutes,
        limit: limit,
        page: page,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        locationCity: locationCity,
        randomize: randomize,
        randomWindowDays: randomWindowDays,
      );

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
