part of 'agenda_controller.dart';

extension AgendaControllerSupportPart on AgendaController {
  UserProfileCacheService get _profileCache => ensureUserProfileCacheService();

  UserSummaryResolver get _userSummaryResolver => UserSummaryResolver.ensure();

  VisibilityPolicyService get _visibilityPolicy =>
      VisibilityPolicyService.ensure();

  PostRepository get _postRepository => PostRepository.ensure();

  FeedSnapshotRepository get _feedSnapshotRepository =>
      ensureFeedSnapshotRepository();

  FeedRenderCoordinator get _feedRenderCoordinator =>
      FeedRenderCoordinator.ensure();

  RuntimeInvariantGuard get _invariantGuard => ensureRuntimeInvariantGuard();

  bool _isRenderablePost(PostsModel post) {
    if (!post.hasVideoSignal) return true;
    return post.hasPlayableVideo;
  }

  String _feedDebugKindForPost(PostsModel post) {
    if (post.isFloodSeriesContent) return 'flood';
    final hasText = post.metin.trim().isNotEmpty;
    final hasImage = post.img.any((entry) => entry.trim().isNotEmpty) ||
        post.thumbnail.trim().isNotEmpty;
    if (post.hasPlayableVideo) return 'video';
    if (hasText && !hasImage) return 'text';
    return 'image';
  }

  void _debugAgendaKinds(
    String label,
    Iterable<PostsModel> posts,
  ) {
    assert(() {
      final list = posts.toList(growable: false);
      const chunkSize = 10;
      for (var start = 0; start < list.length; start += chunkSize) {
        final end =
            (start + chunkSize < list.length) ? start + chunkSize : list.length;
        final slots = list.sublist(start, end).asMap().entries.map((entry) {
          final absoluteIndex = start + entry.key + 1;
          final post = entry.value;
          return '$absoluteIndex:${_feedDebugKindForPost(post)}:${post.docID}';
        }).join(' | ');
        debugPrint(
          '[FeedAgendaKinds] label=$label count=${list.length} range=${start + 1}-$end slots=$slots',
        );
      }
      return true;
    }());
  }

  void _clearAgendaState({
    required String reason,
  }) {
    if (agendaList.isEmpty) return;
    debugPrint(
      '[FeedApply] action=clear reason=$reason currentCount=${agendaList.length}',
    );
    agendaList.clear();
  }

  void _replaceAgendaState(
    List<PostsModel> items, {
    required String reason,
    bool schedulePrefetch = false,
  }) {
    debugPrint(
      '[FeedApply] action=replace reason=$reason currentCount=${agendaList.length} '
      'nextCount=${items.length}',
    );
    agendaList.assignAll(items);
    _debugAgendaKinds(reason, agendaList);
    if (schedulePrefetch) {
      _scheduleFeedPrefetch();
    }
  }

  void _appendUniqueAgendaState(
    List<PostsModel> items, {
    required String reason,
    bool schedulePrefetch = true,
  }) {
    if (items.isEmpty) return;
    final existing = agendaList.map((post) => post.docID).toSet();
    final unique = <PostsModel>[];
    for (final post in items) {
      if (existing.add(post.docID)) {
        unique.add(post);
      }
    }
    if (unique.isEmpty) return;
    debugPrint(
      '[FeedApply] action=append_unique reason=$reason currentCount=${agendaList.length} '
      'addCount=${unique.length} nextCount=${agendaList.length + unique.length}',
    );
    agendaList.addAll(unique);
    _debugAgendaKinds(reason, agendaList);
    if (schedulePrefetch) {
      _scheduleFeedPrefetch();
    }
  }

  void _removeAgendaDocIds(
    Set<String> docIds, {
    required String reason,
  }) {
    if (docIds.isEmpty || agendaList.isEmpty) return;
    final beforeCount = agendaList.length;
    agendaList.removeWhere((post) => docIds.contains(post.docID));
    if (beforeCount == agendaList.length) return;
    debugPrint(
      '[FeedApply] action=remove reason=$reason removedCount=${beforeCount - agendaList.length} '
      'nextCount=${agendaList.length}',
    );
    _debugAgendaKinds(reason, agendaList);
  }

