part of 'market_snapshot_repository.dart';

MarketSnapshotRepository? _maybeFindMarketSnapshotRepository() {
  final isRegistered = Get.isRegistered<MarketSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<MarketSnapshotRepository>();
}

MarketSnapshotRepository _ensureMarketSnapshotRepository() {
  final existing = _maybeFindMarketSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(MarketSnapshotRepository(), permanent: true);
}

CacheFirstCoordinator<List<MarketItemModel>> _createMarketSnapshotCoordinator(
  MarketSnapshotRepository repository,
) {
  return CacheFirstCoordinator<List<MarketItemModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<MarketItemModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<MarketItemModel>>(
      prefsPrefix: 'market_snapshot_v1',
      encode: repository._encodeItems,
      decode: repository._decodeItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<MarketItemModel>>(),
    policy: CacheFirstPolicyRegistry.policyForSurface(
      MarketSnapshotRepository._homeSurfaceKey,
    ),
  );
}

CacheFirstQueryPipeline<MarketListingQuery, List<MarketItemModel>,
    List<MarketItemModel>> _createMarketSnapshotHomePipeline(
  MarketSnapshotRepository repository,
) {
  return CacheFirstQueryPipeline<MarketListingQuery, List<MarketItemModel>,
      List<MarketItemModel>>(
    surfaceKey: MarketSnapshotRepository._homeSurfaceKey,
    coordinator: repository._coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) =>
        query.buildScopeId(MarketSnapshotRepository._homeSurfaceKey),
    fetchRaw: repository._fetchItems,
    resolve: (items) => items,
    loadWarmSnapshot: repository._loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      MarketSnapshotRepository._homeSurfaceKey,
    ),
  );
}

CacheFirstQueryPipeline<MarketListingQuery, List<MarketItemModel>,
    List<MarketItemModel>> _createMarketSnapshotSearchPipeline(
  MarketSnapshotRepository repository,
) {
  return CacheFirstQueryPipeline<MarketListingQuery, List<MarketItemModel>,
      List<MarketItemModel>>(
    surfaceKey: MarketSnapshotRepository._searchSurfaceKey,
    coordinator: repository._coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) =>
        query.buildScopeId(MarketSnapshotRepository._searchSurfaceKey),
    fetchRaw: repository._fetchItems,
    resolve: (items) => items,
    loadWarmSnapshot: repository._loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      MarketSnapshotRepository._searchSurfaceKey,
    ),
  );
}
