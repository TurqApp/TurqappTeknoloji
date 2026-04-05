part of 'splash_view.dart';

extension _SplashViewWarmPart on _SplashViewState {
  Future<void> _runWarmSlice(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }

  Future<void> _runWarmSlices(
    Iterable<Future<void> Function()> slices,
  ) async {
    for (final slice in slices) {
      await _runWarmSlice(slice);
    }
  }

  Future<Map<String, bool>> _loadSplashPasajVisibilitySnapshot({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _pasajVisibilitySnapshot = null;
      _pasajVisibilitySnapshotFuture = null;
    }

    final cached = _pasajVisibilitySnapshot;
    if (cached != null) {
      return cached;
    }

    final inFlight = _pasajVisibilitySnapshotFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final future = () async {
      try {
        final resolved = await loadEffectivePasajVisibility(
          preferCache: true,
          forceRefresh: forceRefresh,
        );
        final normalized = normalizePasajVisibilitySnapshot(resolved);
        _pasajVisibilitySnapshot = normalized;
        return normalized;
      } catch (_) {
        try {
          final local = await loadPasajVisibilitySnapshot();
          final normalized = normalizePasajVisibilitySnapshot(local);
          _pasajVisibilitySnapshot = normalized;
          return normalized;
        } catch (_) {
          final fallback = normalizePasajVisibilitySnapshot(
            null,
            defaultValue: false,
          );
          _pasajVisibilitySnapshot = fallback;
          return fallback;
        }
      } finally {
        _pasajVisibilitySnapshotFuture = null;
      }
    }();

    _pasajVisibilitySnapshotFuture = future;
    return future;
  }

  Future<bool> _isSplashPasajTabEnabled(String tabId) async {
    if (!pasajTabs.contains(tabId)) {
      return true;
    }
    final snapshot = await _loadSplashPasajVisibilitySnapshot();
    return snapshot[tabId] ?? false;
  }

  Future<List<String>> _orderedWarmPasajListingTabs() async {
    const listingTabs = <String>[
      PasajTabIds.market,
      PasajTabIds.jobFinder,
      PasajTabIds.scholarships,
      PasajTabIds.tutoring,
    ];
    final snapshot = await _loadSplashPasajVisibilitySnapshot();
    final ordered = <String>[];

    void addIfVisible(String tabId) {
      if (!listingTabs.contains(tabId)) return;
      if (!(snapshot[tabId] ?? false)) return;
      if (!ordered.contains(tabId)) {
        ordered.add(tabId);
      }
    }

    final preferred = _effectiveEducationTabId();
    if (preferred != null) {
      addIfVisible(preferred);
    }
    for (final tabId in listingTabs) {
      addIfVisible(tabId);
    }
    return ordered;
  }

  Future<void> _warmPasajListingSurface(
    String tabId, {
    required bool onWiFi,
  }) async {
    switch (tabId) {
      case PasajTabIds.market:
        await _warmMarketListings(onWiFi: onWiFi);
        return;
      case PasajTabIds.jobFinder:
        await _warmJobListings(onWiFi: onWiFi);
        return;
      case PasajTabIds.scholarships:
        await _warmScholarshipListings(onWiFi: onWiFi);
        return;
      case PasajTabIds.tutoring:
        await _warmTutoringListings(onWiFi: onWiFi);
        return;
      default:
        return;
    }
  }

  bool _shouldPrioritizeEducationWarmups() {
    return _effectiveStartupRouteHint() == 'nav_education';
  }

