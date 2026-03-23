part of 'profile_controller.dart';

extension ProfileControllerFeedPart on ProfileController {
  void _performSchedulePersistPostCaches() {
    final uid = _resolvedActiveUid;
    if (uid == null || uid.isEmpty) return;
    _persistCacheTimer?.cancel();
    _persistCacheTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persistPostCaches(uid));
    });
  }

  Future<void> _performPersistPostCaches(String uid) async {
    await _profileSnapshotRepository.persistBuckets(
      userId: uid,
      buckets: ProfileBuckets(
        all: allPosts,
        photos: photos,
        videos: videos,
        scheduled: scheduledPosts,
      ),
      limit: postLimit,
      source: CachedResourceSource.server,
    );
  }

  Future<void> _performRestoreCachedListsForActiveUser() async {
    final uid = _resolvedActiveUid;
    if (uid == null || uid.isEmpty) return;
    final resource = await _profileSnapshotRepository.bootstrapProfile(
      userId: uid,
      limit: postLimit,
    );
    _applyProfileBuckets(resource.data);
    unawaited(_warmProfileSurfaceCache());
  }

  Future<void> _performWarmProfileSurfaceCache() async {
    final urls = <String>{userService.avatarUrl};

    void collectFrom(Iterable<PostsModel> posts) {
      for (final post in posts.take(18)) {
        if (post.thumbnail.trim().isNotEmpty) {
          urls.add(post.thumbnail.trim());
        }
        if (post.authorAvatarUrl.trim().isNotEmpty) {
          urls.add(post.authorAvatarUrl.trim());
        }
        for (final img in post.img.take(2)) {
          final normalized = img.trim();
          if (normalized.isNotEmpty) {
            urls.add(normalized);
          }
        }
      }
    }

    collectFrom(allPosts);
    collectFrom(photos);
    collectFrom(videos);
    collectFrom(scheduledPosts);

    for (final url in urls.where((e) => e.isNotEmpty).take(32)) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(url);
      } catch (_) {}
    }
  }

  void _performClearInMemoryPostLists() {
    allPosts.clear();
    photos.clear();
    videos.clear();
    reshares.clear();
    scheduledPosts.clear();
    _lastPrimaryDoc = null;
    _hasMorePrimary = true;
  }

  void _performBindResharesRealtime() {
    final uid = _resolvedActiveUid;
    if (uid == null) return;
    _resharesSub?.cancel();
    _resharesSub = _linkService.listenResharedPosts(uid).listen((refs) {
      _latestReshareRefs = refs;
      _hydrateReshares(uid, refs);
    });
  }

  Future<void> _performHydrateReshares(
    String uid,
    List<UserPostReference> refs,
  ) async {
    try {
      final posts = await _linkService.fetchResharedPosts(uid, refs);
      if (posts.isNotEmpty || reshares.isEmpty) {
        reshares.assignAll(List<PostsModel>.from(posts));
      }
    } catch (e) {
      print('ProfileController hydrate reshares error: $e');
    }
  }

  int _performReshareSortTimestampFor(String postId, int fallback) {
    for (final ref in _latestReshareRefs) {
      if (ref.postId == postId) return ref.timeStamp.toInt();
    }
    return fallback;
  }

  Future<void> _performFetchPosts({
    bool isInitial = false,
    bool force = false,
  }) async {
    await _fetchPrimaryBuckets(initial: isInitial, force: force);
  }

  Future<void> _performFetchPhotos({
    bool isInitial = false,
    bool force = false,
  }) async {
    await _fetchPrimaryBuckets(initial: isInitial, force: force);
  }

  Future<void> _performFetchVideos({
    bool isInitial = false,
    bool force = false,
  }) async {
    await _fetchPrimaryBuckets(initial: isInitial, force: force);
  }

  Future<void> _performFetchScheduledPosts({
    bool isInitial = false,
    bool force = false,
  }) async {
    await _fetchPrimaryBuckets(initial: isInitial, force: force);
  }

  Future<void> _performGetLastPostAndAddToAllPosts() async {
    final uid = _resolvedActiveUid;
    if (uid == null) return;

    final lastPost = await _profileRepository.fetchLatestProfilePost(uid);
    if (lastPost == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (lastPost.timeStamp > nowMs || lastPost.deletedPost == true) {
      return;
    }
    if (lastPost.video.trim().isNotEmpty && !lastPost.hasPlayableVideo) {
      return;
    }

    final existsIndex = allPosts.indexWhere((p) => p.docID == lastPost.docID);
    if (existsIndex == -1) {
      final currentPosts = List<PostsModel>.from(allPosts);
      currentPosts.insert(0, lastPost);
      allPosts.value = currentPosts;
    } else if (existsIndex > 0) {
      final currentPosts = List<PostsModel>.from(allPosts);
      final existing = currentPosts.removeAt(existsIndex);
      currentPosts.insert(0, existing);
      allPosts.value = currentPosts;
    }
  }

  Future<void> _performGetReshares() async {
    final uid = _resolvedActiveUid;
    if (uid == null) return;
    await _hydrateReshares(uid, _latestReshareRefs);
  }

  Future<void> _performGetResharesSingle() async {
    final uid = _resolvedActiveUid;
    if (uid == null) return;

    final post = await _profileRepository.fetchLatestResharePost(uid);
    if (post == null) {
      reshares.clear();
      return;
    }

    if (post.timeStamp > DateTime.now().millisecondsSinceEpoch ||
        post.deletedPost == true) {
      return;
    }

    final exists = reshares.any((p) => p.docID == post.docID);
    if (!exists) {
      reshares.insert(0, post);
    }
  }

  void _performRemoveReshare(String postId) {
    reshares.removeWhere((post) => post.docID == postId);
  }

  Future<void> _performRefreshAll({bool forceSync = false}) async {
    try {
      await _bootstrapHeaderFromTypesense();
      await getCounters();

      await Future.wait([
        _loadInitialPrimaryBuckets(forceSync: forceSync),
        getReshares(),
      ]);
    } catch (e) {
      print('refreshAll error: $e');
    }
  }

  Future<void> _performLoadInitialPrimaryBuckets({
    bool forceSync = false,
  }) async {
    final uid = _resolvedActiveUid;
    if (uid == null || uid.isEmpty) return;
    final resource = await _profileSnapshotRepository.loadProfile(
      userId: uid,
      limit: postLimit,
      forceSync: forceSync,
    );
    final applied = _applyProfileBuckets(resource.data);
    if (!applied) {
      await _fetchPrimaryBuckets(initial: true, force: forceSync);
      return;
    }
    _lastPrimaryDoc = null;
    _hasMorePrimary = true;
    lastPostDoc = null;
    lastPostDocPhotos = null;
    lastPostDocVideos = null;
    lastScheduledDoc = null;
    hasMorePosts = true;
    hasMorePostsPhotos = true;
    hasMorePostsVideos = true;
    hasMoreScheduled = true;
    unawaited(_warmProfileSurfaceCache());
  }

  Future<void> _performFetchPrimaryBuckets({
    required bool initial,
    bool force = false,
  }) async {
    final uid = _resolvedActiveUid;
    if (uid == null) return;
    if (_isLoadingPrimary && !force) return;
    if (!initial && !_hasMorePrimary) return;

    _isLoadingPrimary = true;
    isLoadingMore = true;
    isLoadingMorePhotos = true;
    isLoadingMoreVideos = true;
    isLoadingScheduled = true;

    try {
      if (initial) {
        _lastPrimaryDoc = null;
        _hasMorePrimary = true;
      }

      final page = await _profileRepository.fetchPrimaryPage(
        uid: uid,
        startAfter: initial ? null : _lastPrimaryDoc,
        limit: postLimit,
      );

      if (initial) {
        allPosts.assignAll(page.all);
        photos.assignAll(page.photos);
        videos.assignAll(page.videos);
        scheduledPosts.assignAll(page.scheduled);
      } else {
        allPosts.addAll(_dedupePosts(allPosts, page.all));
        photos.addAll(_dedupePosts(photos, page.photos));
        videos.addAll(_dedupePosts(videos, page.videos));
        scheduledPosts.addAll(_dedupePosts(scheduledPosts, page.scheduled));
      }

      _lastPrimaryDoc = page.lastDoc;
      _hasMorePrimary = page.hasMore;
      lastPostDoc = _lastPrimaryDoc;
      lastPostDocPhotos = _lastPrimaryDoc;
      lastPostDocVideos = _lastPrimaryDoc;
      lastScheduledDoc = _lastPrimaryDoc;
      hasMorePosts = _hasMorePrimary;
      hasMorePostsPhotos = _hasMorePrimary;
      hasMorePostsVideos = _hasMorePrimary;
      hasMoreScheduled = _hasMorePrimary;
      unawaited(_warmProfileSurfaceCache());
    } catch (e) {
      print('_fetchPrimaryBuckets error: $e');
    } finally {
      _isLoadingPrimary = false;
      isLoadingMore = false;
      isLoadingMorePhotos = false;
      isLoadingMoreVideos = false;
      isLoadingScheduled = false;
    }
  }

  List<PostsModel> _performDedupePosts(
    List<PostsModel> existing,
    List<PostsModel> incoming,
  ) {
    final known = existing.map((e) => e.docID).toSet();
    return incoming.where((post) => known.add(post.docID)).toList();
  }

  bool _performApplyProfileBuckets(ProfileBuckets? buckets) {
    if (buckets == null) return false;
    if (buckets.all.isEmpty &&
        buckets.photos.isEmpty &&
        buckets.videos.isEmpty &&
        buckets.scheduled.isEmpty) {
      return false;
    }
    if (buckets.all.isNotEmpty) allPosts.assignAll(buckets.all);
    if (buckets.photos.isNotEmpty) photos.assignAll(buckets.photos);
    if (buckets.videos.isNotEmpty) videos.assignAll(buckets.videos);
    if (buckets.scheduled.isNotEmpty) {
      scheduledPosts.assignAll(buckets.scheduled);
    }
    return true;
  }
}
