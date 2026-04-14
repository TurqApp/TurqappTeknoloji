part of 'agenda_controller.dart';

extension AgendaControllerLoadingPart on AgendaController {
  static const int _connectedColdFeedStageOneLimit = 60;
  static const int _connectedColdFeedStageThreeLimit = 180;
  static const int _connectedColdFeedPrimeBatchFloor = 60;
  static const int _connectedInitialCandidateFetchFloor = 45;

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

  Future<void> _warmInitialFeedVideoPosters(List<PostsModel> posts) async {
    final videoPosts = posts
        .where((post) => post.hasRenderableVideoCard)
        .toList(growable: false);
    if (videoPosts.isEmpty) return;

    final priorityPosts = videoPosts.take(5).toList(growable: false);
    final deferredPosts = videoPosts.skip(priorityPosts.length).toList(
          growable: false,
        );

    await Future.wait(
      priorityPosts.map(_warmFeedPosterForPost),
      eagerError: false,
    );

    if (deferredPosts.isNotEmpty) {
      unawaited(
        Future.wait(
          deferredPosts.map(_warmFeedPosterForPost),
          eagerError: false,
        ),
      );
    }
  }

  Future<void> _warmFeedPosterForPost(PostsModel post) async {
    for (final url in post.preferredVideoPosterUrls) {
      if (url.trim().isEmpty) continue;
      try {
        await TurqImageCacheManager.warmUrl(url)
            .timeout(const Duration(seconds: 2));
        return;
      } catch (_) {}
    }
  }

  void _scheduleInitialFeedVideoPosterWarmup(List<PostsModel> posts) {
    if (posts.isEmpty) return;
    unawaited(_warmInitialFeedVideoPosters(posts));
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

  Future<bool> _seedConnectedStartupHeadFromShard() async {
    if (!ContentPolicy.isConnected ||
        agendaList.isNotEmpty ||
        isLoading.value) {
      return false;
    }
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return false;
    final startupCandidates =
        await _feedSnapshotRepository.inspectHomeStartupShard(
      userId: userId,
      limit: FeedSnapshotRepository.startupHomeLimitValue,
    );
    if (startupCandidates.isEmpty) {
      debugPrint(
        '[FeedStartupSurface] status=connected_startup_shard_empty',
      );
      return _seedConnectedStartupHeadFromLocalFallback(
        reason: 'connected_startup_local_fallback',
      );
    }
    final startupItems = _buildStartupPlannerHead(
      cacheCandidates: startupCandidates,
      targetCount: min(
        startupCandidates.length,
        FeedSnapshotRepository.startupHomeLimitValue,
      ),
      allowSparseSlotFallback: true,
    );
    if (startupItems.isEmpty) {
      debugPrint(
        '[FeedStartupSurface] status=connected_startup_shard_no_head '
        'candidateCount=${startupCandidates.length}',
      );
      return _seedConnectedStartupHeadFromLocalFallback(
        reason: 'connected_startup_local_fallback',
      );
    }
    if (startupItems.length < 2) {
      debugPrint(
        '[FeedStartupSurface] status=connected_startup_shard_skip_single_seed '
        'composedCount=${startupItems.length}',
      );
      return false;
    }
    _startupHeadFinalized = false;
    _startupRenderBootstrapHold = true;
    _activateStartupRenderStages(
      reason: 'connected_startup_shard_seed',
    );
    debugPrint(
      '[FeedStartupPlanner] source=connected_startup_shard '
      'status=apply_seeded_startup_items '
      'rawCount=${startupCandidates.length} composedCount=${startupItems.length}',
    );
    _replaceAgendaState(
      startupItems,
      reason: 'connected_startup_shard_seed',
    );
    _applyStartupRenderStagesNow();
    _scheduleInitialFeedVideoPosterWarmup(startupItems);
    _scheduleReshareFetchForPosts(
      startupItems,
      perPostLimit: 1,
    );
    return true;
  }

  Future<bool> _seedConnectedStartupHeadFromLocalFallback({
    required String reason,
  }) async {
    if (!ContentPolicy.isConnected || agendaList.isNotEmpty || isClosed) {
      return false;
    }
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return false;

    final mergedById = <String, PostsModel>{};

    void addCandidates(Iterable<PostsModel> posts) {
      for (final post in posts) {
        final docId = post.docID.trim();
        if (docId.isEmpty) continue;
        mergedById.putIfAbsent(docId, () => post);
      }
    }

    try {
      final shard = await _feedSnapshotRepository.inspectHomeStartupShard(
        userId: userId,
        limit: FeedSnapshotRepository.startupHomeLimitValue,
      );
      addCandidates(shard);
    } catch (_) {}

    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      final cachePage = await _loadAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: FeedSnapshotRepository.startupHomeLimitValue,
        useStoredCursor: false,
        preferCache: true,
        cacheOnly: true,
        includeSupplementalSources: true,
      );
      addCandidates(cachePage.items);
    } catch (_) {}

