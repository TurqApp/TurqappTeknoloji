part of 'explore_controller.dart';

extension ExploreControllerRuntime on ExploreController {
  void _handleOnInit() {
    _applyUserCacheQuota();
    unawaited(_loadRecentSearchUsersCache());
    UserAnalyticsService.instance.trackFeatureUsage('explore_open');
    _bindRecentSearchUsers();
    _bindFollowingListener();
    exploreScroll.addListener(() {
      _syncNavBarVisibilityForScroll('explore_posts', exploreScroll);
      if (exploreScroll.position.pixels >=
          exploreScroll.position.maxScrollExtent - 200) {
        fetchExplorePosts();
      }

      _syncScrollToTopVisibility(exploreScroll.offset);
    });

    videoScroll.addListener(() {
      _syncNavBarVisibilityForScroll('explore_videos', videoScroll);
      if (videoScroll.position.pixels >=
          videoScroll.position.maxScrollExtent - 200) {
        fetchVideo();
      }

      _syncScrollToTopVisibility(videoScroll.offset);
    });

    photoScroll.addListener(() {
      _syncNavBarVisibilityForScroll('explore_photos', photoScroll);
      if (photoScroll.position.pixels >=
          photoScroll.position.maxScrollExtent - 200) {
        fetchPhoto();
      }

      _syncScrollToTopVisibility(photoScroll.offset);
    });

    floodsScroll.addListener(() {
      _syncNavBarVisibilityForScroll('explore_floods', floodsScroll);
      _updateFloodVisibleIndex();
      _syncScrollToTopVisibility(floodsScroll.offset);
    });

    searchFocus.addListener(() {
      isKeyboardOpen.value = searchFocus.hasFocus;
      if (searchFocus.hasFocus) {
        isSearchMode.value = true;
      }
    });
  }

  void _handleOnSearchChanged(String value) => _performOnSearchChanged(value);

  void _handleClearSearchResults() => _performClearSearchResults();

  Future<void> _handleSearch(String query) => _performSearch(query);

  void _handleResetSearchToDefault() => _performResetSearchToDefault();

  void _handleResetSurfaceForTabTransition() =>
      _performResetSurfaceForTabTransition();

  void _syncNavBarVisibilityForScroll(
    String source,
    ScrollController controller,
  ) {
    if (!controller.hasClients || !controller.position.hasContentDimensions) {
      return;
    }
    maybeFindNavBarController()?.updateVisibilityFromPrimaryScroll(
      source: source,
      offset: controller.position.pixels,
    );
  }

  void _handleOnClose() {
    _currentUserWorker?.dispose();
    _currentUserWorker = null;
    _shortsMirrorWorker?.dispose();
    _shortsMirrorWorker = null;
    _searchDebounce?.cancel();
    _exploreFloodVisibilityDebounce?.cancel();
    _exploreFloodVisibilityDebounce = null;
    _exploreFloodVisibleFractions.clear();
    trendingScroll.dispose();
    exploreScroll.dispose();
    videoScroll.dispose();
    photoScroll.dispose();
    searchController.dispose();
    searchFocus.dispose();
    pageController.dispose();
  }

  void _handleGoToPage(int index) => _performGoToPage(index);
}
