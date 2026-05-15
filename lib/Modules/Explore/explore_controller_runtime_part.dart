part of 'explore_controller.dart';

extension ExploreControllerRuntime on ExploreController {
  void _handleOnInit() {
    _applyUserCacheQuota();
    unawaited(_loadRecentSearchUsersCache());
    UserAnalyticsService.instance.trackFeatureUsage('explore_open');
    _bindRecentSearchUsers();
    _bindFollowingListener();
    exploreScroll.addListener(() {
      maybeFindNavBarController()?.updateVisibilityFromPrimaryScroll(
        source: 'explore_posts',
        offset: exploreScroll.offset,
      );
      if (exploreScroll.position.pixels >=
          exploreScroll.position.maxScrollExtent - 200) {
        fetchExplorePosts();
      }

      _syncScrollToTopVisibility(exploreScroll.offset);
    });

    videoScroll.addListener(() {
      maybeFindNavBarController()?.updateVisibilityFromPrimaryScroll(
        source: 'explore_videos',
        offset: videoScroll.offset,
      );
      if (videoScroll.position.pixels >=
          videoScroll.position.maxScrollExtent - 200) {
        fetchVideo();
      }

      _syncScrollToTopVisibility(videoScroll.offset);
    });

    photoScroll.addListener(() {
      maybeFindNavBarController()?.updateVisibilityFromPrimaryScroll(
        source: 'explore_photos',
        offset: photoScroll.offset,
      );
      if (photoScroll.position.pixels >=
          photoScroll.position.maxScrollExtent - 200) {
        fetchPhoto();
      }

      _syncScrollToTopVisibility(photoScroll.offset);
    });

    floodsScroll.addListener(() {
      maybeFindNavBarController()?.updateVisibilityFromPrimaryScroll(
        source: 'explore_floods',
        offset: floodsScroll.offset,
      );
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

  void _handleOnClose() {
    _currentUserWorker?.dispose();
    _currentUserWorker = null;
    _shortsMirrorWorker?.dispose();
    _shortsMirrorWorker = null;
    _searchDebounce?.cancel();
    exploreScroll.dispose();
    videoScroll.dispose();
    photoScroll.dispose();
    searchController.dispose();
    searchFocus.dispose();
    pageController.dispose();
  }

  void _handleGoToPage(int index) => _performGoToPage(index);
}
