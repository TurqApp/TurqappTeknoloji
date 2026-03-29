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
