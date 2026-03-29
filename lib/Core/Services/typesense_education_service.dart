import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum EducationTypesenseEntity {
  scholarship,
  practiceExam,
  answerKey,
  tutoring,
  job,
  workout,
  pastQuestion,
}

extension _EntityName on EducationTypesenseEntity {
  String get apiLabel {
    switch (this) {
      case EducationTypesenseEntity.scholarship:
        return 'scholarship';
      case EducationTypesenseEntity.practiceExam:
        return 'practice_exam';
      case EducationTypesenseEntity.answerKey:
        return 'answer_key';
      case EducationTypesenseEntity.tutoring:
        return 'tutoring';
      case EducationTypesenseEntity.job:
        return 'job';
      case EducationTypesenseEntity.workout:
        return 'workout';
      case EducationTypesenseEntity.pastQuestion:
        return 'past_question';
    }
  }
}

class TypesenseEducationSearchService {
  TypesenseEducationSearchService._();

  static TypesenseEducationSearchService? _instance;
  static TypesenseEducationSearchService? maybeFind() => _instance;

  static TypesenseEducationSearchService ensure() =>
      maybeFind() ?? (_instance = TypesenseEducationSearchService._());

  static TypesenseEducationSearchService get instance => ensure();
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsPrefix = 'typesense_education_search_v1';

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final Map<String, _CachedEducationSearchResult> _memory =
      <String, _CachedEducationSearchResult>{};
  SharedPreferences? _prefs;

