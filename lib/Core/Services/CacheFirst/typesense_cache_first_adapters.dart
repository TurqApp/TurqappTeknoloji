import 'dart:async';

import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';

import 'cache_first_policy_registry.dart';
import 'cache_scope_namespace.dart';
import 'cache_first_coordinator.dart';
import 'cache_first_query_pipeline.dart';
import 'cached_resource.dart';

class EducationTypesenseQuery {
  const EducationTypesenseQuery({
    required this.entity,
    required this.query,
    this.limit = 30,
    this.page = 1,
    this.filterBy,
    this.sortBy,
    this.userId = '',
    this.scopeTag = '',
  });

  final EducationTypesenseEntity entity;
  final String query;
  final int limit;
  final int page;
  final String? filterBy;
  final String? sortBy;
  final String userId;
  final String scopeTag;

  String buildScopeId({
    required int schemaVersion,
  }) {
    return CacheScopeNamespace.buildQueryScope(
      userId: userId,
      limit: limit,
      scopeTag: scopeTag,
      schemaVersion: schemaVersion,
      qualifiers: <String, Object?>{
        'entity': _educationEntityApiLabel(entity),
        'q': query.trim(),
        'page': page,
        'filter': (filterBy ?? '').trim(),
        'sort': (sortBy ?? '').trim(),
      },
    );
  }
}

String _educationEntityApiLabel(EducationTypesenseEntity entity) {
  switch (entity) {
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

class MarketTypesenseQuery {
  const MarketTypesenseQuery({
    required this.query,
    this.limit = 30,
    this.page = 1,
    this.docId,
    this.userId,
    this.categoryKey,
    this.city,
    this.district,
    this.scopeTag = '',
  });

  final String query;
  final int limit;
  final int page;
  final String? docId;
  final String? userId;
  final String? categoryKey;
  final String? city;
  final String? district;
  final String scopeTag;

  String buildScopeId({
    required int schemaVersion,
  }) {
    return CacheScopeNamespace.buildQueryScope(
      userId: userId ?? '',
      limit: limit,
      scopeTag: scopeTag,
      schemaVersion: schemaVersion,
      qualifiers: <String, Object?>{
        'q': query.trim(),
        'page': page,
        'docId': (docId ?? '').trim(),
        'category': (categoryKey ?? '').trim(),
        'city': (city ?? '').trim(),
        'district': (district ?? '').trim(),
      },
    );
  }
}

class EducationTypesenseCacheFirstAdapter<TResolved> {
  EducationTypesenseCacheFirstAdapter({
    required this.surfaceKey,
    required CacheFirstCoordinator<TResolved> coordinator,
    required FutureOr<TResolved> Function(EducationTypesenseSearchResult raw)
        resolve,
    Future<TResolved?> Function(EducationTypesenseQuery query)?
        loadWarmSnapshot,
    bool Function(TResolved value)? isEmpty,
    int? schemaVersion,
  }) : _pipeline = CacheFirstQueryPipeline<EducationTypesenseQuery,
            EducationTypesenseSearchResult, TResolved>(
          surfaceKey: surfaceKey,
          coordinator: coordinator,
          userIdResolver: (query) => query.userId.trim(),
          scopeIdBuilder: (query) => query.buildScopeId(
            schemaVersion: schemaVersion ??
                CacheFirstPolicyRegistry.schemaVersionForSurface(surfaceKey),
          ),
          fetchRaw: (query) {
            return TypesenseEducationSearchService.instance.searchHits(
              entity: query.entity,
              query: query.query,
              limit: query.limit,
              page: query.page,
              filterBy: query.filterBy,
              sortBy: query.sortBy,
            );
          },
          resolve: resolve,
          loadWarmSnapshot: loadWarmSnapshot,
          isEmpty: isEmpty,
          liveSource: CachedResourceSource.server,
          schemaVersion: schemaVersion ??
              CacheFirstPolicyRegistry.schemaVersionForSurface(surfaceKey),
        );

  final String surfaceKey;
  final CacheFirstQueryPipeline<EducationTypesenseQuery,
      EducationTypesenseSearchResult, TResolved> _pipeline;

  Stream<CachedResource<TResolved>> open(
    EducationTypesenseQuery query, {
    bool forceSync = false,
  }) {
    return _pipeline.open(query, forceSync: forceSync);
  }
}

class MarketTypesenseCacheFirstAdapter<TResolved> {
  MarketTypesenseCacheFirstAdapter({
    required this.surfaceKey,
    required CacheFirstCoordinator<TResolved> coordinator,
    required FutureOr<TResolved> Function(List<dynamic> raw) resolve,
    Future<TResolved?> Function(MarketTypesenseQuery query)? loadWarmSnapshot,
    bool Function(TResolved value)? isEmpty,
    int? schemaVersion,
  }) : _pipeline = CacheFirstQueryPipeline<MarketTypesenseQuery, List<dynamic>,
            TResolved>(
          surfaceKey: surfaceKey,
          coordinator: coordinator,
          userIdResolver: (query) => (query.userId ?? '').trim(),
          scopeIdBuilder: (query) => query.buildScopeId(
            schemaVersion: schemaVersion ??
                CacheFirstPolicyRegistry.schemaVersionForSurface(surfaceKey),
          ),
          fetchRaw: (query) async {
            final items =
                await TypesenseMarketSearchService.instance.searchItems(
              query: query.query,
              limit: query.limit,
              page: query.page,
              docId: query.docId,
              userId: query.userId,
              categoryKey: query.categoryKey,
              city: query.city,
              district: query.district,
            );
            return List<dynamic>.from(items);
          },
          resolve: resolve,
          loadWarmSnapshot: loadWarmSnapshot,
          isEmpty: isEmpty,
          liveSource: CachedResourceSource.server,
          schemaVersion: schemaVersion ??
              CacheFirstPolicyRegistry.schemaVersionForSurface(surfaceKey),
        );

  final String surfaceKey;
  final CacheFirstQueryPipeline<MarketTypesenseQuery, List<dynamic>, TResolved>
      _pipeline;

  Stream<CachedResource<TResolved>> open(
    MarketTypesenseQuery query, {
    bool forceSync = false,
  }) {
    return _pipeline.open(query, forceSync: forceSync);
  }
}
