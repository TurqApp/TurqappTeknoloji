part of 'explore_controller.dart';

extension ExploreControllerApiX on ExploreController {
  void _bindFollowingListener() => _performBindFollowingListener();

  Future<void> _fetchFollowingIDs(String uid) => _performFetchFollowingIDs(uid);

  Future<void> fetchExplorePosts() => _performFetchExplorePosts();

  Future<void> _quickFillExploreFromPoolAndBootstrap() =>
      _performQuickFillExploreFromPoolAndBootstrap();

  Future<void> prepareStartupSurface({bool? allowBackgroundRefresh}) =>
      _performPrepareStartupSurface(
        allowBackgroundRefresh: allowBackgroundRefresh,
      );

  Future<void> persistStartupShard() => _persistExploreStartupShard();

  Future<void> _tryQuickFillExploreFromPool() =>
      _performTryQuickFillExploreFromPool();

  Future<void> _cleanupExplorePoolFill(List<PostsModel> shown) =>
      _performCleanupExplorePoolFill(shown);

  Future<void> _saveExplorePostsToPool(List<PostsModel> posts) =>
      _performSaveExplorePostsToPool(posts);

  bool _isEligibleExplorePost(PostsModel post) =>
      _performIsEligibleExplorePost(post);

  String _exploreCanonicalId(PostsModel post) =>
      _performExploreCanonicalId(post);

  List<PostsModel> _dedupeExplorePosts(List<PostsModel> posts) =>
      _performDedupeExplorePosts(posts);

  Future<List<PostsModel>> _validatePoolPostsAndPrune(List<PostsModel> posts) =>
      _performValidatePoolPostsAndPrune(posts);

  Future<void> fetchTrendingTags({bool forceRefresh = false}) =>
      _performFetchTrendingTags(forceRefresh: forceRefresh);

  Future<void> fetchVideo() => _performFetchVideo();

  Future<void> fetchPhoto() => _performFetchPhoto();

  Future<void> fetchFloods() => _performFetchFloods();

  Future<List<PostsModel>> _filterByPrivacy(List<PostsModel> items) =>
      _performFilterByPrivacy(items);

  List<PostsModel> _prioritizeCachedVideos(List<PostsModel> items) =>
      _performPrioritizeCachedVideos(items);

  void _scheduleExplorePrefetchFromPosts(List<PostsModel> source) =>
      _performScheduleExplorePrefetchFromPosts(source);

  Future<dynamic> _callTypesenseCallable(
          String callableName, Map<String, dynamic> payload) =>
      _performCallTypesenseCallable(callableName, payload);

  Future<List<OgrenciModel>> _filterPendingOrDeletedUsers(
          List<OgrenciModel> users) =>
      _performFilterPendingOrDeletedUsers(users);

  void onSearchChanged(String value) => _handleOnSearchChanged(value);

  void _clearSearchResults() => _handleClearSearchResults();

  Future<void> search(String query) => _handleSearch(query);

  void resetSearchToDefault() => _handleResetSearchToDefault();

  void resetSurfaceForTabTransition() => _handleResetSurfaceForTabTransition();

  void capturePendingFloodEntry({int? preferredIndex, PostsModel? model}) =>
      _performCapturePendingFloodEntry(
        preferredIndex: preferredIndex,
        model: model,
      );
}