    try {
      final warmHome = await _feedSnapshotRepository.inspectWarmHome(
        userId: userId,
        limit: FeedSnapshotRepository.startupHomeLimitValue,
      );
      addCandidates(warmHome.data ?? const <PostsModel>[]);
    } catch (_) {}

    if (mergedById.isEmpty) {
      debugPrint(
        '[FeedStartupSurface] status=${reason}_no_candidates',
      );
      return false;
    }

    final orderedCandidates = mergedById.values.toList(growable: false)
      ..sort((left, right) => right.timeStamp.compareTo(left.timeStamp));
    final startupItems = _buildStartupPlannerHead(
      cacheCandidates: orderedCandidates,
      targetCount: min(
        orderedCandidates.length,
        FeedSnapshotRepository.startupHomeLimitValue,
      ),
      allowSparseSlotFallback: true,
    );
    if (startupItems.isEmpty) {
      debugPrint(
        '[FeedStartupSurface] status=${reason}_no_head '
        'candidateCount=${orderedCandidates.length}',
      );
      return false;
    }
    if (startupItems.length < 2) {
      debugPrint(
        '[FeedStartupSurface] status=${reason}_skip_single_seed '
        'composedCount=${startupItems.length}',
      );
      return false;
    }

    _startupHeadFinalized = false;
    _startupRenderBootstrapHold = true;
    _activateStartupRenderStages(reason: reason);
    debugPrint(
      '[FeedStartupPlanner] source=$reason '
      'status=apply_seeded_startup_items '
      'rawCount=${orderedCandidates.length} composedCount=${startupItems.length}',
    );
    _replaceAgendaState(
      startupItems,
      reason: reason,
    );
    _applyStartupRenderStagesNow();
    _scheduleInitialFeedVideoPosterWarmup(startupItems);
    _scheduleReshareFetchForPosts(
      startupItems,
      perPostLimit: 1,
    );
    return true;
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

  void _cancelDeferredInitialNetworkBootstrap() {}

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

  Future<
      ({
        List<PostsModel> candidates,
        DocumentSnapshot<Map<String, dynamic>>? lastDoc,
        bool usesPrimaryFeed,
      })> _topUpConnectedLiveStartupCandidates({
    required List<PostsModel> initialCandidates,
    required int nowMs,
    required int cutoffMs,
    required int targetCount,
    required DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    required bool usesPrimaryFeed,
  }) async {
    if (initialCandidates.isEmpty || targetCount <= 0) {
      return (
        candidates: initialCandidates,
        lastDoc: lastDoc,
        usesPrimaryFeed: usesPrimaryFeed,
      );
    }

    int previewCountFor(List<PostsModel> candidates) {
      final preview = _agendaFeedApplicationService.buildStartupPlannerHead(
        liveCandidates: candidates,
        cacheCandidates: const <PostsModel>[],
        targetCount: min(candidates.length, targetCount),
        startupVariantOverride: _feedStartupVariantOverride(),
        allowSparseSlotFallback: true,
      );
      return preview.length;
    }

    final combined = initialCandidates.toList(growable: true);
    final seenIds = <String>{
      for (final post in combined)
        if (post.docID.trim().isNotEmpty) post.docID.trim(),
    };
    var resolvedLastDoc = lastDoc;
    var resolvedUsesPrimaryFeed = usesPrimaryFeed;
    var previewCount = previewCountFor(combined);
    var round = 0;

    while (previewCount < targetCount && resolvedLastDoc != null && round < 3) {
      round += 1;
      final page = await _loadAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: _connectedInitialCandidateFetchLimit,
        startAfter: resolvedLastDoc,
        useStoredCursor: false,
        preferCache: false,
        cacheOnly: false,
        usePrimaryFeedPaging: resolvedUsesPrimaryFeed,
      );
      if (page.items.isEmpty) {
        resolvedLastDoc = page.lastDoc;
        resolvedUsesPrimaryFeed = page.usesPrimaryFeed;
        break;
      }
      for (final post in page.items) {
        final docId = post.docID.trim();
        if (docId.isEmpty || !seenIds.add(docId)) {
          continue;
        }
        combined.add(post);
      }
      resolvedLastDoc = page.lastDoc;
      resolvedUsesPrimaryFeed = page.usesPrimaryFeed;
      previewCount = previewCountFor(combined);
      debugPrint(
        '[FeedStartupPlanner] source=initial_bootstrap '
        'status=topup_connected_live_candidates '
        'round=$round candidateCount=${combined.length} '
        'previewCount=$previewCount targetCount=$targetCount',
      );
    }

