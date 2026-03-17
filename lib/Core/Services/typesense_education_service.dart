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

  static final TypesenseEducationSearchService instance =
      TypesenseEducationSearchService._();
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsPrefix = 'typesense_education_search_v1';

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final Map<String, _CachedEducationSearchResult> _memory =
      <String, _CachedEducationSearchResult>{};
  SharedPreferences? _prefs;

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
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _CachedEducationSearchResult(
          result: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
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
        .map((raw) => Map<String, dynamic>.from(raw))
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

  EducationTypesenseSearchResult? _getFromMemory(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _ttl) {
      _memory.remove(key);
      return null;
    }
    return entry.result;
  }

  Future<EducationTypesenseSearchResult?> _getFromPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final data = Map<String, dynamic>.from(
        decoded['d'] as Map? ?? const <String, dynamic>{},
      );
      if (ts <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      final hits = ((data['hits'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .toList(growable: false);
      return EducationTypesenseSearchResult(
        hits: hits,
        found: (data['found'] as num?)?.toInt() ?? hits.length,
        page: (data['page'] as num?)?.toInt() ?? 1,
        limit: (data['limit'] as num?)?.toInt() ?? hits.length,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _store(
    String key,
    EducationTypesenseSearchResult result,
  ) async {
    final cachedAt = DateTime.now();
    _memory[key] = _CachedEducationSearchResult(
      result: result,
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(key),
      jsonEncode(<String, dynamic>{
        't': cachedAt.millisecondsSinceEpoch,
        'd': <String, dynamic>{
          'hits': result.hits,
          'found': result.found,
          'page': result.page,
          'limit': result.limit,
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
  const _CachedEducationSearchResult({
    required this.result,
    required this.cachedAt,
  });

  final EducationTypesenseSearchResult result;
  final DateTime cachedAt;
}

class EducationTypesenseSearchResult {
  const EducationTypesenseSearchResult({
    required this.hits,
    required this.found,
    required this.page,
    required this.limit,
  });

  final List<Map<String, dynamic>> hits;
  final int found;
  final int page;
  final int limit;
}
