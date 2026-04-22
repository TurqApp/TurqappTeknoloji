part of 'social_profile_controller.dart';

extension SocialProfileControllerFeedPart on SocialProfileController {
  int _initialFreshHeadLimit(int limit) {
    if (limit <= 0) return 0;
    return limit < 3 ? limit : 3;
  }

  bool _hasUsableBuckets(ProfileBuckets? buckets) {
    if (buckets == null) return false;
    return buckets.all.isNotEmpty ||
        buckets.photos.isNotEmpty ||
        buckets.reshares.isNotEmpty ||
        buckets.scheduled.isNotEmpty;
  }

  Future<ProfileBuckets?> _loadFirstUsableProfileBuckets({
    required int limit,
    required bool force,
  }) async {
    await for (final resource in ProfilePostsSnapshotRepository.ensure()
        .openProfile(
      userId: userID,
      limit: limit,
      forceSync: force,
    )) {
      final buckets = resource.data;
      debugPrint(
        '[SocialProfilePrimary] stage=stream userId=$userID source=${resource.source.name} '
        'all=${buckets?.all.length ?? 0} photos=${buckets?.photos.length ?? 0} '
        'reshares=${buckets?.reshares.length ?? 0} scheduled=${buckets?.scheduled.length ?? 0}',
      );
      if (_hasUsableBuckets(buckets)) {
        return buckets;
      }
    }
    return null;
  }

  void _appendPrimaryBuckets(ProfileBuckets buckets) {
    allPosts.addAll(_dedupePosts(allPosts, buckets.all));
    photos.addAll(_dedupePosts(photos, buckets.photos));
    reshares.addAll(_dedupePosts(reshares, buckets.reshares));
    scheduledPosts.addAll(_dedupePosts(scheduledPosts, buckets.scheduled));
    bootstrapFeedPlaybackAfterDataChange();
  }

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
      debugPrint(
        '[SocialProfilePrimary] stage=start userId=$userID initial=$initial force=$force '
        'limit=${limitOverride ?? pageSize} hasMore=$_hasMorePrimary all=${allPosts.length} '
        'photos=${photos.length} reshares=${reshares.length} scheduled=${scheduledPosts.length}',
      );
      if (initial) {
        _lastPrimaryDoc = null;
        _hasMorePrimary = true;
      }

      final limit = limitOverride ?? pageSize;
      if (initial) {
        final headLimit = _initialFreshHeadLimit(limit);
        if (headLimit > 0) {
          final freshHead = await PerformanceService.traceFeedLoad(
            () => _profileRepository.fetchPrimaryPage(
              uid: userID,
              startAfter: null,
              limit: headLimit,
            ),
            postCount: allPosts.length,
            feedMode: 'profile_primary_head',
          );
          debugPrint(
            '[SocialProfilePrimary] stage=fresh_head userId=$userID '
            'all=${freshHead.all.length} photos=${freshHead.photos.length} '
            'videos=${freshHead.videos.length} scheduled=${freshHead.scheduled.length} '
            'hasMore=${freshHead.hasMore}',
          );
          if (_hasUsableBuckets(freshHead)) {
            _applyPrimaryBuckets(
              ProfileBuckets(
                all: freshHead.all,
                photos: freshHead.photos,
                videos: freshHead.videos,
                reshares: freshHead.reshares,
                scheduled: freshHead.scheduled,
              ),
              replaceReshares: false,
            );
            _lastPrimaryDoc = freshHead.lastDoc;
            _hasMorePrimary = freshHead.hasMore;
            lastPostDoc = _lastPrimaryDoc;
            lastPostDocPhoto = _lastPrimaryDoc;
            lastScheduledDoc = _lastPrimaryDoc;
          }
        }

        final buckets = await _loadFirstUsableProfileBuckets(
          limit: limit,
          force: force,
        );
        if (_hasUsableBuckets(buckets)) {
          _appendPrimaryBuckets(buckets!);
        }
        hasMorePosts.value = _hasMorePrimary;
        hasMorePhoto.value = _hasMorePrimary;
        hasMoreScheduled.value = _hasMorePrimary;
        debugPrint(
          '[SocialProfilePrimary] stage=initial_mix userId=$userID '
          'all=${allPosts.length} photos=${photos.length} '
          'reshares=${reshares.length} scheduled=${scheduledPosts.length} '
          'hasMore=$_hasMorePrimary',
        );
        return;
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
      debugPrint(
        '[SocialProfilePrimary] stage=page userId=$userID initial=$initial '
        'all=${page.all.length} photos=${page.photos.length} videos=${page.videos.length} '
        'reshares=${page.reshares.length} scheduled=${page.scheduled.length} hasMore=${page.hasMore}',
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
      debugPrint(
        '[SocialProfilePrimary] stage=applied userId=$userID initial=$initial '
        'all=${allPosts.length} photos=${photos.length} reshares=${reshares.length} '
        'scheduled=${scheduledPosts.length} hasMore=$_hasMorePrimary',
      );
      bootstrapFeedPlaybackAfterDataChange();
    } catch (e) {
      debugPrint(
        '[SocialProfilePrimary] stage=error userId=$userID initial=$initial force=$force error=$e',
      );
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
