part of 'following_followers_controller.dart';

const Duration _followingFollowersNicknameCacheTtl = Duration(minutes: 5);
const Duration _followingFollowersNicknameCacheStaleRetention =
    Duration(minutes: 20);
const int _followingFollowersMaxNicknameCacheEntries = 300;
const Duration _followingFollowersCounterCacheTtl = Duration(seconds: 30);
const Duration _followingFollowersCounterCacheStaleRetention =
    Duration(minutes: 3);
const int _followingFollowersMaxCounterCacheEntries = 300;
const Duration _followingFollowersRelationListCacheTtl = Duration(minutes: 10);
const Duration _followingFollowersRelationListCacheStaleRetention =
    Duration(hours: 1);
const int _followingFollowersMaxRelationListCacheEntries = 400;
const int _followingFollowersSelfInitialLimit =
    ReadBudgetRegistry.followRelationPreviewInitialLimit;
const int _followingFollowersSelfRefreshLimit =
    ReadBudgetRegistry.followRelationPreviewInitialLimit;
const int _followingFollowersOtherUserLimit =
    ReadBudgetRegistry.followRelationPreviewInitialLimit;

final Map<String, _NicknameCacheEntry>
    _followingFollowersNicknameCacheByUserId = <String, _NicknameCacheEntry>{};
final Map<String, _CounterCacheEntry> _followingFollowersCounterCacheByUserId =
    <String, _CounterCacheEntry>{};
final Map<String, _RelationListCacheEntry>
    _followingFollowersFollowersListCacheByUserId =
    <String, _RelationListCacheEntry>{};
final Map<String, _RelationListCacheEntry>
    _followingFollowersFollowingsListCacheByUserId =
    <String, _RelationListCacheEntry>{};

extension FollowingFollowersControllerCachePart
    on FollowingFollowersController {
  int _resolveLimit({required bool initial}) {
    if (isSelf) {
      return initial
          ? _followingFollowersSelfInitialLimit
          : _followingFollowersSelfRefreshLimit;
    }
    return _followingFollowersOtherUserLimit;
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
    final cached = _followingFollowersCounterCacheByUserId[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            _followingFollowersCounterCacheTtl) {
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
      _followingFollowersCounterCacheByUserId[userId] = _CounterCacheEntry(
        followers: followers,
        followings: followings,
        cachedAt: DateTime.now(),
      );
    } catch (_) {}
  }

  Future<void> _loadNicknameCached() async {
    _pruneNicknameCache();
    final cached = _followingFollowersNicknameCacheByUserId[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            _followingFollowersNicknameCacheTtl) {
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
      _followingFollowersNicknameCacheByUserId[userId] = _NicknameCacheEntry(
        nickname: name,
        cachedAt: DateTime.now(),
      );
    } catch (_) {}
  }

  void _pruneNicknameCache() {
    final now = DateTime.now();
    _followingFollowersNicknameCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) >
          _followingFollowersNicknameCacheStaleRetention,
    );
    if (_followingFollowersNicknameCacheByUserId.length <=
        _followingFollowersMaxNicknameCacheEntries) {
      return;
    }
    final entries = _followingFollowersNicknameCacheByUserId.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = _followingFollowersNicknameCacheByUserId.length -
        _followingFollowersMaxNicknameCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _followingFollowersNicknameCacheByUserId.remove(entries[i].key);
    }
  }

  Future<void> getFollowers({
    bool initial = false,
    bool forceServer = false,
  }) async {
    if (isLoadingFollowers) return;

    if (initial &&
        !forceServer &&
        _restoreRelationListCache(isFollowers: true)) {
      return;
    }

    isLoadingFollowers = true;
    if (initial) {
      hasMoreFollowers = true;
    }

    try {
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
    } finally {
      isLoadingFollowers = false;
    }
  }

  Future<void> getFollowing({
    bool initial = false,
    bool forceServer = false,
  }) async {
    if (isLoadingFollowing) return;

    if (initial &&
        !forceServer &&
        _restoreRelationListCache(isFollowers: false)) {
      return;
    }

    isLoadingFollowing = true;
    if (initial) {
      hasMoreFollowing = true;
    }

    try {
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
    } finally {
      isLoadingFollowing = false;
    }
  }

  bool _restoreRelationListCache({required bool isFollowers}) {
    _pruneRelationListCache();
    final entry = isFollowers
        ? _followingFollowersFollowersListCacheByUserId[userId]
        : _followingFollowersFollowingsListCacheByUserId[userId];
    if (entry == null) return false;
    if (DateTime.now().difference(entry.cachedAt) >
        _followingFollowersRelationListCacheTtl) {
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
      _followingFollowersFollowersListCacheByUserId[userId] =
          _RelationListCacheEntry(
        ids: _normalizedIds(takipciler),
        cachedAt: now,
      );
    } else {
      _followingFollowersFollowingsListCacheByUserId[userId] =
          _RelationListCacheEntry(
        ids: _normalizedIds(takipEdilenler),
        cachedAt: now,
      );
    }
  }

  void _pruneRelationListCache() {
    final now = DateTime.now();
    _followingFollowersFollowersListCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) >
          _followingFollowersRelationListCacheStaleRetention,
    );
    _followingFollowersFollowingsListCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) >
          _followingFollowersRelationListCacheStaleRetention,
    );

    void trimCache(Map<String, _RelationListCacheEntry> target) {
      if (target.length <= _followingFollowersMaxRelationListCacheEntries) {
        return;
      }
      final entries = target.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
      final removeCount =
          target.length - _followingFollowersMaxRelationListCacheEntries;
      for (var i = 0; i < removeCount; i++) {
        target.remove(entries[i].key);
      }
    }

    trimCache(_followingFollowersFollowersListCacheByUserId);
    trimCache(_followingFollowersFollowingsListCacheByUserId);
  }

  void _pruneCounterCache() {
    final now = DateTime.now();
    _followingFollowersCounterCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) >
          _followingFollowersCounterCacheStaleRetention,
    );
    if (_followingFollowersCounterCacheByUserId.length <=
        _followingFollowersMaxCounterCacheEntries) {
      return;
    }
    final entries = _followingFollowersCounterCacheByUserId.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = _followingFollowersCounterCacheByUserId.length -
        _followingFollowersMaxCounterCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _followingFollowersCounterCacheByUserId.remove(entries[i].key);
    }
  }
}
