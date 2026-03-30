part of 'explore_repository.dart';

extension ExploreRepositoryPagePart on ExploreRepository {
  Future<ExploreQueryPage> _runPageQueryImpl(
    Query<Map<String, dynamic>> query, {
    bool excludeSeriesRoots = false,
    required int pageLimit,
    required String feedMode,
  }) async {
    final snap = await PerformanceService.traceFeedLoad(
      () => query.get(),
      feedMode: feedMode,
    );
    final postIds = snap.docs.map((doc) => doc.id).toList(growable: false);
    final byId = await fetchPostsByIds(postIds, preferCache: true);
    final items = postIds
        .map((id) => byId[id])
        .whereType<PostsModel>()
        .where((item) => !item.shouldHideWhileUploading)
        .where((item) => !excludeSeriesRoots || item.floodCount <= 1)
        .take(pageLimit)
        .toList(growable: false);
    return ExploreQueryPage(
      items,
      snap.docs.isEmpty ? null : snap.docs.last,
      snap.docs.length >= (excludeSeriesRoots ? pageLimit * 3 : pageLimit),
    );
  }
}
