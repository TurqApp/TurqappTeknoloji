part of 'follower_controller.dart';

const Duration _followerFollowStateCacheTtl = Duration(seconds: 20);
const Duration _followerFollowStateStaleRetention = Duration(minutes: 3);
const int _followerMaxFollowStateCacheEntries = 800;
const Duration _followerUserCacheTtl = Duration(minutes: 5);
const Duration _followerUserCacheStaleRetention = Duration(minutes: 20);
const int _followerMaxUserCacheEntries = 400;

final Map<String, _FollowerUserCacheEntry> _followerUserCacheById =
    <String, _FollowerUserCacheEntry>{};
final Map<String, _FollowStateCacheEntry> _followerFollowStateCacheByUser =
    <String, _FollowStateCacheEntry>{};

extension _FollowerControllerCacheX on FollowerController {
  Future<void> getData(String userID) async {
    if (isLoaded.value) return;
    _pruneUserCache();

    final cached = _followerUserCacheById[userID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _followerUserCacheTtl) {
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
      _followerUserCacheById[userID] = _FollowerUserCacheEntry(
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
    _followerUserCacheById.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) > _followerUserCacheStaleRetention,
    );
    if (_followerUserCacheById.length <= _followerMaxUserCacheEntries) {
      return;
    }
    final entries = _followerUserCacheById.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount =
        _followerUserCacheById.length - _followerMaxUserCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _followerUserCacheById.remove(entries[i].key);
    }
  }

  Future<void> followControl(String userID) async {
    final myUid = _currentUid;
    if (myUid.isEmpty) return;
    _pruneFollowStateCache();

    final cacheKey = '$myUid:$userID';
    final cached = _followerFollowStateCacheByUser[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            _followerFollowStateCacheTtl) {
      isFollowed.value = cached.isFollowed;
      return;
    }

    final exists = await _followRepository.isFollowing(
      userID,
      currentUid: myUid,
      preferCache: true,
    );
    isFollowed.value = exists;
    _followerFollowStateCacheByUser[cacheKey] = _FollowStateCacheEntry(
      isFollowed: exists,
      cachedAt: DateTime.now(),
    );
  }

  void _pruneFollowStateCache() {
    final now = DateTime.now();
    _followerFollowStateCacheByUser.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) > _followerFollowStateStaleRetention,
    );
    if (_followerFollowStateCacheByUser.length <=
        _followerMaxFollowStateCacheEntries) {
      return;
    }
    final entries = _followerFollowStateCacheByUser.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = _followerFollowStateCacheByUser.length -
        _followerMaxFollowStateCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _followerFollowStateCacheByUser.remove(entries[i].key);
    }
  }
}

class _FollowerUserCacheEntry {
  final String avatarUrl;
  final String nickname;
  final String fullname;
  final DateTime cachedAt;

  const _FollowerUserCacheEntry({
    required this.avatarUrl,
    required this.nickname,
    required this.fullname,
    required this.cachedAt,
  });
}

class _FollowStateCacheEntry {
  final bool isFollowed;
  final DateTime cachedAt;

  const _FollowStateCacheEntry({
    required this.isFollowed,
    required this.cachedAt,
  });
}
