part of 'explore_repository.dart';

extension ExploreRepositoryFacadePart on ExploreRepository {
  Future<ExploreQueryPage> fetchExplorePostsPage({
    DocumentSnapshot? startAfter,
    int pageLimit = ReadBudgetRegistry.explorePostsPageLimit,
    int? nowMs,
  }) =>
      _fetchExplorePostsPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<ExploreQueryPage> fetchVideoReadyPage({
    DocumentSnapshot? startAfter,
    int pageLimit = ReadBudgetRegistry.exploreVideoPageLimit,
    int? nowMs,
  }) =>
      _fetchVideoReadyPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<ExploreQueryPage> fetchVideoFallbackPage({
    DocumentSnapshot? startAfter,
    int pageLimit = ReadBudgetRegistry.exploreVideoPageLimit,
    int? nowMs,
  }) =>
      _fetchVideoFallbackPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<ExploreQueryPage> fetchVideoBroadPage({
    DocumentSnapshot? startAfter,
    int pageLimit = ReadBudgetRegistry.exploreVideoPageLimit,
    int? nowMs,
  }) =>
      _fetchVideoBroadPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<ExploreQueryPage> fetchPhotoPage({
    DocumentSnapshot? startAfter,
    int pageLimit = ReadBudgetRegistry.explorePhotoPageLimit,
    int? nowMs,
  }) =>
      _fetchPhotoPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<ExploreQueryPage> fetchFloodServerPage({
    DocumentSnapshot? startAfter,
    int pageLimit = ReadBudgetRegistry.exploreFloodPageLimit,
    int? nowMs,
  }) =>
      _fetchFloodServerPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<ExploreQueryPage> fetchStoredFloodManifestPage({
    required int offset,
    int pageLimit = ReadBudgetRegistry.exploreFloodPageLimit,
    int? nowMs,
  }) =>
      _fetchStoredFloodManifestPage(
        offset: offset,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<void> ensureFloodManifestStoreFresh({bool force = false}) =>
      _ensureFloodManifestStoreFresh(force: force);

  Future<int> ensureFloodManifestStoreReady({
    bool force = false,
    Duration timeout = const Duration(seconds: 8),
  }) =>
      _ensureFloodManifestStoreReady(
        force: force,
        timeout: timeout,
      );

  Future<List<PostsModel>> loadFloodManifestSeries(String anyFloodId) =>
      _loadFloodManifestSeries(anyFloodId);

  Future<ExploreQueryPage> fetchFloodFallbackPage({
    DocumentSnapshot? startAfter,
    int pageLimit = ReadBudgetRegistry.exploreFloodPageLimit,
    int? nowMs,
  }) =>
      _fetchFloodFallbackPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<Map<String, PostsModel>> fetchPostsByIds(
    List<String> postIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) {
    return PostRepository.ensure().fetchPostsByIds(
      postIds,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
  }
}
