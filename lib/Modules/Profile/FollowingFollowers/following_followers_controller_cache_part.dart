part of 'following_followers_controller.dart';

extension FollowingFollowersControllerCachePart
    on FollowingFollowersController {
  int _resolveLimit({required bool initial}) {
    if (isSelf) {
      return initial
          ? FollowingFollowersController._selfInitialLimit
          : FollowingFollowersController._selfRefreshLimit;
    }
    return FollowingFollowersController._otherUserLimit;
  }

  List<String> _normalizedIds(Iterable<String> ids) {
    return ids
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<void> getCounters() async {
    _pruneCounterCache();
    final cached = FollowingFollowersController._counterCacheByUserId[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            FollowingFollowersController._counterCacheTtl) {
      takipciCounter.value = cached.followers;
      takipedilenCounter.value = cached.followings;
      return;
    }

    try {
      final summary = await _userSummaryResolver.resolve(
        userId,
        preferCache: true,
      );
      final followers = summary?.followerCount ?? 0;
      final followings = summary?.followingCount ?? 0;
      takipciCounter.value = followers;
      takipedilenCounter.value = followings;
      FollowingFollowersController._counterCacheByUserId[userId] =
          _CounterCacheEntry(
        followers: followers,
        followings: followings,
        cachedAt: DateTime.now(),
      );
    } catch (_) {}
  }

  Future<void> _loadNicknameCached() async {
    _pruneNicknameCache();
    final cached = FollowingFollowersController._nicknameCacheByUserId[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            FollowingFollowersController._nicknameCacheTtl) {
      nickname.value = cached.nickname;
      return;
    }
    try {
      final summary = await _userSummaryResolver.resolve(
        userId,
        preferCache: true,
      );
      final name = summary?.nickname.trim() ?? '';
      nickname.value = name;
      FollowingFollowersController._nicknameCacheByUserId[userId] =
          _NicknameCacheEntry(
        nickname: name,
        cachedAt: DateTime.now(),
      );
    } catch (_) {}
  }

  void _pruneNicknameCache() {
    final now = DateTime.now();
    FollowingFollowersController._nicknameCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) >
          FollowingFollowersController._nicknameCacheStaleRetention,
    );
    if (FollowingFollowersController._nicknameCacheByUserId.length <=
        FollowingFollowersController._maxNicknameCacheEntries) {
      return;
    }
    final entries = FollowingFollowersController._nicknameCacheByUserId.entries
        .toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount =
        FollowingFollowersController._nicknameCacheByUserId.length -
            FollowingFollowersController._maxNicknameCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      FollowingFollowersController._nicknameCacheByUserId.remove(
        entries[i].key,
      );
    }
  }

  Future<void> getFollowers({
    bool initial = false,
    bool forceServer = false,
  }) async {
    if (isLoadingFollowers) return;
    if (!isSelf && takipciler.isNotEmpty) return;

    if (initial &&
        !forceServer &&
        _restoreRelationListCache(isFollowers: true)) {
      return;
    }

    isLoadingFollowers = true;
    if (initial) {
      hasMoreFollowers = true;
    }

    final fetchLimit = _resolveLimit(initial: initial);
    final ids = await _followRepository.getFollowerPreviewIds(
      userId,
      limit: fetchLimit,
      preferCache: !forceServer,
      forceRefresh: forceServer,
    );
    takipciler.value = _normalizedIds(ids).toList(growable: false);
    hasMoreFollowers = false;

    _saveRelationListCache(isFollowers: true);
    isLoadingFollowers = false;
  }

  Future<void> getFollowing({
    bool initial = false,
    bool forceServer = false,
  }) async {
    if (isLoadingFollowing) return;
    if (!isSelf && takipEdilenler.isNotEmpty) return;

    if (initial &&
        !forceServer &&
        _restoreRelationListCache(isFollowers: false)) {
      return;
    }

    isLoadingFollowing = true;
    if (initial) {
      hasMoreFollowing = true;
    }

    final fetchLimit = _resolveLimit(initial: initial);
    final ids = await _followRepository.getFollowingPreviewIds(
      userId,
      limit: fetchLimit,
      preferCache: !forceServer,
      forceRefresh: forceServer,
    );
    takipEdilenler.value = _normalizedIds(ids).toList(growable: false);
    hasMoreFollowing = false;

    _saveRelationListCache(isFollowers: false);
    isLoadingFollowing = false;
  }

  bool _restoreRelationListCache({required bool isFollowers}) {
    _pruneRelationListCache();
    final entry = isFollowers
        ? FollowingFollowersController._followersListCacheByUserId[userId]
        : FollowingFollowersController._followingsListCacheByUserId[userId];
    if (entry == null) return false;
    if (DateTime.now().difference(entry.cachedAt) >
        FollowingFollowersController._relationListCacheTtl) {
      return false;
    }
    if (isFollowers) {
      takipciler.value = _normalizedIds(entry.ids);
      hasMoreFollowers = false;
    } else {
      takipEdilenler.value = _normalizedIds(entry.ids);
      hasMoreFollowing = false;
    }
    return true;
  }

  void _saveRelationListCache({required bool isFollowers}) {
    final now = DateTime.now();
    if (isFollowers) {
      FollowingFollowersController._followersListCacheByUserId[userId] =
          _RelationListCacheEntry(
        ids: _normalizedIds(takipciler),
        cachedAt: now,
      );
    } else {
      FollowingFollowersController._followingsListCacheByUserId[userId] =
          _RelationListCacheEntry(
        ids: _normalizedIds(takipEdilenler),
        cachedAt: now,
      );
    }
  }

  void _pruneRelationListCache() {
    final now = DateTime.now();
    FollowingFollowersController._followersListCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) >
          FollowingFollowersController._relationListCacheStaleRetention,
    );
    FollowingFollowersController._followingsListCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) >
          FollowingFollowersController._relationListCacheStaleRetention,
    );

    void trimCache(Map<String, _RelationListCacheEntry> target) {
      if (target.length <=
          FollowingFollowersController._maxRelationListCacheEntries) {
        return;
      }
      final entries = target.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
      final removeCount = target.length -
          FollowingFollowersController._maxRelationListCacheEntries;
      for (var i = 0; i < removeCount; i++) {
        target.remove(entries[i].key);
      }
    }

    trimCache(FollowingFollowersController._followersListCacheByUserId);
    trimCache(FollowingFollowersController._followingsListCacheByUserId);
  }

  void _pruneCounterCache() {
    final now = DateTime.now();
    FollowingFollowersController._counterCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) >
          FollowingFollowersController._counterCacheStaleRetention,
    );
    if (FollowingFollowersController._counterCacheByUserId.length <=
        FollowingFollowersController._maxCounterCacheEntries) {
      return;
    }
    final entries = FollowingFollowersController._counterCacheByUserId.entries
        .toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount =
        FollowingFollowersController._counterCacheByUserId.length -
            FollowingFollowersController._maxCounterCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      FollowingFollowersController._counterCacheByUserId.remove(entries[i].key);
    }
  }
}
