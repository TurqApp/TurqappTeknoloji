part of 'social_profile_followers_controller.dart';

extension SocialProfileFollowersControllerRuntimeX
    on SocialProfileFollowersController {
  void _handleOnInit() {
    getFollowers();
    getFollowing();
  }

  Future<void> getFollowers() async {
    _pruneRelationCache();
    final followersCacheKey = 'followers:$userID';
    final cachedFollowers =
        SocialProfileFollowersController._relationCache[followersCacheKey];
    if (cachedFollowers != null &&
        DateTime.now().difference(cachedFollowers.cachedAt) <=
            SocialProfileFollowersController._relationCacheTtl) {
      takipciler.value = List<String>.from(cachedFollowers.ids);
      hasMoreFollowers = false;
      return;
    }
    if (takipciler.isNotEmpty) return;
    if (isLoadingFollowers || !hasMoreFollowers) return;
    isLoadingFollowers = true;

    final ids = await _followRepository.getFollowerIds(
      userID,
      preferCache: true,
      forceRefresh: false,
    );
    takipciler.value = ids.take(limit).toList();
    SocialProfileFollowersController._relationCache[followersCacheKey] =
        _RelationListCacheEntry(
      ids: List<String>.from(takipciler),
      cachedAt: DateTime.now(),
    );

    hasMoreFollowers = false;
    isLoadingFollowers = false;
  }

  Future<void> getFollowing() async {
    _pruneRelationCache();
    final followingsCacheKey = 'followings:$userID';
    final cachedFollowings =
        SocialProfileFollowersController._relationCache[followingsCacheKey];
    if (cachedFollowings != null &&
        DateTime.now().difference(cachedFollowings.cachedAt) <=
            SocialProfileFollowersController._relationCacheTtl) {
      takipEdilenler.value = List<String>.from(cachedFollowings.ids);
      hasMoreFollowing = false;
      return;
    }
    if (takipEdilenler.isNotEmpty) return;
    if (isLoadingFollowing || !hasMoreFollowing) return;
    isLoadingFollowing = true;

    final ids = await _visibilityPolicy.loadViewerFollowingIds(
      viewerUserId: userID,
      preferCache: true,
      forceRefresh: false,
    );
    takipEdilenler.value = ids.take(limit).toList();
    SocialProfileFollowersController._relationCache[followingsCacheKey] =
        _RelationListCacheEntry(
      ids: List<String>.from(takipEdilenler),
      cachedAt: DateTime.now(),
    );

    hasMoreFollowing = false;
    isLoadingFollowing = false;
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _pruneRelationCache() {
    final now = DateTime.now();
    SocialProfileFollowersController._relationCache.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) >
          SocialProfileFollowersController._relationCacheStaleRetention,
    );
    if (SocialProfileFollowersController._relationCache.length <=
        SocialProfileFollowersController._maxRelationCacheEntries) {
      return;
    }
    final entries = SocialProfileFollowersController._relationCache.entries
        .toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = SocialProfileFollowersController._relationCache.length -
        SocialProfileFollowersController._maxRelationCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      SocialProfileFollowersController._relationCache.remove(entries[i].key);
    }
  }

  void _handleOnClose() {
    pageController.dispose();
  }
}
