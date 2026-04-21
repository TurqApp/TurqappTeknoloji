part of 'social_profile_controller.dart';

extension SocialProfileControllerFeedPart on SocialProfileController {
  void _applyPrimaryBuckets(
    ProfileBuckets buckets, {
    bool replaceReshares = true,
  }) {
    allPosts.assignAll(buckets.all);
    photos.assignAll(buckets.photos);
    if (replaceReshares || buckets.reshares.isNotEmpty || reshares.isEmpty) {
      reshares.assignAll(buckets.reshares);
    }
    final isOwnProfile =
        CurrentUserService.instance.effectiveUserId.trim() == userID.trim();
    if (isOwnProfile) {
      scheduledPosts.assignAll(buckets.scheduled);
    } else {
      scheduledPosts.clear();
    }
    bootstrapFeedPlaybackAfterDataChange();
  }

  Future<void> _performGetPosts({bool initial = false}) async {
    await _fetchPrimaryBuckets(initial: initial, limitOverride: pageSize);
  }

  Future<void> _performGetPhotos({bool initial = false}) async {
    await _fetchPrimaryBuckets(initial: initial, limitOverride: pageSizePhoto);
  }

  Future<void> _performSetPostSelection(int index) async {
    postSelection.value = index;
    if (index != 0) {
      VideoStateManager.instance.pauseAllVideos(force: true);
    }
    UserAnalyticsService.instance
        .trackFeatureUsage('social_profile_tab_$index');
    if (index == 5) {
      if (scheduledPosts.isEmpty || lastScheduledDoc == null) {
        await fetchScheduledPosts(initial: true);
      }
    }
  }

  Future<void> _performFetchScheduledPosts({bool initial = false}) async {
    await _fetchPrimaryBuckets(
      initial: initial,
      limitOverride: pageSizeScheduled,
    );
  }

  Future<void> _performRefreshAll() async {
    try {
      await getCounters();
      await getUserData();
      await getSocialMediaLinks();

      _lastPrimaryDoc = null;
      _hasMorePrimary = true;

      await Future.wait([
        _fetchPrimaryBuckets(initial: true, force: true),
        getReshares(),
      ]);
      bootstrapFeedPlaybackAfterDataChange();
    } catch (e) {
      print('SocialProfile.refreshAll error: $e');
    }
  }

  Future<void> _performRestoreCachedBuckets() async {
    final buckets =
        await ProfilePostsSnapshotRepository.ensure().readLocalBuckets(
      userId: userID,
      limit: pageSize,
    );
    if (buckets == null) return;
    if (buckets.all.isEmpty &&
        buckets.photos.isEmpty &&
        buckets.reshares.isEmpty &&
        buckets.scheduled.isEmpty) {
      return;
    }
    _applyPrimaryBuckets(buckets);
  }

  Future<void> _performFetchPrimaryBuckets({
    required bool initial,
    bool force = false,
    int? limitOverride,
  }) async {
    if (_isLoadingPrimary && !force) return;
    if (!initial && !_hasMorePrimary) return;

    _isLoadingPrimary = true;
    isLoadingPosts.value = true;
    isLoadingPhoto.value = true;
    isLoadingScheduled.value = true;
    try {
      if (initial) {
        _lastPrimaryDoc = null;
        _hasMorePrimary = true;
      }

      final limit = limitOverride ?? pageSize;
      if (initial) {
        final resource =
            await ProfilePostsSnapshotRepository.ensure().loadProfile(
          userId: userID,
          limit: limit,
          forceSync: force,
        );
        final buckets = resource.data;
        if (buckets != null &&
            (buckets.all.isNotEmpty ||
                buckets.photos.isNotEmpty ||
                buckets.reshares.isNotEmpty ||
                buckets.scheduled.isNotEmpty)) {
          _applyPrimaryBuckets(buckets);
        }
      }

      final page = await PerformanceService.traceFeedLoad(
        () => _profileRepository.fetchPrimaryPage(
          uid: userID,
          startAfter: initial ? null : _lastPrimaryDoc,
          limit: limit,
        ),
        postCount: allPosts.length,
        feedMode: 'profile_primary',
      );

      if (initial) {
        _applyPrimaryBuckets(
          ProfileBuckets(
            all: page.all,
            photos: page.photos,
            videos: page.videos,
            reshares: page.reshares,
            scheduled: page.scheduled,
          ),
          replaceReshares: false,
        );
      } else {
        allPosts.addAll(_dedupePosts(allPosts, page.all));
        photos.addAll(_dedupePosts(photos, page.photos));
        reshares.addAll(_dedupePosts(reshares, page.reshares));
        scheduledPosts.addAll(_dedupePosts(scheduledPosts, page.scheduled));
      }

      _lastPrimaryDoc = page.lastDoc;
      _hasMorePrimary = page.hasMore;
      lastPostDoc = _lastPrimaryDoc;
      lastPostDocPhoto = _lastPrimaryDoc;
      lastScheduledDoc = _lastPrimaryDoc;
      hasMorePosts.value = _hasMorePrimary;
      hasMorePhoto.value = _hasMorePrimary;
      hasMoreScheduled.value = _hasMorePrimary;

      await _profileRepository.writeBuckets(
        userID,
        ProfileBuckets(
          all: allPosts,
          photos: photos,
          videos: allPosts.where((post) => post.hasPlayableVideo).toList(),
          reshares: reshares,
          scheduled: scheduledPosts,
        ),
      );
      bootstrapFeedPlaybackAfterDataChange();
    } catch (e) {
      print('_fetchPrimaryBuckets(SocialProfile) error: $e');
    } finally {
      _isLoadingPrimary = false;
      isLoadingPosts.value = false;
      isLoadingPhoto.value = false;
      isLoadingScheduled.value = false;
    }
  }

  List<PostsModel> _performDedupePosts(
    List<PostsModel> existing,
    List<PostsModel> incoming,
  ) {
    final known = existing.map((e) => e.docID).toSet();
    return incoming.where((post) => known.add(post.docID)).toList();
  }
}
