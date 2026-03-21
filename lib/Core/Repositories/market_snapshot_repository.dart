import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';
import 'package:turqappv2/Models/market_item_model.dart';

class MarketListingQuery {
  const MarketListingQuery({
    required this.query,
    required this.userId,
    this.limit = 120,
    this.page = 1,
    this.scopeTag = '',
  });

  final String query;
  final String userId;
  final int limit;
  final int page;
  final String scopeTag;

  String get scopeId => <String>[
        query.trim(),
        'limit=$limit',
        'page=$page',
        'scope=${scopeTag.trim()}',
      ].join('|');
}

class MarketSnapshotRepository extends GetxService {
  MarketSnapshotRepository();

  static const String _homeSurfaceKey = 'market_home_snapshot';
  static const String _searchSurfaceKey = 'market_search_snapshot';

  static MarketSnapshotRepository? maybeFind() {
    if (!Get.isRegistered<MarketSnapshotRepository>()) return null;
    return Get.find<MarketSnapshotRepository>();
  }

  static MarketSnapshotRepository _ensureService() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(MarketSnapshotRepository(), permanent: true);
  }

  static MarketSnapshotRepository ensure() {
    return _ensureService();
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

  Stream<CachedResource<List<MarketItemModel>>> openHome({
    required String userId,
    int limit = 120,
    int page = 1,
    bool forceSync = false,
  }) {
    return _homePipeline.open(
      MarketListingQuery(
        query: '*',
        userId: userId,
        limit: limit,
        page: page,
        scopeTag: page <= 1 ? 'home' : 'home_page_$page',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<MarketItemModel>>> loadHome({
    required String userId,
    int limit = 120,
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
    int limit = 40,
    int page = 1,
    bool forceSync = false,
  }) {
    return _searchPipeline.open(
      MarketListingQuery(
        query: query,
        userId: userId,
        limit: limit,
        page: page,
        scopeTag: page <= 1 ? 'search' : 'search_page_$page',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<MarketItemModel>>> search({
    required String query,
    required String userId,
    int limit = 40,
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

  Future<List<MarketItemModel>> _fetchItems(MarketListingQuery query) {
    return TypesenseMarketSearchService.instance.searchItems(
      query: query.query,
      limit: query.limit,
      page: query.page,
      preferCache: true,
    );
  }

  Future<List<MarketItemModel>?> _loadWarmSnapshot(
    MarketListingQuery query,
  ) async {
    final items = await TypesenseMarketSearchService.instance.searchItems(
      query: query.query,
      limit: query.limit,
      page: query.page,
      preferCache: true,
      cacheOnly: true,
    );
    return items.isEmpty ? null : items;
  }

  Map<String, dynamic> _encodeItems(List<MarketItemModel> items) {
    return <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }

  List<MarketItemModel> _decodeItems(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) => MarketItemModel.fromJson(Map<String, dynamic>.from(raw)))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}
