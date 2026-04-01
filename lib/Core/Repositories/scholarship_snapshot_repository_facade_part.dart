part of 'scholarship_snapshot_repository.dart';

ScholarshipSnapshotRepository? maybeFindScholarshipSnapshotRepository() {
  final isRegistered = Get.isRegistered<ScholarshipSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<ScholarshipSnapshotRepository>();
}

ScholarshipSnapshotRepository ensureScholarshipSnapshotRepository() {
  final existing = maybeFindScholarshipSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(ScholarshipSnapshotRepository(), permanent: true);
}

extension ScholarshipSnapshotRepositoryFacadePart
    on ScholarshipSnapshotRepository {
  Future<CachedResource<ScholarshipListingSnapshot>> loadCachedHome({
    required String userId,
    int limit = ReadBudgetRegistry.scholarshipHomeInitialLimit,
    int page = 1,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.scholarships)) {
      return pasajDisabledResource<ScholarshipListingSnapshot>(
        const ScholarshipListingSnapshot(
          items: <Map<String, dynamic>>[],
          found: 0,
        ),
      );
    }
    final effectiveLimit =
        ReadBudgetRegistry.resolveScholarshipHomeInitialLimit(
      limit,
    );
    final query = EducationTypesenseQuery(
      entity: EducationTypesenseEntity.scholarship,
      query: '*',
      limit: effectiveLimit,
      page: page,
      userId: userId,
      scopeTag: page <= 1 ? 'home' : 'home_page_$page',
    );
    final schemaVersion = CacheFirstPolicyRegistry.schemaVersionForSurface(
      ScholarshipSnapshotRepository._homeSurfaceKey,
    );
    final key = ScopedSnapshotKey(
      surfaceKey: ScholarshipSnapshotRepository._homeSurfaceKey,
      userId: userId.trim(),
      scopeId: query.buildScopeId(schemaVersion: schemaVersion),
    );
    return _coordinator.bootstrap(
      key,
      loadWarmSnapshot: () => _loadWarmSnapshot(query),
      schemaVersion: schemaVersion,
    );
  }

  Stream<CachedResource<ScholarshipListingSnapshot>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.scholarshipHomeInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.scholarships)) {
      yield* pasajDisabledStream<ScholarshipListingSnapshot>(
        const ScholarshipListingSnapshot(
          items: <Map<String, dynamic>>[],
          found: 0,
        ),
      );
      return;
    }
    yield* _openHomeImpl(
      userId: userId,
      limit: ReadBudgetRegistry.resolveScholarshipHomeInitialLimit(limit),
      page: page,
      forceSync: forceSync,
    );
  }

  Future<CachedResource<ScholarshipListingSnapshot>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.scholarshipHomeInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.scholarships)) {
      return pasajDisabledResource<ScholarshipListingSnapshot>(
        const ScholarshipListingSnapshot(
          items: <Map<String, dynamic>>[],
          found: 0,
        ),
      );
    }
    return _loadHomeImpl(
      userId: userId,
      limit: ReadBudgetRegistry.resolveScholarshipHomeInitialLimit(limit),
      page: page,
      forceSync: forceSync,
    );
  }

  Stream<CachedResource<ScholarshipListingSnapshot>> openSearch({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.scholarshipSearchInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.scholarships)) {
      yield* pasajDisabledStream<ScholarshipListingSnapshot>(
        const ScholarshipListingSnapshot(
          items: <Map<String, dynamic>>[],
          found: 0,
        ),
      );
      return;
    }
    yield* _openSearchImpl(
      query: query,
      userId: userId,
      limit: ReadBudgetRegistry.resolveScholarshipSearchInitialLimit(limit),
      page: page,
      forceSync: forceSync,
    );
  }

  Future<CachedResource<ScholarshipListingSnapshot>> search({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.scholarshipSearchInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.scholarships)) {
      return pasajDisabledResource<ScholarshipListingSnapshot>(
        const ScholarshipListingSnapshot(
          items: <Map<String, dynamic>>[],
          found: 0,
        ),
      );
    }
    return _searchImpl(
      query: query,
      userId: userId,
      limit: ReadBudgetRegistry.resolveScholarshipSearchInitialLimit(limit),
      page: page,
      forceSync: forceSync,
    );
  }

  Future<void> invalidateUserScopedSurfaces(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;
    await Future.wait(<Future<void>>[
      _coordinator.clearSurface(
        ScholarshipSnapshotRepository._homeSurfaceKey,
        userId: normalized,
      ),
      _coordinator.clearSurface(
        ScholarshipSnapshotRepository._searchSurfaceKey,
        userId: normalized,
      ),
    ]);
  }
}
