part of 'splash_view.dart';

extension _SplashViewWarmPart on _SplashViewState {
  Future<void> _performRunCriticalWarmStartLoads({
    required bool isFirstLaunch,
  }) async {
    try {
      final onWiFi = _isOnWiFiNow();
      final storyController = maybeFindStoryRowController();
      if (storyController == null) return;
      final agendaController = ensureAgendaController();
      final recommendedController = ensureRecommendedUserListController();

      await Future.wait([
        (() async {
          try {
            final shorts = maybeFindShortController();
            if (shorts == null) return;
            await _warmShortSnapshotForStartup(
              onWiFi: onWiFi,
              isFirstLaunch: isFirstLaunch,
            );
            await shorts.backgroundPreload().timeout(
                  Duration(seconds: onWiFi ? 4 : 2),
                  onTimeout: () {},
                );
            shorts.warmStart(
              targetCount:
                  onWiFi ? (isFirstLaunch ? 6 : 8) : (isFirstLaunch ? 3 : 4),
              maxPages: onWiFi ? 2 : 1,
            );
            _primeShortVideoSegments(shorts);
          } catch (_) {}
        })(),
        _forceLoadStoriesSync(
          storyController,
          limit: onWiFi ? (isFirstLaunch ? 20 : 30) : (isFirstLaunch ? 10 : 16),
        ),
        (() async {
          try {
            await _warmFeedSnapshotForStartup(
              onWiFi: onWiFi,
              isFirstLaunch: isFirstLaunch,
            );
            await agendaController
                .hydrateInitialFeedFromCache(
                  targetCount: _feedWarmPoolLimit(),
                )
                .timeout(const Duration(seconds: 3));
            _primeFeedVideoSegments(agendaController);
          } catch (_) {}
        })(),
        (() async {
          try {
            await _warmMarketListings(onWiFi: onWiFi).timeout(
              Duration(milliseconds: onWiFi ? 1400 : 900),
              onTimeout: () {},
            );
          } catch (_) {}
        })(),
        (() async {
          try {
            await _warmJobListings(onWiFi: onWiFi).timeout(
              Duration(milliseconds: onWiFi ? 1400 : 900),
              onTimeout: () {},
            );
          } catch (_) {}
        })(),
        (() async {
          try {
            await recommendedController
                .ensureLoaded(limit: recommendedController.usersWarmCount)
                .timeout(
                  Duration(milliseconds: onWiFi ? 1600 : 1100),
                  onTimeout: () {},
                );
          } catch (_) {}
        })(),
      ]);

      unawaited(
        _warmUserMetaAndAvatars(
          agendaController: agendaController,
          storyController: storyController,
          recommendedController: recommendedController,
          onWiFi: onWiFi,
        ).timeout(
          Duration(milliseconds: onWiFi ? 900 : 500),
          onTimeout: () {},
        ),
      );
      unawaited(
        _warmProfileCacheSurfaces(onWiFi: onWiFi).timeout(
          Duration(milliseconds: onWiFi ? 900 : 500),
          onTimeout: () {},
        ),
      );
      unawaited(
        _warmSliderCaches(onWiFi: onWiFi).timeout(
          Duration(milliseconds: onWiFi ? 1200 : 650),
          onTimeout: () {},
        ),
      );
    } catch (_) {}
  }

  void _primeShortVideoSegments(ShortController shorts) {
    try {
      final prefetch = maybeFindPrefetchScheduler();
      if (prefetch == null) return;
      final docIds = shorts.shorts
          .where((p) => p.hasPlayableVideo)
          .map((p) => p.docID)
          .where((id) => id.isNotEmpty)
          .take(12)
          .toList();
      if (docIds.isEmpty) return;
      unawaited(prefetch.updateQueue(docIds, 0));
    } catch (_) {}
  }

  void _primeFeedVideoSegments(AgendaController agendaController) {
    try {
      final prefetch = maybeFindPrefetchScheduler();
      if (prefetch == null) return;
      final docIds = agendaController.agendaList
          .where((p) => p.hasPlayableVideo)
          .map((p) => p.docID)
          .where((id) => id.isNotEmpty)
          .take(15)
          .toList();
      if (docIds.isEmpty) return;
      unawaited(prefetch.updateFeedQueue(docIds, 0));
    } catch (_) {}
  }

