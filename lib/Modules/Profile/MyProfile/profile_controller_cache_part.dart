part of 'profile_controller.dart';

extension ProfileControllerCachePart on ProfileController {
  void _performSchedulePersistPostCaches() {
    final uid = _resolvedActiveUid;
    if (uid == null || uid.isEmpty) return;
    _persistCacheTimer?.cancel();
    _persistCacheTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_performPersistPostCaches(uid));
    });
  }

  Future<void> _performPersistPostCaches(String uid) async {
    await _profileSnapshotRepository.persistBuckets(
      userId: uid,
      buckets: ProfileBuckets(
        all: allPosts,
        photos: photos,
        videos: videos,
        reshares: reshares,
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
    final applied = _applyProfileBuckets(resource.data);
    if (applied) {
      bootstrapFeedPlaybackAfterDataChange();
    }
    unawaited(_performWarmProfileSurfaceCache());
  }

  Future<void> _performWarmProfileSurfaceCache() async {
    final pinnedPosts = _resolveWarmProfileSurfacePosts();
    final cacheManager = maybeFindSegmentCacheManager();
    var hlsCount = 0;
    if (cacheManager != null &&
        cacheManager.isReady &&
        pinnedPosts.isNotEmpty) {
      cacheManager.cachePostCards(pinnedPosts);
      for (final post in pinnedPosts) {
        final docId = post.docID.trim();
        final playbackUrl = post.playbackUrl.trim();
        if (docId.isEmpty || playbackUrl.isEmpty) continue;
        cacheManager.cacheHlsEntry(docId, playbackUrl);
        hlsCount++;
      }
      debugPrint(
        '[ProfileOnYukleme] phase=my_profile_pin_cache '
        'posts=${pinnedPosts.length} hls=$hlsCount',
      );
    }

    final avatarUrls = <String>{userService.avatarUrl};
    final imageUrls = <String>{};

    void collectFrom(Iterable<PostsModel> posts) {
      for (final post in posts.take(18)) {
        final preview = post.primaryVisualUrl.trim();
        if (preview.isNotEmpty) {
          imageUrls.add(preview);
        }
        if (post.authorAvatarUrl.trim().isNotEmpty) {
          avatarUrls.add(post.authorAvatarUrl.trim());
        }
        for (final img in post.canonicalImageUrls.take(2)) {
          final normalized = img.trim();
          if (normalized.isNotEmpty) {
            imageUrls.add(normalized);
          }
        }
      }
    }

    collectFrom(allPosts);
    collectFrom(photos);
    collectFrom(videos);
    collectFrom(reshares);
    collectFrom(scheduledPosts);

    for (final url in avatarUrls.where((e) => e.isNotEmpty).take(16)) {
      try {
        await TurqAvatarCacheManager.instance.getSingleFile(url);
      } catch (_) {}
    }

    for (final url in imageUrls.where((e) => e.isNotEmpty).take(32)) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(url);
      } catch (_) {}
    }
  }

  List<PostsModel> _resolveWarmProfileSurfacePosts() {
    final seen = <String>{};
    final posts = <PostsModel>[];
    for (final post in <PostsModel>[
      ...allPosts,
      ...reshares,
    ]) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seen.add(docId)) continue;
      posts.add(post);
    }
    posts.sort((left, right) {
      final timeCompare = right.timeStamp.compareTo(left.timeStamp);
      if (timeCompare != 0) return timeCompare;
      return right.docID.trim().compareTo(left.docID.trim());
    });
    return posts.take(postLimit).toList(growable: false);
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
    bootstrapFeedPlaybackAfterDataChange();
    unawaited(_performWarmProfileSurfaceCache());
  }

  bool _performApplyProfileBuckets(ProfileBuckets? buckets) {
    if (buckets == null) return false;
    if (buckets.all.isEmpty &&
        buckets.photos.isEmpty &&
        buckets.videos.isEmpty &&
        buckets.reshares.isEmpty &&
        buckets.scheduled.isEmpty) {
      return false;
    }
    allPosts.assignAll(buckets.all);
    photos.assignAll(buckets.photos);
    videos.assignAll(buckets.videos);
    reshares.assignAll(buckets.reshares);
    scheduledPosts.assignAll(buckets.scheduled);
    return true;
  }
}
