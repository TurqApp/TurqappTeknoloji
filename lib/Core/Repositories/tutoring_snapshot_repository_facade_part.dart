part of 'tutoring_snapshot_repository.dart';

TutoringSnapshotRepository? maybeFindTutoringSnapshotRepository() {
  final isRegistered = Get.isRegistered<TutoringSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<TutoringSnapshotRepository>();
}

TutoringSnapshotRepository ensureTutoringSnapshotRepository() {
  final existing = maybeFindTutoringSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(TutoringSnapshotRepository(), permanent: true);
}

extension TutoringSnapshotRepositoryFacadePart on TutoringSnapshotRepository {
  Future<CachedResource<List<TutoringModel>>> loadCachedOwner({
    required String userId,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.tutoring)) {
      return pasajDisabledResource<List<TutoringModel>>(
        const <TutoringModel>[],
      );
    }
    final query = TutoringOwnerQuery(userId: userId);
    final schemaVersion = CacheFirstPolicyRegistry.schemaVersionForSurface(
      TutoringSnapshotRepository._ownerSurfaceKey,
    );
    final key = ScopedSnapshotKey(
      surfaceKey: TutoringSnapshotRepository._ownerSurfaceKey,
      userId: userId.trim(),
      scopeId: query.buildScopeId(schemaVersion: schemaVersion),
    );
    return _coordinator.bootstrap(
      key,
      schemaVersion: schemaVersion,
    );
  }

  Stream<CachedResource<List<TutoringModel>>> openOwner({
    required String userId,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.tutoring)) {
      yield* pasajDisabledStream<List<TutoringModel>>(
        const <TutoringModel>[],
      );
      return;
    }
    yield* _ownerPipeline.open(
      TutoringOwnerQuery(userId: userId),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TutoringModel>>> loadOwner({
    required String userId,
    bool forceSync = false,
  }) {
    return openOwner(
      userId: userId,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<TutoringModel>>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.tutoringHomeInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.tutoring)) {
      yield* pasajDisabledStream<List<TutoringModel>>(
        const <TutoringModel>[],
      );
      return;
    }
    final effectiveLimit =
        ReadBudgetRegistry.resolveTutoringHomeInitialLimit(limit);
    yield* _homeAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.tutoring,
        query: '*',
        limit: effectiveLimit,
        page: page,
        userId: userId,
        scopeTag: page <= 1 ? 'home' : 'home_page_$page',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TutoringModel>>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.tutoringHomeInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      page: page,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<TutoringModel>>> openSearch({
    required String userId,
    required String query,
    int limit = ReadBudgetRegistry.tutoringSearchInitialLimit,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.tutoring)) {
      yield* pasajDisabledStream<List<TutoringModel>>(
        const <TutoringModel>[],
      );
      return;
    }
    final effectiveLimit =
        ReadBudgetRegistry.resolveTutoringSearchInitialLimit(limit);
    yield* _searchAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.tutoring,
        query: query,
        limit: effectiveLimit,
        page: 1,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TutoringModel>>> search({
    required String userId,
    required String query,
    int limit = ReadBudgetRegistry.tutoringSearchInitialLimit,
    bool forceSync = false,
  }) {
    return openSearch(
      userId: userId,
      query: query,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<void> invalidateUserScopedSurfaces(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;
    await Future.wait(<Future<void>>[
      _coordinator.clearSurface(
        TutoringSnapshotRepository._ownerSurfaceKey,
        userId: normalized,
      ),
      _coordinator.clearSurface(
        TutoringSnapshotRepository._homeSurfaceKey,
        userId: normalized,
      ),
      _coordinator.clearSurface(
        TutoringSnapshotRepository._searchSurfaceKey,
        userId: normalized,
      ),
    ]);
  }
}
