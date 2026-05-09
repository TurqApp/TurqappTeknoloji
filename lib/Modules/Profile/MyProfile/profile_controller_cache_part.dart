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
      limit: _profileFirstPaintCacheLimit,
      source: CachedResourceSource.server,
    );
    debugPrint(
      '[ProfilePostsCache] action=persist_first_paint '
      'source=firebase limit=$_profileFirstPaintCacheLimit '
      'all=${allPosts.length} photos=${photos.length} '
      'videos=${videos.length} reshares=${reshares.length} '
      'scheduled=${scheduledPosts.length}',
    );
  }

  Future<void> _performRestoreCachedListsForActiveUser() async {
    final uid = _resolvedActiveUid;
    if (uid == null || uid.isEmpty) {
      unawaited(_performWarmProfileSurfaceCache());
      return;
    }

    final hasVisiblePosts = allPosts.isNotEmpty ||
        photos.isNotEmpty ||
        videos.isNotEmpty ||
        reshares.isNotEmpty ||
        scheduledPosts.isNotEmpty;
    if (hasVisiblePosts) {
      debugPrint(
        '[ProfilePostsCache] action=skip_first_paint '
        'reason=visible_posts_exist all=${allPosts.length} '
        'photos=${photos.length} videos=${videos.length} '
        'reshares=${reshares.length} scheduled=${scheduledPosts.length}',
      );
      unawaited(_performWarmProfileSurfaceCache());
      return;
    }

    final cached = await _profileSnapshotRepository.readLocalBuckets(
      userId: uid,
      limit: _profileFirstPaintCacheLimit,
    );
    if (cached == null || cached.all.isEmpty) {
      debugPrint(
        '[ProfilePostsCache] action=first_paint_miss userId=$uid',
      );
      unawaited(_performWarmProfileSurfaceCache());
      return;
    }

    allPosts.assignAll(cached.all);
    photos.assignAll(cached.photos);
    videos.assignAll(cached.videos);
    reshares.assignAll(cached.reshares);
    scheduledPosts.assignAll(cached.scheduled);
    _hasMorePrimary = true;
    hasMorePosts = true;
    hasMorePostsPhotos = true;
    hasMorePostsVideos = true;
    hasMoreScheduled = true;
    bootstrapFeedPlaybackAfterDataChange();
    debugPrint(
      '[ProfilePostsCache] action=first_paint_apply '
      'source=last_firebase_snapshot limit=$_profileFirstPaintCacheLimit '
      'all=${cached.all.length} photos=${cached.photos.length} '
      'videos=${cached.videos.length} reshares=${cached.reshares.length} '
      'scheduled=${cached.scheduled.length}',
    );
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
      for (final post in posts.take(_profileMediaCacheLimit)) {
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

    collectFrom(pinnedPosts);

    for (final url
        in avatarUrls.where((e) => e.isNotEmpty).take(_profileMediaCacheLimit)) {
      try {
        await TurqAvatarCacheManager.instance.getSingleFile(url);
      } catch (_) {}
    }

    for (final url
        in imageUrls.where((e) => e.isNotEmpty).take(_profileMediaCacheLimit)) {
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
    return posts.take(_profileMediaCacheLimit).toList(growable: false);
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
  }) =>
      _fetchPrimaryBuckets(initial: true, force: forceSync);
}
