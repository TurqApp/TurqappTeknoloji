import 'dart:async';

import 'package:turqappv2/Core/Services/typesense_education_service.dart';

import 'cache_first_policy_registry.dart';
import 'cache_scope_namespace.dart';
import 'cache_first_coordinator.dart';
import 'cache_first_query_pipeline.dart';
import 'cached_resource.dart';

class EducationTypesenseDocIdQuery {
  const EducationTypesenseDocIdQuery({
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
        'entity': _entityApiLabel(entity),
        'q': query.trim(),
        'page': page,
        'filter': (filterBy ?? '').trim(),
        'sort': (sortBy ?? '').trim(),
      },
    );
  }
}

class EducationTypesenseDocIdHydrationAdapter<TResolved> {
  EducationTypesenseDocIdHydrationAdapter({
    required this.surfaceKey,
    required CacheFirstCoordinator<TResolved> coordinator,
    required Future<List<String>> Function(EducationTypesenseDocIdQuery query)
        fetchDocIds,
    required FutureOr<TResolved> Function(List<String> docIds) hydrate,
    Future<TResolved?> Function(EducationTypesenseDocIdQuery query)?
        loadWarmSnapshot,
    bool Function(TResolved value)? isEmpty,
    int? schemaVersion,
  }) : _pipeline = CacheFirstQueryPipeline<EducationTypesenseDocIdQuery,
            List<String>, TResolved>(
          surfaceKey: surfaceKey,
          coordinator: coordinator,
          userIdResolver: (query) => query.userId.trim(),
          scopeIdBuilder: (query) => query.buildScopeId(
            schemaVersion: schemaVersion ??
                CacheFirstPolicyRegistry.schemaVersionForSurface(surfaceKey),
          ),
          fetchRaw: fetchDocIds,
          resolve: hydrate,
          loadWarmSnapshot: loadWarmSnapshot,
          isEmpty: isEmpty,
          liveSource: CachedResourceSource.server,
          schemaVersion: schemaVersion ??
              CacheFirstPolicyRegistry.schemaVersionForSurface(surfaceKey),
        );

  final String surfaceKey;
  final CacheFirstQueryPipeline<EducationTypesenseDocIdQuery, List<String>,
      TResolved> _pipeline;

  Stream<CachedResource<TResolved>> open(
    EducationTypesenseDocIdQuery query, {
    bool forceSync = false,
  }) {
    return _pipeline.open(query, forceSync: forceSync);
  }

  static Future<List<String>> defaultFetchDocIds(
    EducationTypesenseDocIdQuery query,
  ) {
    return TypesenseEducationSearchService.instance.searchDocIds(
      entity: query.entity,
      query: query.query,
      limit: query.limit,
      page: query.page,
      filterBy: query.filterBy,
      sortBy: query.sortBy,
    );
  }
}

String _entityApiLabel(EducationTypesenseEntity entity) {
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