  Future<void> _performRunWarmStartLoads({required bool isFirstLaunch}) async {
    try {
      final onWiFi = _isOnWiFiNow();
      final storyController = maybeFindStoryRowController();
      if (storyController == null) return;
      final shortTarget =
          onWiFi ? (isFirstLaunch ? 8 : 10) : (isFirstLaunch ? 4 : 6);
      final storyTarget = onWiFi ? 30 : 18;

      try {
        final shorts = maybeFindShortController();
        if (shorts != null && shorts.shorts.length < shortTarget) {
          shorts.warmStart(
            targetCount: shortTarget,
            maxPages: onWiFi ? 2 : 1,
          );
        }
      } catch (_) {}

      if (storyController.users.length < storyTarget) {
        await _forceLoadStoriesSync(storyController, limit: storyTarget);
      }
    } catch (_) {}
  }

  Future<void> _performPrepareMinimumStartupBeforeNav({
    required bool isFirstLaunch,
  }) async {
    const timeout = Duration(milliseconds: 1000);

    try {
      await Future.any([
        _prepareMinimumStartupCore(
          isFirstLaunch: isFirstLaunch,
          onWiFi: _isOnWiFiNow(),
        ),
        Future.delayed(timeout),
      ]);
      _minimumStartupPrepared = true;
    } catch (_) {}
  }

  Future<void> _performPrepareSynchronizedStartupBeforeNav({
    required bool isFirstLaunch,
  }) async {
    await Future.wait([
      _prepareMinimumStartupBeforeNav(isFirstLaunch: isFirstLaunch),
      _ensureMinSplashDuration(),
    ]);

    unawaited(
      _waitForCriticalDataReadiness(
        timeout: _SplashViewState._syncStartupMaxWait,
      ),
    );
    await _ensureMinLaunchToNavDuration();
  }

  Future<void> _ensureMinSplashDuration() async {
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs;
    final remainingMs =
        _SplashViewState._syncMinSplashDuration.inMilliseconds - elapsedMs;
    if (remainingMs > 0) {
      await Future.delayed(Duration(milliseconds: remainingMs));
    }
  }

  Future<void> _ensureMinLaunchToNavDuration() async {
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - appLaunchEpochMs;
    final remainingMs =
        _SplashViewState._syncMinLaunchToNavDuration.inMilliseconds - elapsedMs;
    if (remainingMs > 0) {
      await Future.delayed(Duration(milliseconds: remainingMs));
    }
  }