    return (
      candidates: combined,
      lastDoc: resolvedLastDoc,
      usesPrimaryFeed: resolvedUsesPrimaryFeed,
    );
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
    _agendaRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      _agendaRetryTimer = null;
      if (isClosed) return;
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
  }) {
    debugPrint(
      '[FeedBootstrapRequest] trigger=$trigger initial=$initial '
      'pageLimit=${pageLimit ?? 0} agendaCount=${agendaList.length}',
    );
    return fetchAgendaBigData(
      initial: initial,
      pageLimit: pageLimit,
      trigger: trigger,
    );
  }

  void _applyInitialFeedPagePlan({
    required bool initial,
    required List<PostsModel> currentAgenda,
    required List<PostsModel> visibleItems,
    required AgendaFeedPageApplyPlan pageApplyPlan,
  }) {
    if (visibleItems.isEmpty) return;

    final shouldFinalizeStartupHead = initial &&
        _shouldReplaceSeededStartupHeadOnInitialBootstrap(currentAgenda);
    if (pageApplyPlan.freshScheduledIds.isNotEmpty) {
      markHighlighted(
        pageApplyPlan.freshScheduledIds,
        keepFor: const Duration(milliseconds: 900),
      );
    }

    if (shouldFinalizeStartupHead) {
      final mergedAgenda =
          _agendaFeedApplicationService.mergeLiveItemsPreservingCurrentOrder(
        currentItems: currentAgenda,
        liveItems: visibleItems,
      );
      final nextAgenda = mergedAgenda.isNotEmpty ? mergedAgenda : visibleItems;
      debugPrint(
        '[FeedStartupPlanner] source=initial_bootstrap '
        'status=replace_seeded_head_with_live_planner '
        'currentCount=${currentAgenda.length} liveCount=${visibleItems.length} '
        'nextCount=${nextAgenda.length} '
        'currentHead=${currentAgenda.take(5).map((post) => post.docID).join(",")} '
        'liveHead=${visibleItems.take(5).map((post) => post.docID).join(",")} '
        'nextHead=${nextAgenda.take(5).map((post) => post.docID).join(",")}',
      );
      _replaceAgendaState(
        nextAgenda,
        reason: 'initial_seeded_head_merged_live_planner',
      );
      _startupHeadFinalized = true;
      _scheduleInitialFeedVideoPosterWarmup(
        _initialVisibleVideoWarmupWindow(nextAgenda),
      );
      if (pageApplyPlan.itemsToAdd.isNotEmpty) {
        _scheduleReshareFetchForPosts(
          pageApplyPlan.itemsToAdd,
          perPostLimit: 1,
        );
      }
      return;
    }

    if (pageApplyPlan.itemsToAdd.isEmpty) {
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
      _replaceAgendaState(
        startupItems,
        reason: 'initial_items_to_add',
      );
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
      _applyStartupRenderStagesNow();
      _scheduleInitialFeedVideoPosterWarmup(startupItems);
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
    _appendUniqueAgendaState(
      pageApplyPlan.itemsToAdd,
      reason: 'initial_items_append',
    );
    if (initial) {
      _applyStartupRenderStagesNow();
    }
    _scheduleInitialFeedVideoPosterWarmup(pageApplyPlan.itemsToAdd);
    _scheduleReshareFetchForPosts(
      pageApplyPlan.itemsToAdd,
      perPostLimit: 1,
    );
  }

  void _applyRefreshMergedAgenda({
    required List<PostsModel> mergedAgenda,
  }) {
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
  }) async {
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
      _usePrimaryFeedPaging = true;
      hasMore.value = true;
      _plannedColdFeedWindow.clear();
      _plannedColdFeedLastDoc = null;
      _plannedColdFeedUsesPrimaryFeed = true;
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
          ? _connectedInitialCandidateFetchLimit
          : loadLimit;
      final shouldPreferCacheOnOpen = !liveConnected;
      final seenDocIds = currentAgenda
          .map((post) => post.docID.trim())
          .where((docId) => docId.isNotEmpty)
          .toSet();
      final plannedColdPage = initial || liveConnected
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
      var effectiveUsesPrimaryFeed = _usePrimaryFeedPaging;
      var effectiveHasMore = hasMore.value;
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
      effectiveUsesPrimaryFeed = page.usesPrimaryFeed;
      effectiveHasMore = initial && liveConnected
          ? page.items.isNotEmpty || page.lastDoc != null
          : (page.lastDoc != null && page.items.length >= sourcePageLimit);

      final skipConnectedStartupSupport =
          initial && currentAgenda.isEmpty && liveConnected;
      if (skipConnectedStartupSupport) {
        debugPrint(
          '[FeedStartupSupport] status=skip_connected_live_support '
          'candidateCount=${page.items.length}',
        );
      }
      final rawPageVisibleItems = initial
          ? (skipConnectedStartupSupport
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
      var effectiveRawPageVisibleItems = rawPageVisibleItems;
      if (initial &&
          currentAgenda.isEmpty &&
          liveConnected &&
          rawPageVisibleItems.isNotEmpty) {
        final startupTargetCount = FeedSnapshotRepository.startupHomeLimitValue;
        final startupPreviewCount = _agendaFeedApplicationService
            .buildStartupPlannerHead(
              liveCandidates: rawPageVisibleItems,
              cacheCandidates: const <PostsModel>[],
              targetCount: min(rawPageVisibleItems.length, startupTargetCount),
              startupVariantOverride: _feedStartupVariantOverride(),
              allowSparseSlotFallback: true,
            )
            .length;
        if (startupPreviewCount < startupTargetCount &&
            effectiveLastDoc != null) {
          final topUp = await _topUpConnectedLiveStartupCandidates(
            initialCandidates: rawPageVisibleItems,
            nowMs: nowMs,
            cutoffMs: cutoffMs,
            targetCount: startupTargetCount,
            lastDoc: effectiveLastDoc,
            usesPrimaryFeed: effectiveUsesPrimaryFeed,
          );
          effectiveRawPageVisibleItems = topUp.candidates;
          effectiveLastDoc = topUp.lastDoc;
          effectiveUsesPrimaryFeed = topUp.usesPrimaryFeed;
          effectiveHasMore = effectiveRawPageVisibleItems.isNotEmpty ||
              effectiveLastDoc != null;
        }
      }
      final pageVisibleItems = initial &&
              currentAgenda.isEmpty &&
              effectiveRawPageVisibleItems.isNotEmpty
          ? _applyStartupPlannerHeadOrder(
              effectiveRawPageVisibleItems,
              allowSparseSlotFallback: liveConnected,
            )
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

      final pageApplyPlan = _agendaFeedApplicationService.buildPageApplyPlan(
        currentItems: agendaList.toList(growable: false),
        pageItems: visibleItems,
        nowMs: nowMs,
        loadLimit: loadLimit,
        lastDoc: effectiveLastDoc,
        usesPrimaryFeed: effectiveUsesPrimaryFeed,
        maxItemsToAdd: usesPlannedColdPage ? loadLimit : null,
        pageItemsPreplanned:
            usesPlannedColdPage || (initial && currentAgenda.isEmpty),
      );

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
            currentAgenda.length < _connectedColdFeedStageThreeLimit;
        effectiveLastDoc = _plannedColdFeedLastDoc;
        effectiveUsesPrimaryFeed = _plannedColdFeedUsesPrimaryFeed;
        effectiveHasMore = hasPlannedRemaining || canGrowConnectedPlan;
        debugPrint(
          '[FeedColdPlanApply] currentCount=${currentAgenda.length} '
          'candidateCount=${page.items.length} addCount=${pageApplyPlan.itemsToAdd.length} '
          'remaining=$remainingPlannedCount',
        );
        if (!hasPlannedRemaining) {
          _plannedColdFeedWindow.clear();
          _plannedColdFeedLastDoc = null;
          _plannedColdFeedUsesPrimaryFeed = true;
        }
      }

      _usePrimaryFeedPaging = effectiveUsesPrimaryFeed;
      lastDoc = effectiveLastDoc;

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
          usesPrimaryFeed: resolvedUsesPrimaryFeed,
          targetLimit: targetLimit,
          logLabel: 'FeedColdPlan',
        );

        if (_plannedColdFeedWindow.length >= targetLimit ||
            page.lastDoc == null ||
            page.items.length < currentBatchLimit) {
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
          usesPrimaryFeed: usesPrimaryFeed,
          visibleCount: visibleCount,
        ),
      );
    });
  }

  Future<void> _warmConnectedColdFeedReservoir({
    required int nowMs,
    required int cutoffMs,
    required List<PostsModel> seedPosts,
    required List<PostsModel> fetchedPosts,
    required DocumentSnapshot<Map<String, dynamic>>? lastDoc,
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
    debugPrint(
      '[FeedColdPlanCache] hydrated planned=${_plannedColdFeedWindow.length}',
    );
  }

  Future<void> _storeColdFeedPlanWindow({
    required List<PostsModel> seedPosts,
    required List<PostsModel> fetchedPosts,
    required DocumentSnapshot<Map<String, dynamic>>? lastDoc,
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
    final blockSize = FeedRenderBlockPlan.postSlotsPerBlock;
    while (output.length < targetLimit) {
      final blockTarget = min(blockSize, targetLimit - output.length);
      final plannedBlock = _planStrictColdFeedBlock(
        fresh: fresh,
        repeated: repeated,
        usedIds: usedIds,
        currentItemCount: output.length,
        blockTarget: blockTarget,
      );
      if (plannedBlock.length < blockTarget) {
        break;
      }
      for (final post in plannedBlock) {
        final docId = post.docID.trim();
        if (docId.isEmpty || !usedIds.add(docId)) {
          continue;
        }
        output.add(post);
        if (output.length >= targetLimit) {
          break;
        }
      }
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

    final now = DateTime.now();
    if (_lastEnsureInitialLoadAt != null &&
        now.difference(_lastEnsureInitialLoadAt!) <
            const Duration(seconds: 2)) {
      return;
    }
    _lastEnsureInitialLoadAt = now;
    _ensureInitialLoadInFlight = true;
    final future = _dispatchFeedBootstrapRequest(
      initial: true,
      trigger: 'ensure_initial_load',
    );
    _ensureInitialLoadFuture = future;
    try {
      await future;
    } finally {
      _ensureInitialLoadInFlight = false;
      if (identical(_ensureInitialLoadFuture, future)) {
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
        debugPrint(
          '[FeedStartupSurface] status=kick_live_finalize_from_seed '
          'agendaCount=${agendaList.length}',
        );
        unawaited(ensureInitialFeedLoaded());
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
        final seededFromShard = await _profileFeedStartupSurfaceStep(
          'seed_connected_startup_shard',
          _seedConnectedStartupHeadFromShard,
        );
        if (seededFromShard && agendaList.isNotEmpty) {
          if (preferSynchronousConnectedLoad) {
            await _profileFeedStartupSurfaceStep(
              'ensure_initial_feed_loaded_connected_seed',
              () => ensureInitialFeedLoaded(),
            );
            if (agendaList.isNotEmpty) {
              await _profileFeedStartupSurfaceStep(
                'prepare_surface_after_connected_seed_sync',
                () async {
                  _prepareFeedSurfaceAfterDataReady(
                    playbackBootstrapSource:
                        'ensure_feed_surface_ready_connected_seed_sync',
                  );
                },
              );
            }
            return;
          }
          debugPrint(
            '[FeedStartupSurface] status=kick_live_finalize_from_connected_seed '
            'agendaCount=${agendaList.length}',
          );
          unawaited(
            ensureInitialFeedLoaded(),
          );
          await _profileFeedStartupSurfaceStep(
            'prepare_surface_after_connected_seed',
            () async {
              _prepareFeedSurfaceAfterDataReady(
                playbackBootstrapSource:
                    'ensure_feed_surface_ready_connected_seed',
              );
            },
          );
          return;
        }
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

  Future<void> refreshAgenda() async {
    final refreshEpoch = _feedMutationEpoch + 1;
    _feedMutationEpoch = refreshEpoch;
    try {
      _resetFeedPageFetchTrigger();
      _cancelDeferredInitialNetworkBootstrap();
      _feedRefreshInFlight = true;
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

      await _refreshAgendaFromLiveSource(refreshEpoch: refreshEpoch);
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

  Future<void> _refreshAgendaFromLiveSource({
    required int refreshEpoch,
  }) async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final previousAgenda = agendaList.toList(growable: false);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      final loadLimit = _refreshPlannerMergeLimit;
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
        return;
      }

      final pageApplyPlan = _agendaFeedApplicationService.buildPageApplyPlan(
        currentItems: previousAgenda,
        pageItems: page.items,
        nowMs: nowMs,
        loadLimit: loadLimit,
        lastDoc: page.lastDoc,
        usesPrimaryFeed: page.usesPrimaryFeed,
      );
      final refreshPlan = _agendaFeedApplicationService.buildRefreshPlan(
        currentItems: previousAgenda,
        fetchedPosts: page.items,
        nowMs: nowMs,
      );
      final mergedAgenda =
          _agendaFeedApplicationService.mergeLiveItemsPreservingCurrentOrder(
        currentItems: previousAgenda,
        liveItems: page.items,
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
      hasMore.value = pageApplyPlan.hasMore;
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
        centeredIndex.value = -1;
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
    }
  }
}
