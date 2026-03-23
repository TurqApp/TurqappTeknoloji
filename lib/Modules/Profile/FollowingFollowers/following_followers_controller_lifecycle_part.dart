part of 'following_followers_controller.dart';

extension FollowingFollowersControllerLifecyclePart
    on FollowingFollowersController {
  void _handleOnInit() {
    _loadNicknameCached();
    getCounters();
    final followersCached = _restoreRelationListCache(isFollowers: true);
    final followingsCached = _restoreRelationListCache(isFollowers: false);
    if (!followersCached) {
      getFollowers(initial: true);
    }
    if (!followingsCached) {
      getFollowing(initial: true);
    }
  }

  void _handleOnClose() {
    pageController.dispose();
    searchTakipciController.dispose();
    searchTakipEdilenController.dispose();
  }

  bool _resolveIsSelf() => isCurrentUserId(userId);

  void _applyLocalMutation({
    required String currentUid,
    required String otherUserID,
    required bool nowFollowing,
  }) {
    if (userId == currentUid) {
      if (nowFollowing) {
        if (!takipEdilenler.contains(otherUserID)) {
          takipEdilenler.insert(0, otherUserID);
        }
      } else {
        takipEdilenler.remove(otherUserID);
      }
      takipedilenCounter.value = nowFollowing
          ? takipedilenCounter.value + 1
          : (takipedilenCounter.value - 1).clamp(0, 1 << 30);
      _saveRelationListCache(isFollowers: false);
      _relationIdSetCache['followings'] = _RelationIdSetCacheEntry(
        ids: takipEdilenler.toSet(),
        cachedAt: DateTime.now(),
      );
    }
    if (userId == otherUserID) {
      if (nowFollowing) {
        if (!takipciler.contains(currentUid)) {
          takipciler.insert(0, currentUid);
        }
      } else {
        takipciler.remove(currentUid);
      }
      takipciCounter.value = nowFollowing
          ? takipciCounter.value + 1
          : (takipciCounter.value - 1).clamp(0, 1 << 30);
      _saveRelationListCache(isFollowers: true);
      _relationIdSetCache['followers'] = _RelationIdSetCacheEntry(
        ids: takipciler.toSet(),
        cachedAt: DateTime.now(),
      );
    }
  }
}