  Future<void> _waitForCriticalDataReadiness({
    required Duration timeout,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final feedReady = _isFeedReady();
      final storyReady = _isStoryReady();
      final shortsReady = _isShortsReady();
      if (feedReady && storyReady && shortsReady) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 140));
    }
  }

  bool _isFeedReady() {
    return (maybeFindAgendaController()?.agendaList.length ?? 0) >=
        _SplashViewState._minFeedPostsForNav;
  }

  bool _isStoryReady() {
    final storyController = maybeFindStoryRowController();
    if (storyController == null) return false;
    return storyController.users.length >=
        _SplashViewState._minStoryUsersForNav;
  }

  bool _isShortsReady() {
    return (maybeFindShortController()?.shorts.length ?? 0) >=
        _SplashViewState._minShortsForNav;
  }

  Future<void> _prepareMinimumStartupCore({
    required bool isFirstLaunch,
    required bool onWiFi,
  }) async {
    unawaited(
      _initCacheProxy()
          .timeout(
            onWiFi ? const Duration(seconds: 3) : const Duration(seconds: 2),
            onTimeout: () {},
          )
          .catchError((_) {}),
    );
    await _runCriticalWarmStartLoads(isFirstLaunch: isFirstLaunch)
        .timeout(
          onWiFi ? const Duration(seconds: 2) : const Duration(seconds: 1),
          onTimeout: () {},
        )
        .catchError((_) {});
  }

  bool _isOnWiFiNow() {
    try {
      return NetworkAwarenessService.ensure().isOnWiFi;
    } catch (_) {
      return false;
    }
  }

  Future<void> _warmMarketListings({required bool onWiFi}) async {
    try {
      final warmLimit = onWiFi ? 18 : 10;
      final userId = CurrentUserService.instance.effectiveUserId;
      final cached = await MarketSnapshotRepository.ensure()
          .openHome(
            userId: userId,
            limit: warmLimit,
          )
          .first;
      _trackStartupSnapshot(
        surface: 'market',
        resource: cached,
        itemCount: (cached.data ?? const <MarketItemModel>[]).length,
      );
      final cachedItems = cached.data ?? const <MarketItemModel>[];

      if (cachedItems.where((item) => item.status == 'active').length >= 10) {
        return;
      }

      await MarketSnapshotRepository.ensure().loadHome(
        userId: userId,
        limit: warmLimit,
        forceSync: true,
      );
    } catch (_) {}
  }

  Future<void> _warmJobListings({required bool onWiFi}) async {
    try {
      final warmLimit = onWiFi ? 18 : 10;
      final userId = CurrentUserService.instance.effectiveUserId;
      final cached = await ensureJobHomeSnapshotRepository()
          .openHome(
            userId: userId,
            limit: warmLimit,
          )
          .first;
      _trackStartupSnapshot(
        surface: 'jobs',
        resource: cached,
        itemCount: (cached.data ?? const <dynamic>[]).length,
      );
      final cachedItems = cached.data ?? const <dynamic>[];

      if (cachedItems.length >= 10) {
        return;
      }

      await ensureJobHomeSnapshotRepository().loadHome(
        userId: userId,
        limit: warmLimit,
        forceSync: true,
      );
    } catch (_) {}
  }

  Future<void> _warmFeedSnapshotForStartup({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) async {
    try {
      final userId = CurrentUserService.instance.effectiveUserId;
      if (userId.isEmpty) return;
      final warmLimit = _feedWarmPoolLimit();
      final snapshot = await ensureFeedSnapshotRepository().bootstrapHome(
        userId: userId,
        limit: warmLimit,
      );
      _feedWarmSnapshotHit = snapshot.hasLocalSnapshot;
      _feedWarmSnapshotSource = snapshot.source.name;
      _feedWarmSnapshotAgeMs = snapshot.snapshotAt == null
          ? null
          : DateTime.now().difference(snapshot.snapshotAt!).inMilliseconds;
      _trackStartupSnapshot(
        surface: 'feed',
        resource: snapshot,
        itemCount: (snapshot.data ?? const <dynamic>[]).length,
      );
    } catch (_) {}
  }

  Future<void> _warmShortSnapshotForStartup({
    required bool onWiFi,
    required bool isFirstLaunch,
  }) async {
    try {
      final userId = CurrentUserService.instance.effectiveUserId;
      if (userId.isEmpty) return;
      final warmLimit =
          onWiFi ? (isFirstLaunch ? 6 : 8) : (isFirstLaunch ? 3 : 4);
      final snapshot = await ensureShortSnapshotRepository().bootstrapHome(
        userId: userId,
        limit: warmLimit,
      );
      _shortWarmSnapshotHit = snapshot.hasLocalSnapshot;
      _shortWarmSnapshotSource = snapshot.source.name;
      _shortWarmSnapshotAgeMs = snapshot.snapshotAt == null
          ? null
          : DateTime.now().difference(snapshot.snapshotAt!).inMilliseconds;
      _trackStartupSnapshot(
        surface: 'short',
        resource: snapshot,
        itemCount: (snapshot.data ?? const <dynamic>[]).length,
      );
    } catch (_) {}
  }

  void _trackStartupSnapshot<T>({
    required String surface,
    required CachedResource<T> resource,
    required int itemCount,
  }) {
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi == null) return;
    playbackKpi.track(
      PlaybackKpiEventType.startup,
      <String, dynamic>{
        'surface': surface,
        'hasLocalSnapshot': resource.hasLocalSnapshot,
        'source': resource.source.name,
        'isStale': resource.isStale,
        'snapshotAgeMs': resource.snapshotAt == null
            ? null
            : DateTime.now().difference(resource.snapshotAt!).inMilliseconds,
        'itemCount': itemCount,
      },
    );
  }

  Future<void> _warmUserMetaAndAvatars({
    required AgendaController agendaController,
    required StoryRowController storyController,
    RecommendedUserListController? recommendedController,
    required bool onWiFi,
  }) async {
    try {
      final userIds = <String>{};
      final currentUid = CurrentUserService.instance.effectiveUserId;
      if (currentUid.isNotEmpty) {
        userIds.add(currentUid);
      }

      final feedTake = onWiFi ? 28 : 14;
      final storyTake = onWiFi ? 18 : 10;
      final recommendedTake = onWiFi ? 18 : 10;

      for (final post in agendaController.agendaList.take(feedTake)) {
        userIds.add(post.userID);
        if (post.originalUserID.isNotEmpty) {
          userIds.add(post.originalUserID);
        }
      }
      for (final user in storyController.users.take(storyTake)) {
        userIds.add(user.userID);
      }
      if (recommendedController != null) {
        for (final user in recommendedController.list.take(recommendedTake)) {
          userIds.add(user.userID);
        }
      }

      if (userIds.isEmpty) return;

      final userCache = ensureUserProfileCacheService();
      final profiles = await userCache.getProfiles(
        userIds.toList(),
        preferCache: true,
      );

      final avatarUrls = <String>[];
      for (final uid in userIds) {
        final url = (profiles[uid]?['avatarUrl'] ?? '').toString().trim();
        if (url.isNotEmpty) avatarUrls.add(url);
      }

      final warmCount = onWiFi ? 36 : 12;
      for (final url in avatarUrls.take(warmCount)) {
        try {
          await TurqImageCacheManager.instance.getSingleFile(url);
          final provider = CachedNetworkImageProvider(
            url,
            cacheManager: TurqImageCacheManager.instance,
          );
          if (mounted) {
            await precacheImage(provider, context);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _warmProfileCacheSurfaces({required bool onWiFi}) async {
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;

      final urls = <String>{};
      final avatarUrl = CurrentUserService.instance.avatarUrl.trim();
      if (avatarUrl.isNotEmpty) {
        urls.add(avatarUrl);
        try {
          await TurqImageCacheManager.instance.getSingleFile(avatarUrl);
          if (mounted) {
            await precacheImage(
              CachedNetworkImageProvider(
                avatarUrl,
                cacheManager: TurqImageCacheManager.instance,
              ),
              context,
            );
          }
        } catch (_) {}
      }

      final cache = ProfilePostsCacheService();
      final buckets = await Future.wait([
        cache.readBucket(uid: uid, bucket: 'all'),
        cache.readBucket(uid: uid, bucket: 'photos'),
        cache.readBucket(uid: uid, bucket: 'videos'),
        cache.readBucket(uid: uid, bucket: 'scheduled'),
      ]);

      for (final bucket in buckets) {
        for (final post in bucket.take(onWiFi ? 18 : 10)) {
          if (post.thumbnail.trim().isNotEmpty) {
            urls.add(post.thumbnail.trim());
          }
          for (final img in post.img.take(2)) {
            final normalized = img.trim();
            if (normalized.isNotEmpty) {
              urls.add(normalized);
            }
          }
        }
      }

      for (final url
          in urls.where((e) => e.isNotEmpty).take(onWiFi ? 40 : 20)) {
        try {
          await TurqImageCacheManager.instance.getSingleFile(url);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _warmSliderCaches({required bool onWiFi}) async {
    try {
      const sliderIds = <String>[
        'ads_feed',
        'ads_profile',
        'ads_market',
        'ads_scholarship',
        'ads_answer_key',
        'ads_job',
        'ads_practice_exam',
        'ads_tutoring',
        'is_bul',
        'online_sinav',
        'cevap_anahtari',
        'ozel_ders',
        'denemeler',
      ];
      final cache = SliderCacheService();

      for (final sliderId in sliderIds) {
        final snapshot = await cache.readSnapshot(sliderId);
        if (snapshot.hasItems) {
          for (final url in snapshot.items
              .where((e) => e.startsWith('http'))
              .take(onWiFi ? 8 : 4)) {
            try {
              await TurqImageCacheManager.instance.getSingleFile(url);
            } catch (_) {}
          }
          if (snapshot.isFresh) {
            continue;
          }
        }

        final resolved = await cache.refreshAndCacheSources(
          sliderId,
          warmRemoteLimit: onWiFi ? 8 : 4,
        );
        if (resolved.isEmpty) continue;
      }
    } catch (_) {}
  }

  Future<void> _forceLoadStoriesSync(
    StoryRowController storyController, {
    int limit = 30,
  }) async {
    try {
      if (storyController.users.length >= limit ||
          storyController.isLoading.value) {
        if (storyController.users.isEmpty) {
          await storyController.addMyUserImmediately();
        }
        return;
      }
      await storyController.loadStories(
        limit: limit,
        cacheFirst: true,
        silentLoad: false,
      );
      if (storyController.users.isEmpty) {
        await storyController.addMyUserImmediately();
      }
    } catch (_) {
      try {
        await storyController.addMyUserImmediately();
      } catch (_) {}
    }
  }
}
