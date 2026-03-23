part of 'follower_controller.dart';

extension FollowerControllerDataPart on FollowerController {
  Future<void> getData(String userID) async {
    if (isLoaded.value) return;
    _pruneUserCache();

    final cached = _userCacheById[userID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _userCacheTtl) {
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
      _userCacheById[userID] = _FollowerUserCacheEntry(
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
    _userCacheById.removeWhere(
      (_, entry) => now.difference(entry.cachedAt) > _userCacheStaleRetention,
    );
    if (_userCacheById.length <= _maxUserCacheEntries) return;
    final entries = _userCacheById.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = _userCacheById.length - _maxUserCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _userCacheById.remove(entries[i].key);
    }
  }

  Future<void> followControl(String userID) async {
    final myUid = _currentUid;
    if (myUid.isEmpty) return;
    _pruneFollowStateCache();

    final cacheKey = '$myUid:$userID';
    final cached = _followStateCacheByUser[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _followStateCacheTtl) {
      isFollowed.value = cached.isFollowed;
      return;
    }

    final exists = await _followRepository.isFollowing(
      userID,
      currentUid: myUid,
      preferCache: true,
    );
    isFollowed.value = exists;
    _followStateCacheByUser[cacheKey] = _FollowStateCacheEntry(
      isFollowed: exists,
      cachedAt: DateTime.now(),
    );
  }

  void _pruneFollowStateCache() {
    final now = DateTime.now();
    _followStateCacheByUser.removeWhere(
      (_, entry) => now.difference(entry.cachedAt) > _followStateStaleRetention,
    );
    if (_followStateCacheByUser.length <= _maxFollowStateCacheEntries) return;
    final entries = _followStateCacheByUser.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount =
        _followStateCacheByUser.length - _maxFollowStateCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _followStateCacheByUser.remove(entries[i].key);
    }
  }
}
