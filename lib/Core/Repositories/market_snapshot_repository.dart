import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';
import 'package:turqappv2/Models/market_item_model.dart';

part 'market_snapshot_repository_data_part.dart';
part 'market_snapshot_repository_models_part.dart';
part 'market_snapshot_repository_facade_part.dart';

class MarketSnapshotRepository extends GetxService {
  MarketSnapshotRepository();

  static const String _homeSurfaceKey = 'market_home_snapshot';
  static const String _searchSurfaceKey = 'market_search_snapshot';

  static MarketSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<MarketSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<MarketSnapshotRepository>();
  }

  static MarketSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(MarketSnapshotRepository(), permanent: true);
  }

  late final CacheFirstCoordinator<List<MarketItemModel>> _coordinator =
      CacheFirstCoordinator<List<MarketItemModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<MarketItemModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<MarketItemModel>>(
      prefsPrefix: 'market_snapshot_v1',
      encode: _encodeItems,
      decode: _decodeItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<MarketItemModel>>(),
    policy: const CacheFirstPolicy(
      snapshotTtl: Duration(minutes: 20),
      minLiveSyncInterval: Duration(seconds: 30),
      syncOnOpen: true,
      allowWarmLaunchFallback: true,
      persistWarmLaunchSnapshot: true,
      treatWarmLaunchAsStale: true,
      preservePreviousOnEmptyLive: true,
    ),
  );

  late final CacheFirstQueryPipeline<MarketListingQuery, List<MarketItemModel>,
          List<MarketItemModel>> _homePipeline =
      CacheFirstQueryPipeline<MarketListingQuery, List<MarketItemModel>,
          List<MarketItemModel>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.scopeId,
    fetchRaw: _fetchItems,
    resolve: (items) => items,
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
  );

  late final CacheFirstQueryPipeline<MarketListingQuery, List<MarketItemModel>,
          List<MarketItemModel>> _searchPipeline =
      CacheFirstQueryPipeline<MarketListingQuery, List<MarketItemModel>,
          List<MarketItemModel>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.scopeId,
    fetchRaw: _fetchItems,
    resolve: (items) => items,
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
  );
}
