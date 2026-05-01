part of 'agenda_controller.dart';

extension AgendaControllerLoadingPart on AgendaController {
  static const bool _feedSeededStartupHeadEnabled = false;
  static const bool _feedStartupSupportFallbackEnabled = false;
  static const bool _feedLaunchFallbackCandidatesEnabled = false;
  static const int _connectedColdFeedStageOneLimit = 60;
  static const int _connectedColdFeedStageTwoLimit = 120;
  static const int _connectedColdFeedStageThreeLimit = 180;
  static const int _connectedColdFeedStageFourLimit = 240;
  static const int _connectedColdFeedStageThreeViewedTrigger = 50;
  static const int _connectedColdFeedStageFourViewedTrigger = 110;
  static const int _connectedColdFeedStageFourReadyViewedCheckpoint = 170;
  static const int _connectedColdFeedPrimeBatchFloor = 60;
  static const int _connectedInitialCandidateFetchFloor = 45;
  static const int _feedIdentityWarmPriorityCount = 5;
  static const int _startupWarmPreloadVideoCount = 1;
  static const Duration _deferredInitialNetworkBootstrapDelay =
      Duration(milliseconds: 520);
  static const Duration _startupWarmPreloadFallbackDelay =
      Duration(milliseconds: 900);
  static const Duration _startupWarmPreloadReleaseDelay =
      Duration(milliseconds: 16);
  static const Duration _startupWarmPreloadRenderReleaseDelay =
      Duration(milliseconds: 32);

  int _connectedColdFeedCandidateFetchLimitForTarget(int targetLimit) =>
      targetLimit + _connectedColdFeedPrimeBatchFloor;

  int _connectedColdFeedPrimeBatchLimitForTarget(int targetLimit) => min(
        _connectedColdFeedCandidateFetchLimitForTarget(targetLimit),
        max(
          _connectedColdFeedPrimeBatchFloor,
          ReadBudgetRegistry.feedLivePageLimit,
        ),
      );

  int get _connectedInitialCandidateFetchLimit => min(
        _connectedColdFeedPrimeBatchLimitForTarget(
          _connectedColdFeedStageOneLimit,
        ),
        max(
          _connectedInitialCandidateFetchFloor,
          ReadBudgetRegistry.feedLivePageLimit,
        ),
      );

  int get _connectedReservoirWarmVisibleBatchLimit => min(
        _connectedColdFeedPrimeBatchFloor,
        FeedSnapshotRepository.startupHomeLimitValue +
            _feedIdentityWarmPriorityCount +
            4,
      );

  Future<T> _profileFeedStartupSurfaceStep<T>(
    String label,
    Future<T> Function() action,
  ) async {
    final startedAt = DateTime.now();
    debugPrint('[FeedStartupSurface] start:$label');
    try {
      final result = await action();
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint('[FeedStartupSurface] end:$label elapsedMs=$elapsedMs');
      return result;
    } catch (error) {
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint(
        '[FeedStartupSurface] fail:$label elapsedMs=$elapsedMs error=$error',
      );
      rethrow;
    }
  }

  void _recordFeedMotorSignal({
    required String name,
    required String status,
    String reason = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final normalizedReason = reason.trim();
    debugPrint(
      '[FeedMotorSignal] name=$name status=$status '
      'reason=${normalizedReason.isEmpty ? "none" : normalizedReason} '
      'metadata=$metadata',
    );
    recordQALabFeedFetchEvent(
      stage: 'motor_signal_$name',
      trigger: normalizedReason.isEmpty ? name : normalizedReason,
      metadata: <String, dynamic>{
        'status': status,
        ...metadata,
      },
    );
    if (status == 'ok') return;
    _invariantGuard.record(
      surface: 'feed',
      invariantKey: 'feed_motor_$name',
      message: 'Feed motor signal reported $status',
      payload: <String, dynamic>{
        'reason': normalizedReason,
        'status': status,
        ...metadata,
      },
    );
  }

  void _recordFeedMotorContractSnapshot({required String reason}) {
    const expectedStageOne = 60;
    const expectedStageTwo = 120;
    const expectedStageThree = 180;
    const expectedStageFour = 240;
    const expectedTriggerThree = 50;
    const expectedTriggerFour = 110;
    const expectedStageFourReadyCheckpoint = 170;
    const expectedPostsPerBlock = 15;
    const expectedVisualPriority = 5;
    final contract = <String, dynamic>{
      'typesensePrimaryEnabled': FeedSnapshotRepository.typesensePrimaryEnabled,
      'typesenseFirestoreFallbackEnabled':
          FeedSnapshotRepository.typesenseFirestoreFallbackEnabled,
      'connectedSeedEnabled': _feedSeededStartupHeadEnabled,
      'startupSupportFallbackEnabled': _feedStartupSupportFallbackEnabled,
      'launchFallbackCandidatesEnabled': _feedLaunchFallbackCandidatesEnabled,
      'stageOneLimit': _connectedColdFeedStageOneLimit,
      'stageTwoLimit': _connectedColdFeedStageTwoLimit,
      'stageThreeLimit': _connectedColdFeedStageThreeLimit,
      'stageFourLimit': _connectedColdFeedStageFourLimit,
      'stageThreeViewedTrigger': _connectedColdFeedStageThreeViewedTrigger,
      'stageFourViewedTrigger': _connectedColdFeedStageFourViewedTrigger,
      'stageFourReadyViewedCheckpoint':
          _connectedColdFeedStageFourReadyViewedCheckpoint,
      'stageBatchFloor': _connectedColdFeedPrimeBatchFloor,
      'postsPerBlock': FeedRenderBlockPlan.postSlotsPerBlock,
      'visualPriorityCount': _feedIdentityWarmPriorityCount,
    };
    _recordFeedMotorSignal(
      name: 'contract_snapshot',
      status: 'ok',
      reason: reason,
      metadata: contract,
    );

    void assertRule(bool condition, String key, String message) {
      if (condition) return;
      _invariantGuard.record(
        surface: 'feed',
        invariantKey: key,
        message: message,
        payload: contract,
      );
    }

    assertRule(
      !_feedSeededStartupHeadEnabled,
      'feed_motor_seeded_startup_head_enabled',
      'Feed seeded startup head must stay disabled',
    );
    assertRule(
      !_feedStartupSupportFallbackEnabled,
      'feed_motor_startup_support_fallback_enabled',
      'Feed startup support fallback must stay disabled',
    );
    assertRule(
      !_feedLaunchFallbackCandidatesEnabled,
      'feed_motor_launch_fallback_candidates_enabled',
      'Feed launch fallback candidates must stay disabled',
    );
    assertRule(
      FeedSnapshotRepository.typesensePrimaryEnabled,
      'feed_motor_typesense_primary_disabled',
      'Feed motor Typesense primary source is disabled',
    );
    assertRule(
      !FeedSnapshotRepository.typesenseFirestoreFallbackEnabled,
      'feed_motor_firestore_fallback_enabled',
      'Feed motor Firestore fallback is enabled',
    );
    assertRule(
      _connectedColdFeedStageOneLimit == expectedStageOne &&
          _connectedColdFeedStageTwoLimit == expectedStageTwo &&
          _connectedColdFeedStageThreeLimit == expectedStageThree &&
          _connectedColdFeedStageFourLimit == expectedStageFour,
      'feed_motor_stage_limits_changed',
      'Feed motor staged reservoir limits changed',
    );
    assertRule(
      _connectedColdFeedStageThreeViewedTrigger == expectedTriggerThree &&
          _connectedColdFeedStageFourViewedTrigger == expectedTriggerFour &&
          _connectedColdFeedStageFourReadyViewedCheckpoint ==
              expectedStageFourReadyCheckpoint,
      'feed_motor_stage_triggers_changed',
      'Feed motor staged reservoir triggers changed',
    );
    assertRule(
      FeedRenderBlockPlan.postSlotsPerBlock == expectedPostsPerBlock,
      'feed_motor_render_block_changed',
      'Feed render block size changed',
    );
    assertRule(
      _feedIdentityWarmPriorityCount == expectedVisualPriority,
      'feed_motor_visual_priority_changed',
      'Feed visual warm priority count changed',
    );
  }

  int get _refreshPlannerMergeLimit =>
      min(8, ReadBudgetRegistry.feedLivePageLimit);

  List<PostsModel> _initialVisibleVideoWarmupWindow(
    List<PostsModel> posts, {
    int limit = 5,
  }) {
    if (posts.isEmpty || limit <= 0) return const <PostsModel>[];
    return posts
        .where((post) => post.hasRenderableVideoCard)
        .take(limit)
        .toList(growable: false);
  }

  List<PostsModel> _startupWarmPlayerPreloadWindow(
    List<PostsModel> posts, {
    int limit = _startupWarmPreloadVideoCount,
  }) {
    if (!GetPlatform.isAndroid || posts.isEmpty || limit <= 0) {
      return const <PostsModel>[];
    }
    return posts
        .where(_canAutoplayVideoPost)
        .take(limit)
        .toList(growable: false);
  }

  Future<void> _warmInitialFeedVisuals(List<PostsModel> posts) async {
    final windowPosts = posts
        .take(FeedRenderBlockPlan.postSlotsPerBlock)
        .toList(growable: false);
    if (windowPosts.isEmpty) return;

    final priorityPosts = windowPosts
        .take(_feedIdentityWarmPriorityCount)
        .toList(growable: false);
    final deferredPosts = windowPosts.skip(priorityPosts.length).toList(
          growable: false,
        );

    final priorityStats = await _warmFeedVisualBatch(
      priorityPosts,
      parallel: true,
    );
    debugPrint(
      '[FeedVisualWarm15x5] status=priority_ready '
      'priority=${priorityPosts.length} total=${windowPosts.length} '
      'avatarBytes=${priorityStats.avatarBytes} '
      'thumbnailBytes=${priorityStats.thumbnailBytes}',
    );
    _recordFeedMotorSignal(
      name: 'visual_priority_ready',
      status: 'ok',
      metadata: <String, dynamic>{
        'priority': priorityPosts.length,
        'total': windowPosts.length,
        'avatarBytes': priorityStats.avatarBytes,
        'thumbnailBytes': priorityStats.thumbnailBytes,
      },
    );

    if (deferredPosts.isEmpty) return;
    unawaited(
      _warmFeedVisualBatch(deferredPosts).then((deferredStats) {
        debugPrint(
          '[FeedVisualWarm15x5] status=deferred_ready '
          'deferred=${deferredPosts.length} total=${windowPosts.length} '
          'avatarBytes=${deferredStats.avatarBytes} '
          'thumbnailBytes=${deferredStats.thumbnailBytes}',
        );
        _recordFeedMotorSignal(
          name: 'visual_deferred_ready',
          status: 'ok',
          metadata: <String, dynamic>{
            'deferred': deferredPosts.length,
            'total': windowPosts.length,
            'avatarBytes': deferredStats.avatarBytes,
            'thumbnailBytes': deferredStats.thumbnailBytes,
          },
        );
      }),
    );
  }

  Future<({int avatarBytes, int thumbnailBytes})> _warmFeedVisualBatch(
    List<PostsModel> posts, {
    bool parallel = false,
  }) async {
    if (parallel) {
      final stats = await Future.wait(
        posts.map(_warmFeedVisualsForPost),
        eagerError: false,
      );
      return (
        avatarBytes: stats.fold<int>(
          0,
          (total, stat) => total + stat.avatarBytes,
        ),
        thumbnailBytes: stats.fold<int>(
          0,
          (total, stat) => total + stat.thumbnailBytes,
        ),
      );
    }

    var avatarBytes = 0;
    var thumbnailBytes = 0;
    for (final post in posts) {
      final stats = await _warmFeedVisualsForPost(post);
      avatarBytes += stats.avatarBytes;
      thumbnailBytes += stats.thumbnailBytes;
    }
    return (
      avatarBytes: avatarBytes,
      thumbnailBytes: thumbnailBytes,
    );
  }

  Future<({int avatarBytes, int thumbnailBytes})> _warmFeedVisualsForPost(
    PostsModel post,
  ) async {
    final results = await Future.wait<int>(
      [
        _warmFeedAvatarForPost(post),
        _warmFeedPosterForPost(post),
      ],
      eagerError: false,
    );
    return (
      avatarBytes: results[0],
      thumbnailBytes: results[1],
    );
  }

  List<String> _preferredFeedThumbnailUrlsForPost(PostsModel post) {
    final urls = <String>[];
    for (final url in post.preferredVideoPosterUrls) {
      final normalized = url.trim();
      if (normalized.isNotEmpty && !urls.contains(normalized)) {
        urls.add(normalized);
      }
    }
    return urls;
  }

  Future<int> _warmFeedPosterForPost(PostsModel post) async {
    for (final url in _preferredFeedThumbnailUrlsForPost(post)) {
      if (url.trim().isEmpty) continue;
      try {
        final file = await TurqImageCacheManager.warmUrl(url)
            .timeout(const Duration(seconds: 2));
        try {
          return await file.length();
        } catch (_) {
          return 0;
        }
      } catch (_) {}
    }
    return 0;
  }

  Future<int> _warmFeedAvatarForPost(PostsModel post) async {
    final url = post.authorAvatarUrl.trim();
    if (url.isEmpty) return 0;
    try {
      final file = await TurqImageCacheManager.warmUrl(url)
          .timeout(const Duration(seconds: 2));
      try {
        return await file.length();
      } catch (_) {
        return 0;
      }
    } catch (_) {
      return 0;
    }
  }

  Future<void> _primeInitialVisibleCardImageHints(
    List<PostsModel> posts,
  ) async {
    final visiblePosts = posts.take(3).toList(growable: false);
    if (visiblePosts.isEmpty) return;

    final avatarUrls = visiblePosts
        .map((post) => post.authorAvatarUrl.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final posterUrls = visiblePosts
        .where((post) => post.hasRenderableVideoCard)
        .expand(
            (post) => post.preferredVideoPosterUrls.map((url) => url.trim()))
        .where((url) => url.isNotEmpty)
        .take(3)
        .toList(growable: false);

    await Future.wait(
      <Future<void>>[
        ...avatarUrls.map(_primeCachedImageHint),
        ...posterUrls.map(_primeCachedImageHint),
      ],
      eagerError: false,
    );
  }

  Future<void> _primeCachedImageHint(String url) async {
    final normalized = url.trim();
    if (normalized.isEmpty) return;
    try {
      final cached = await TurqImageCacheManager.instance
          .getFileFromCache(normalized)
          .timeout(const Duration(milliseconds: 120));
      final file = cached?.file;
      if (file != null && file.existsSync()) {
        TurqImageCacheManager.rememberResolvedFile(normalized, file.path);
      }
    } catch (_) {}
  }

  void _scheduleInitialFeedVideoPosterWarmup(List<PostsModel> posts) {
    if (posts.isEmpty) return;
    unawaited(_warmInitialFeedVisuals(posts));
  }

  void _cancelStartupWarmPlayerPreload() {
    _startupWarmPreloadFallbackTimer?.cancel();
    _startupWarmPreloadFallbackTimer = null;
    _startupWarmPreloadReleaseTimer?.cancel();
    _startupWarmPreloadReleaseTimer = null;
    _startupWarmPreloadPrimaryDocId = null;
    _startupWarmPreloadPreparedDocIds.clear();
    if (startupWarmPreloadDocIdsRx.isNotEmpty) {
      startupWarmPreloadDocIdsRx.clear();
    }
  }

  void _scheduleStartupWarmPlayerPreload(
    List<PostsModel> posts, {
    required String reason,
  }) {
    _cancelStartupWarmPlayerPreload();
    final preloadPosts = _startupWarmPlayerPreloadWindow(posts);
    final effectivePreloadPosts = GetPlatform.isAndroid
        ? preloadPosts.take(1).toList(growable: false)
        : preloadPosts;
    if (GetPlatform.isAndroid) {
      debugPrint(
        '[FeedStartupWarmPreload] status=android_singleton_hidden_layer '
        'reason=$reason requested=${preloadPosts.length} effective=${effectivePreloadPosts.length}',
      );
    }
    if (effectivePreloadPosts.isEmpty) {
      _applyStartupRenderStagesNow();
      return;
    }
    startupWarmPreloadDocIdsRx.assignAll(
      effectivePreloadPosts
          .map((post) => post.docID.trim())
          .where((docId) => docId.isNotEmpty),
    );
    if (startupWarmPreloadDocIdsRx.isEmpty) {
      _applyStartupRenderStagesNow();
      return;
    }
    _startupWarmPreloadPrimaryDocId = startupWarmPreloadDocIdsRx.first;
    _startupWarmPreloadFallbackTimer = Timer(
      _startupWarmPreloadFallbackDelay,
      _completeStartupWarmPlayerPreload,
    );
  }

  void _completeStartupWarmPlayerPreload() {
    _startupWarmPreloadFallbackTimer?.cancel();
    _startupWarmPreloadFallbackTimer = null;
    _startupWarmPreloadReleaseTimer?.cancel();
    _startupWarmPreloadReleaseTimer = null;
    _startupWarmPreloadPrimaryDocId = null;
    _startupWarmPreloadPreparedDocIds.clear();
    if (startupWarmPreloadDocIdsRx.isEmpty) {
      if (_startupRenderBootstrapHold) {
        Future<void>.delayed(
          _startupWarmPreloadRenderReleaseDelay,
          () {
            if (isClosed) return;
            _applyStartupRenderStagesNow();
          },
        );
      }
      return;
    }
    startupWarmPreloadDocIdsRx.clear();
    if (_startupRenderBootstrapHold) {
      Future<void>.delayed(
        _startupWarmPreloadRenderReleaseDelay,
        () {
          if (isClosed) return;
          _applyStartupRenderStagesNow();
        },
      );
    }
  }

  void markStartupWarmPlayerPrepared(String docId) {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) return;
    if (!startupWarmPreloadDocIdsRx.contains(normalizedDocId)) return;
    _startupWarmPreloadPreparedDocIds.add(normalizedDocId);
    final primaryDocId = _startupWarmPreloadPrimaryDocId?.trim() ?? '';
    if (primaryDocId.isEmpty || primaryDocId != normalizedDocId) return;
    final allPrepared = startupWarmPreloadDocIdsRx.every(
      _startupWarmPreloadPreparedDocIds.contains,
    );
    if (!allPrepared || _startupWarmPreloadReleaseTimer != null) return;
    _startupWarmPreloadReleaseTimer = Timer(
      _startupWarmPreloadReleaseDelay,
      _completeStartupWarmPlayerPreload,
    );
  }

  void markStartupWarmPlayerFirstFrame(String docId) {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) return;
    if (!startupWarmPreloadDocIdsRx.contains(normalizedDocId)) return;
    _startupWarmPreloadPreparedDocIds.add(normalizedDocId);
    final primaryDocId = _startupWarmPreloadPrimaryDocId?.trim() ?? '';
    if (primaryDocId.isEmpty || primaryDocId != normalizedDocId) return;
    _startupWarmPreloadReleaseTimer?.cancel();
    _startupWarmPreloadReleaseTimer = Timer(
      _startupWarmPreloadReleaseDelay,
      _completeStartupWarmPlayerPreload,
    );
  }

