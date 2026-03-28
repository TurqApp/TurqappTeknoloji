part of 'cikmis_sorular_snapshot_repository.dart';

CacheFirstCoordinator<List<Map<String, dynamic>>> _buildPastQuestionCoordinator(
  CikmisSorularSnapshotRepository repository,
) {
  return CacheFirstCoordinator<List<Map<String, dynamic>>>(
    memoryStore: MemoryScopedSnapshotStore<List<Map<String, dynamic>>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<Map<String, dynamic>>>(
      prefsPrefix: 'past_question_snapshot_v3',
      encode: repository._encodeDocs,
      decode: repository._decodeDocs,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<Map<String, dynamic>>>(),
    policy: CacheFirstPolicyRegistry.policyForSurface(
      _pastQuestionHomeSnapshotSurfaceKey,
    ),
  );
}

CacheFirstQueryPipeline<String, List<Map<String, dynamic>>,
    List<Map<String, dynamic>>> _buildPastQuestionHomePipeline(
  CikmisSorularSnapshotRepository repository,
) {
  return CacheFirstQueryPipeline<String, List<Map<String, dynamic>>,
      List<Map<String, dynamic>>>(
    surfaceKey: _pastQuestionHomeSnapshotSurfaceKey,
    coordinator: repository._coordinator,
    userIdResolver: (userId) => userId,
    scopeIdBuilder: (userId) => CacheScopeNamespace.buildQueryScope(
      userId: userId,
      limit: 0,
      scopeTag: 'home',
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        _pastQuestionHomeSnapshotSurfaceKey,
      ),
      qualifiers: const <String, Object?>{
        'entity': 'past_question_root',
      },
    ),
    fetchRaw: (_) => repository._repository.fetchRootDocs(preferCache: false),
    resolve: (docs) => docs,
    loadWarmSnapshot: (_) => repository._repository.fetchRootDocs(
      cacheOnly: true,
    ),
    isEmpty: (docs) => docs.isEmpty,
    liveSource: CachedResourceSource.server,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      _pastQuestionHomeSnapshotSurfaceKey,
    ),
  );
}
