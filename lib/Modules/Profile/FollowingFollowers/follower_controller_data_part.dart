part of 'follower_controller.dart';

extension FollowerControllerDataPart on FollowerController {
  Future<void> getData(String userID) async {
    if (isLoaded.value) return;
    _pruneUserCache();

    final cached = FollowerController._userCacheById[userID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            FollowerController._userCacheTtl) {
      avatarUrl.value = cached.avatarUrl;
      nickname.value = cached.nickname;
      fullname.value = cached.fullname;
      isLoaded.value = true;
      return;
    }

    final data = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (data != null) {
      final resolvedAvatar = data.avatarUrl;
      final resolvedNickname = data.nickname;
      final resolvedFullname = data.displayName;
      avatarUrl.value = resolvedAvatar;
      nickname.value = resolvedNickname;
      fullname.value = resolvedFullname;
      FollowerController._userCacheById[userID] = _FollowerUserCacheEntry(
        avatarUrl: resolvedAvatar,
        nickname: resolvedNickname,
        fullname: resolvedFullname,
        cachedAt: DateTime.now(),
      );
    }

    isLoaded.value = true;
  }

  void _pruneUserCache() {
    final now = DateTime.now();
    FollowerController._userCacheById.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) >
          FollowerController._userCacheStaleRetention,
    );
    if (FollowerController._userCacheById.length <=
        FollowerController._maxUserCacheEntries) {
      return;
    }
    final entries = FollowerController._userCacheById.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = FollowerController._userCacheById.length -
        FollowerController._maxUserCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      FollowerController._userCacheById.remove(entries[i].key);
    }
  }

  Future<void> followControl(String userID) async {
    final myUid = _currentUid;
    if (myUid.isEmpty) return;
    _pruneFollowStateCache();

    final cacheKey = '$myUid:$userID';
    final cached = FollowerController._followStateCacheByUser[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            FollowerController._followStateCacheTtl) {
      isFollowed.value = cached.isFollowed;
      return;
    }

    final exists = await _followRepository.isFollowing(
      userID,
      currentUid: myUid,
      preferCache: true,
    );
    isFollowed.value = exists;
    FollowerController._followStateCacheByUser[cacheKey] =
        _FollowStateCacheEntry(
      isFollowed: exists,
      cachedAt: DateTime.now(),
    );
  }

  void _pruneFollowStateCache() {
    final now = DateTime.now();
    FollowerController._followStateCacheByUser.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) >
          FollowerController._followStateStaleRetention,
    );
    if (FollowerController._followStateCacheByUser.length <=
        FollowerController._maxFollowStateCacheEntries) {
      return;
    }
    final entries = FollowerController._followStateCacheByUser.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = FollowerController._followStateCacheByUser.length -
        FollowerController._maxFollowStateCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      FollowerController._followStateCacheByUser.remove(entries[i].key);
    }
  }
}
