part of 'market_snapshot_repository.dart';

extension MarketSnapshotRepositoryFacadePart on MarketSnapshotRepository {
  Stream<CachedResource<List<MarketItemModel>>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.marketHomeInitialLimit,
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
}