  bool canAutoplayInTests(PostsModel post) => _canAutoplayVideoPost(post);

  bool _isBlurredIzBirakVideo(PostsModel post, [int? nowMs]) {
    final scheduled = post.scheduledAt.toInt();
    if (scheduled <= 0 || post.video.trim().isEmpty) return false;
    final publishAt =
        scheduled > 0 ? scheduled : post.izBirakYayinTarihi.toInt();
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return publishAt > now;
  }

  bool _canAutoplayVideoPost(PostsModel post, [int? nowMs]) {
    return post.hasPlayableVideo && !_isBlurredIzBirakVideo(post, nowMs);
  }

  bool get isPrimaryFeedRouteVisible {
    final route = Get.currentRoute.trim();
    if (route.isEmpty) return true;
    return route == '/NavBarView' || route == 'NavBarView';
  }

  bool get canClaimPlaybackNow {
    final nav = maybeFindNavBarController();
    if (nav != null && nav.selectedIndex.value != 0) return false;
    if (nav?.mediaOverlayActive ?? false) return false;
    if (_feedRefreshInFlight) return false;
    if (pauseAll.value) return false;
    if (playbackSuspended.value) return false;
    if (!isPrimaryFeedRouteVisible) return false;
    return true;
  }

  Future<bool> _canViewerSeePost(PostsModel post) async {
    if (hiddenPosts.contains(post.docID)) return false;
    if (post.deletedPost == true) return false;
    if (!_isRenderablePost(post)) return false;
    if (await _isUserDeactivated(post.userID)) return false;

    final summary = await _userSummaryResolver.resolve(
      post.userID,
      preferCache: true,
    );
    if (summary == null) return false;
    return _visibilityPolicy.canViewerSeeDiscoveryAuthorFromSummary(
      authorUserId: post.userID,
      followingIds: followingIDs,
      rozet: summary.rozet,
      isApproved: summary.isApproved,
      isDeleted: summary.isDeleted,
    );
  }

  String get latestQAScrollToken => _qaLatestScrollToken;

  bool get isFollowingMode => feedViewMode.value == FeedViewMode.following;
  bool get isCityMode => feedViewMode.value == FeedViewMode.city;

  String get feedTitle {
    if (isFollowingMode) return 'agenda.following'.tr;
    if (isCityMode) return 'agenda.city'.tr;
    return 'app.name'.tr;
  }

  String get currentUserLocationCity {
    return CurrentUserService.instance.preferredLocationCity;
  }

  void setFeedViewMode(FeedViewMode mode) {
    if (feedViewMode.value == mode) return;
    final previousMode = feedViewMode.value;
    if (mode == FeedViewMode.city && currentUserLocationCity.trim().isEmpty) {
      return;
    }
    feedViewMode.value = mode;
    if (previousMode == FeedViewMode.city || mode == FeedViewMode.city) {
      unawaited(refreshAgenda(forceNewLaunchSession: true));
    }
  }

  int _agendaCutoffMs(int nowMs) {
    return nowMs - _agendaWindow.inMilliseconds;
  }

  bool _isInAgendaWindow(num ts, int nowMs) {
    final v = ts.toInt();
    return v >= _agendaCutoffMs(nowMs) && v <= nowMs;
  }

  bool _isEligibleAgendaPost(PostsModel post, int nowMs) {
    if (post.isFloodMember) {
      return false;
    }
    final ts = post.timeStamp.toInt();
    if (ts < _agendaCutoffMs(nowMs)) {
      return false;
    }
    if (ts <= nowMs) {
      return true;
    }
    return post.scheduledAt.toInt() > 0;
  }
}

