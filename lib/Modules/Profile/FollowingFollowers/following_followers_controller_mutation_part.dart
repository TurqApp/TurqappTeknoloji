part of 'following_followers_controller.dart';

void _applyFollowMutationToCachesImpl({
  required String currentUid,
  required String otherUserID,
  required bool nowFollowing,
}) {
  final now = DateTime.now();
  final myFollowingEntry =
      _followingFollowersFollowingsListCacheByUserId[currentUid];
  if (myFollowingEntry != null) {
    final list = List<String>.from(myFollowingEntry.ids);
    if (nowFollowing) {
      if (!list.contains(otherUserID)) list.insert(0, otherUserID);
    } else {
      list.remove(otherUserID);
    }
    _followingFollowersFollowingsListCacheByUserId[currentUid] =
        _RelationListCacheEntry(ids: list, cachedAt: now);
  }

  final otherFollowersEntry =
      _followingFollowersFollowersListCacheByUserId[otherUserID];
  if (otherFollowersEntry != null) {
    final list = List<String>.from(otherFollowersEntry.ids);
    if (nowFollowing) {
      if (!list.contains(currentUid)) list.insert(0, currentUid);
    } else {
      list.remove(currentUid);
    }
    _followingFollowersFollowersListCacheByUserId[otherUserID] =
        _RelationListCacheEntry(ids: list, cachedAt: now);
  }

  final myCounter = _followingFollowersCounterCacheByUserId[currentUid];
  if (myCounter != null) {
    final nextFollowings = nowFollowing
        ? myCounter.followings + 1
        : (myCounter.followings - 1).clamp(0, 1 << 30);
    _followingFollowersCounterCacheByUserId[currentUid] = _CounterCacheEntry(
      followers: myCounter.followers,
      followings: nextFollowings,
      cachedAt: now,
    );
  }

  final otherCounter = _followingFollowersCounterCacheByUserId[otherUserID];
  if (otherCounter != null) {
    final nextFollowers = nowFollowing
        ? otherCounter.followers + 1
        : (otherCounter.followers - 1).clamp(0, 1 << 30);
    _followingFollowersCounterCacheByUserId[otherUserID] = _CounterCacheEntry(
      followers: nextFollowers,
      followings: otherCounter.followings,
      cachedAt: now,
    );
  }

  final currentController = FollowingFollowersController.maybeFind(
    tag: currentUid,
  );
  if (currentController != null) {
    currentController._applyLocalMutation(
      currentUid: currentUid,
      otherUserID: otherUserID,
      nowFollowing: nowFollowing,
    );
  }
  final otherController = FollowingFollowersController.maybeFind(
    tag: otherUserID,
  );
  if (otherController != null) {
    otherController._applyLocalMutation(
      currentUid: currentUid,
      otherUserID: otherUserID,
      nowFollowing: nowFollowing,
    );
  }
}

extension FollowingFollowersControllerMutationPart
    on FollowingFollowersController {
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
