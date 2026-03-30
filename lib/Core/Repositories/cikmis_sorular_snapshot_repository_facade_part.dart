part of 'cikmis_sorular_snapshot_repository.dart';

CikmisSorularSnapshotRepository? maybeFindCikmisSorularSnapshotRepository() {
  final isRegistered = Get.isRegistered<CikmisSorularSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<CikmisSorularSnapshotRepository>();
}

CikmisSorularSnapshotRepository ensureCikmisSorularSnapshotRepository() {
  final existing = maybeFindCikmisSorularSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(CikmisSorularSnapshotRepository(), permanent: true);
}

extension CikmisSorularSnapshotRepositoryFacadePart
    on CikmisSorularSnapshotRepository {
  Future<CachedResource<List<Map<String, dynamic>>>> loadCachedHome({
    required String userId,
  }) {
    final schemaVersion = CacheFirstPolicyRegistry.schemaVersionForSurface(
      _pastQuestionHomeSnapshotSurfaceKey,
    );
    final key = ScopedSnapshotKey(
      surfaceKey: _pastQuestionHomeSnapshotSurfaceKey,
      userId: userId,
      scopeId: CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: 0,
        scopeTag: 'home',
        schemaVersion: schemaVersion,
        qualifiers: const <String, Object?>{
          'entity': 'past_question_root',
        },
      ),
    );
    return _coordinator.bootstrap(
      key,
      loadWarmSnapshot: () => _repository.fetchRootDocs(cacheOnly: true),
      schemaVersion: schemaVersion,
    );
  }

  Stream<CachedResource<List<Map<String, dynamic>>>> openHome({
    required String userId,
    bool forceSync = false,
  }) {
    return _homePipeline.open(userId, forceSync: forceSync);
  }

  Future<CachedResource<List<Map<String, dynamic>>>> loadHome({
    required String userId,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<Map<String, dynamic>>>> openSearch({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.pastQuestionSearchInitialLimit,
    bool forceSync = false,
  }) =>
      openPastQuestionSearch(
        this,
        query: query,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Future<CachedResource<List<Map<String, dynamic>>>> search({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.pastQuestionSearchInitialLimit,
    bool forceSync = false,
  }) {
    return openSearch(
      query: query,
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }
}