extension AgendaControllerPublicApiPart on AgendaController {
  void _scheduleFeedManifestWindowSync({
    required String reason,
  }) {
    _manifestWindowSyncTimer?.cancel();
    if (isClosed) return;
    final nextRefreshAt =
        _feedSnapshotRepository.nextExpectedFeedManifestRefreshAt;
    var delay = const Duration(minutes: 12);
    if (nextRefreshAt != null) {
      final candidate = nextRefreshAt
          .add(const Duration(seconds: 15))
          .difference(DateTime.now());
      if (candidate > Duration.zero) {
        delay = candidate;
      } else {
        delay = const Duration(minutes: 1);
      }
    }
    if (delay > FeedManifestRepository.manifestWindowCadence) {
      delay = FeedManifestRepository.manifestWindowCadence;
    }
    debugPrint(
      '[FeedManifestWindowSync] status=scheduled reason=$reason '
      'delayMs=${delay.inMilliseconds} '
      'manifest=${_feedSnapshotRepository.activeFeedManifestId} '
      'generatedAt=${_feedSnapshotRepository.activeFeedManifestGeneratedAt}',
    );
    _manifestWindowSyncTimer = Timer(delay, () {
      unawaited(
        _syncFeedManifestWindowIfNeeded(
          trigger: 'timer:$reason',
        ),
      );
    });
  }

