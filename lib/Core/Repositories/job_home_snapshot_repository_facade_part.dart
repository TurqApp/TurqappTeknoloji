part of 'job_home_snapshot_repository.dart';

JobHomeSnapshotRepository? maybeFindJobHomeSnapshotRepository() {
  final isRegistered = Get.isRegistered<JobHomeSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<JobHomeSnapshotRepository>();
}

JobHomeSnapshotRepository ensureJobHomeSnapshotRepository() {
  final existing = maybeFindJobHomeSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(JobHomeSnapshotRepository(), permanent: true);
}

extension JobHomeSnapshotRepositoryFacadePart on JobHomeSnapshotRepository {
  Future<CachedResource<List<JobModel>>> loadCachedOwner({
    required String userId,
    int limit = ReadBudgetRegistry.jobOwnerInitialLimit,
  }) {
    final query = JobOwnerQuery(
      userId: userId,
      limit: limit,
    );
    final surfaceKey = JobHomeSnapshotRepository._ownerSurfaceKey;
    final schemaVersion = CacheFirstPolicyRegistry.schemaVersionForSurface(
      surfaceKey,
    );
    final key = ScopedSnapshotKey(
      surfaceKey: surfaceKey,
      userId: userId.trim(),
      scopeId: query.buildScopeId(schemaVersion: schemaVersion),
    );
    return _coordinator.bootstrap(
      key,
      schemaVersion: schemaVersion,
    );
  }

  Stream<CachedResource<List<JobModel>>> openOwner({
    required String userId,
    int limit = ReadBudgetRegistry.jobOwnerInitialLimit,
    bool forceSync = false,
  }) {
    return _ownerPipeline.open(
      JobOwnerQuery(
        userId: userId,
        limit: limit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<JobModel>>> loadOwner({
    required String userId,
    int limit = ReadBudgetRegistry.jobOwnerInitialLimit,
    bool forceSync = false,
  }) {
    return openOwner(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<JobModel>>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.jobHomeInitialLimit,
    bool forceSync = false,
  }) {
    return _homeAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.job,
        query: '*',
        limit: limit,
        userId: userId,
        scopeTag: 'home',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<JobModel>>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.jobHomeInitialLimit,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<JobModel>>> openSearch({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.jobSearchInitialLimit,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.job,
        query: query,
        limit: limit,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<JobModel>>> search({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.jobSearchInitialLimit,
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