  static dynamic _cloneValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneValue).toList(growable: false);
    }
    return value;
  }

  static Map<String, dynamic> _cloneHitMap(Map<String, dynamic> source) {
    return source.map(
      (key, value) => MapEntry(key, _cloneValue(value)),
    );
  }

  static List<Map<String, dynamic>> _cloneHits(
    List<Map<String, dynamic>> hits,
  ) {
    return hits.map(_cloneHitMap).toList(growable: false);
  }

  static EducationTypesenseSearchResult _cloneResult(
    EducationTypesenseSearchResult result,
  ) {
    return EducationTypesenseSearchResult(
      hits: _cloneHits(result.hits),
      found: result.found,
      page: result.page,
      limit: result.limit,
    );
  }

  static String quoteFilterValue(String value) {
    final normalized = value.trim().replaceAll('`', r'\`');
    return '`$normalized`';
  }

  static String filterIn(String field, List<String> values) {
    final normalized = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map(quoteFilterValue)
        .toList(growable: false);
    return '$field:=[${normalized.join(',')}]';
  }

  Future<EducationTypesenseSearchResult> searchHits({
    required EducationTypesenseEntity entity,
    required String query,
    int limit = 30,
    int page = 1,
    String? filterBy,
    String? sortBy,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final normalized = query.trim();
    final cacheKey = _searchCacheKey(
      entity: entity,
      query: normalized,
      limit: limit,
      page: page,
      filterBy: filterBy,
      sortBy: sortBy,
    );

    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getCachedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return _cloneResult(disk.result);
      }
    }

    if (cacheOnly) {
      return EducationTypesenseSearchResult(
        hits: const <Map<String, dynamic>>[],
        found: 0,
        page: page,
        limit: limit,
      );
    }

    final callable = _functions.httpsCallable('f21_searchEducationCallable');
    final payload = <String, dynamic>{
      'q': normalized.isEmpty ? '*' : normalized,
      'entity': entity.apiLabel,
      'limit': limit,
      'page': page,
    };
    final filter = filterBy?.trim() ?? '';
    if (filter.isNotEmpty) {
      payload['filterBy'] = filter;
    }
    final sort = sortBy?.trim() ?? '';
    if (sort.isNotEmpty) {
      payload['sortBy'] = sort;
    }
    final response = await callable.call(payload);
    final data = Map<String, dynamic>.from(response.data as Map? ?? {});
    final hits = ((data['hits'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((raw) => _cloneHitMap(Map<String, dynamic>.from(raw)))
        .toList(growable: false);
    final result = EducationTypesenseSearchResult(
      hits: hits,
      found: (data['found'] as num?)?.toInt() ?? hits.length,
      page: (data['page'] as num?)?.toInt() ?? page,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
    );
    await _store(cacheKey, result);
    return result;
  }

  Future<List<String>> searchDocIds({
    required EducationTypesenseEntity entity,
    required String query,
    int limit = 30,
    int page = 1,
    String? filterBy,
    String? sortBy,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return [];
    final result = await searchHits(
      entity: entity,
      query: normalized,
      limit: limit,
      page: page,
      filterBy: filterBy,
      sortBy: sortBy,
    );
    final ids = <String>[];
    for (final hitMap in result.hits) {
      final docId = (hitMap['docId'] ?? hitMap['id'])?.toString().trim() ?? '';
      if (docId.isNotEmpty) ids.add(docId);
    }
    return ids;
  }

  Future<void> invalidateEntity(EducationTypesenseEntity entity) async {
    final entityPrefix = 'entity=${entity.apiLabel}|';
    _memory.removeWhere((key, _) => key.startsWith(entityPrefix));
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs.getKeys().where((key) {
      if (!key.startsWith('$_prefsPrefix:')) return false;
      final scopedKey = key.substring('$_prefsPrefix:'.length);
      return scopedKey.startsWith(entityPrefix);
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

  EducationTypesenseSearchResult? _getFromMemory(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _ttl) {
      _memory.remove(key);
      return null;
    }
    return _cloneResult(entry.result);
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(value.trim());
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

  Future<_CachedEducationSearchResult?> _getCachedFromPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = _prefsKey(key);
    final raw = prefs?.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final ts = _asInt(decoded['t']);
      final data = Map<String, dynamic>.from(
        decoded['d'] as Map? ?? const <String, dynamic>{},
      );
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > _ttl) {
        await prefs?.remove(prefsKey);
        return null;
      }
      var shouldPrune = false;
      final hits = <Map<String, dynamic>>[];
      for (final rawHit
          in ((data['hits'] as List<dynamic>?) ?? const <dynamic>[])) {
        if (rawHit is! Map) {
          shouldPrune = true;
          continue;
        }
        final hit = _cloneHitMap(Map<String, dynamic>.from(rawHit));
        if (hit.isEmpty) {
          shouldPrune = true;
          continue;
        }
        hits.add(hit);
      }
      if (shouldPrune) {
        if (hits.isEmpty) {
          await prefs?.remove(prefsKey);
          return null;
        }
        await prefs?.setString(
          prefsKey,
          jsonEncode(<String, dynamic>{
            't': ts,
            'd': <String, dynamic>{
              'hits': hits,
              'found': _asInt(data['found'], fallback: hits.length),
              'page': _asInt(data['page'], fallback: 1),
              'limit': _asInt(data['limit'], fallback: hits.length),
            },
          }),
        );
      }
      return _CachedEducationSearchResult(
        result: EducationTypesenseSearchResult(
          hits: hits,
          found: _asInt(data['found'], fallback: hits.length),
          page: _asInt(data['page'], fallback: 1),
          limit: _asInt(data['limit'], fallback: hits.length),
        ),
        cachedAt: cachedAt,
      );
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<void> _store(
    String key,
    EducationTypesenseSearchResult result,
  ) async {
    final cachedAt = DateTime.now();
    final clonedResult = _cloneResult(result);
    _memory[key] = _CachedEducationSearchResult(
      result: clonedResult,
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(key),
      jsonEncode(<String, dynamic>{
        't': cachedAt.millisecondsSinceEpoch,
        'd': <String, dynamic>{
          'hits': clonedResult.hits,
          'found': clonedResult.found,
          'page': clonedResult.page,
          'limit': clonedResult.limit,
        },
      }),
    );
  }

  String _searchCacheKey({
    required EducationTypesenseEntity entity,
    required String query,
    required int limit,
    required int page,
    String? filterBy,
    String? sortBy,
  }) {
    return <String>[
      'entity=${entity.apiLabel}',
      'q=${query.trim()}',
      'limit=$limit',
      'page=$page',
      'filter=${(filterBy ?? '').trim()}',
      'sort=${(sortBy ?? '').trim()}',
    ].join('|');
  }

  String _prefsKey(String key) => '$_prefsPrefix:$key';
}

class _CachedEducationSearchResult {
  _CachedEducationSearchResult({
    required EducationTypesenseSearchResult result,
    required this.cachedAt,
  }) : result = TypesenseEducationSearchService._cloneResult(result);

  final EducationTypesenseSearchResult result;
  final DateTime cachedAt;
}

class EducationTypesenseSearchResult {
  EducationTypesenseSearchResult({
    required List<Map<String, dynamic>> hits,
    required this.found,
    required this.page,
    required this.limit,
  }) : hits = TypesenseEducationSearchService._cloneHits(hits);

  final List<Map<String, dynamic>> hits;
  final int found;
  final int page;
  final int limit;
}
