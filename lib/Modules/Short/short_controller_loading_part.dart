part of 'short_controller.dart';

int _currentVisibleShortIndex(ShortController controller) {
  if (controller.shorts.isEmpty) return 0;
  return controller.lastIndex.value.clamp(0, controller.shorts.length - 1);
}

extension ShortControllerLoadingPart on ShortController {
  static const int _shortMotorStageOneLimit = 60;
  static const int _shortMotorStageTwoLimit = 120;
  static const int _shortMotorStageThreeLimit = 180;
  static const int _shortMotorStageFourLimit = 240;
  static const int _shortMotorStageThreeViewedTrigger = 50;
  static const int _shortMotorStageFourViewedTrigger = 110;
  static const int _shortMotorStageFourReadyCheckpoint = 170;

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
    recordQALabFeedFetchEvent(
      surface: 'short',
      stage: stage,
      trigger: trigger,
      metadata: metadata,
    );
  }

  void _recordShortMotorContractSnapshot({required String reason}) {
    const expectedStageOne = 60;
    const expectedStageTwo = 120;
    const expectedStageThree = 180;
    const expectedStageFour = 240;
    const expectedTriggerThree = 50;
    const expectedTriggerFour = 110;
    const expectedReadyCheckpoint = 170;
    final contract = <String, dynamic>{
      'stageOneLimit': _shortMotorStageOneLimit,
      'stageTwoLimit': _shortMotorStageTwoLimit,
      'stageThreeLimit': _shortMotorStageThreeLimit,
      'stageFourLimit': _shortMotorStageFourLimit,
      'stageThreeViewedTrigger': _shortMotorStageThreeViewedTrigger,
      'stageFourViewedTrigger': _shortMotorStageFourViewedTrigger,
      'stageFourReadyCheckpoint': _shortMotorStageFourReadyCheckpoint,
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
    if (_shortMotorStageOneLimit != expectedStageOne ||
        _shortMotorStageTwoLimit != expectedStageTwo ||
        _shortMotorStageThreeLimit != expectedStageThree ||
        _shortMotorStageFourLimit != expectedStageFour) {
      _invariantGuard.record(
        surface: 'short',
        invariantKey: 'short_motor_stage_limits_changed',
        message: 'Short motor stage limits changed',
        payload: contract,
      );
    }
    if (_shortMotorStageThreeViewedTrigger != expectedTriggerThree ||
        _shortMotorStageFourViewedTrigger != expectedTriggerFour ||
        _shortMotorStageFourReadyCheckpoint != expectedReadyCheckpoint) {
      _invariantGuard.record(
        surface: 'short',
        invariantKey: 'short_motor_stage_triggers_changed',
        message: 'Short motor stage triggers changed',
        payload: contract,
      );
    }
  }

  int shortMotorStageOneLimit() => _shortMotorStageOneLimit;

  Future<void> ensureShortMotorStageForViewedIndex(
    int viewedIndex, {
    String trigger = 'runtime',
  }) async {
    final viewedCount = viewedIndex + 1;
    var targetCount = _shortMotorStageOneLimit;
    var maxPages = 4;
    var stageLabel = 'stage_one';
    if (viewedCount >= _shortMotorStageFourViewedTrigger) {
      targetCount = _shortMotorStageFourLimit;
      maxPages = 10;
      stageLabel = viewedCount >= _shortMotorStageFourReadyCheckpoint
          ? 'stage_four_checkpoint'
          : 'stage_four';
    } else if (viewedCount >= _shortMotorStageThreeViewedTrigger) {
      targetCount = _shortMotorStageThreeLimit;
      maxPages = 8;
      stageLabel = 'stage_three';
    } else if (shorts.length < _shortMotorStageTwoLimit) {
      targetCount = _shortMotorStageTwoLimit;
      maxPages = 6;
      stageLabel = 'stage_two';
    }

    debugPrint(
      '[ShortMotorSignal] name=stage_gate status=ok '
      'reason=$trigger metadata={viewedCount: $viewedCount, targetCount: $targetCount, currentCount: ${shorts.length}, stage: $stageLabel}',
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

  void _logShortLaunchMotorInputSnapshot(
    List<PostsModel> posts, {
    required String trigger,
    required QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    if (!kDebugMode || posts.isEmpty) {
      return;
    }
    final anchorMs = startupSurfaceSessionSeed(sessionNamespace: 'short');
    final snapshot = LaunchMotorSelectionService.analyzePool(
      latestPool: posts,
      anchorMs: anchorMs,
      window: shortLaunchMotorContract.window,
      bandMinutes: shortLaunchMotorContract.bandMinutes,
      subsliceMs: shortLaunchMotorContract.subsliceMs,
      minuteSets: shortLaunchMotorContract.minuteSets,
    );
    debugPrint(
      '[ShortLaunchMotorInput] '
      'trigger=$trigger startAfter=${startAfter?.id ?? ''} '
      'anchor=${DateTime.fromMillisecondsSinceEpoch(anchorMs).toIso8601String()} '
      'motor=${snapshot.motorIndex} ownedMinutes=${snapshot.ownedMinutes.join(",")} '
      'visibleCount=${posts.length} strictCount=${snapshot.strictSelection.length} '
      'queueCount=${snapshot.queueCount} '
      'sample=${snapshot.strictSelection.take(5).map((post) => post.docID).join(",")}',
    );
  }

  LaunchMotorPoolFillResult _buildShortLaunchMotorPoolFill(
    List<PostsModel> posts, {
    required int targetCount,
  }) {
    final result = LaunchMotorSelectionService.buildPoolFillResult(
      latestPool: posts,
      anchorMs: startupSurfaceSessionSeed(sessionNamespace: 'short'),
      contract: shortLaunchMotorContract,
      targetCount: targetCount,
      // Keep short startup inside the motor window, but when strict queues are
      // sparse do not leave the launch surface underfilled.
      fallbackToAffinityWhenSparse: true,
      fallbackToLatestWhenEmpty: true,
    );
    return LaunchMotorPoolFillResult(
      snapshot: result.snapshot,
      selectedPool: _sortShortOldestFirst(result.selectedPool),
    );
  }

  List<PostsModel> _sortShortOldestFirst(List<PostsModel> items) {
    if (items.length < 2) {
      return items.toList(growable: false);
    }
    final sorted = items.toList(growable: false)
      ..sort((left, right) =>
          LaunchMotorSelectionService.compareLatestPosts(right, left));
    return sorted;
  }

  Future<_ShortPageResult> _fetchPage({
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
    int? pageSizeOverride,
    String trigger = 'manual',
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor = startAfter;
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc = startAfter;
    bool hasMoreDocs = true;
    const int maxPageScans = 8;
    final effectivePageSize = pageSizeOverride ?? pageSize;
    final collected = <PostsModel>[];
    final seenDocIds = <String>{};
    List<PostsModel>? fallbackPosts;
    LaunchMotorPoolFillResult? poolFillResult;

    for (int attempt = 0; attempt < maxPageScans; attempt++) {
      final page = await _shortRepository.fetchReadyPage(
        startAfter: cursor,
        pageSize: effectivePageSize,
        nowMs: nowMs,
      );

      lastDoc = page.lastDoc;
      hasMoreDocs = page.hasMore;

      if (page.posts.isEmpty) {
        break;
      }

      final sourceNotReady = page.posts
          .where(
              (post) => post.hasRenderableVideoCard && !post.hasPlayableVideo)
          .toList(growable: false);
      if (sourceNotReady.isNotEmpty) {
        _recordShortFetchEvent(
          stage: 'source_not_ready',
          trigger: trigger,
          metadata: <String, dynamic>{
            'count': sourceNotReady.length,
            'docIds': sourceNotReady
                .take(6)
                .map((post) => post.docID)
                .toList(growable: false),
            'hlsStatuses': sourceNotReady
                .take(6)
                .map((post) => post.hlsStatus)
                .toList(growable: false),
          },
        );
      }

      final rawWithVideo =
          page.posts.where(_isEligibleShortPost).toList(growable: false);
      final timeFiltered = rawWithVideo
          .where((p) => p.timeStamp <= nowMs)
          .toList(growable: false);
      final arsivFiltered =
          timeFiltered.where((p) => p.arsiv == false).toList(growable: false);
      final finalFiltered = arsivFiltered
          .where((p) => p.deletedPost != true)
          .where((p) => p.gizlendi != true)
          .toList(growable: false);

      if (finalFiltered.isNotEmpty) {
        final filtered = await _filterVisibleShortPosts(finalFiltered);
        if (filtered.isNotEmpty) {
          for (final post in filtered) {
            if (!seenDocIds.add(post.docID)) continue;
            collected.add(post);
          }
          poolFillResult = _buildShortLaunchMotorPoolFill(
            collected,
            targetCount: effectivePageSize,
          );
          if (!poolFillResult.needsTopUp(effectivePageSize)) {
            final resultPosts = poolFillResult.selectedPool;
            if (resultPosts.isNotEmpty) {
              _logShortLaunchMotorInputSnapshot(
                resultPosts,
                trigger: trigger,
                startAfter: startAfter,
              );
              return _ShortPageResult(
                resultPosts,
                lastDoc,
                hasMoreDocs,
                postsPreplanned: true,
              );
            }
          }
        } else if (fallbackPosts == null) {
          final fallback = await _filterVisibleShortPosts(
            finalFiltered,
          );
          if (fallback.isNotEmpty) {
            fallbackPosts = fallback;
          }
        }
      }

      if (!page.hasMore || page.lastDoc == null) {
        break;
      }
      cursor = page.lastDoc;
    }

    if (collected.isEmpty && fallbackPosts != null) {
      final resultPosts = _buildShortLaunchMotorPoolFill(
        fallbackPosts,
        targetCount: effectivePageSize,
      ).selectedPool;
      _logShortLaunchMotorInputSnapshot(
        resultPosts,
        trigger: '${trigger}_fallback',
        startAfter: startAfter,
      );
      return _ShortPageResult(
        resultPosts,
        lastDoc,
        hasMoreDocs,
        postsPreplanned: true,
      );
    }

    final resultPosts = (poolFillResult ??
            _buildShortLaunchMotorPoolFill(
              collected,
              targetCount: effectivePageSize,
            ))
        .selectedPool;
    _logShortLaunchMotorInputSnapshot(
      resultPosts,
      trigger: trigger,
      startAfter: startAfter,
    );
    return _ShortPageResult(
      resultPosts,
      lastDoc,
      hasMoreDocs,
      postsPreplanned: true,
    );
  }

  Future<List<PostsModel>> _filterVisibleShortPosts(
    List<PostsModel> posts, {
    bool preservePresentationOrder = false,
  }) async {
    if (posts.isEmpty) return const <PostsModel>[];
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
    unawaited(_persistVisibleSnapshot());
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
    _log(
      '[Shorts] loadInitialShorts - BAŞLADI',
    );
    _log(
      '[Shorts] Current shorts list IDs BEFORE: ${shorts.map((s) => s.docID).take(5).toList()}',
    );

    if (shorts.isEmpty || shorts.length < _initialPreloadCount) {
      _log('[Shorts] Motor öncesi seed kapalı - liste sıfırlanıyor');
      isLoading.value = false;
      hasMore.value = true;
      _lastDoc = null;
      clearCache();
      _log('[Shorts] loadInitialShorts - _loadNextPage çağrılıyor');
      await _loadNextPage(trigger: 'initial_empty_bootstrap');
    } else {
      _log('[Shorts] Motor öncesi seed kapalı - mevcut liste korunuyor');
      final sortedExisting = _sortShortOldestFirst(
        shorts.toList(growable: false),
      );
      _replaceShorts(sortedExisting, remapCache: true);
      unawaited(preloadRange(_currentVisibleShortIndex(this), range: 0));
    }

    _log(
      '[Shorts] loadInitialShorts - TAMAMLANDI, shorts.length: ${shorts.length}',
    );
    _log(
      '[Shorts] Current shorts list IDs AFTER: ${shorts.map((s) => s.docID).take(5).toList()}',
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
      unawaited(_persistVisibleSnapshot());
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
    if (isLoading.value || !hasMore.value) {
      _log(
        '[Shorts] loadMoreIfNeeded BLOCKED - isLoading: ${isLoading.value}, hasMore: ${hasMore.value}',
      );
      return;
    }
    final remainingAfterCurrent = shorts.length - currentIndex - 1;
    if (remainingAfterCurrent <= bufferedPageSize) {
      _log('[Shorts] loadMoreIfNeeded TRIGGERED - Loading next page...');
      await _loadNextPage(trigger: 'scroll_near_end');
    } else {
      _log(
        '[Shorts] loadMoreIfNeeded - Not yet time to load (remaining: $remainingAfterCurrent, triggerRemaining: $bufferedPageSize, at: $currentIndex)',
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
    if (_renderWindowFrozenOnCellular) {
      _recordShortFetchEvent(
        stage: 'skipped',
        trigger: trigger,
        metadata: <String, dynamic>{
          'reason': 'cellular_render_freeze',
          'currentCount': shorts.length,
        },
      );
      return;
    }
    _log(
      '[Shorts] _loadNextPage başladı - isLoading: ${isLoading.value}, hasMore: ${hasMore.value}',
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
      final result = await _fetchPage(
        startAfter: _lastDoc,
        pageSizeOverride: bufferedPageSize,
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
        shorts.addAll(nextItems);
        unawaited(_persistVisibleSnapshot());
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
    if (remapCache) {
      _remapCacheForNewList(
        previous: previous,
        next: newItems,
      );
    }
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
    return;
  }

  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

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