  void _resumeFeedPlaybackAfterRefresh({
    required int expectedEpoch,
  }) {
    if (agendaList.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed ||
          pauseAll.value ||
          agendaList.isEmpty ||
          _feedMutationEpoch != expectedEpoch) {
        return;
      }
      resumeFeedPlayback();
    });
  }

  void _prepareFeedSurfaceAfterDataReady({
    required String playbackBootstrapSource,
  }) {
    if (agendaList.isEmpty) return;

    _prefetchThumbnailBatches();
    _prefetchUpcomingImages();

    if (_needsInitialFeedPlaybackPrime) {
      primeInitialCenteredPost();
    } else if (centeredIndex.value == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (agendaList.isNotEmpty && centeredIndex.value == -1) {
          primeInitialCenteredPost();
        }
      });
    }

    if (IntegrationTestMode.skipBackgroundStartupWork) {
      return;
    }
  }

  void _scheduleDeferredInitialNetworkBootstrap({
    required String reason,
    bool allowEmptyAgenda = false,
  }) {
    final agendaReady = agendaList.isNotEmpty;
    if (!ContentPolicy.isConnected || (!allowEmptyAgenda && !agendaReady)) {
      return;
    }
    if (_startupHeadFinalized ||
        isLoading.value ||
        _ensureInitialLoadInFlight) {
      return;
    }

    final token = _deferredInitialNetworkBootstrapToken + 1;
    _deferredInitialNetworkBootstrapToken = token;
    _deferredInitialNetworkBootstrapTimer?.cancel();
    debugPrint(
      '[FeedStartupSurface] status=schedule_deferred_initial_load '
      'reason=$reason delayMs=${_deferredInitialNetworkBootstrapDelay.inMilliseconds} '
      'agendaCount=${agendaList.length} allowEmptyAgenda=$allowEmptyAgenda',
    );
    _deferredInitialNetworkBootstrapTimer = Timer(
      _deferredInitialNetworkBootstrapDelay,
      () {
        if (isClosed || _deferredInitialNetworkBootstrapToken != token) {
          return;
        }
        _deferredInitialNetworkBootstrapTimer = null;
        if (!ContentPolicy.isConnected ||
            _startupHeadFinalized ||
            isLoading.value ||
            _ensureInitialLoadInFlight) {
          if (!allowEmptyAgenda || agendaList.isNotEmpty) {
            return;
          }
        }
        if (!allowEmptyAgenda && agendaList.isEmpty) {
          return;
        }
        debugPrint(
          '[FeedStartupSurface] status=run_deferred_initial_load '
          'reason=$reason agendaCount=${agendaList.length} '
          'allowEmptyAgenda=$allowEmptyAgenda',
        );
        unawaited(ensureInitialFeedLoaded());
      },
    );
  }

  Future<bool> _seedConnectedStartupHeadFromShard() async {
    debugPrint(
      '[FeedStartupSurface] status=connected_seed_disabled_runtime',
    );
    return false;
  }

  Future<bool> _seedConnectedStartupHeadFromLocalFallback({
    required String reason,
  }) async {
    debugPrint(
      '[FeedStartupSurface] status=${reason}_disabled_live_motor_only',
    );
    return false;
  }

  Future<bool> _restoreConnectedStartupHeadAfterTransientFailure() {
    return _seedConnectedStartupHeadFromLocalFallback(
      reason: 'transient_failure_local_fallback',
    );
  }

  bool _shouldReplaceSeededStartupHeadOnInitialBootstrap(
    List<PostsModel> currentAgenda,
  ) {
    return currentAgenda.isNotEmpty &&
        _startupPlannerHeadApplied &&
        ContentPolicy.isConnected;
  }

  bool _shouldFinalizeConnectedLiveStartupHead({
    required bool initial,
    required List<PostsModel> currentAgenda,
  }) {
    return initial && currentAgenda.isEmpty && ContentPolicy.isConnected;
  }

  void _performResetSurfaceForTabTransition() {
    _feedMutationEpoch++;
    _cancelStartupWarmPlayerPreload();
    _cancelDeferredInitialNetworkBootstrap();
    _cancelPendingPlaybackReassert();
    _pendingCenteredDocId = null;
    _startupLockedFeedDocId = null;
    _startupPlaybackLockedAt = null;
    _lastPlaybackCommandDocId = null;
    _lastPlaybackCommandAt = null;
    lastCenteredIndex = agendaList.isEmpty ? null : 0;
    centeredIndex.value = -1;
    _visibleFractions.clear();
    pauseAll.value = false;

    try {
      VideoStateManager.instance.pauseAllVideos(force: true);
    } catch (_) {}

    void resetNow() {
      if (!scrollController.hasClients) return;
      try {
        scrollController.jumpTo(0);
      } catch (_) {}
    }

    resetNow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      resetNow();
    });
  }

  void _cancelDeferredInitialNetworkBootstrap() {
    _deferredInitialNetworkBootstrapToken++;
    _deferredInitialNetworkBootstrapTimer?.cancel();
    _deferredInitialNetworkBootstrapTimer = null;
  }

  bool _isTransientAgendaUnavailable(Object error) {
    if (error is FirebaseException && error.code == 'unavailable') {
      return true;
    }
    final message = normalizeLowercase(error.toString());
    return message.contains('cloud_firestore/unavailable') ||
        message.contains('unable to resolve host firestore.googleapis.com') ||
        message.contains('unknownhostexception') ||
        message.contains('the service is currently unavailable');
  }

  void _clearAgendaRetry() {
    _agendaRetryTimer?.cancel();
    _agendaRetryTimer = null;
    _agendaRetryCount = 0;
  }

  void _scheduleAgendaRetry({required bool initial}) {
    if (_agendaRetryTimer?.isActive == true) return;
    _agendaRetryCount = (_agendaRetryCount + 1).clamp(1, 5);
    final delaySeconds = min(30, _agendaRetryCount * 3);
    debugPrint(
      '[FeedRetryTimer] status=scheduled initial=$initial '
      'retryCount=$_agendaRetryCount delaySeconds=$delaySeconds '
      'currentCount=${agendaList.length}',
    );
    recordQALabFeedFetchEvent(
      stage: 'retry_scheduled',
      trigger: 'retry_timer',
      metadata: <String, dynamic>{
        'initial': initial,
        'retryCount': _agendaRetryCount,
        'delaySeconds': delaySeconds,
        'currentCount': agendaList.length,
      },
    );
    _agendaRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      _agendaRetryTimer = null;
      if (isClosed) return;
      debugPrint(
        '[FeedRetryTimer] status=fired initial=$initial '
        'retryCount=$_agendaRetryCount delaySeconds=$delaySeconds '
        'currentCount=${agendaList.length}',
      );
      recordQALabFeedFetchEvent(
        stage: 'retry_fired',
        trigger: 'retry_timer',
        metadata: <String, dynamic>{
          'initial': initial,
          'retryCount': _agendaRetryCount,
          'delaySeconds': delaySeconds,
          'currentCount': agendaList.length,
        },
      );
      unawaited(
        fetchAgendaBigData(
          initial: initial,
          trigger: 'retry_timer',
        ),
      );
    });
  }

  Future<void> _dispatchFeedBootstrapRequest({
    required bool initial,
    required String trigger,
    int? pageLimit,
    int? expectedMutationEpoch,
  }) {
    if (initial) {
      _recordFeedMotorContractSnapshot(reason: trigger);
    }
    debugPrint(
      '[FeedBootstrapRequest] trigger=$trigger initial=$initial '
      'pageLimit=${pageLimit ?? 0} agendaCount=${agendaList.length} '
      'expectedMutationEpoch=${expectedMutationEpoch ?? -1}',
    );
    return fetchAgendaBigData(
      initial: initial,
      pageLimit: pageLimit,
      trigger: trigger,
      expectedMutationEpoch: expectedMutationEpoch,
    );
  }

  void _applyInitialFeedPagePlan({
    required bool initial,
    required List<PostsModel> currentAgenda,
    required List<PostsModel> visibleItems,
    required AgendaFeedPageApplyPlan pageApplyPlan,
  }) {
    if (visibleItems.isEmpty) return;

    debugPrint(
      '[FeedLaunchMotorApply] '
      'initial=$initial prefilled=${pageApplyPlan.pageItemsPreplanned} '
      'visible=${visibleItems.length} addCount=${pageApplyPlan.itemsToAdd.length} '
      'current=${currentAgenda.length} hasMore=${pageApplyPlan.hasMore}',
    );

    final shouldFinalizeStartupHead = initial &&
        _shouldReplaceSeededStartupHeadOnInitialBootstrap(currentAgenda);
    if (pageApplyPlan.freshScheduledIds.isNotEmpty) {
      markHighlighted(
        pageApplyPlan.freshScheduledIds,
        keepFor: const Duration(milliseconds: 900),
      );
    }

    if (shouldFinalizeStartupHead) {
      final appendedItems = pageApplyPlan.itemsToAdd;
      final replacementAgenda = pageApplyPlan.pageItemsPreplanned
          ? _agendaFeedApplicationService.buildPlannerPageItems(
              visibleItems,
              currentItemCount: 0,
            )
          : _agendaFeedApplicationService.buildPlannerPageItems(
              visibleItems,
              currentItemCount: 0,
            );
      debugPrint(
        '[FeedStartupPlanner] source=initial_bootstrap '
        'status=bypass_seeded_head_with_live_pool '
        'currentCount=${currentAgenda.length} liveCount=${visibleItems.length} '
        'replacementCount=${replacementAgenda.length} '
        'appendCount=${appendedItems.length} '
        'currentHead=${currentAgenda.take(5).map((post) => post.docID).join(",")} '
        'liveHead=${visibleItems.take(5).map((post) => post.docID).join(",")}',
      );
      _replaceAgendaState(
        replacementAgenda,
        reason: 'initial_seeded_head_bypass_live_pool',
      );
      _startupHeadFinalized = true;
      _scheduleInitialFeedVideoPosterWarmup(
        _initialVisibleVideoWarmupWindow(replacementAgenda),
      );
      if (appendedItems.isNotEmpty) {
        _scheduleReshareFetchForPosts(
          appendedItems,
          perPostLimit: 1,
        );
      }
      return;
    }

    if (pageApplyPlan.itemsToAdd.isEmpty) {
      debugPrint(
        '[FeedAppendDiagnostics] status=empty_apply initial=$initial '
        'current=${currentAgenda.length} visible=${visibleItems.length} '
        'arranged=${pageApplyPlan.arrangedPageItemCount} '
        'duplicateExisting=${pageApplyPlan.duplicateExistingCount} '
        'hasMore=${pageApplyPlan.hasMore}',
      );
      return;
    }

    if (initial && _startupPlannerHeadApplied && !_startupHeadFinalized) {
      _startupHeadFinalized = true;
    }
    final shouldActivateStartupStages = initial && agendaList.isEmpty;
    if (initial && currentAgenda.isEmpty) {
      final startupItems = pageApplyPlan.itemsToAdd;
      if (shouldActivateStartupStages && startupItems.isNotEmpty) {
        _startupRenderBootstrapHold = true;
        _activateStartupRenderStages(
          reason: 'initial_items_to_add',
        );
      }
      debugPrint(
        '[FeedStartupPlanner] source=initial_bootstrap '
        'status=apply_composed_startup_items '
        'rawCount=${pageApplyPlan.itemsToAdd.length} '
        'composedCount=${startupItems.length}',
      );
      _scheduleInitialFeedVideoPosterWarmup(startupItems);
      unawaited(_primeInitialVisibleCardImageHints(startupItems));
      _replaceAgendaState(
        startupItems,
        reason: 'initial_items_to_add',
      );
      if (GetPlatform.isAndroid) {
        _applyStartupRenderStagesNow();
      }
      if (_shouldFinalizeConnectedLiveStartupHead(
        initial: initial,
        currentAgenda: currentAgenda,
      )) {
        _startupHeadFinalized = true;
        debugPrint(
          '[FeedStartupPlanner] source=initial_bootstrap '
          'status=finalize_connected_live_startup_head '
          'composedCount=${startupItems.length}',
        );
      }
      _scheduleStartupWarmPlayerPreload(
        startupItems,
        reason: 'initial_items_to_add',
      );
      _scheduleReshareFetchForPosts(
        startupItems,
        perPostLimit: 1,
      );
      return;
    }

    if (initial && shouldActivateStartupStages) {
      _startupRenderBootstrapHold = true;
      _activateStartupRenderStages(
        reason: 'initial_items_to_add',
      );
    }
    if (!initial && pageApplyPlan.itemsToAdd.length >= 3) {
      _scheduleGrowthRenderRelease(
        reason: 'append_growth_items',
        itemCount: pageApplyPlan.itemsToAdd.length,
      );
    }
    _scheduleInitialFeedVideoPosterWarmup(pageApplyPlan.itemsToAdd);
    _appendUniqueAgendaState(
      pageApplyPlan.itemsToAdd,
      reason: 'initial_items_append',
    );
    if (initial) {
      unawaited(_primeInitialVisibleCardImageHints(pageApplyPlan.itemsToAdd));
    }
    if (initial && GetPlatform.isAndroid) {
      _applyStartupRenderStagesNow();
    }
    if (initial) {
      _scheduleStartupWarmPlayerPreload(
        agendaList.toList(growable: false),
        reason: 'initial_items_append',
      );
    }
    _scheduleReshareFetchForPosts(
      pageApplyPlan.itemsToAdd,
      perPostLimit: 1,
    );
  }

  void _applyRefreshMergedAgenda({
    required List<PostsModel> mergedAgenda,
  }) {
    _cancelStartupWarmPlayerPreload();
    _prefetchedThumbnailPostCount = 0;
    _resetStartupRenderStages();
    _prefetchedThumbnailDocIds.clear();
    publicReshareEvents.clear();
    feedReshareEntries.clear();
    highlightDocIDs.clear();
    _replaceAgendaState(
      mergedAgenda,
      reason: 'refresh_merge_live_items',
    );
  }

  // Yeni yüklenen gönderileri en üste almak için güvenli yenileme
  Future<void> prependUploadedAndRefresh() async {
    try {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
      await refreshAgenda();
    } catch (e) {
      print('prependUploadedAndRefresh error: $e');
    }
  }

  Future<void> fetchAgendaBigData({
    bool initial = false,
    int? pageLimit,
    String trigger = 'manual',
    int? expectedMutationEpoch,
  }) async {
    if (_renderWindowFrozenOnCellular && !initial) {
      recordQALabFeedFetchEvent(
        stage: 'skipped',
        trigger: trigger,
        metadata: <String, dynamic>{
          'initial': initial,
          'pageLimit': pageLimit ?? 0,
          'reason': 'cellular_render_freeze',
          'currentCount': agendaList.length,
        },
      );
      debugPrint(
        '[FeedBootstrapRequest] status=skip_cellular_render_freeze '
        'trigger=$trigger agendaCount=${agendaList.length}',
      );
      return;
    }
    if (initial && agendaList.isNotEmpty && _startupHeadFinalized) {
      recordQALabFeedFetchEvent(
        stage: 'skipped',
        trigger: trigger,
        metadata: <String, dynamic>{
          'initial': initial,
          'pageLimit': pageLimit ?? 0,
          'reason': 'startup_already_ready',
          'currentCount': agendaList.length,
        },
      );
      debugPrint(
        '[FeedBootstrapRequest] status=skip_already_ready trigger=$trigger '
        'agendaCount=${agendaList.length}',
      );
      return;
    }
    recordQALabFeedFetchEvent(
      stage: 'requested',
      trigger: trigger,
      metadata: <String, dynamic>{
        'initial': initial,
        'pageLimit': pageLimit ?? 0,
        'isLoading': isLoading.value,
        'hasMore': hasMore.value,
        'currentCount': agendaList.length,
      },
    );
    _cancelDeferredInitialNetworkBootstrap();
    final previousAgenda = agendaList.toList(growable: false);
    final previousReshares = publicReshareEvents.toList(growable: false);
    final previousFeedReshares = feedReshareEntries.toList(growable: false);
    final previousLastDoc = lastDoc;
    final previousFeedTypesenseNextPage = _feedTypesenseNextPage;
    final previousHasMore = hasMore.value;
    final previousUsePrimaryFeedPaging = _usePrimaryFeedPaging;
    final preserveVisibleSeededHeadOnInitialBootstrap = initial &&
        previousAgenda.isNotEmpty &&
        _startupPlannerHeadApplied &&
        !_startupHeadFinalized &&
        ContentPolicy.isConnected;
    if (initial) {
      _resetFeedPageFetchTrigger();
      lastDoc = null;
      _feedTypesenseNextPage = null;
      _usePrimaryFeedPaging = true;
      hasMore.value = true;
      _plannedColdFeedWindow.clear();
      _plannedColdFeedLastDoc = null;
      _plannedColdFeedUsesPrimaryFeed = true;
      _plannedColdFeedNextTypesensePage = null;
      _connectedFeedReservoirWarmTarget = 0;
      _connectedFeedReservoirWarmInFlight = false;
      _connectedFeedStageFourReadyCheckpointLogged = false;
      _prefetchedThumbnailPostCount = 0;
      _prefetchedThumbnailDocIds.clear();
      if (!preserveVisibleSeededHeadOnInitialBootstrap) {
        _startupPlannerHeadApplied = false;
        _startupHeadFinalized = false;
        _clearAgendaState(reason: 'initial_bootstrap_reset');
        // Eski yeniden paylaşım meta verilerini sıfırla
        publicReshareEvents.clear();
        feedReshareEntries.clear();

        // 🎯 INSTAGRAM STYLE: İlk açılışta centered index'i sıfırla
        centeredIndex.value = -1;

        debugPrint(
          '[FeedStartupSurface] status=skip_feed_cache_bootstrap_live_only '
          'connected=${ContentPolicy.isConnected}',
        );

        // Reshare yüklemelerini ilk render sonrasına ertele; launch jank'i azaltır.
        _scheduleInitialReshareMerge();

        if (agendaList.isNotEmpty &&
            _startupHeadFinalized &&
            !ContentPolicy.isConnected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (agendaList.isNotEmpty &&
                (_needsInitialFeedPlaybackPrime || centeredIndex.value == -1)) {
              primeInitialCenteredPost();
            }
          });
          return;
        }

        if (agendaList.isNotEmpty &&
            !ContentPolicy.shouldBootstrapNetwork(
              ContentScreenKind.feed,
              hasLocalContent: true,
            )) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (agendaList.isNotEmpty &&
                (_needsInitialFeedPlaybackPrime || centeredIndex.value == -1)) {
              primeInitialCenteredPost();
            }
          });
          return;
        }
      }
    }

    if (!hasMore.value || isLoading.value) {
      recordQALabFeedFetchEvent(
        stage: 'skipped',
        trigger: trigger,
        metadata: <String, dynamic>{
          'initial': initial,
          'pageLimit': pageLimit ?? 0,
          'isLoading': isLoading.value,
          'hasMore': hasMore.value,
          'currentCount': agendaList.length,
        },
      );
      return;
    }

    final startedLoading = !isLoading.value;
    if (startedLoading) {
      isLoading.value = true;
    }
    recordQALabFeedFetchEvent(
      stage: 'started',
      trigger: trigger,
      metadata: <String, dynamic>{
        'initial': initial,
        'pageLimit': pageLimit ?? 0,
        'startedLoading': startedLoading,
        'currentCount': agendaList.length,
      },
    );
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      final loadLimit = initial
          ? ReadBudgetRegistry.feedLivePageLimit
          : (pageLimit ?? fetchLimit);
      final currentAgenda = agendaList.toList(growable: false);
      final liveConnected = ContentPolicy.isConnected;
      final sourcePageLimit = initial && liveConnected
          ? (isCityMode ? 50 : FeedSnapshotRepository.startupHomeLimitValue)
          : loadLimit;
      final shouldPreferCacheOnOpen = !liveConnected;
      final seenDocIds = currentAgenda
          .map((post) => post.docID.trim())
          .where((docId) => docId.isNotEmpty)
          .toSet();
      final plannedColdPage = initial
          ? null
          : _loadPlannedColdFeedPage(
              currentAgenda: currentAgenda,
              limit: loadLimit,
            );
      final usesPlannedColdPage = plannedColdPage != null;
      final storedCursor = lastDoc is DocumentSnapshot<Map<String, dynamic>>
          ? lastDoc as DocumentSnapshot<Map<String, dynamic>>?
          : null;
      var effectiveLastDoc = storedCursor;
      var effectiveNextTypesensePage = _feedTypesenseNextPage;
      var effectiveUsesPrimaryFeed = _usePrimaryFeedPaging;
      var effectiveHasMore = hasMore.value;
      var effectivePageItemsPreplanned = usesPlannedColdPage;
      List<PostsModel> visibleItems = const <PostsModel>[];
      final page = plannedColdPage ??
          await _loadAgendaSourcePage(
            nowMs: nowMs,
            cutoffMs: cutoffMs,
            limit: sourcePageLimit,
            startAfter: null,
            useStoredCursor: true,
            preferCache: shouldPreferCacheOnOpen,
            cacheOnly: !liveConnected,
          );
      effectiveLastDoc = page.lastDoc;
      effectiveNextTypesensePage = page.nextTypesensePage;
      effectiveUsesPrimaryFeed = page.usesPrimaryFeed;
      effectivePageItemsPreplanned =
          usesPlannedColdPage || page.itemsPreplanned;
      effectiveHasMore = FeedTypesensePagingContract.resolvePageHasMore(
        initial: initial,
        liveConnected: liveConnected,
        itemCount: page.items.length,
        sourcePageLimit: sourcePageLimit,
        lastDoc: page.lastDoc,
        nextTypesensePage: page.nextTypesensePage,
      );

      final skipConnectedStartupSupport =
          initial && currentAgenda.isEmpty && liveConnected;
      if (skipConnectedStartupSupport) {
        debugPrint(
          '[FeedStartupSupport] status=skip_connected_live_support '
          'candidateCount=${page.items.length}',
        );
      }
      final rawPageVisibleItems = initial
          ? ((isCityMode || skipConnectedStartupSupport)
              ? page.items
              : await _augmentStartupSupportCandidates(
                  candidates: page.items,
                  nowMs: nowMs,
                  primaryCutoffMs: cutoffMs,
                  targetCount: FeedSnapshotRepository.startupHomeLimitValue,
                  preferCache: shouldPreferCacheOnOpen,
                  cacheOnly: !liveConnected,
                  allowNetworkFallbackFetch: true,
                ))
          : page.items;
      final effectiveRawPageVisibleItems = rawPageVisibleItems;
      final pageVisibleItems = initial &&
              currentAgenda.isEmpty &&
              effectiveRawPageVisibleItems.isNotEmpty
          ? (effectivePageItemsPreplanned
              ? effectiveRawPageVisibleItems
                  .take(FeedSnapshotRepository.startupHomeLimitValue)
                  .toList(growable: false)
              : (isCityMode
                  ? effectiveRawPageVisibleItems
                  : _applyStartupPlannerHeadOrder(
                  effectiveRawPageVisibleItems,
                  allowSparseSlotFallback: liveConnected,
                )))
          : effectiveRawPageVisibleItems;
      if (initial &&
          currentAgenda.isEmpty &&
          effectiveRawPageVisibleItems.length != pageVisibleItems.length) {
        debugPrint(
          '[FeedStartupPlanner] source=initial_bootstrap '
          'status=compose_before_page_apply '
          'rawCount=${effectiveRawPageVisibleItems.length} '
          'composedCount=${pageVisibleItems.length}',
        );
      }

      if (initial) {
        visibleItems = pageVisibleItems;
      } else {
        visibleItems = pageVisibleItems.where((post) {
          final docId = post.docID.trim();
          return docId.isNotEmpty && seenDocIds.add(docId);
        }).toList(growable: false);
      }

      debugPrint(
        '[FeedAppendDiagnostics] trigger=$trigger initial=$initial '
        'rawPage=${page.items.length} rawVisible=${effectiveRawPageVisibleItems.length} '
        'pageVisible=${pageVisibleItems.length} dedupedVisible=${visibleItems.length} '
        'current=${currentAgenda.length} loadLimit=$loadLimit '
        'itemsPreplanned=$effectivePageItemsPreplanned '
        'usesPlannedColdPage=$usesPlannedColdPage',
      );

      final pageApplyPlan = _agendaFeedApplicationService.buildPageApplyPlan(
        currentItems: agendaList.toList(growable: false),
        pageItems: visibleItems,
        nowMs: nowMs,
        loadLimit: loadLimit,
        lastDoc: effectiveLastDoc,
        hasMore: effectiveHasMore,
        usesPrimaryFeed: effectiveUsesPrimaryFeed,
        maxItemsToAdd: usesPlannedColdPage ? loadLimit : null,
        pageItemsPreplanned: usesPlannedColdPage ||
            effectivePageItemsPreplanned ||
            (initial && currentAgenda.isEmpty),
      );

      debugPrint(
        '[FeedAppendDiagnostics] trigger=$trigger plan arranged=${pageApplyPlan.arrangedPageItemCount} '
        'duplicateExisting=${pageApplyPlan.duplicateExistingCount} '
        'capped=${pageApplyPlan.cappedCount} '
        'itemsToAdd=${pageApplyPlan.itemsToAdd.length} '
        'hasMore=${pageApplyPlan.hasMore}',
      );

      if (expectedMutationEpoch != null &&
          expectedMutationEpoch != _feedMutationEpoch) {
        debugPrint(
          '[FeedBootstrapRequest] status=skip_stale_apply trigger=$trigger '
          'expectedMutationEpoch=$expectedMutationEpoch '
          'currentMutationEpoch=$_feedMutationEpoch',
        );
        return;
      }
      if (_renderWindowFrozenOnCellular && !initial) {
        debugPrint(
          '[FeedBootstrapRequest] status=skip_cellular_render_freeze_after_fetch '
          'trigger=$trigger agendaCount=${agendaList.length}',
        );
        return;
      }

      if (usesPlannedColdPage) {
        final consumedDocIds = <String>{
          for (final post in currentAgenda)
            if (post.docID.trim().isNotEmpty) post.docID.trim(),
          for (final post in pageApplyPlan.itemsToAdd)
            if (post.docID.trim().isNotEmpty) post.docID.trim(),
        };
        final remainingPlannedCount =
            _remainingPlannedColdFeedCount(seenDocIds: consumedDocIds);
        final hasPlannedRemaining = remainingPlannedCount > 0;
        final canGrowConnectedPlan = ContentPolicy.isConnected &&
            currentAgenda.length < _connectedColdFeedStageFourLimit;
        effectiveLastDoc = _plannedColdFeedLastDoc;
        effectiveNextTypesensePage = _plannedColdFeedNextTypesensePage;
        effectiveUsesPrimaryFeed = _plannedColdFeedUsesPrimaryFeed;
        effectiveHasMore = FeedTypesensePagingContract.resolvePlannedHasMore(
          hasPlannedRemaining: hasPlannedRemaining,
          canGrowConnectedPlan: canGrowConnectedPlan,
          lastDoc: effectiveLastDoc,
          nextTypesensePage: effectiveNextTypesensePage,
        );
        debugPrint(
          '[FeedColdPlanApply] currentCount=${currentAgenda.length} '
          'candidateCount=${page.items.length} addCount=${pageApplyPlan.itemsToAdd.length} '
          'remaining=$remainingPlannedCount',
        );
        if (!hasPlannedRemaining) {
          _plannedColdFeedWindow.clear();
          _plannedColdFeedLastDoc = null;
          _plannedColdFeedUsesPrimaryFeed = true;
          _plannedColdFeedNextTypesensePage = null;
        }
      }

      _usePrimaryFeedPaging = effectiveUsesPrimaryFeed;
      lastDoc = effectiveLastDoc;
      _feedTypesenseNextPage = effectiveNextTypesensePage;

      final projectedVisibleCount =
          currentAgenda.length + pageApplyPlan.itemsToAdd.length;
      if (!liveConnected &&
          (visibleItems.isNotEmpty || page.items.isNotEmpty)) {
        _scheduleConnectedColdFeedReservoirWarmup(
          nowMs: nowMs,
          cutoffMs: cutoffMs,
          seedPosts: visibleItems.isNotEmpty ? visibleItems : currentAgenda,
          fetchedPosts: page.items,
          lastDoc: page.lastDoc,
          nextTypesensePage: page.nextTypesensePage,
          usesPrimaryFeed: page.usesPrimaryFeed,
          visibleCount: projectedVisibleCount,
        );
      }

      _applyInitialFeedPagePlan(
        initial: initial,
        currentAgenda: currentAgenda,
        visibleItems: visibleItems,
        pageApplyPlan: pageApplyPlan,
      );

      hasMore.value = effectiveHasMore;
      _reconcileFeedPageFetchTriggerToCurrentRunway(
        reason: initial ? 'initial_apply' : 'append_apply',
      );
      if (effectiveHasMore) {
        _maybeTriggerDeferredFeedGrowth(
          reason: initial ? 'initial_apply' : 'append_apply',
        );
      }
      if (initial && liveConnected && effectiveHasMore) {
        _scheduleConnectedFeedReservoirStageWarmup(
          targetLimit: _connectedColdFeedStageTwoLimit,
          reason: 'initial_page2_ready_before_50',
        );
      }
      _clearAgendaRetry();
      recordQALabFeedFetchEvent(
        stage: 'completed',
        trigger: trigger,
        metadata: <String, dynamic>{
          'initial': initial,
          'loadLimit': loadLimit,
          'visibleItemCount': visibleItems.length,
          'agendaCount': agendaList.length,
          'hasMore': hasMore.value,
          'usesPrimaryFeed': effectiveUsesPrimaryFeed,
        },
      );
    } catch (e) {
      print("fetchAgendaBigData error: $e");
      recordQALabFeedFetchEvent(
        stage: 'failed',
        trigger: trigger,
        metadata: <String, dynamic>{
          'initial': initial,
          'pageLimit': pageLimit ?? 0,
          'error': e.toString(),
          'currentCount': agendaList.length,
        },
      );
      if (_isTransientAgendaUnavailable(e)) {
        var restoredFromLocalFallback = false;
        if (agendaList.isEmpty) {
          restoredFromLocalFallback =
              await _restoreConnectedStartupHeadAfterTransientFailure();
        }
        if (agendaList.isEmpty && previousAgenda.isNotEmpty) {
          _replaceAgendaState(
            previousAgenda,
            reason: 'transient_retry_restore_previous',
          );
          publicReshareEvents.assignAll(previousReshares);
          feedReshareEntries.assignAll(previousFeedReshares);
          lastDoc = previousLastDoc;
          _feedTypesenseNextPage = previousFeedTypesenseNextPage;
          hasMore.value = previousHasMore;
          _usePrimaryFeedPaging = previousUsePrimaryFeedPaging;
          if (_needsInitialFeedPlaybackPrime || centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        }
        _scheduleAgendaRetry(
          initial: initial && agendaList.isEmpty && !restoredFromLocalFallback,
        );
      }
    } finally {
      if (startedLoading) {
        isLoading.value = false; // HER DURUMDA EN SON ÇALIŞIR
      }

      // 🎯 INSTAGRAM STYLE: İlk açılışta ilk videoyu otomatik centered yap
      if (initial && agendaList.isNotEmpty) {
        // Bir frame bekle ki VisibilityDetector build olsun
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty &&
              (_needsInitialFeedPlaybackPrime || centeredIndex.value == -1)) {
            primeInitialCenteredPost();
          }
        });
      }
    }
  }

  Future<void> _primeColdFeedPlanWindow({
    required int nowMs,
    required int cutoffMs,
    required List<PostsModel> seedPosts,
    required int targetLimit,
    List<PostsModel> existingFetchedPosts = const <PostsModel>[],
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int? nextTypesensePage,
    bool usesPrimaryFeed = true,
  }) async {
    final batchLimit = _connectedColdFeedPrimeBatchLimitForTarget(targetLimit);
    final fetchLimit = _connectedColdFeedCandidateFetchLimitForTarget(
      targetLimit,
    );
    if (targetLimit <= FeedSnapshotRepository.startupHomeLimitValue) {
      return;
    }
    if (!ContentPolicy.isConnected || seedPosts.isEmpty) {
      return;
    }

    try {
      final fetchedPosts = _dedupeColdPlanPosts(existingFetchedPosts).toList();
      final fetchedIds = <String>{
        for (final post in fetchedPosts)
          if (post.docID.trim().isNotEmpty) post.docID.trim(),
      };
      var cursor = startAfter;
      var resolvedNextTypesensePage = nextTypesensePage;
      var fetchedItemCount = fetchedPosts.length;
      var resolvedLastDoc = startAfter;
      var resolvedUsesPrimaryFeed = usesPrimaryFeed;

      while (fetchedItemCount < fetchLimit) {
        final remainingFetchBudget = fetchLimit - fetchedItemCount;
        final currentBatchLimit = min(batchLimit, remainingFetchBudget);
        if (currentBatchLimit <= 0) {
          break;
        }

        final page = await _loadAgendaSourcePage(
          nowMs: nowMs,
          cutoffMs: cutoffMs,
          limit: currentBatchLimit,
          startAfter: cursor,
          typesensePage: resolvedNextTypesensePage,
          useStoredCursor: false,
          preferCache: false,
          cacheOnly: false,
          usePrimaryFeedPaging: true,
          includeSupplementalSources: true,
        );

        if (page.items.isEmpty) {
          break;
        }

        fetchedItemCount += page.items.length;
        resolvedLastDoc = page.lastDoc;
        resolvedNextTypesensePage = page.nextTypesensePage;
        resolvedUsesPrimaryFeed = page.usesPrimaryFeed;

        for (final post in page.items) {
          final docId = post.docID.trim();
          if (docId.isEmpty || !fetchedIds.add(docId)) {
            continue;
          }
          fetchedPosts.add(post);
        }

        await _storeColdFeedPlanWindow(
          seedPosts: seedPosts,
          fetchedPosts: fetchedPosts,
          lastDoc: resolvedLastDoc,
          nextTypesensePage: resolvedNextTypesensePage,
          usesPrimaryFeed: resolvedUsesPrimaryFeed,
          targetLimit: targetLimit,
          logLabel: 'FeedColdPlan',
        );

        if (FeedTypesensePagingContract.shouldStopPriming(
          plannedCount: _plannedColdFeedWindow.length,
          targetLimit: targetLimit,
          itemCount: page.items.length,
          batchLimit: currentBatchLimit,
          lastDoc: page.lastDoc,
          nextTypesensePage: page.nextTypesensePage,
        )) {
          break;
        }

        cursor = page.lastDoc;
      }
    } catch (error) {
      debugPrint('[FeedColdPlan] failed error=$error');
    }
  }

  void _scheduleConnectedColdFeedReservoirWarmup({
    required int nowMs,
    required int cutoffMs,
    required List<PostsModel> seedPosts,
    required List<PostsModel> fetchedPosts,
    required DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    required int? nextTypesensePage,
    required bool usesPrimaryFeed,
    required int visibleCount,
  }) {
    if (!ContentPolicy.isConnected || seedPosts.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed || !ContentPolicy.isConnected || seedPosts.isEmpty) return;
      unawaited(
        _warmConnectedColdFeedReservoir(
          nowMs: nowMs,
          cutoffMs: cutoffMs,
          seedPosts: seedPosts,
          fetchedPosts: fetchedPosts,
          lastDoc: lastDoc,
          nextTypesensePage: nextTypesensePage,
          usesPrimaryFeed: usesPrimaryFeed,
          visibleCount: visibleCount,
        ),
      );
    });
  }

  void _maybeScheduleConnectedFeedReservoirForViewedCount(int viewedCount) {
    _maybeRecordConnectedFeedStageFourReadyCheckpoint(viewedCount);
    if (viewedCount >= _connectedColdFeedStageFourViewedTrigger) {
      _scheduleConnectedFeedReservoirStageWarmup(
        targetLimit: _connectedColdFeedStageFourLimit,
        reason:
            'viewed_${_connectedColdFeedStageFourViewedTrigger}_page4_ready_before_170',
      );
      return;
    }
    if (viewedCount >= _connectedColdFeedStageThreeViewedTrigger) {
      _scheduleConnectedFeedReservoirStageWarmup(
        targetLimit: _connectedColdFeedStageThreeLimit,
        reason:
            'viewed_${_connectedColdFeedStageThreeViewedTrigger}_page3_ready_before_110',
      );
    }
  }

  void _maybeRecordConnectedFeedStageFourReadyCheckpoint(int viewedCount) {
    if (_connectedFeedStageFourReadyCheckpointLogged ||
        viewedCount < _connectedColdFeedStageFourReadyViewedCheckpoint) {
      return;
    }
    _connectedFeedStageFourReadyCheckpointLogged = true;
    final planned = _plannedColdFeedWindow.length;
    final ready = planned >= _connectedColdFeedStageFourLimit ||
        agendaList.length >= _connectedColdFeedStageFourLimit;
    _recordFeedMotorSignal(
      name: ready ? 'stage_four_ready_at_170' : 'stage_four_not_ready_at_170',
      status: ready ? 'ok' : 'warn',
      reason: 'viewed_170_stage4_checkpoint',
      metadata: <String, dynamic>{
        'viewedCount': viewedCount,
        'currentCount': agendaList.length,
        'planned': planned,
        'target': _connectedColdFeedStageFourLimit,
        'warmTarget': _connectedFeedReservoirWarmTarget,
        'warmInFlight': _connectedFeedReservoirWarmInFlight,
      },
    );
  }

  void _scheduleConnectedFeedReservoirStageWarmup({
    required int targetLimit,
    required String reason,
  }) {
    if (!ContentPolicy.isConnected) return;
    if (targetLimit <= FeedSnapshotRepository.startupHomeLimitValue) return;
    if (_plannedColdFeedWindow.length >= targetLimit) return;
    if (_connectedFeedReservoirWarmTarget >= targetLimit) return;
    if (_connectedFeedReservoirWarmInFlight) return;
    if (agendaList.isEmpty) return;
    final nextTypesensePage =
        _plannedColdFeedNextTypesensePage ?? _feedTypesenseNextPage;
    if (nextTypesensePage == null && lastDoc == null) return;
    _connectedFeedReservoirWarmTarget = targetLimit;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      unawaited(
        _warmConnectedFeedReservoirStage(
          targetLimit: targetLimit,
          reason: reason,
        ),
      );
    });
  }

  Future<void> _warmConnectedFeedReservoirStage({
    required int targetLimit,
    required String reason,
  }) async {
    if (!ContentPolicy.isConnected || agendaList.isEmpty) return;
    if (_connectedFeedReservoirWarmInFlight) return;
    _connectedFeedReservoirWarmInFlight = true;
    try {
      final nextTypesensePage =
          _plannedColdFeedNextTypesensePage ?? _feedTypesenseNextPage;
      final cursor = _plannedColdFeedLastDoc ??
          (lastDoc is DocumentSnapshot<Map<String, dynamic>>
              ? lastDoc as DocumentSnapshot<Map<String, dynamic>>
              : null);
      if (nextTypesensePage == null && cursor == null) return;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      final seedPosts = _plannedColdFeedWindow.isNotEmpty
          ? _plannedColdFeedWindow.toList(growable: false)
          : agendaList.toList(growable: false);
      debugPrint(
        '[FeedTypesenseStageWarm] status=start reason=$reason '
        'target=$targetLimit seed=${seedPosts.length} '
        'nextTypesensePage=${nextTypesensePage ?? 0}',
      );
      _recordFeedMotorSignal(
        name: 'reservoir_stage_start',
        status: 'ok',
        reason: reason,
        metadata: <String, dynamic>{
          'target': targetLimit,
          'seed': seedPosts.length,
          'nextTypesensePage': nextTypesensePage ?? 0,
          'batchLimit': _connectedReservoirWarmVisibleBatchLimit,
        },
      );
      final page = await _loadAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: _connectedReservoirWarmVisibleBatchLimit,
        startAfter: cursor,
        typesensePage: nextTypesensePage,
        useStoredCursor: false,
        preferCache: false,
        cacheOnly: false,
        usePrimaryFeedPaging: true,
        includeSupplementalSources: false,
      );
      if (page.items.isEmpty) {
        debugPrint(
          '[FeedTypesenseStageWarm] status=empty reason=$reason '
          'target=$targetLimit',
        );
        _recordFeedMotorSignal(
          name: 'reservoir_stage_empty',
          status: 'warn',
          reason: reason,
          metadata: <String, dynamic>{
            'target': targetLimit,
            'planned': _plannedColdFeedWindow.length,
            'nextTypesensePage': page.nextTypesensePage ?? 0,
          },
        );
        return;
      }
      await _storeColdFeedPlanWindow(
        seedPosts: seedPosts,
        fetchedPosts: page.items,
        lastDoc: page.lastDoc,
        nextTypesensePage: page.nextTypesensePage,
        usesPrimaryFeed: page.usesPrimaryFeed,
        targetLimit: targetLimit,
        logLabel: 'FeedTypesenseStageWarm',
      );
      debugPrint(
        '[FeedTypesenseStageWarm] status=ready reason=$reason '
        'target=$targetLimit fetched=${page.items.length} '
        'planned=${_plannedColdFeedWindow.length} '
        'nextTypesensePage=${page.nextTypesensePage ?? 0}',
      );
      _recordFeedMotorSignal(
        name: 'reservoir_stage_ready',
        status: 'ok',
        reason: reason,
        metadata: <String, dynamic>{
          'target': targetLimit,
          'fetched': page.items.length,
          'planned': _plannedColdFeedWindow.length,
          'nextTypesensePage': page.nextTypesensePage ?? 0,
          'usesPrimaryFeed': page.usesPrimaryFeed,
          'itemsPreplanned': page.itemsPreplanned,
        },
      );
      _maybeTriggerFeedGrowthAfterReservoirReady(reason: reason);
    } catch (error) {
      debugPrint(
        '[FeedTypesenseStageWarm] status=failed reason=$reason '
        'target=$targetLimit error=$error',
      );
      _recordFeedMotorSignal(
        name: 'reservoir_stage_failed',
        status: 'error',
        reason: reason,
        metadata: <String, dynamic>{
          'target': targetLimit,
          'error': error.toString(),
        },
      );
    } finally {
      if (_plannedColdFeedWindow.length < targetLimit &&
          _connectedFeedReservoirWarmTarget == targetLimit) {
        _connectedFeedReservoirWarmTarget = _plannedColdFeedWindow.length;
      }
      _connectedFeedReservoirWarmInFlight = false;
    }
  }

  void _maybeTriggerFeedGrowthAfterReservoirReady({required String reason}) {
    if (isClosed ||
        agendaList.isEmpty ||
        isLoading.value ||
        !hasMore.value ||
        _plannedColdFeedWindow.isEmpty) {
      return;
    }
    final centered = centeredIndex.value;
    final viewedCount =
        centered >= 0 && centered < agendaList.length ? centered + 1 : 0;
    if (viewedCount < _nextPageFetchTriggerCount) return;
    final triggerCount = _nextPageFetchTriggerCount;
    debugPrint(
      '[FeedFetchTrigger] source=reservoir_ready '
      'reason=$reason viewedCount=$viewedCount '
      'currentCount=${agendaList.length} '
      'planned=${_plannedColdFeedWindow.length} '
      'triggerCount=$triggerCount',
    );
    _recordFeedMotorSignal(
      name: 'reservoir_growth_trigger',
      status: 'ok',
      reason: reason,
      metadata: <String, dynamic>{
        'viewedCount': viewedCount,
        'currentCount': agendaList.length,
        'planned': _plannedColdFeedWindow.length,
        'triggerCount': triggerCount,
      },
    );
    _advanceFeedPageFetchTrigger(viewedCount);
    fetchAgendaBigData(
      pageLimit: ReadBudgetRegistry.feedPageFetchLimit,
      trigger: 'reservoir_ready',
    );
  }

  Future<void> _warmConnectedColdFeedReservoir({
    required int nowMs,
    required int cutoffMs,
    required List<PostsModel> seedPosts,
    required List<PostsModel> fetchedPosts,
    required DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    required int? nextTypesensePage,
    required bool usesPrimaryFeed,
    required int visibleCount,
  }) async {
    if (!ContentPolicy.isConnected || seedPosts.isEmpty) return;

    await _hydratePlannedColdFeedWindowFromWarmCache();
    final planningSeedPosts = _plannedColdFeedWindow.isNotEmpty
        ? _plannedColdFeedWindow.toList(growable: false)
        : seedPosts;
    final targetLimit = _connectedColdFeedStageThreeLimit;
    if (_plannedColdFeedWindow.length >= targetLimit) {
      return;
    }

    if (fetchedPosts.isNotEmpty) {
      await _storeColdFeedPlanWindow(
        seedPosts: planningSeedPosts,
        fetchedPosts: fetchedPosts,
        lastDoc: lastDoc,
        nextTypesensePage: nextTypesensePage,
        usesPrimaryFeed: usesPrimaryFeed,
        targetLimit: targetLimit,
        logLabel: 'FeedColdPlan',
      );
    }

    if (_plannedColdFeedWindow.length >= targetLimit) {
      return;
    }

    await _primeColdFeedPlanWindow(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      seedPosts: planningSeedPosts,
      targetLimit: targetLimit,
      existingFetchedPosts: fetchedPosts,
      startAfter: lastDoc,
      nextTypesensePage: nextTypesensePage,
      usesPrimaryFeed: usesPrimaryFeed,
    );
  }

  Future<void> _hydratePlannedColdFeedWindowFromWarmCache() async {
    if (_plannedColdFeedWindow.isNotEmpty) return;
    if (ContentPolicy.isConnected) {
      return;
    }
    final userId = CurrentUserService.instance.effectiveUserId;
    if (userId.isEmpty) return;
    final warm = await _feedSnapshotRepository.inspectWarmHome(
      userId: userId,
      limit: _connectedColdFeedStageThreeLimit,
    );
    final cached = _dedupeColdPlanPosts(warm.data ?? const <PostsModel>[]);
    if (cached.length <= FeedSnapshotRepository.startupHomeLimitValue) {
      return;
    }
    _plannedColdFeedWindow
      ..clear()
      ..addAll(cached.take(_connectedColdFeedStageThreeLimit));
    _plannedColdFeedLastDoc = null;
    _plannedColdFeedUsesPrimaryFeed = true;
    _plannedColdFeedNextTypesensePage = null;
    debugPrint(
      '[FeedColdPlanCache] hydrated planned=${_plannedColdFeedWindow.length}',
    );
  }

  Future<void> _storeColdFeedPlanWindow({
    required List<PostsModel> seedPosts,
    required List<PostsModel> fetchedPosts,
    required DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    required int? nextTypesensePage,
    required bool usesPrimaryFeed,
    required int targetLimit,
    required String logLabel,
  }) async {
    final combined = <PostsModel>[];
    final seenDocIds = <String>{};
    for (final post in <PostsModel>[...seedPosts, ...fetchedPosts]) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenDocIds.add(docId)) {
        continue;
      }
      combined.add(post);
    }

    if (combined.isEmpty) {
      return;
    }

    combined.sort((left, right) => right.timeStamp.compareTo(left.timeStamp));
    final diversityMemory = FeedDiversityMemoryService.ensure();
    await diversityMemory.ensureReady();
    final recentHeadDocIds = diversityMemory.startupHeadPenaltyDocIds();
    final recentHeadFloodRootIds =
        diversityMemory.startupHeadPenaltyFloodRootIds();
    final coldWindow = _buildColdFeedPlanWindow(
      combined,
      seedPosts: seedPosts,
      targetLimit: targetLimit,
      recentHeadDocIds: recentHeadDocIds,
      recentHeadFloodRootIds: recentHeadFloodRootIds,
    );

    _plannedColdFeedWindow
      ..clear()
      ..addAll(coldWindow);
    _plannedColdFeedLastDoc = lastDoc;
    _plannedColdFeedUsesPrimaryFeed = usesPrimaryFeed;
    _plannedColdFeedNextTypesensePage = nextTypesensePage;

    diversityMemory.rememberStartupHead(
      coldWindow,
      limit: targetLimit,
    );

    debugPrint(
      '[$logLabel] target=$targetLimit planned=${coldWindow.length} '
      'seeded=${seedPosts.length} fetched=${fetchedPosts.length} '
      'candidateFetch=${min(combined.length, _connectedColdFeedCandidateFetchLimitForTarget(targetLimit))}',
    );
  }

  List<PostsModel> _buildColdFeedPlanWindow(
    List<PostsModel> combined, {
    required List<PostsModel> seedPosts,
    required int targetLimit,
    required Set<String> recentHeadDocIds,
    required Set<String> recentHeadFloodRootIds,
  }) {
    if (combined.isEmpty || targetLimit <= 0) {
      return const <PostsModel>[];
    }

    final fresh = <PostsModel>[];
    final repeated = <PostsModel>[];
    for (final post in combined) {
      if (_isRecentStartupHeadPost(
        post,
        recentHeadDocIds: recentHeadDocIds,
        recentHeadFloodRootIds: recentHeadFloodRootIds,
      )) {
        repeated.add(post);
      } else {
        fresh.add(post);
      }
    }

    final seededHead = _dedupeColdPlanPosts(seedPosts)
        .take(targetLimit)
        .toList(growable: false);
    final output = <PostsModel>[...seededHead];
    final usedIds = <String>{
      for (final post in seededHead)
        if (post.docID.trim().isNotEmpty) post.docID.trim(),
    };
    bool appendPlannedPosts(Iterable<PostsModel> posts, {required int limit}) {
      if (limit <= 0) {
        return false;
      }
      var remainingLimit = limit;
      var added = false;
      for (final post in posts) {
        if (output.length >= targetLimit || remainingLimit <= 0) {
          break;
        }
        final docId = post.docID.trim();
        if (docId.isEmpty || !usedIds.add(docId)) {
          continue;
        }
        output.add(post);
        added = true;
        remainingLimit--;
        if (remainingLimit <= 0) {
          break;
        }
      }
      return added;
    }

    final blockSize = FeedRenderBlockPlan.postSlotsPerBlock;
    while (output.length < targetLimit) {
      final partialBlockRemainder = output.length % blockSize;
      final fillingPartialBlock = partialBlockRemainder != 0;
      final nextBlockSize = partialBlockRemainder == 0
          ? blockSize
          : blockSize - partialBlockRemainder;
      final blockTarget = min(nextBlockSize, targetLimit - output.length);
      final plannedBlock = _planStrictColdFeedBlock(
        fresh: fresh,
        repeated: repeated,
        usedIds: usedIds,
        currentItemCount: output.length,
        blockTarget: blockTarget,
      );
      if (plannedBlock.length < blockTarget) {
        appendPlannedPosts(plannedBlock, limit: plannedBlock.length);
        final remainingBlockTarget = min(
          blockTarget - plannedBlock.length,
          targetLimit - output.length,
        );
        final sparseFallback = _takeColdPlanCandidates(
          fresh: fresh,
          repeated: repeated,
          usedIds: usedIds,
          limit: fresh.length + repeated.length,
        ).take(remainingBlockTarget).toList(growable: false);
        final filledRemainder = appendPlannedPosts(
          sparseFallback,
          limit: remainingBlockTarget,
        );
        if (filledRemainder || plannedBlock.isNotEmpty) {
          continue;
        }
        if (fillingPartialBlock) {
          final partialFallback = _takeColdPlanCandidates(
            fresh: fresh,
            repeated: repeated,
            usedIds: usedIds,
            limit: fresh.length + repeated.length,
          ).take(blockTarget).toList(growable: false);
          if (appendPlannedPosts(partialFallback, limit: blockTarget)) {
            continue;
          }
        }
        break;
      }
      appendPlannedPosts(plannedBlock, limit: blockTarget);
    }

    return output.take(targetLimit).toList(growable: false);
  }

  List<PostsModel> _dedupeColdPlanPosts(List<PostsModel> posts) {
    final seenIds = <String>{};
    final output = <PostsModel>[];
    for (final post in posts) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenIds.add(docId)) {
        continue;
      }
      output.add(post);
    }
    return output;
  }

  List<PostsModel> _planStrictColdFeedBlock({
    required List<PostsModel> fresh,
    required List<PostsModel> repeated,
    required Set<String> usedIds,
    required int currentItemCount,
    required int blockTarget,
  }) {
    if (blockTarget <= 0) {
      return const <PostsModel>[];
    }

    final remainingCount = fresh.length + repeated.length - usedIds.length;
    if (remainingCount <= 0) {
      return const <PostsModel>[];
    }

    final poolLimits = <int>{
      max(blockTarget * 8, ReadBudgetRegistry.feedPersistSnapshotLimit),
      max(blockTarget * 12, ReadBudgetRegistry.feedPersistSnapshotLimit * 2),
      max(blockTarget * 16, ReadBudgetRegistry.feedPersistSnapshotLimit * 3),
      remainingCount,
    }.where((value) => value > 0).toList(growable: false)
      ..sort();

    List<PostsModel> best = const <PostsModel>[];
    var bestScore = -1 << 20;
    final requiredImageMatches = _coldPlanImageTargetCount(
      currentItemCount: currentItemCount,
      blockTarget: blockTarget,
    );
    for (final limit in poolLimits) {
      final candidatePool = _takeColdPlanCandidates(
        fresh: fresh,
        repeated: repeated,
        usedIds: usedIds,
        limit: limit,
      );
      if (candidatePool.isEmpty) {
        break;
      }

      final plannedBlock = _agendaFeedApplicationService.buildPlannerSlice(
        candidatePool,
        currentItemCount: currentItemCount,
        targetCount: blockTarget,
        includeStartupHeadPenalty: false,
        allowSparseSlotFallback: false,
        emitLaunchMotorDiagnostics: false,
      );
      final score = _scoreColdPlanBlock(
        plannedBlock,
        currentItemCount: currentItemCount,
      );
      final shouldPromote = plannedBlock.length > best.length ||
          (plannedBlock.length == best.length && score > bestScore);
      if (shouldPromote) {
        best = plannedBlock;
        bestScore = score;
      }
      if (plannedBlock.length >= blockTarget &&
          _coldPlanImageMatchCount(
                plannedBlock,
                currentItemCount: currentItemCount,
              ) >=
              requiredImageMatches) {
        return plannedBlock.take(blockTarget).toList(growable: false);
      }
    }

    if (best.length < blockTarget) {
      final rescuePool = _takeColdPlanCandidates(
        fresh: fresh,
        repeated: repeated,
        usedIds: usedIds,
        limit: remainingCount,
      );
      if (rescuePool.isNotEmpty) {
        final rescueBlock = _agendaFeedApplicationService.buildPlannerSlice(
          rescuePool,
          currentItemCount: currentItemCount,
          targetCount: blockTarget,
          includeStartupHeadPenalty: false,
          allowSparseSlotFallback: true,
          emitLaunchMotorDiagnostics: false,
        );
        if (rescueBlock.length > best.length) {
          best = rescueBlock.take(blockTarget).toList(growable: false);
        }
      }
    }

    return best;
  }

  int _scoreColdPlanBlock(
    List<PostsModel> plannedBlock, {
    required int currentItemCount,
  }) {
    if (plannedBlock.isEmpty) return -1 << 20;
    var score = plannedBlock.length * 100;
    for (var index = 0; index < plannedBlock.length; index++) {
      final desiredBucket = FeedRenderBlockPlan.postSlotPlan[
          (currentItemCount + index) % FeedRenderBlockPlan.postSlotPlan.length];
      final actualBucket = _coldPlanBucketForPost(plannedBlock[index]);
      switch (desiredBucket) {
        case FeedPlannerPostBucket.image:
          if (actualBucket == FeedPlannerPostBucket.image) {
            score += 1000;
          } else if (actualBucket == FeedPlannerPostBucket.flood) {
            score -= 250;
          }
          break;
        case FeedPlannerPostBucket.flood:
          if (actualBucket == FeedPlannerPostBucket.flood) {
            score += 200;
          }
          break;
        case FeedPlannerPostBucket.text:
          if (actualBucket == FeedPlannerPostBucket.text) {
            score += 80;
          } else if (actualBucket == FeedPlannerPostBucket.live) {
            score += 40;
          }
          break;
        case FeedPlannerPostBucket.live:
        case FeedPlannerPostBucket.cache:
          if (actualBucket == FeedPlannerPostBucket.live ||
              actualBucket == FeedPlannerPostBucket.cache) {
            score += 20;
          }
          break;
      }
    }
    return score;
  }

  int _coldPlanImageTargetCount({
    required int currentItemCount,
    required int blockTarget,
  }) {
    var count = 0;
    for (var index = 0; index < blockTarget; index++) {
      final desiredBucket = FeedRenderBlockPlan.postSlotPlan[
          (currentItemCount + index) % FeedRenderBlockPlan.postSlotPlan.length];
      if (desiredBucket == FeedPlannerPostBucket.image) {
        count++;
      }
    }
    return count;
  }

  int _coldPlanImageMatchCount(
    List<PostsModel> plannedBlock, {
    required int currentItemCount,
  }) {
    var count = 0;
    for (var index = 0; index < plannedBlock.length; index++) {
      final desiredBucket = FeedRenderBlockPlan.postSlotPlan[
          (currentItemCount + index) % FeedRenderBlockPlan.postSlotPlan.length];
      if (desiredBucket != FeedPlannerPostBucket.image) {
        continue;
      }
      if (_coldPlanBucketForPost(plannedBlock[index]) ==
          FeedPlannerPostBucket.image) {
        count++;
      }
    }
    return count;
  }

  FeedPlannerPostBucket _coldPlanBucketForPost(PostsModel post) {
    if (post.isFloodSeriesContent) {
      return FeedPlannerPostBucket.flood;
    }
    if (post.hasPlayableVideo) {
      return FeedPlannerPostBucket.live;
    }
    final hasImage = post.hasImageContent || post.thumbnail.trim().isNotEmpty;
    final hasText = post.hasTextContent;
    if (hasImage) {
      return FeedPlannerPostBucket.image;
    }
    if (hasText) {
      return FeedPlannerPostBucket.text;
    }
    return FeedPlannerPostBucket.live;
  }

  List<PostsModel> _takeColdPlanCandidates({
    required List<PostsModel> fresh,
    required List<PostsModel> repeated,
    required Set<String> usedIds,
    required int limit,
  }) {
    if (limit <= 0) {
      return const <PostsModel>[];
    }

    final candidates = <PostsModel>[];
    void appendFrom(List<PostsModel> source) {
      for (final post in source) {
        if (candidates.length >= limit) {
          return;
        }
        final docId = post.docID.trim();
        if (docId.isEmpty || usedIds.contains(docId)) {
          continue;
        }
        candidates.add(post);
      }
    }

    appendFrom(fresh);
    appendFrom(repeated);
    return candidates;
  }

  bool _isRecentStartupHeadPost(
    PostsModel post, {
    required Set<String> recentHeadDocIds,
    required Set<String> recentHeadFloodRootIds,
  }) {
    final docId = post.docID.trim();
    if (docId.isNotEmpty && recentHeadDocIds.contains(docId)) {
      return true;
    }
    final floodRootId = _resolveColdPlanFloodRootId(post);
    if (floodRootId.isNotEmpty &&
        recentHeadFloodRootIds.contains(floodRootId)) {
      return true;
    }
    return false;
  }

  String _resolveColdPlanFloodRootId(PostsModel post) {
    if (!post.isFloodSeriesContent) {
      return '';
    }
    final mainFlood = post.mainFlood.trim();
    if (mainFlood.isNotEmpty) {
      return mainFlood;
    }
    if (post.isFloodSeriesRoot) {
      return post.docID.trim();
    }
    return post.docID.trim().replaceFirst(RegExp(r'_\d+$'), '');
  }

  _AgendaSourcePage? _loadPlannedColdFeedPage({
    required List<PostsModel> currentAgenda,
    required int limit,
  }) {
    if (_plannedColdFeedWindow.isEmpty || limit <= 0) {
      return null;
    }
    final currentDocIds = <String>{
      for (final post in currentAgenda)
        if (post.docID.trim().isNotEmpty) post.docID.trim(),
    };
    final remaining = _plannedColdFeedWindow.where((post) {
      final docId = post.docID.trim();
      return docId.isNotEmpty && !currentDocIds.contains(docId);
    }).toList(growable: false);
    if (remaining.isEmpty) {
      return null;
    }
    return _AgendaSourcePage(
      remaining.take(limit).toList(growable: false),
      _plannedColdFeedLastDoc,
      _plannedColdFeedUsesPrimaryFeed,
      true,
      _plannedColdFeedNextTypesensePage,
    );
  }

  int _remainingPlannedColdFeedCount({
    required Set<String> seenDocIds,
  }) {
    if (_plannedColdFeedWindow.isEmpty) return 0;
    var count = 0;
    for (final post in _plannedColdFeedWindow) {
      final docId = post.docID.trim();
      if (docId.isEmpty || seenDocIds.contains(docId)) {
        continue;
      }
      count++;
    }
    return count;
  }

  Future<bool> _awaitFeedAuthReadiness() async {
    final currentUser = CurrentUserService.instance;
    if (!currentUser.hasAuthUser ||
        currentUser.effectiveUserId.trim().isEmpty) {
      _lastFeedAuthUnavailableAt = null;
      return true;
    }
    if (currentUser.effectiveUserId.trim().isNotEmpty) {
      _lastFeedAuthUnavailableAt = null;
      return true;
    }
    final now = DateTime.now();
    final lastUnavailableAt = _lastFeedAuthUnavailableAt;
    if (lastUnavailableAt != null &&
        now.difference(lastUnavailableAt) < const Duration(seconds: 2)) {
      return false;
    }
    try {
      await currentUser.ensureAuthReady(
        waitForAuthState: true,
        timeout: const Duration(seconds: 2),
        recordTimeoutFailure: false,
      );
    } catch (_) {}
    final authReady = currentUser.hasAuthUser &&
        currentUser.effectiveUserId.trim().isNotEmpty;
    _lastFeedAuthUnavailableAt = authReady ? null : now;
    return authReady;
  }

  Future<void> ensureInitialFeedLoaded() async {
    if (agendaList.isNotEmpty && _startupHeadFinalized) {
      return;
    }
    final inFlight = _ensureInitialLoadFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    if (isLoading.value || _ensureInitialLoadInFlight) {
      return;
    }

    _ensureInitialLoadInFlight = true;
    Future<void>? future;
    try {
      final authReady = await _awaitFeedAuthReadiness();
      if (!authReady) {
        _scheduleDeferredInitialNetworkBootstrap(
          reason: 'auth_not_ready_retry',
          allowEmptyAgenda: true,
        );
        return;
      }
      final now = DateTime.now();
      if (_lastEnsureInitialLoadAt != null &&
          now.difference(_lastEnsureInitialLoadAt!) <
              const Duration(seconds: 2)) {
        return;
      }
      _lastEnsureInitialLoadAt = now;
      final expectedMutationEpoch = _feedMutationEpoch;
      future = _dispatchFeedBootstrapRequest(
        initial: true,
        trigger: 'ensure_initial_load',
        expectedMutationEpoch: expectedMutationEpoch,
      );
      _ensureInitialLoadFuture = future;
      await future;
    } finally {
      _ensureInitialLoadInFlight = false;
      if (future != null && identical(_ensureInitialLoadFuture, future)) {
        _ensureInitialLoadFuture = null;
      }
    }
  }

  Future<void> ensureFeedSurfaceReady({
    bool preferSynchronousConnectedLoad = false,
  }) async {
    final inFlight = _surfaceBootstrapFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    final future = _performEnsureFeedSurfaceReady(
      preferSynchronousConnectedLoad: preferSynchronousConnectedLoad,
    );
    _surfaceBootstrapFuture = future;
    try {
      await future;
    } finally {
      if (identical(_surfaceBootstrapFuture, future)) {
        _surfaceBootstrapFuture = null;
      }
    }
  }

  Future<void> _performEnsureFeedSurfaceReady({
    required bool preferSynchronousConnectedLoad,
  }) async {
    final connectedStartup = ContentPolicy.isConnected;
    if (agendaList.isEmpty && !isLoading.value) {
      debugPrint(
        '[FeedStartupSurface] status=skip_feed_cache_hydrate_live_only '
        'connected=$connectedStartup',
      );
    }

    if (agendaList.isNotEmpty) {
      if (connectedStartup &&
          !_startupHeadFinalized &&
          !isLoading.value &&
          !_ensureInitialLoadInFlight) {
        if (_startupPlannerHeadApplied) {
          _scheduleDeferredInitialNetworkBootstrap(
            reason: 'connected_seed_existing_agenda',
          );
        } else {
          debugPrint(
            '[FeedStartupSurface] status=kick_live_finalize_from_existing_agenda '
            'agendaCount=${agendaList.length}',
          );
          unawaited(ensureInitialFeedLoaded());
        }
      }
      await _profileFeedStartupSurfaceStep('prepare_surface_after_data_ready',
          () async {
        _prepareFeedSurfaceAfterDataReady(
          playbackBootstrapSource: 'ensure_feed_surface_ready',
        );
      });
      return;
    }

    if (!isLoading.value) {
      if (connectedStartup) {
        await _profileFeedStartupSurfaceStep(
          'connected_seed_disabled',
          _seedConnectedStartupHeadFromShard,
        );
        if (preferSynchronousConnectedLoad) {
          await _profileFeedStartupSurfaceStep(
            'ensure_initial_feed_loaded_connected',
            () => ensureInitialFeedLoaded(),
          );
          if (agendaList.isNotEmpty) {
            await _profileFeedStartupSurfaceStep(
              'prepare_surface_after_connected_network_load',
              () async {
                _prepareFeedSurfaceAfterDataReady(
                  playbackBootstrapSource:
                      'ensure_feed_surface_ready_connected_network_load',
                );
              },
            );
          }
          return;
        }
        debugPrint(
          '[FeedStartupSurface] status=defer_connected_initial_load '
          'agendaEmpty=${agendaList.isEmpty}',
        );
        unawaited(
          ensureInitialFeedLoaded(),
        );
        return;
      }
      await _profileFeedStartupSurfaceStep('ensure_initial_feed_loaded', () {
        return ensureInitialFeedLoaded();
      });
      await _profileFeedStartupSurfaceStep('prepare_surface_after_network_load',
          () async {
        _prepareFeedSurfaceAfterDataReady(
          playbackBootstrapSource: 'ensure_feed_surface_ready_after_load',
        );
      });
    }
  }

  Future<void> refreshAgenda({
    bool forceNewLaunchSession = false,
  }) async {
    final refreshEpoch = _feedMutationEpoch + 1;
    _feedMutationEpoch = refreshEpoch;
    try {
      if (forceNewLaunchSession) {
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
      _cancelStartupWarmPlayerPreload();
      _startupRenderBootstrapHold = false;
      _resetFeedPageFetchTrigger();
      _cancelDeferredInitialNetworkBootstrap();
      _pendingCenteredDocId = null;
      _startupLockedFeedDocId = null;
      _startupPlaybackLockedAt = null;
      _lastPlaybackCommandDocId = null;
      _lastPlaybackCommandAt = null;

      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }

      // Following/reshare verilerini yenile (SWR)
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isNotEmpty) unawaited(_fetchFollowingAndReshares(uid));

      await _refreshAgendaFromLiveSource(
        refreshEpoch: refreshEpoch,
        forceNewLaunchSession: forceNewLaunchSession,
      );
      _feedRefreshInFlight = false;
      _resumeFeedPlaybackAfterRefresh(expectedEpoch: refreshEpoch);
      unawaited(Future<void>(() async {
        try {
          await _fetchAndMergeReshareEvents(
            eventLimit: ReadBudgetRegistry.reshareFeedWarmupInitialLimit,
          );
        } catch (_) {}
      }));
    } catch (e) {
      print("refreshAgenda error: $e");
      _feedRefreshInFlight = false;
      _resumeFeedPlaybackAfterRefresh(expectedEpoch: refreshEpoch);
    }
  }

  Future<void> refreshAgendaFromUserAction() {
    return refreshAgenda(forceNewLaunchSession: true);
  }

  Future<void> _refreshAgendaFromLiveSource({
    required int refreshEpoch,
    bool forceNewLaunchSession = false,
  }) async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final previousAgenda = agendaList.toList(growable: false);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      final loadLimit = forceNewLaunchSession
          ? _connectedInitialCandidateFetchLimit
          : _refreshPlannerMergeLimit;
      final page = await _loadAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: loadLimit,
        startAfter: null,
        useStoredCursor: false,
        preferCache: false,
        cacheOnly: false,
        usePrimaryFeedPaging: true,
      );
      if (page.items.isEmpty) {
        _recordFeedMotorSignal(
          name: 'refresh_empty_page',
          status: previousAgenda.isEmpty ? 'ok' : 'warn',
          reason: 'refresh',
          metadata: <String, dynamic>{
            'previousCount': previousAgenda.length,
            'refreshEpoch': refreshEpoch,
            'usesPrimaryFeed': page.usesPrimaryFeed,
            'itemsPreplanned': page.itemsPreplanned,
            'nextTypesensePage': page.nextTypesensePage ?? 0,
          },
        );
        return;
      }

      final pageApplyPlan = _agendaFeedApplicationService.buildPageApplyPlan(
        currentItems: previousAgenda,
        pageItems: page.items,
        nowMs: nowMs,
        loadLimit: loadLimit,
        lastDoc: page.lastDoc,
        hasMore: FeedTypesensePagingContract.resolveTopUpHasMore(
          itemCount: page.items.length,
          lastDoc: page.lastDoc,
          nextTypesensePage: page.nextTypesensePage,
        ),
        usesPrimaryFeed: page.usesPrimaryFeed,
        pageItemsPreplanned: page.itemsPreplanned,
      );
      final refreshPlan = _agendaFeedApplicationService.buildRefreshPlan(
        currentItems: previousAgenda,
        fetchedPosts: page.items,
        nowMs: nowMs,
      );
      final mergedAgenda = forceNewLaunchSession
          ? refreshPlan.replacementItems
          : _agendaFeedApplicationService.mergeLiveItemsPreservingCurrentOrder(
              currentItems: previousAgenda,
              liveItems: page.items,
              liveItemsPreplanned: page.itemsPreplanned,
            );
      final refreshTargetIndex = mergedAgenda.indexWhere(
        (post) => _canAutoplayVideoPost(post),
      );
      final refreshTargetDocId =
          refreshTargetIndex >= 0 && refreshTargetIndex < mergedAgenda.length
              ? mergedAgenda[refreshTargetIndex].docID
              : (mergedAgenda.isNotEmpty ? mergedAgenda.first.docID : null);

      _usePrimaryFeedPaging = pageApplyPlan.usesPrimaryFeed;
      lastDoc = pageApplyPlan.lastDoc;
      _feedTypesenseNextPage = page.nextTypesensePage;
      hasMore.value = FeedTypesensePagingContract.resolveTopUpHasMore(
        itemCount: pageApplyPlan.itemsToAdd.length,
        lastDoc: pageApplyPlan.lastDoc,
        nextTypesensePage: page.nextTypesensePage,
      );
      _reconcileFeedPageFetchTriggerToCurrentRunway(
        reason: forceNewLaunchSession ? 'refresh_reset' : 'refresh_merge',
      );
      if (hasMore.value) {
        _maybeTriggerDeferredFeedGrowth(
          reason: forceNewLaunchSession ? 'refresh_reset' : 'refresh_merge',
        );
      }
      _feedRefreshInFlight = true;
      _applyRefreshMergedAgenda(
        mergedAgenda: mergedAgenda,
      );
      if (refreshEpoch == _feedMutationEpoch) {
        _pendingCenteredDocId = refreshTargetDocId;
        _startupLockedFeedDocId = refreshTargetDocId;
        _startupPlaybackLockedAt =
            refreshTargetDocId == null ? null : DateTime.now();
        _lastPlaybackCommandDocId = null;
        _lastPlaybackCommandAt = null;
        _visibleFractions.clear();
        _visibleUpdatedAt.clear();
        _lastPlaybackWindowSignature = null;
        _lastPlaybackRowUpdateDocId = null;
        lastCenteredIndex = refreshTargetIndex >= 0 ? refreshTargetIndex : 0;
        centeredIndex.value = refreshTargetIndex >= 0 ? refreshTargetIndex : -1;
      }

      if (refreshPlan.freshScheduledIds.isNotEmpty) {
        markHighlighted(
          refreshPlan.freshScheduledIds,
          keepFor: const Duration(milliseconds: 900),
        );
      }

      _scheduleInitialFeedVideoPosterWarmup(
        _initialVisibleVideoWarmupWindow(mergedAgenda),
      );

      if (agendaList.isNotEmpty && pageApplyPlan.itemsToAdd.isNotEmpty) {
        _scheduleReshareFetchForPosts(
          pageApplyPlan.itemsToAdd,
          perPostLimit: 1,
        );
      }
    } finally {
      isLoading.value = false;
      _scheduleFeedManifestWindowSync(reason: 'refresh_complete');
    }
  }
}
