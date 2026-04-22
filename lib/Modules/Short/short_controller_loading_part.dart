part of 'short_controller.dart';

int _currentVisibleShortIndex(ShortController controller) {
  if (controller.shorts.isEmpty) return 0;
  return controller.lastIndex.value.clamp(0, controller.shorts.length - 1);
}

extension ShortControllerLoadingPart on ShortController {
  bool _isConsumedShortPostForResume(PostsModel post) {
    final docId = post.docID.trim();
    if (docId.isEmpty) return false;
    final cacheManager = maybeFindSegmentCacheManager();
    final entry = cacheManager?.getEntry(docId);
    if (entry == null) return false;
    return entry.shortConsumedAt != null;
  }

  void schedulePersistVisibleSnapshot({
    Duration delay = const Duration(milliseconds: 220),
  }) {
    _persistVisibleSnapshotTimer?.cancel();
    _persistVisibleSnapshotTimer = Timer(delay, () {
      _persistVisibleSnapshotTimer = null;
      unawaited(_persistVisibleSnapshot());
    });
  }

  Future<void> persistVisibleSnapshotNow() async {
    _persistVisibleSnapshotTimer?.cancel();
    _persistVisibleSnapshotTimer = null;
    await _persistVisibleSnapshot();
  }

  Future<ShortResumeState?> _loadPersistedResumeState() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return null;
    return ensureShortResumeStateStore().load(userId: userId);
  }

  Future<List<PostsModel>> _restorePersistedResumeQueue() async {
    final persisted = await _loadPersistedResumeState();
    if (persisted == null || persisted.remainingPosts.isEmpty) {
      return const <PostsModel>[];
    }
    final eligible = persisted.remainingPosts
        .where(_isEligibleShortPost)
        .where((post) => !_isConsumedShortPostForResume(post))
        .toList(growable: false);
    if (eligible.isEmpty) {
      return const <PostsModel>[];
    }
    final restored = await _filterVisibleShortPosts(
      eligible,
      hydrateAuthors: false,
    );
    final restoredDocIds = restored
        .take(8)
        .map((post) => post.docID)
        .where((docId) => docId.trim().isNotEmpty)
        .join(',');
    _log(
      '[ShortResumeQueue] status=restore_payload '
      'manifest=${persisted.manifestId} '
      'slot=${persisted.cursorSlotIndex} '
      'item=${persisted.cursorItemIndex} '
      'savedAtMs=${persisted.savedAtMs} '
      'remaining=${persisted.remainingPosts.length} '
      'eligible=${eligible.length} '
      'restored=${restored.length} '
      'docs=$restoredDocIds',
    );
    return restored;
  }

  Future<List<PostsModel>> _loadOfflineReadyShortPosts({
    required int limit,
  }) async {
    final cacheManager = maybeFindSegmentCacheManager();
    if (cacheManager == null || !cacheManager.isReady) {
      return const <PostsModel>[];
    }
    final rawPosts = cacheManager.getOfflineReadyPostsForShort(limit: limit);
    if (rawPosts.isEmpty) {
      return const <PostsModel>[];
    }
    final eligible =
        rawPosts.where(_isEligibleShortPost).toList(growable: false);
    if (eligible.isEmpty) {
      return const <PostsModel>[];
    }
    return _filterVisibleShortPosts(eligible);
  }

  List<PostsModel> _applyStartupShortPresentationOrder(
    List<PostsModel> posts,
  ) {
    if (_startupPresentationApplied || posts.length < 2) {
      return posts;
    }
    _startupPresentationApplied = true;
    return posts;
  }

  void _recordShortFetchEvent({
    required String stage,
    required String trigger,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    debugPrint(
      '[ShortFetchTiming] stage=$stage trigger=$trigger metadata=$metadata',
    );
    recordQALabFeedFetchEvent(
      surface: 'short',
      stage: stage,
      trigger: trigger,
      metadata: metadata,
    );
  }

  void _recordShortMotorContractSnapshot({required String reason}) {
    const expectedInitialBlock = 15;
    const expectedRunway = 9;
    const expectedStageOne = 60;
    const expectedStageTwo = 120;
    const expectedStageThree = 180;
    const expectedStageFour = 240;
    const expectedTriggerTwo = 50;
    const expectedTriggerThree = 110;
    const expectedTriggerFour = 170;
    final contract = <String, dynamic>{
      'initialBlockSize': ShortGrowthPolicy.initialBlockSize,
      'growthRunwayCount': ShortGrowthPolicy.growthRunwayCount,
      'stageOneLimit': ShortGrowthPolicy.stageOneLimit,
      'stageTwoLimit': ShortGrowthPolicy.stageTwoLimit,
      'stageThreeLimit': ShortGrowthPolicy.stageThreeLimit,
      'stageFourLimit': ShortGrowthPolicy.stageFourLimit,
      'stageTwoViewedTrigger': ShortGrowthPolicy.stageTwoViewedTrigger,
      'stageThreeViewedTrigger': ShortGrowthPolicy.stageThreeViewedTrigger,
      'stageFourViewedTrigger': ShortGrowthPolicy.stageFourViewedTrigger,
    };
    debugPrint(
      '[ShortMotorSignal] name=contract_snapshot status=ok '
      'reason=$reason metadata=$contract',
    );
    _invariantGuard.record(
      surface: 'short',
      invariantKey: 'short_motor_contract_snapshot',
      message: 'Short motor contract snapshot recorded',
      payload: <String, dynamic>{
        'reason': reason,
        ...contract,
      },
    );
    if (ShortGrowthPolicy.stageOneLimit != expectedStageOne ||
        ShortGrowthPolicy.stageTwoLimit != expectedStageTwo ||
        ShortGrowthPolicy.stageThreeLimit != expectedStageThree ||
        ShortGrowthPolicy.stageFourLimit != expectedStageFour) {
      _invariantGuard.record(
        surface: 'short',
        invariantKey: 'short_motor_stage_limits_changed',
        message: 'Short motor stage limits changed',
        payload: contract,
      );
    }
    if (ShortGrowthPolicy.stageTwoViewedTrigger != expectedTriggerTwo ||
        ShortGrowthPolicy.stageThreeViewedTrigger != expectedTriggerThree ||
        ShortGrowthPolicy.stageFourViewedTrigger != expectedTriggerFour) {
      _invariantGuard.record(
        surface: 'short',
        invariantKey: 'short_motor_stage_triggers_changed',
        message: 'Short motor stage triggers changed',
        payload: contract,
      );
    }
    if (ShortGrowthPolicy.initialBlockSize != expectedInitialBlock ||
        ShortGrowthPolicy.growthRunwayCount != expectedRunway) {
      _invariantGuard.record(
        surface: 'short',
        invariantKey: 'short_motor_growth_profile_changed',
        message: 'Short motor growth profile changed',
        payload: contract,
      );
    }
  }

  int shortMotorStageOneLimit() => ShortGrowthPolicy.stageOneLimit;

  Future<void> ensureShortMotorStageForViewedIndex(
    int viewedIndex, {
    String trigger = 'runtime',
  }) async {
    final viewedCount = viewedIndex + 1;
    final targetCount =
        ShortGrowthPolicy.targetCountForViewedCount(viewedCount);
    var stageLimit = ShortGrowthPolicy.stageOneLimit;
    var maxPages = 1;
    var stageLabel = 'stage_one';
    if (viewedCount >= ShortGrowthPolicy.stageFourViewedTrigger) {
      stageLimit = ShortGrowthPolicy.stageFourLimit;
      maxPages = 1;
      stageLabel = 'stage_four';
    } else if (viewedCount >= ShortGrowthPolicy.stageThreeViewedTrigger) {
      stageLimit = ShortGrowthPolicy.stageThreeLimit;
      maxPages = 1;
      stageLabel = 'stage_three';
    } else if (viewedCount >= ShortGrowthPolicy.stageTwoViewedTrigger) {
      stageLimit = ShortGrowthPolicy.stageTwoLimit;
      maxPages = 1;
      stageLabel = 'stage_two';
    }

    debugPrint(
      '[ShortMotorSignal] name=stage_gate status=ok '
      'reason=$trigger metadata={viewedCount: $viewedCount, targetCount: $targetCount, stageLimit: $stageLimit, currentCount: ${shorts.length}, stage: $stageLabel}',
    );
    if (shorts.length >= targetCount || isLoading.value || !hasMore.value) {
      return;
    }
    await warmStart(
      targetCount: targetCount,
      maxPages: maxPages,
    );
  }

  void _bindFollowingListener() {
    final myUid = CurrentUserService.instance.effectiveUserId;
    if (myUid.isEmpty) return;
    _state.followingSub?.cancel();
    _fetchFollowingList(myUid);
  }

  Future<void> _fetchFollowingList(String myUid) async {
    try {
      final ids = await _visibilityPolicy.loadViewerFollowingIds(
        viewerUserId: myUid,
        preferCache: true,
      );
      _followingIDs
        ..clear()
        ..addAll(ids);
    } catch (e) {
      _log('following fetch error: $e');
    }
  }

  Future<_ShortPageResult> _fetchPage({
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
    int? pageSizeOverride,
    int? minimumSelectedCountOverride,
    String trigger = 'manual',
  }) async {
    final totalStartedAt = DateTime.now();
    final effectivePageSize = pageSizeOverride ?? pageSize;
    try {
      final manifestStartedAt = DateTime.now();
      final manifestPage = await _shortManifestRepository.takeNextPage(
        pageSize: effectivePageSize,
      );
      _recordShortFetchEvent(
        stage: 'manifest_page_timing',
        trigger: trigger,
        metadata: <String, dynamic>{
          'elapsedMs':
              DateTime.now().difference(manifestStartedAt).inMilliseconds,
          'returnedCount': manifestPage.posts.length,
          'hasMore': manifestPage.hasMore,
          'manifestId': manifestPage.manifestId,
          'slotIndex': manifestPage.slotIndex,
        },
      );
      _recordShortFetchEvent(
        stage: 'fetch_page_total_timing',
        trigger: trigger,
        metadata: <String, dynamic>{
          'elapsedMs': DateTime.now().difference(totalStartedAt).inMilliseconds,
          'resultCount': manifestPage.posts.length,
          'source': 'manifest',
        },
      );
      return _ShortPageResult(
        manifestPage.posts,
        null,
        manifestPage.hasMore,
        postsPreplanned: true,
      );
    } catch (e) {
      _recordShortFetchEvent(
        stage: 'manifest_failed',
        trigger: trigger,
        metadata: <String, dynamic>{
          'error': '$e',
          'source': 'manifest',
        },
      );
      return const _ShortPageResult(
        <PostsModel>[],
        null,
        false,
        postsPreplanned: true,
      );
    }
  }

  Future<List<PostsModel>> _filterVisibleShortPosts(
    List<PostsModel> posts, {
    bool preservePresentationOrder = false,
    bool hydrateAuthors = true,
  }) async {
    if (posts.isEmpty) return const <PostsModel>[];
    if (!hydrateAuthors) {
      return posts.toList(growable: false);
    }
    final authorIds =
        posts.map((e) => e.userID).toSet().toList(growable: false);
    final userSummaries = await _fetchUserSummaries(authorIds);

    final filtered = <PostsModel>[];
    for (final p in posts) {
      final summary = userSummaries[p.userID];
      if (summary == null) {
        filtered.add(p);
        continue;
      }
      if (summary.isDeleted) {
        continue;
      }
      filtered.add(
        p.copyWith(
          authorNickname:
              p.authorNickname.isNotEmpty ? p.authorNickname : summary.nickname,
          authorDisplayName: p.authorDisplayName.isNotEmpty
              ? p.authorDisplayName
              : summary.displayName,
          authorAvatarUrl: p.authorAvatarUrl.isNotEmpty
              ? p.authorAvatarUrl
              : summary.avatarUrl,
          rozet: p.rozet.isNotEmpty ? p.rozet : summary.rozet,
        ),
      );
    }

    return filtered;
  }

  Future<void> reconcileVisibleShortSurface({
    required String trigger,
  }) async {
    if (_renderWindowFrozenOnCellular) return;
    final currentShorts = shorts.toList(growable: false);
    if (currentShorts.isEmpty) return;

    final reconciled = await _filterVisibleShortPosts(
      currentShorts,
      preservePresentationOrder: true,
    );
    if (reconciled.isEmpty || _hasSameRenderOrder(currentShorts, reconciled)) {
      return;
    }

    _recordShortFetchEvent(
      stage: 'visible_reconcile',
      trigger: trigger,
      metadata: <String, dynamic>{
        'beforeCount': currentShorts.length,
        'afterCount': reconciled.length,
      },
    );
    _replaceShorts(reconciled, remapCache: true);
    schedulePersistVisibleSnapshot();
  }

  Future<void> backgroundPreload() async {
    if (_renderWindowFrozenOnCellular) return;
    if (_isFirstVideoReady()) {
      return;
    }

    if (_backgroundPreloadFuture != null) {
      return _backgroundPreloadFuture;
    }

    _log(
        '[Shorts] 🚀 Background preload başlatılıyor (disk cache destekli)...');

    final future = _runBackgroundPreload();
    _backgroundPreloadFuture = future;

    try {
      await future;
    } finally {
      if (identical(_backgroundPreloadFuture, future)) {
        _backgroundPreloadFuture = null;
      }
    }
  }

  Future<void> _runInitialLoadOnce() {
    final inFlight = _initialLoadFuture;
    if (inFlight != null) return inFlight;

    final future = _performInitialLoad();
    _initialLoadFuture = future;
    return future.whenComplete(() {
      if (identical(_initialLoadFuture, future)) {
        _initialLoadFuture = null;
      }
    });
  }

  Future<void> _performInitialLoad() async {
    final startedAt = DateTime.now();
    debugPrint(
      '[ShortColdStart] stage=initial_load_start at=${startedAt.toIso8601String()} '
      'count=${shorts.length}',
    );
    _log(
      '[Shorts] loadInitialShorts - BAŞLADI',
    );
    _log(
      '[Shorts] Current shorts list IDs BEFORE: ${shorts.map((s) => s.docID).take(5).toList()}',
    );

    if (shorts.isEmpty || shorts.length < _initialPreloadCount) {
      final sessionMode = _resolveShortSessionSourceMode(
        reason: 'initial_load',
      );
      _log(
        '[ShortSessionSource] status=initial_load mode=${sessionMode.name} '
        'currentCount=${shorts.length}',
      );
      isLoading.value = false;
      hasMore.value = true;
      _lastDoc = null;
      clearCache();
      final resumedQueue = await _restorePersistedResumeQueue();
      if (resumedQueue.isNotEmpty) {
        _replaceShorts(
          _applyStartupShortPresentationOrder(resumedQueue),
          remapCache: true,
        );
        lastIndex.value = 0;
        _preferFreshLaunchIndex = false;
        _log(
          '[ShortResumeQueue] status=restored count=${resumedQueue.length} '
          'first=${resumedQueue.first.docID}',
        );
        unawaited(preloadRange(0, range: 0));
      } else if (sessionMode == _ShortSessionSourceMode.mobileCacheOnly) {
        final cachedPosts = await _loadOfflineReadyShortPosts(
          limit: ReadBudgetRegistry.shortHomeInitialLimitValue,
        );
        if (cachedPosts.isNotEmpty) {
          _replaceShorts(
            _applyStartupShortPresentationOrder(cachedPosts),
            remapCache: true,
          );
          _log(
            '[ShortSessionSource] status=cache_bootstrap_ok '
            'count=${cachedPosts.length}',
          );
          unawaited(preloadRange(_currentVisibleShortIndex(this), range: 0));
        } else if (_promoteShortSessionToMobileNetworkFallback(
          reason: 'initial_cache_empty',
        )) {
          _log(
            '[ShortSessionSource] status=cache_bootstrap_empty '
            'fallback=network',
          );
          await _loadNextPage(trigger: 'initial_mobile_network_fallback');
        } else {
          _log(
            '[ShortSessionSource] status=cache_bootstrap_empty '
            'fallback=blocked',
          );
        }
      } else {
        _log('[Shorts] loadInitialShorts - _loadNextPage çağrılıyor');
        await _loadNextPage(trigger: 'initial_empty_bootstrap');
      }
    } else {
      _log('[Shorts] Manifest listesi mevcut - sıralama korunuyor');
      unawaited(preloadRange(_currentVisibleShortIndex(this), range: 0));
    }

    _log(
      '[Shorts] loadInitialShorts - TAMAMLANDI, shorts.length: ${shorts.length}',
    );
    _log(
      '[Shorts] Current shorts list IDs AFTER: ${shorts.map((s) => s.docID).take(5).toList()}',
    );
    debugPrint(
      '[ShortColdStart] stage=initial_load_end elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds} '
      'count=${shorts.length} isLoading=${isLoading.value} hasMore=${hasMore.value}',
    );
  }

  Future<void> _runBackgroundPreload() async {
    if (shorts.isNotEmpty) {
      _log(
          '[Shorts] 🔄 Liste zaten mevcut (${shorts.length} video), ilk 5 preload');
      final initialCount = math.min(_initialPreloadCount, shorts.length);
      final futures = <Future>[];
      for (int i = 0; i < initialCount; i++) {
        if (!cache.containsKey(i)) {
          futures.add(_preloadSingleVideoWithCache(i, shorts[i]));
        }
      }
      await Future.wait(futures);
      for (int i = 0; i < initialCount; i++) {
        cache[i]?.setPreferredBufferDuration(
          _neighborBufferSeconds,
        );
        _tiers[i] = _CacheTier.hot;
      }
      return;
    }

    try {
      _log('[Shorts] 📱 İlk defa yükleme yapılıyor...');
      await _runInitialLoadOnce();

      if (shorts.isNotEmpty) {
        final initialCount = math.min(_initialPreloadCount, shorts.length);
        _log('[Shorts] ⚡ İlk $initialCount video preload ediliyor...');
        final futures = <Future>[];
        for (int i = 0; i < initialCount; i++) {
          if (!cache.containsKey(i)) {
            futures.add(_preloadSingleVideoWithCache(i, shorts[i]));
          }
        }
        await Future.wait(futures);
        for (int i = 0; i < initialCount; i++) {
          cache[i]?.setPreferredBufferDuration(
            _neighborBufferSeconds,
          );
          _tiers[i] = _CacheTier.hot;
        }
        _log(
          '[Shorts] ✅ Background preload tamamlandı - ilk $initialCount video hazır',
        );
      }
    } catch (e) {
      _log('[Shorts] ❌ Background preload hatası: $e');
    }
  }

  Future<void> refreshShorts() async {
    if (_renderWindowFrozenOnCellular) return;
    if (isRefreshing.value || isLoading.value) {
      return;
    }

    _log('[Shorts] 🔄 Refresh başlatıldı');
    isRefreshing.value = true;

    try {
      _ensureShortLaunchSessionFresh(
        reason: 'refresh',
        forceNew: true,
      );
      isLoading.value = false;
      hasMore.value = true;
      _lastDoc = null;

      final result = await _fetchPage();

      if (result.posts.isEmpty) {
        _log('[Shorts] ⚠️ Refresh sonucu boş - mevcut liste korunuyor');
        hasMore.value = result.hasMore;
        return;
      }

      final previousShorts = shorts.toList(growable: false);
      if (_isShortRouteVisible && previousShorts.isNotEmpty) {
        final appendPlan = _shortFeedApplicationService.buildAppendPlan(
          currentShorts: previousShorts,
          fetchedPosts: result.posts,
          isEligiblePost: _isEligibleShortPost,
          fetchedPostsPreplanned: result.postsPreplanned,
        );
        _log(
          '[ShortLaunchMotorApply] mode=refresh_append_only '
          'prefilled=${result.postsPreplanned} fetched=${result.posts.length} '
          'added=${appendPlan.itemsToAppend.length} current=${shorts.length}',
        );
        if (appendPlan.itemsToAppend.isNotEmpty) {
          _recordShortFetchEvent(
            stage: 'append_apply',
            trigger: 'refresh_route_visible_append_only',
            metadata: <String, dynamic>{
              'beforeCount': shorts.length,
              'appendCount': appendPlan.itemsToAppend.length,
            },
          );
          shorts.addAll(appendPlan.itemsToAppend);
          schedulePersistVisibleSnapshot();
        }
        _lastDoc = result.lastDoc;
        hasMore.value = result.hasMore;
        return;
      }
      final refreshPlan = _shortFeedApplicationService.buildRefreshPlan(
        previousShorts: previousShorts,
        fetchedPosts: result.posts,
        previousIndex: lastIndex.value,
        fetchedPostsPreplanned: result.postsPreplanned,
      );
      final newList = refreshPlan.replacementItems;
      _log(
        '[ShortLaunchMotorApply] mode=refresh '
        'prefilled=${result.postsPreplanned} fetched=${result.posts.length} '
        'replacement=${newList.length} remappedIndex=${refreshPlan.remappedIndex}',
      );

      _replaceShorts(newList, remapCache: true);

      _lastDoc = result.lastDoc;
      hasMore.value = result.hasMore;
      lastIndex.value = refreshPlan.remappedIndex;
      if (newList.isNotEmpty && !cache.containsKey(lastIndex.value)) {
        await _preloadSingleVideoWithCache(
          lastIndex.value,
          newList[lastIndex.value],
        );
      }
      schedulePersistVisibleSnapshot();
    } catch (e) {
      _log('[Shorts] ❌ Refresh hatası: $e');
      hasMore.value = true;
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadInitialShorts() async {
    await _runInitialLoadOnce();
  }

  Future<void> loadMoreIfNeeded(int currentIndex) async {
    if (_renderWindowFrozenOnCellular) {
      _log('[Shorts] loadMore blocked - cellular freeze active');
      return;
    }
    _log(
      '[Shorts] loadMoreIfNeeded called - currentIndex: $currentIndex, shorts.length: ${shorts.length}, isLoading: ${isLoading.value}, hasMore: ${hasMore.value}',
    );
    if (isLoading.value) {
      _log(
          '[Shorts] loadMoreIfNeeded ATTACH - waiting for in-flight page load');
      await (_loadNextPageFuture ?? Future<void>.value());
      return;
    }
    if (!hasMore.value) {
      _log(
        '[Shorts] loadMoreIfNeeded BLOCKED - isLoading: ${isLoading.value}, hasMore: ${hasMore.value}',
      );
      return;
    }
    final remainingAfterCurrent = shorts.length - currentIndex - 1;
    if (remainingAfterCurrent <= ShortGrowthPolicy.growthRunwayCount) {
      _log('[Shorts] loadMoreIfNeeded TRIGGERED - Loading next page...');
      await _loadNextPage(trigger: 'scroll_near_end');
    } else {
      _log(
        '[Shorts] loadMoreIfNeeded - Not yet time to load (remaining: $remainingAfterCurrent, triggerRemaining: ${ShortGrowthPolicy.growthRunwayCount}, at: $currentIndex)',
      );
    }
  }

  Future<void> warmStart({int targetCount = 20, int maxPages = 2}) async {
    if (_renderWindowFrozenOnCellular) return;
    try {
      if (shorts.isEmpty) {
        if (_backgroundPreloadFuture != null) {
          await _backgroundPreloadFuture;
        } else {
          await _runInitialLoadOnce();
        }
      }
      if (shorts.isNotEmpty) {
        await updateCacheTiers(_currentVisibleShortIndex(this));
      }
      int loops = 0;
      while (shorts.length < targetCount && hasMore.value && loops < maxPages) {
        await _loadNextPage(trigger: 'warm_start');
        loops++;
      }
    } catch (_) {}
  }

  Future<void> _loadNextPage({String trigger = 'manual'}) async {
    final inFlight = _loadNextPageFuture;
    if (inFlight != null) {
      _recordShortFetchEvent(
        stage: 'attach_inflight',
        trigger: trigger,
        metadata: <String, dynamic>{
          'currentCount': shorts.length,
          'isLoading': isLoading.value,
        },
      );
      await inFlight;
      return;
    }
    final future = _performLoadNextPage(trigger: trigger);
    _loadNextPageFuture = future;
    try {
      await future;
    } finally {
      if (identical(_loadNextPageFuture, future)) {
        _loadNextPageFuture = null;
      }
    }
  }

  Future<void> _performLoadNextPage({String trigger = 'manual'}) async {
    if (_renderWindowFrozenOnCellular &&
        !_promoteShortSessionToMobileNetworkFallback(reason: trigger)) {
      _recordShortFetchEvent(
        stage: 'skipped',
        trigger: trigger,
        metadata: <String, dynamic>{
          'reason': 'cellular_render_freeze',
          'mode': _shortSessionSourceMode.name,
          'currentCount': shorts.length,
        },
      );
      return;
    }
    _log(
      '[Shorts] _loadNextPage başladı - isLoading: ${isLoading.value}, '
      'hasMore: ${hasMore.value}, mode=${_shortSessionSourceMode.name}',
    );
    _recordShortFetchEvent(
      stage: 'requested',
      trigger: trigger,
      metadata: <String, dynamic>{
        'isLoading': isLoading.value,
        'hasMore': hasMore.value,
        'currentCount': shorts.length,
      },
    );
    if (isLoading.value || !hasMore.value) {
      _recordShortFetchEvent(
        stage: 'skipped',
        trigger: trigger,
        metadata: <String, dynamic>{
          'isLoading': isLoading.value,
          'hasMore': hasMore.value,
          'currentCount': shorts.length,
        },
      );
      return;
    }
    isLoading.value = true;
    _recordShortFetchEvent(
      stage: 'started',
      trigger: trigger,
      metadata: <String, dynamic>{
        'currentCount': shorts.length,
      },
    );
    try {
      final currentCount = shorts.length;
      final loadPageSize = ShortFetchPolicy.pageSizeForLoad(
        currentCount: currentCount,
        initialPageSize: pageSize,
        bufferedPageSize: bufferedPageSize,
      );
      final minimumSelectedCount = ShortFetchPolicy.minimumSelectedCountForLoad(
        currentCount: currentCount,
        initialBlockSize: ShortGrowthPolicy.initialBlockSize,
        pageSize: loadPageSize,
      );
      final result = await _fetchPage(
        startAfter: _lastDoc,
        pageSizeOverride: loadPageSize,
        minimumSelectedCountOverride: minimumSelectedCount,
        trigger: trigger,
      );
      if (_renderWindowFrozenOnCellular) {
        _recordShortFetchEvent(
          stage: 'skipped',
          trigger: trigger,
          metadata: <String, dynamic>{
            'reason': 'cellular_render_freeze_after_fetch',
            'currentCount': shorts.length,
          },
        );
        return;
      }

      if (result.posts.isEmpty) {
        hasMore.value = result.hasMore;
        _recordShortFetchEvent(
          stage: 'completed',
          trigger: trigger,
          metadata: <String, dynamic>{
            'returnedCount': 0,
            'addedCount': 0,
            'currentCount': shorts.length,
            'hasMore': result.hasMore,
          },
        );
        if (!result.hasMore) {
          _log('[Shorts] Yeni sayfa bulunamadı, hasMore=false');
        }
        return;
      }

      _lastDoc = result.lastDoc;
      final appendPlan = _shortFeedApplicationService.buildAppendPlan(
        currentShorts: shorts.toList(growable: false),
        fetchedPosts: result.posts,
        isEligiblePost: _isEligibleShortPost,
        fetchedPostsPreplanned: result.postsPreplanned,
      );
      _log(
        '[ShortLaunchMotorApply] mode=append '
        'prefilled=${result.postsPreplanned} fetched=${result.posts.length} '
        'added=${appendPlan.itemsToAppend.length} current=${shorts.length}',
      );
      if (appendPlan.itemsToAppend.isNotEmpty) {
        final nextItems = shorts.isEmpty
            ? _applyStartupShortPresentationOrder(appendPlan.itemsToAppend)
            : appendPlan.itemsToAppend;
        _recordShortFetchEvent(
          stage: 'append_apply',
          trigger: trigger,
          metadata: <String, dynamic>{
            'beforeCount': shorts.length,
            'appendCount': nextItems.length,
          },
        );
        debugPrint(
          '[ShortColdStart] stage=first_assign trigger=$trigger '
          'beforeCount=${shorts.length} appendCount=${nextItems.length} '
          'afterCount=${shorts.length + nextItems.length}',
        );
        shorts.addAll(nextItems);
        schedulePersistVisibleSnapshot();
      }

      hasMore.value = result.hasMore;
      _recordShortFetchEvent(
        stage: 'completed',
        trigger: trigger,
        metadata: <String, dynamic>{
          'returnedCount': result.posts.length,
          'addedCount': appendPlan.itemsToAppend.length,
          'currentCount': shorts.length,
          'hasMore': result.hasMore,
        },
      );
    } catch (e) {
      _recordShortFetchEvent(
        stage: 'failed',
        trigger: trigger,
        metadata: <String, dynamic>{
          'currentCount': shorts.length,
          'error': '$e',
        },
      );
      _log('loadNextPage error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, UserSummary>> _fetchUserSummaries(
      List<String> uids) async {
    if (uids.isEmpty) return {};

    final result = <String, UserSummary>{};
    final missing = <String>[];
    for (final uid in uids) {
      final cached = _authorSummaryCache.get(uid);
      if (cached != null) {
        result[uid] = cached;
      } else {
        missing.add(uid);
      }
    }

    if (missing.isEmpty) return result;

    const chunk = 10;
    for (int i = 0; i < missing.length; i += chunk) {
      final part = missing.sublist(i, (i + chunk).clamp(0, missing.length));
      try {
        final users = await _userSummaryResolver.resolveMany(
          part,
          preferCache: true,
        );

        for (final entry in users.entries) {
          result[entry.key] = entry.value;
          _authorSummaryCache.put(entry.key, entry.value);
        }
      } catch (e) {
        _log('_fetchUserSummaries chunk error: $e');
      }
    }

    return result;
  }

  void _replaceShorts(
    List<PostsModel> newItems, {
    bool remapCache = true,
  }) {
    newItems = newItems.where(_isEligibleShortPost).toList(growable: false);
    if (_hasSameRenderOrder(shorts, newItems)) {
      return;
    }
    final previous = shorts.toList(growable: false);
    if (_isShortRouteVisible && previous.isNotEmpty && newItems.isNotEmpty) {
      final existingIds = previous.map((item) => item.docID).toSet();
      final appendOnlyItems = <PostsModel>[];
      final seenIncoming = <String>{};
      for (final item in newItems) {
        final docId = item.docID;
        if (docId.isEmpty ||
            existingIds.contains(docId) ||
            !seenIncoming.add(docId)) {
          continue;
        }
        appendOnlyItems.add(item);
      }
      _recordShortFetchEvent(
        stage: 'replace_blocked',
        trigger: 'replace_shorts_route_visible',
        metadata: <String, dynamic>{
          'beforeCount': previous.length,
          'incomingCount': newItems.length,
          'appendOnlyCount': appendOnlyItems.length,
        },
      );
      if (appendOnlyItems.isNotEmpty) {
        _recordShortFetchEvent(
          stage: 'append_apply',
          trigger: 'replace_shorts_route_visible_append_only',
          metadata: <String, dynamic>{
            'beforeCount': previous.length,
            'appendCount': appendOnlyItems.length,
          },
        );
        shorts.addAll(appendOnlyItems);
      }
      return;
    }
    if (remapCache) {
      _remapCacheForNewList(
        previous: previous,
        next: newItems,
      );
    }
    _recordShortFetchEvent(
      stage: 'replace_apply',
      trigger: 'replace_shorts',
      metadata: <String, dynamic>{
        'beforeCount': previous.length,
        'afterCount': newItems.length,
        'remapCache': remapCache,
      },
    );
    shorts.assignAll(newItems);
  }

  bool _hasSameRenderOrder(
    List<PostsModel> current,
    List<PostsModel> next,
  ) {
    if (identical(current, next)) return true;
    if (current.length != next.length) return false;
    for (int i = 0; i < current.length; i++) {
      if (current[i].docID != next[i].docID) {
        return false;
      }
    }
    return true;
  }

  Future<void> _persistVisibleSnapshot() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    if (shorts.isEmpty) {
      await ensureShortResumeStateStore().clear(userId: userId);
      return;
    }
    final visibleIndex = lastIndex.value.clamp(0, shorts.length - 1);
    final remainingPosts = shorts
        .skip(visibleIndex)
        .where((post) => !_isConsumedShortPostForResume(post))
        .toList(growable: false);
    final cursor = _shortManifestRepository.currentCursorSnapshot();
    final state = ShortResumeState(
      manifestId: cursor.manifestId,
      cursorSlotIndex: cursor.slotIndex,
      cursorItemIndex: cursor.itemIndex,
      hasMore: hasMore.value || cursor.hasMore,
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
      remainingPosts: remainingPosts,
    );
    await ensureShortResumeStateStore().save(
      userId: userId,
      state: state,
    );
  }

  void _remapCacheForNewList({
    required List<PostsModel> previous,
    required List<PostsModel> next,
  }) {
    if (cache.isEmpty) return;

    final adaptersByDocId = <String, HLSVideoAdapter>{};
    final tiersByDocId = <String, _CacheTier>{};

    for (int i = 0; i < previous.length; i++) {
      final docId = previous[i].docID;
      if (docId.isEmpty) continue;
      final adapter = cache[i];
      if (adapter != null) {
        adaptersByDocId[docId] = adapter;
      }
      final tier = _tiers[i];
      if (tier != null) {
        tiersByDocId[docId] = tier;
      }
    }

    final remappedCache = <int, HLSVideoAdapter>{};
    final remappedTiers = <int, _CacheTier>{};
    final retainedDocIds = <String>{};

    for (int i = 0; i < next.length; i++) {
      final docId = next[i].docID;
      final adapter = adaptersByDocId[docId];
      if (adapter != null) {
        remappedCache[i] = adapter;
        retainedDocIds.add(docId);
      }
      final tier = tiersByDocId[docId];
      if (tier != null) {
        remappedTiers[i] = tier;
      }
    }

    final releaseTasks = <Future<void>>[];
    for (final entry in adaptersByDocId.entries) {
      if (retainedDocIds.contains(entry.key)) continue;
      _unregisterPlaybackHandleForIndex(-1, docIdOverride: entry.key);
      releaseTasks.add(_videoPool.release(entry.value));
    }

    cache
      ..clear()
      ..addAll(remappedCache);
    _tiers
      ..clear()
      ..addAll(remappedTiers);

    if (releaseTasks.isNotEmpty) {
      unawaited(() async {
        try {
          await Future.wait(releaseTasks);
        } catch (_) {}
      }());
    }
  }
}
