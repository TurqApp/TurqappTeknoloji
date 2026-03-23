part of 'profile_controller.dart';

extension ProfileControllerAccountPart on ProfileController {
  void _performListenToCounterChanges() {
    final uid = _resolvedActiveUid;
    if (uid == null) return;

    _counterSub?.cancel();

    _counterSub = _userRepository.watchUserRaw(uid).listen((snapshot) {
      final data = snapshot;
      if (data != null) {
        followerCount.value = (data['counterOfFollowers'] as num?)?.toInt() ??
            (data['followersCount'] as num?)?.toInt() ??
            (data['takipci'] as num?)?.toInt() ??
            (data['followerCount'] as num?)?.toInt() ??
            0;
        followingCount.value = (data['counterOfFollowings'] as num?)?.toInt() ??
            (data['followingCount'] as num?)?.toInt() ??
            (data['takip'] as num?)?.toInt() ??
            (data['followCount'] as num?)?.toInt() ??
            0;
      }
    });
  }

  void _performOnAuthChanged(User? user) {
    final newUid = user?.uid;
    if (newUid == null) {
      _activeUid = null;
      _counterSub?.cancel();
      _counterSub = null;
      try {
        allPosts.clear();
      } catch (_) {
        allPosts.value = [];
      }
      try {
        photos.clear();
      } catch (_) {
        photos.value = [];
      }
      try {
        videos.clear();
      } catch (_) {
        videos.value = [];
      }
      try {
        reshares.clear();
      } catch (_) {
        reshares.value = [];
      }
      try {
        scheduledPosts.clear();
      } catch (_) {
        scheduledPosts.value = [];
      }

      followerCount.value = 0;
      followingCount.value = 0;
      lastPostDoc = null;
      lastPostDocPhotos = null;
      lastPostDocVideos = null;
      lastScheduledDoc = null;
      hasMorePosts = true;
      hasMorePostsPhotos = true;
      hasMorePostsVideos = true;
      hasMoreScheduled = true;
      return;
    }

    if (newUid != _activeUid) {
      _activeUid = newUid;
      _clearInMemoryPostLists();
      _listenToCounterChanges();
      unawaited(_restoreCachedListsForActiveUser());
      refreshAll();
    }
  }

  Future<void> _performGetCounters() async {
    final uid = _resolvedActiveUid;
    if (uid == null) return;

    try {
      final data = await _userRepository.getUserRaw(
        uid,
        preferCache: true,
      );
      followerCount.value = (data?['counterOfFollowers'] as num?)?.toInt() ??
          (data?['followersCount'] as num?)?.toInt() ??
          (data?['takipci'] as num?)?.toInt() ??
          (data?['followerCount'] as num?)?.toInt() ??
          0;
      followingCount.value = (data?['counterOfFollowings'] as num?)?.toInt() ??
          (data?['followingCount'] as num?)?.toInt() ??
          (data?['takip'] as num?)?.toInt() ??
          (data?['followCount'] as num?)?.toInt() ??
          0;

      if (followerCount.value == 0 || followingCount.value == 0) {
        final followers = await _followRepository.getFollowerIds(
          uid,
          preferCache: true,
          forceRefresh: false,
        );
        final followings = await _visibilityPolicy.loadViewerFollowingIds(
          viewerUserId: uid,
          preferCache: true,
          forceRefresh: false,
        );
        followerCount.value = followers.length;
        followingCount.value = followings.length;
      }
    } catch (e) {
      print("⚠️ getCounters error: $e");
    }
  }
}