  Future<void> _syncFeedManifestWindowIfNeeded({
    required String trigger,
  }) async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    try {
      final changed =
          await _feedSnapshotRepository.syncActiveFeedManifestWindow(
        userId: userId,
      );
      debugPrint(
        '[FeedManifestWindowSync] status=${changed ? 'changed' : 'stable'} '
        'trigger=$trigger '
        'manifest=${_feedSnapshotRepository.activeFeedManifestId} '
        'generatedAt=${_feedSnapshotRepository.activeFeedManifestGeneratedAt} '
        'nextAt=${_feedSnapshotRepository.nextExpectedFeedManifestRefreshAt?.millisecondsSinceEpoch ?? 0}',
      );
      if (changed) {
        _lastPrimarySurfaceVisibleMutationEpoch = -1;
      }
    } catch (error) {
      debugPrint(
        '[FeedManifestWindowSync] status=fail trigger=$trigger error=$error',
      );
    } finally {
      if (!isClosed) {
        _scheduleFeedManifestWindowSync(reason: 'post_$trigger');
      }
    }
  }

  void handleNetworkPolicyTransition(NetworkType networkType) {
    ensureFeedSnapshotRepository().debugPrintLastGapSummary();
    debugPrint(
      '[FeedNetworkPolicy] status=dispatch network=${networkType.name} '
      'frozen=$_renderWindowFrozenOnCellular agendaCount=${agendaList.length}',
    );
    _renderWindowFrozenOnCellular = false;
    debugPrint(
      '[FeedNetworkPolicy] status=live_network network=${networkType.name} '
      'agendaCount=${agendaList.length} mutationEpoch=$_feedMutationEpoch',
    );
    final shouldRefreshStartupSurface = networkType == NetworkType.wifi &&
        (_lastStartupSurfacePreparedNetwork != networkType ||
            _lastStartupSurfacePreparedMutationEpoch != _feedMutationEpoch ||
            agendaList.isEmpty ||
            !_startupHeadFinalized);
    _lastStartupSurfacePreparedNetwork = networkType;
    if (shouldRefreshStartupSurface) {
      _lastStartupSurfacePreparedMutationEpoch = _feedMutationEpoch;
      unawaited(
        prepareStartupSurface(
          allowBackgroundRefresh: true,
          source: 'network_transition',
        ),
      );
    } else if (networkType == NetworkType.wifi) {
      ensureFeedSnapshotRepository().debugPrintLastGapSummary();
      debugPrint(
        '[FeedStartupSurface] status=skip_network_repeat '
        'network=${networkType.name} agendaCount=${agendaList.length} '
        'mutationEpoch=$_feedMutationEpoch finalized=$_startupHeadFinalized',
      );
    }
  }

  Future<void> onPrimarySurfaceVisible() {
    unawaited(
      _syncFeedManifestWindowIfNeeded(
        trigger: 'primary_surface_visible',
      ),
    );
    if (_lastPrimarySurfaceVisibleMutationEpoch == _feedMutationEpoch) {
      debugPrint(
        '[FeedStartupSurface] status=skip_primary_surface_repeat '
        'agendaCount=${agendaList.length} mutationEpoch=$_feedMutationEpoch '
        'finalized=$_startupHeadFinalized',
      );
      return Future<void>.value();
    }
    _lastPrimarySurfaceVisibleMutationEpoch = _feedMutationEpoch;
    return prepareStartupSurface(
      allowBackgroundRefresh:
          ContentPolicy.allowBackgroundRefresh(ContentScreenKind.feed),
      source: 'primary_surface_visible',
    );
  }

  Future<void> prepareStartupSurface({
    bool? allowBackgroundRefresh,
    String source = 'unspecified',
  }) {
    final active = _startupPrepareFuture;
    debugPrint(
      '[FeedStartupSurface] status=request source=$source '
      'agendaCount=${agendaList.length} mutationEpoch=$_feedMutationEpoch '
      'inFlight=${active != null} finalized=$_startupHeadFinalized',
    );
    if (active != null) {
      return active;
    }
    final future = _performPrepareStartupSurface(
      allowBackgroundRefresh: allowBackgroundRefresh,
      source: source,
    );
    _startupPrepareFuture = future;
    return future.whenComplete(() {
      if (identical(_startupPrepareFuture, future)) {
        _startupPrepareFuture = null;
      }
    });
  }

  Future<void> _performPrepareStartupSurface({
    bool? allowBackgroundRefresh,
    required String source,
  }) async {
    debugPrint(
      '[FeedStartupSurface] status=begin source=$source '
      'agendaCount=${agendaList.length} mutationEpoch=$_feedMutationEpoch '
      'finalized=$_startupHeadFinalized plannerApplied=$_startupPlannerHeadApplied',
    );
    if (agendaList.isEmpty && !_startupPlannerHeadApplied) {
      final deviceSession = DeviceSessionService.instance;
      final deviceSalt = deviceSession.cachedDeviceKey;
      beginStartupSurfaceSession(
        sessionNamespace: 'feed',
        deviceSalt: deviceSalt,
        forceNew: true,
      );
      if (deviceSalt.isEmpty) {
        unawaited(
          deviceSession.warmDeviceKey().then((_) {
            final warmedSalt = deviceSession.cachedDeviceKey;
            if (warmedSalt.isEmpty) return;
            beginStartupSurfaceSession(
              sessionNamespace: 'feed',
              deviceSalt: warmedSalt,
            );
          }),
        );
      }
    }
    final allowRefresh = allowBackgroundRefresh ??
        ContentPolicy.allowBackgroundRefresh(ContentScreenKind.feed);
    await ensureFeedSurfaceReady(
      preferSynchronousConnectedLoad: !allowRefresh,
    );
    _primeStartupPlaybackWindow();
    await _recordFeedStartupSurface(
      source: 'feed_surface_ready:$source',
    );
    debugPrint(
      '[FeedStartupSurface] status=end source=$source '
      'agendaCount=${agendaList.length} mutationEpoch=$_feedMutationEpoch '
      'finalized=$_startupHeadFinalized',
    );
    if (!allowRefresh || agendaList.isEmpty || _startupHeadFinalized) return;
  }

  void _primeStartupPlaybackWindow() {
    if (agendaList.isEmpty) return;
    if (_shouldDelayStartupPlaybackWork && !GetPlatform.isAndroid) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (isClosed || agendaList.isEmpty) return;
        _primeStartupPlaybackWindowNow();
      });
      return;
    }
    _primeStartupPlaybackWindowNow();
  }

  void _primeStartupPlaybackWindowNow() {
    if (agendaList.isEmpty) return;
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;
    final startupWindow = _resolveFeedStartupWarmPosts()
        .where((post) => _canAutoplayVideoPost(post))
        .take(AgendaControllerFeedPart._feedSplashWarmPlayableCount)
        .toList(growable: false);
    if (startupWindow.isEmpty) return;
    final cacheManager = maybeFindSegmentCacheManager();
    for (final post in startupWindow) {
      final docId = post.docID.trim();
      final playbackUrl = post.playbackUrl.trim();
      if (cacheManager != null &&
          cacheManager.isReady &&
          docId.isNotEmpty &&
          playbackUrl.isNotEmpty) {
        cacheManager.cachePostCards(<PostsModel>[post]);
        cacheManager.cacheHlsEntry(docId, playbackUrl);
      }
    }
    unawaited(
      prefetch.updateFeedQueueForPosts(
        startupWindow,
        0,
        maxDocs: startupWindow.length,
      ),
    );
    final startupWarmLogs = <String>[];
    for (var i = 0; i < startupWindow.length; i++) {
      final readySegments = _feedStartupReadySegmentsForPlayableRank(i);
      if (readySegments <= 0) continue;
      prefetch.boostDoc(
        startupWindow[i].docID,
        readySegments: readySegments,
      );
      startupWarmLogs.add(
        '${i + 1}:${startupWindow[i].docID}:segments=$readySegments',
      );
    }
    if (startupWarmLogs.isNotEmpty) {
      debugPrint(
        '[FeedOnYukleme] phase=splash_startup count=${startupWarmLogs.length} '
        'entries=${startupWarmLogs.join(' | ')}',
      );
    }
  }

  Future<void> persistStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final startupCandidates = _buildOrderedAgendaSnapshot(
      limit: _startupShardCandidateLimit(
        FeedSnapshotRepository.startupHomeLimitValue,
      ),
    );
    if (startupCandidates.isEmpty && ContentPolicy.isConnected) {
      debugPrint(
        '[FeedStartupPersist] status=preserve_previous reason=empty_connected_agenda '
        'target=shard',
      );
      return;
    }
    await _persistFeedStartupShardOnly(
      userId: userId,
      ordered: startupCandidates,
      snapshotAt: DateTime.now(),
      source: 'feed_runtime',
    );
  }

  Future<void> persistStartupArtifacts() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final snapshotAt = DateTime.now();
    final ordered = _buildOrderedAgendaSnapshot(
      limit: ReadBudgetRegistry.feedPersistSnapshotLimit,
    );
    final startupCandidates = _buildOrderedAgendaSnapshot(
      limit: _startupShardCandidateLimit(
        FeedSnapshotRepository.startupHomeLimitValue,
      ),
    );
    if (ordered.isEmpty) {
      if (ContentPolicy.isConnected) {
        debugPrint(
          '[FeedStartupPersist] status=preserve_previous reason=empty_connected_agenda '
          'target=artifacts',
        );
        return;
      }
      await _persistFeedStartupShardOnly(
        userId: userId,
        ordered: startupCandidates,
        snapshotAt: snapshotAt,
        source: 'none',
      );
      return;
    }
    await _feedSnapshotRepository.persistHomeSnapshot(
      userId: userId,
      posts: ordered,
      limit: ReadBudgetRegistry.feedPersistSnapshotLimit,
      source: CachedResourceSource.memory,
      snapshotAt: snapshotAt,
    );
    await _persistFeedStartupShardOnly(
      userId: userId,
      ordered: startupCandidates,
      snapshotAt: snapshotAt,
      source: 'feed_runtime',
    );
  }

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) =>
      _performOnPostVisibilityChanged(modelIndex, visibleFraction);

  void suspendPlaybackForOverlay() => _performSuspendPlaybackForOverlay();

  void resumePlaybackAfterOverlay() {
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.idle ||
        binding.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      _performResumePlaybackAfterOverlay();
      return;
    }
    binding.addPostFrameCallback((_) {
      if (isClosed) return;
      _performResumePlaybackAfterOverlay();
    });
  }

  void resetVisibleFeedSurfaceAfterShortReturn() =>
      _performResetVisibleFeedSurfaceAfterShortReturn();

  void resetSurfaceForTabTransition() => _performResetSurfaceForTabTransition();

  void _scheduleVisibilityEvaluation({
    required double playThreshold,
    required double stopThreshold,
  }) =>
      _performScheduleVisibilityEvaluation(
        playThreshold: playThreshold,
        stopThreshold: stopThreshold,
      );

  void _evaluateCenteredPlayback({
    required double playThreshold,
    required double stopThreshold,
  }) =>
      _performEvaluateCenteredPlayback(
        playThreshold: playThreshold,
        stopThreshold: stopThreshold,
      );

  void _trackPlaybackWindow() => _performTrackPlaybackWindow();

  void _bindFollowingListener() => _performBindFollowingListener();

  void _bindMergedFeedEntries() => _performBindMergedFeedEntries();

  void _bindFilteredFeedEntries() => _performBindFilteredFeedEntries();

  void _bindRenderFeedEntries() => _performBindRenderFeedEntries();

  void _rebuildMergedFeedEntries() => _performRebuildMergedFeedEntries();

  void _rebuildFilteredFeedEntries() => _performRebuildFilteredFeedEntries();

  void _rebuildRenderFeedEntries({
    bool ignoreStartupBootstrapHold = false,
    bool ignoreGrowthAppendHold = false,
  }) =>
      _performRebuildRenderFeedEntries(
        ignoreStartupBootstrapHold: ignoreStartupBootstrapHold,
        ignoreGrowthAppendHold: ignoreGrowthAppendHold,
      );

  Future<void> _recordFeedStartupSurface({
    required String source,
    int? itemCount,
  }) async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final count = itemCount ?? agendaList.length;
    bool startupShardHydrated = false;
    int? startupShardAgeMs;
    if (count > 0 && !ContentPolicy.isConnected) {
      try {
        final existingManifest =
            await ensureStartupSnapshotManifestStore().load(userId: userId);
        final existingRecord = existingManifest?.surfaces['feed'];
        startupShardHydrated = existingRecord?.startupShardHydrated == true;
        startupShardAgeMs = existingRecord?.startupShardAgeMs;
      } catch (_) {}
    }
    final hasLocalSnapshot = !ContentPolicy.isConnected && count > 0;
    await ensureStartupSnapshotManifestStore().recordSurfaceState(
      surface: 'feed',
      userId: userId,
      itemCount: count,
      hasLocalSnapshot: hasLocalSnapshot,
      source: count > 0 ? source : 'none',
      startupShardHydrated: startupShardHydrated,
      startupShardAgeMs: startupShardAgeMs,
    );
  }

  Future<void> _persistFeedStartupShardOnly({
    required String userId,
    required List<PostsModel> ordered,
    required DateTime snapshotAt,
    required String source,
  }) async {
    final limit = _startupShardCandidateLimit(
      FeedSnapshotRepository.startupHomeLimitValue,
    );
    if (ordered.isEmpty) {
      await ensureStartupSnapshotShardStore().clear(
        surface: 'feed',
        userId: userId,
      );
      await _recordFeedStartupSurface(
        source: 'none',
        itemCount: 0,
      );
      return;
    }
    await ensureStartupSnapshotShardStore().save(
      surface: 'feed',
      userId: userId,
      itemCount: ordered.length,
      limit: limit,
      source: source,
      snapshotAt: snapshotAt,
      payload: _feedSnapshotRepository.encodeHomeStartupPayload(
        ordered,
        limit: limit,
      ),
    );
    await _recordFeedStartupSurface(
      source: source,
      itemCount: ordered.length,
    );
  }
}

extension AgendaControllerOverlayReturnPart on AgendaController {
  void _performResetVisibleFeedSurfaceAfterShortReturn() {
    _performResetSurfaceForTabTransition();
  }
}
