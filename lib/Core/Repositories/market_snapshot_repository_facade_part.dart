part of 'market_snapshot_repository.dart';

extension MarketSnapshotRepositoryFacadePart on MarketSnapshotRepository {
  Future<CachedResource<List<MarketItemModel>>> loadCachedOwner({
    required String userId,
    int limit = ReadBudgetRegistry.marketOwnerInitialLimit,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.market)) {
      return pasajDisabledResource<List<MarketItemModel>>(
        const <MarketItemModel>[],
      );
    }
    final effectiveLimit =
        ReadBudgetRegistry.resolveMarketOwnerInitialLimit(limit);
    final query = MarketOwnerQuery(
      userId: userId,
      limit: effectiveLimit,
    );
    final schemaVersion = CacheFirstPolicyRegistry.schemaVersionForSurface(
      MarketSnapshotRepository._ownerSurfaceKey,
    );
    final key = ScopedSnapshotKey(
      surfaceKey: MarketSnapshotRepository._ownerSurfaceKey,
      userId: userId.trim(),
      scopeId: query.buildScopeId(MarketSnapshotRepository._ownerSurfaceKey),
    );
    return _coordinator.bootstrap(
      key,
      schemaVersion: schemaVersion,
    );
  }

  Stream<CachedResource<List<MarketItemModel>>> openOwner({
    required String userId,
    int limit = ReadBudgetRegistry.marketOwnerInitialLimit,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.market)) {
      yield* pasajDisabledStream<List<MarketItemModel>>(
        const <MarketItemModel>[],
      );
      return;
    }
    final effectiveLimit =
        ReadBudgetRegistry.resolveMarketOwnerInitialLimit(limit);
    yield* _ownerPipeline.open(
      MarketOwnerQuery(
        userId: userId,
        limit: effectiveLimit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<MarketItemModel>>> loadOwner({
    required String userId,
    int limit = ReadBudgetRegistry.marketOwnerInitialLimit,
    bool forceSync = false,
  }) {
    return openOwner(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<MarketItemModel>>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.marketHomeInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.market)) {
      yield* pasajDisabledStream<List<MarketItemModel>>(
        const <MarketItemModel>[],
      );
      return;
    }
    final effectiveLimit = ReadBudgetRegistry.resolveMarketHomeInitialLimit(
      limit,
    );
    yield* _homePipeline.open(
      MarketListingQuery(
        query: '*',
        userId: userId,
        limit: effectiveLimit,
        page: page,
        scopeTag: page <= 1 ? 'home' : 'home_page_$page',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<MarketItemModel>>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.marketHomeInitialLimit,
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

  Stream<CachedResource<List<MarketItemModel>>> openSearch({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.marketSearchInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.market)) {
      yield* pasajDisabledStream<List<MarketItemModel>>(
        const <MarketItemModel>[],
      );
      return;
    }
    final effectiveLimit = ReadBudgetRegistry.resolveMarketSearchInitialLimit(
      limit,
    );
    yield* _searchPipeline.open(
      MarketListingQuery(
        query: query,
        userId: userId,
        limit: effectiveLimit,
        page: page,
        scopeTag: page <= 1 ? 'search' : 'search_page_$page',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<MarketItemModel>>> search({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.marketSearchInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) {
    return openSearch(
      query: query,
      userId: userId,
      limit: limit,
      page: page,
      forceSync: forceSync,
    ).last;
  }

  Future<void> invalidateUserScopedSurfaces(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;
    await Future.wait(<Future<void>>[
      _coordinator.clearSurface(
        MarketSnapshotRepository._ownerSurfaceKey,
        userId: normalized,
      ),
      _coordinator.clearSurface(
        MarketSnapshotRepository._homeSurfaceKey,
        userId: normalized,
      ),
      _coordinator.clearSurface(
        MarketSnapshotRepository._searchSurfaceKey,
        userId: normalized,
      ),
    ]);
  }
}