  Future<void> _performRunCriticalWarmStartLoads({
    required bool isFirstLaunch,
  }) async {
    try {
      unawaited(HlsSegmentPolicy.refresh());
      final onWiFi = _isOnWiFiNow();
      final storyController = maybeFindStoryRowController();
      final agendaController = ensureAgendaController();
      final recommendedController = ensureRecommendedUserListController();
      final prioritizeHomeWarmups = _shouldRequireFeedReadiness();
      final prioritizeExploreWarmups = _shouldPrioritizeExploreWarmups();
      final prioritizeProfileWarmups = _shouldPrioritizeProfileWarmups();
      final prioritizeEducationWarmups = _shouldPrioritizeEducationWarmups();
      final prioritizeEducationMarketWarmups =
          _shouldPrioritizeEducationMarketWarmups();
      final prioritizeEducationJobWarmups =
          _shouldPrioritizeEducationJobWarmups();
      final deferShortCriticalWarmup =
          Platform.isAndroid && prioritizeHomeWarmups;
      final criticalSlices = <Future<void> Function()>[];

      if (prioritizeHomeWarmups) {
        criticalSlices.add(() async {
          await _warmFeedSnapshotForStartup(
            onWiFi: onWiFi,
            isFirstLaunch: isFirstLaunch,
          );
          await agendaController
              .prepareStartupSurface(
                allowBackgroundRefresh: false,
              )
              .timeout(const Duration(seconds: 3), onTimeout: () {});
        });
        if (storyController != null) {
          criticalSlices.add(() async {
            await _forceLoadStoriesSync(
              storyController,
              limit: ReadBudgetRegistry.storyStartupWarmLimit(
                onWiFi: onWiFi,
                isFirstLaunch: isFirstLaunch,
              ),
            );
          });
        }
        if (!deferShortCriticalWarmup) {
          criticalSlices.add(() async {
            final shorts = maybeFindShortController();
            if (shorts == null) return;
            await _warmShortSnapshotForStartup(
              onWiFi: onWiFi,
              isFirstLaunch: isFirstLaunch,
            );
            await shorts
                .prepareStartupSurface(
                  allowBackgroundRefresh: false,
                )
                .timeout(
                  Duration(seconds: onWiFi ? 4 : 2),
                  onTimeout: () {},
                );
            _primeShortVideoSegments(shorts);
          });
        }
        criticalSlices.add(() async {
          await recommendedController
              .ensureLoaded(limit: recommendedController.usersWarmCount)
              .timeout(
                Duration(milliseconds: onWiFi ? 1600 : 1100),
                onTimeout: () {},
              );
        });
      }

      if (prioritizeProfileWarmups) {
        criticalSlices.add(() async {
          final profileController =
              ProfileController.maybeFind() ?? ProfileController.ensure();
          await profileController
              .prepareStartupSurface(
                allowBackgroundRefresh: ContentPolicy.allowBackgroundRefresh(
                  ContentScreenKind.profile,
                ),
              )
              .timeout(
                Duration(milliseconds: onWiFi ? 1000 : 650),
                onTimeout: () {},
              );
        });
        criticalSlices.add(() async {
          await _warmProfileCacheSurfaces(
            onWiFi: onWiFi,
          ).timeout(
            Duration(milliseconds: onWiFi ? 900 : 500),
            onTimeout: () {},
          );
        });
      }

      if (prioritizeExploreWarmups) {
        criticalSlices.add(() async {
          final exploreController =
              maybeFindExploreController() ?? ensureExploreController();
          await exploreController
              .prepareStartupSurface(
                allowBackgroundRefresh: ContentPolicy.allowBackgroundRefresh(
                  ContentScreenKind.explore,
                ),
              )
              .timeout(
                Duration(milliseconds: onWiFi ? 1100 : 650),
                onTimeout: () {},
              );
        });
      }

      if (prioritizeEducationWarmups) {
        if (prioritizeEducationMarketWarmups) {
          criticalSlices.add(() async {
            if (!await _isSplashPasajTabEnabled(PasajTabIds.market)) return;
            await prepareMarketStartupSurface(
              maybeFindMarketController() ?? ensureMarketController(),
              allowBackgroundRefresh: onWiFi,
            ).timeout(
              Duration(milliseconds: onWiFi ? 1200 : 800),
              onTimeout: () {},
            );
          });
        }
        if (prioritizeEducationJobWarmups) {
          criticalSlices.add(() async {
            if (!await _isSplashPasajTabEnabled(PasajTabIds.jobFinder)) {
              return;
            }
            await prepareJobFinderStartupSurface(
              maybeFindJobFinderController() ?? ensureJobFinderController(),
              allowBackgroundRefresh: onWiFi,
            ).timeout(
              Duration(milliseconds: onWiFi ? 1200 : 800),
              onTimeout: () {},
            );
          });
        }
      }

      await _runWarmSlices(criticalSlices);

      final deferredSlices = <Future<void> Function()>[];
      if (prioritizeHomeWarmups && storyController != null) {
        deferredSlices.add(() async {
          await _warmUserMetaAndAvatars(
            agendaController: agendaController,
            storyController: storyController,
            recommendedController: recommendedController,
            onWiFi: onWiFi,
          ).timeout(
            Duration(milliseconds: onWiFi ? 900 : 500),
            onTimeout: () {},
          );
        });
      }
      if (!prioritizeProfileWarmups) {
        deferredSlices.add(() async {
          await _warmProfileCacheSurfaces(
            onWiFi: onWiFi,
          ).timeout(
            Duration(milliseconds: onWiFi ? 900 : 500),
            onTimeout: () {},
          );
        });
      }

      final deferredWarmSlicesFuture = _runWarmSlices(deferredSlices);
      final warmSliderFuture = _warmSliderCaches(onWiFi: onWiFi).timeout(
        Duration(milliseconds: onWiFi ? 1200 : 650),
        onTimeout: () {},
      );

      if (Platform.isAndroid && isFirstLaunch) {
        await Future.any([
          deferredWarmSlicesFuture,
          Future.delayed(
            Duration(milliseconds: onWiFi ? 280 : 180),
          ),
        ]);
        unawaited(warmSliderFuture);
      } else {
        unawaited(deferredWarmSlicesFuture);
        unawaited(warmSliderFuture);
      }
    } catch (_) {}
  }

