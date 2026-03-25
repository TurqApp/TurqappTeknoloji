part of 'profile_controller.dart';

extension ProfileControllerRuntimePart on ProfileController {
  void _listenToCounterChanges() => _performListenToCounterChanges();

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

  void _bindResharesRealtime() => _performBindResharesRealtime();

  Future<void> _hydrateReshares(String uid, List<UserPostReference> refs) =>
      _performHydrateReshares(uid, refs);

  int reshareSortTimestampFor(String postId, int fallback) =>
      _performReshareSortTimestampFor(postId, fallback);

  void _onAuthChanged(User? user) => _performOnAuthChanged(user);

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

  Future<void> getCounters() => _performGetCounters();

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

  void setPostSelection(int index) => _performSetPostSelection(index);

  GlobalKey getPostKey({
    required String docId,
    required bool isReshare,
  }) =>
      _performGetPostKey(
        docId: docId,
        isReshare: isReshare,
      );

  String mergedEntryIdentity({
    required String docId,
    required bool isReshare,
  }) =>
      _performMergedEntryIdentity(
        docId: docId,
        isReshare: isReshare,
      );

  int indexOfMergedEntry({
    required String docId,
    required bool isReshare,
  }) =>
      _performIndexOfMergedEntry(
        docId: docId,
        isReshare: isReshare,
      );

  String agendaInstanceTag({
    required String docId,
    required bool isReshare,
  }) =>
      _performAgendaInstanceTag(
        docId: docId,
        isReshare: isReshare,
      );

  void disposeAgendaContentController(String docID) =>
      _performDisposeAgendaContentController(docID);

  Future<void> fetchPosts({bool isInitial = false, bool force = false}) =>
      _performFetchPosts(
        isInitial: isInitial,
        force: force,
      );

  Future<void> fetchPhotos({bool isInitial = false, bool force = false}) =>
      _performFetchPhotos(
        isInitial: isInitial,
        force: force,
      );

  Future<void> fetchVideos({bool isInitial = false, bool force = false}) =>
      _performFetchVideos(
        isInitial: isInitial,
        force: force,
      );

  Future<void> fetchScheduledPosts({
    bool isInitial = false,
    bool force = false,
  }) =>
      _performFetchScheduledPosts(
        isInitial: isInitial,
        force: force,
      );

  Future<void> showSocialMediaLinkDelete(String docID) =>
      _performShowSocialMediaLinkDelete(docID);

  Future<void> getLastPostAndAddToAllPosts() =>
      _performGetLastPostAndAddToAllPosts();

  Future<void> getReshares() => _performGetReshares();

  Future<void> getResharesSingle() => _performGetResharesSingle();

  void removeReshare(String postId) => _performRemoveReshare(postId);

  Future<void> refreshAll({bool forceSync = false}) =>
      _performRefreshAll(forceSync: forceSync);

  Future<void> _loadInitialPrimaryBuckets({
    bool forceSync = false,
  }) =>
      _performLoadInitialPrimaryBuckets(forceSync: forceSync);

  Future<void> _fetchPrimaryBuckets({
    required bool initial,
    bool force = false,
  }) =>
      _performFetchPrimaryBuckets(
        initial: initial,
        force: force,
      );

  List<PostsModel> _dedupePosts(
    List<PostsModel> existing,
    List<PostsModel> incoming,
  ) =>
      _performDedupePosts(existing, incoming);

  bool _applyProfileBuckets(ProfileBuckets? buckets) =>
      _performApplyProfileBuckets(buckets);
}