  void _primeShortVideoSegments(ShortController shorts) {
    try {
      final prefetch = maybeFindPrefetchScheduler();
      if (prefetch == null) return;
      final startupWindow = shorts.shorts
          .take(ReadBudgetRegistry.shortReadyForNavCount)
          .toList(growable: false);
      if (startupWindow.isEmpty) return;
      unawaited(prefetch.updateQueueForPosts(
        startupWindow,
        0,
        maxDocs: startupWindow.length,
      ));
      _primeShortStartupSegments(shorts, prefetch);
    } catch (_) {}
  }

  void _primeShortStartupSegments(
    ShortController shorts,
    PrefetchScheduler prefetch,
  ) {
    try {
      final startupWindow = shorts.shorts
          .where((post) => post.hasPlayableVideo)
          .take(ReadBudgetRegistry.shortReadyForNavCount)
          .toList(growable: false);
      for (final post in startupWindow) {
        prefetch.boostDoc(
          post.docID,
          readySegments: SegmentCacheRuntimeService.globalReadySegmentCount,
        );
      }
    } catch (_) {}
  }

  Future<void> _performRunWarmStartLoads({required bool isFirstLaunch}) async {
    try {
      final onWiFi = _isOnWiFiNow();
      final storyController = maybeFindStoryRowController();
      final shortTarget = ReadBudgetRegistry.shortWarmTargetCount(
        onWiFi: onWiFi,
        isFirstLaunch: isFirstLaunch,
      );
      final storyTarget =
          ReadBudgetRegistry.storyWarmReadyTarget(onWiFi: onWiFi);
      final deferShortWarmStart = _shouldRequireFeedReadiness();
      final warmSlices = <Future<void> Function()>[];

      if (!deferShortWarmStart) {
        warmSlices.add(() async {
          final shorts = maybeFindShortController();
          if (shorts == null || shorts.shorts.length >= shortTarget) return;
          await shorts.warmStart(
            targetCount: shortTarget,
            maxPages: ReadBudgetRegistry.shortWarmMaxPages(onWiFi: onWiFi),
          );
        });
      }

      if (storyController != null) {
        warmSlices.add(() async {
          if (storyController.users.length < storyTarget) {
            await _forceLoadStoriesSync(storyController, limit: storyTarget);
          }
        });
        warmSlices.add(() async {
          await _warmCurrentStoryMedia(
            storyController,
            take: storyTarget,
          );
        });
      }

      if (!_shouldRequireFeedReadiness()) {
        final orderedListingTabs = await _orderedWarmPasajListingTabs();
        for (final tabId in orderedListingTabs) {
          warmSlices.add(() async {
            await _warmPasajListingSurface(
              tabId,
              onWiFi: onWiFi,
            ).timeout(
              const Duration(milliseconds: 1400),
              onTimeout: () {},
            );
          });
        }
      }

      await _runWarmSlices(warmSlices);
    } catch (_) {}
  }

  Future<void> _warmCurrentStoryMedia(
    StoryRowController storyController, {
    required int take,
  }) async {
    try {
      final urls = <String>{};
      for (final user in storyController.users.cast<dynamic>().take(take)) {
        final avatarUrl = (user.avatarUrl ?? '').toString().trim();
        if (avatarUrl.isNotEmpty) {
          urls.add(avatarUrl);
        }
        final stories = (user.stories as List?) ?? const <dynamic>[];
        if (stories.isEmpty) continue;
        final story = stories.first;
        final musicCoverUrl = (story.musicCoverUrl ?? '').toString().trim();
        if (musicCoverUrl.isNotEmpty) {
          urls.add(musicCoverUrl);
        }
        final elements = (story.elements as List?) ?? const <dynamic>[];
        for (final element in elements) {
          final type = (element.type?.toString() ?? '').toLowerCase();
          final content = (element.content ?? '').toString().trim();
          if (content.isEmpty) continue;
          if (type.endsWith('image') || type.endsWith('gif')) {
            urls.add(content);
            break;
          }
        }
      }
      if (urls.isEmpty) return;
      for (final url in urls) {
        try {
          await TurqImageCacheManager.warmUrl(url);
        } catch (_) {}
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
      return _SplashViewState._networkRuntimeService.isOnWiFi;
    } catch (_) {
      return false;
    }
  }

  Future<void> _warmMarketListings({
    required bool onWiFi,
  }) async {
    try {
      if (!await _isSplashPasajTabEnabled(PasajTabIds.market)) {
        return;
      }
      final warmLimit =
          ReadBudgetRegistry.startupListingWarmLimit(onWiFi: onWiFi);
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
      final activeCount =
          cachedItems.where((item) => item.status == 'active').length;
      if (activeCount >= warmLimit && !cached.isStale) {
        return;
      }

      await MarketSnapshotRepository.ensure().loadHome(
        userId: userId,
        limit: warmLimit,
        forceSync: true,
      );
    } catch (_) {}
  }

  Future<void> _warmJobListings({
    required bool onWiFi,
  }) async {
    try {
      if (!await _isSplashPasajTabEnabled(PasajTabIds.jobFinder)) {
        return;
      }
      final warmLimit =
          ReadBudgetRegistry.startupListingWarmLimit(onWiFi: onWiFi);
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
      if (cachedItems.length >= warmLimit && !cached.isStale) {
        return;
      }

      await ensureJobHomeSnapshotRepository().loadHome(
        userId: userId,
        limit: warmLimit,
        forceSync: true,
      );
    } catch (_) {}
  }

  Future<void> _warmScholarshipListings({
    required bool onWiFi,
  }) async {
    try {
      if (!await _isSplashPasajTabEnabled(PasajTabIds.scholarships)) {
        return;
      }
      final warmLimit =
          ReadBudgetRegistry.startupListingWarmLimit(onWiFi: onWiFi);
      final userId = CurrentUserService.instance.effectiveUserId;
      final cached = await ensureScholarshipSnapshotRepository()
          .openHome(
            userId: userId,
            limit: warmLimit,
          )
          .first;
      _trackStartupSnapshot(
        surface: 'scholarships',
        resource: cached,
        itemCount: cached.data?.items.length ?? 0,
      );
      final cachedItems = cached.data?.items ?? const <Map<String, dynamic>>[];
      if (cachedItems.length >= warmLimit && !cached.isStale) {
        return;
      }

      await ensureScholarshipSnapshotRepository().loadHome(
        userId: userId,
        limit: warmLimit,
        forceSync: true,
      );
    } catch (_) {}
  }

  Future<void> _warmTutoringListings({
    required bool onWiFi,
  }) async {
    try {
      if (!await _isSplashPasajTabEnabled(PasajTabIds.tutoring)) {
        return;
      }
      final warmLimit =
          ReadBudgetRegistry.startupListingWarmLimit(onWiFi: onWiFi);
      final userId = CurrentUserService.instance.effectiveUserId;
      final cached = await ensureTutoringSnapshotRepository()
          .openHome(
            userId: userId,
            limit: warmLimit,
          )
          .first;
      _trackStartupSnapshot(
        surface: 'tutoring',
        resource: cached,
        itemCount: (cached.data ?? const <dynamic>[]).length,
      );
      final cachedItems = cached.data ?? const <dynamic>[];
      if (cachedItems.length >= warmLimit && !cached.isStale) {
        return;
      }

      await ensureTutoringSnapshotRepository().loadHome(
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
      final snapshot = await ensureFeedSnapshotRepository().inspectWarmHome(
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
        startupShardHydrated: _feedStartupShardHydrated,
        startupShardAgeMs: _feedStartupShardAgeMs,
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
      final warmLimit = ReadBudgetRegistry.shortStartupSnapshotLimit(
        onWiFi: onWiFi,
        isFirstLaunch: isFirstLaunch,
      );
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
        startupShardHydrated: _shortStartupShardHydrated,
        startupShardAgeMs: _shortStartupShardAgeMs,
      );
      unawaited(
        _persistShortStartupShard(
          snapshot,
          onWiFi: onWiFi,
        ),
      );
    } catch (_) {}
  }

  void _trackStartupSnapshot<T>({
    required String surface,
    required CachedResource<T> resource,
    required int itemCount,
    bool startupShardHydrated = false,
    int? startupShardAgeMs,
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
    unawaited(
      ensureStartupSnapshotManifestStore().recordSurface(
        surface: surface,
        userId: CurrentUserService.instance.effectiveUserId,
        resource: resource,
        itemCount: itemCount,
        startupShardHydrated: startupShardHydrated,
        startupShardAgeMs: startupShardAgeMs,
      ),
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

      final feedTake =
          ReadBudgetRegistry.startupUserMetaFeedTake(onWiFi: onWiFi);
      final storyTake =
          ReadBudgetRegistry.startupUserMetaStoryTake(onWiFi: onWiFi);
      final recommendedTake =
          ReadBudgetRegistry.startupUserMetaRecommendedTake(onWiFi: onWiFi);

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

      final warmCount =
          ReadBudgetRegistry.startupAvatarWarmCount(onWiFi: onWiFi);
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
        for (final post in bucket.take(
          ReadBudgetRegistry.startupProfileBucketTake(onWiFi: onWiFi),
        )) {
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

      for (final url in urls.where((e) => e.isNotEmpty).take(
            ReadBudgetRegistry.startupProfileUrlWarmCount(onWiFi: onWiFi),
          )) {
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
          for (final url
              in snapshot.items.where((e) => e.startsWith('http')).take(
                    ReadBudgetRegistry.startupSliderWarmRemoteLimit(
                      onWiFi: onWiFi,
                    ),
                  )) {
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
          warmRemoteLimit:
              ReadBudgetRegistry.startupSliderWarmRemoteLimit(onWiFi: onWiFi),
        );
        if (resolved.isEmpty) continue;
      }
    } catch (_) {}
  }

  Future<void> _forceLoadStoriesSync(
    StoryRowController storyController, {
    int limit = ReadBudgetRegistry.storyInitialLimit,
  }) async {
    try {
      if (storyController.users.length >= limit ||
          storyController.isLoadingAny) {
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
