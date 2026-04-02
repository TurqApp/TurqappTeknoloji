part of 'short_controller.dart';

extension ShortControllerLoadingPart on ShortController {
  List<PostsModel> _applyStartupShortPresentationOrder(
    List<PostsModel> posts,
  ) {
    if (_startupPresentationApplied || posts.length < 2) {
      return posts;
    }
    _startupPresentationApplied = true;
    return reorderForStartupSurface(
      posts,
      surfaceKey: 'short_startup',
      maxShuffleWindow: ContentPolicy.initialPoolLimit(
        ContentScreenKind.shorts,
      ),
    );
  }

  bool get _shouldPreferOfflineCache =>
      NetworkAwarenessService.maybeFind()?.isConnected == false;

  Future<bool> _tryApplyOfflineCachedShorts({
    required int limit,
    required String trigger,
    bool persistSnapshot = true,
  }) async {
    final offlineFallback = await _loadOfflineCachedShorts(
      limit: limit,
      trigger: trigger,
    );
    if (offlineFallback.isEmpty) {
      return false;
    }

    _log('[Shorts] Offline cache tercih edildi ($trigger)');
    _replaceShorts(offlineFallback);
    _lastDoc = null;
    hasMore.value = false;
    if (persistSnapshot) {
      await _shortSnapshotRepository.persistHomeSnapshot(
        userId: _currentUserId,
        posts: offlineFallback,
        limit: limit,
        source: CachedResourceSource.scopedDisk,
      );
    }
    await preloadRange(0, range: 0);
    return true;
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
    String trigger = 'manual',
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor = startAfter;
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc = startAfter;
    bool hasMoreDocs = true;
    const int maxPageScans = 4;
    final effectivePageSize = pageSizeOverride ?? pageSize;
    final collected = <PostsModel>[];
    final seenDocIds = <String>{};

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
            if (collected.length >= effectivePageSize) {
              return _ShortPageResult(
                collected.take(effectivePageSize).toList(growable: false),
                lastDoc,
                hasMoreDocs,
              );
            }
          }
        }
      }

      if (!page.hasMore || page.lastDoc == null) {
        break;
      }
      cursor = page.lastDoc;
    }

    return _ShortPageResult(
      collected.take(effectivePageSize).toList(growable: false),
      lastDoc,
      hasMoreDocs,
    );
  }

  Future<List<PostsModel>> _filterVisibleShortPosts(
    List<PostsModel> posts,
  ) async {
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
          authorNickname: p.authorNickname.isNotEmpty
              ? p.authorNickname
              : summary.nickname,
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

  Future<List<PostsModel>> _loadOfflineCachedShorts({
    required int limit,
    required String trigger,
  }) async {
    final cacheManager = SegmentCacheManager.maybeFind();
    if (cacheManager == null || !cacheManager.isReady)
      return const <PostsModel>[];

    final docIds = cacheManager.getOfflineReadyDocIds(limit: limit);
    if (docIds.isEmpty) {
      _recordShortFetchEvent(
        stage: 'offline_cache_empty',
        trigger: trigger,
      );
      return const <PostsModel>[];
    }

    final cachedPosts = cacheManager.getOfflineReadyPosts(limit: limit);
    final byId = <String, PostsModel>{
      for (final post in cachedPosts) post.docID: post,
    };
    final missingDocIds = docIds
        .where((docId) => !byId.containsKey(docId))
        .toList(growable: false);
    if (missingDocIds.isNotEmpty) {
      byId.addAll(
        await _shortRepository.fetchByIds(
          missingDocIds,
          preferCache: true,
        ),
      );
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final ordered = docIds
        .map((docId) => byId[docId])
        .whereType<PostsModel>()
        .where(_isEligibleShortPost)
        .where((post) => post.timeStamp <= nowMs)
        .where((post) => !post.arsiv && post.deletedPost != true)
        .where((post) => post.gizlendi != true)
        .toList(growable: false);
    final filtered = await _filterVisibleShortPosts(ordered);
    _recordShortFetchEvent(
      stage: filtered.isEmpty ? 'offline_cache_miss' : 'offline_cache_hit',
      trigger: trigger,
      metadata: <String, dynamic>{
        'candidateCount': docIds.length,
        'resolvedCount': byId.length,
        'returnedCount': filtered.length,
      },
    );
    return filtered;
  }

  Future<void> backgroundPreload() async {
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

    final initialLimit =
        ContentPolicy.initialPoolLimit(ContentScreenKind.shorts);
    if (_shouldPreferOfflineCache) {
      final appliedOfflineCache = await _tryApplyOfflineCachedShorts(
        limit: initialLimit,
        trigger: shorts.isEmpty
            ? 'initial_offline_cache_preferred'
            : 'existing_list_offline_cache_preferred',
      );
      if (appliedOfflineCache) {
        return;
      }
    }

    if (shorts.isEmpty) {
      final snapshot = await _shortSnapshotRepository.loadHome(
        userId: _currentUserId,
        limit: initialLimit,
      );
      final initialPlan = _shortFeedApplicationService.buildInitialLoadPlan(
        currentShorts: shorts.toList(growable: false),
        snapshotPosts: snapshot.data ?? const <PostsModel>[],
        isEligiblePost: _isEligibleShortPost,
      );
      if (initialPlan.replacementItems != null) {
        _replaceShorts(
          _applyStartupShortPresentationOrder(initialPlan.replacementItems!),
        );
        await preloadRange(0, range: 0);
        if (initialPlan.shouldScheduleBackgroundRefresh &&
            ContentPolicy.allowBackgroundRefresh(ContentScreenKind.shorts)) {
          unawaited(_loadNextPage(trigger: 'background_refresh'));
        }
        return;
      }
      if (initialPlan.shouldResetPagination) {
        _log('[Shorts] Liste boş - sıfırlama yapılıyor');
        isLoading.value = false;
        hasMore.value = true;
        _lastDoc = null;
        clearCache();
      }
      if (await _tryApplyOfflineCachedShorts(
        limit: initialLimit,
        trigger: 'initial_offline_cache_fallback',
      )) {
        return;
      }
      if (initialPlan.shouldBootstrapNextPage) {
        _log('[Shorts] loadInitialShorts - _loadNextPage çağrılıyor');
        await _loadNextPage(trigger: 'initial_empty_bootstrap');
      }
    } else {
      final initialPlan = _shortFeedApplicationService.buildInitialLoadPlan(
        currentShorts: shorts.toList(growable: false),
        snapshotPosts: const <PostsModel>[],
        isEligiblePost: _isEligibleShortPost,
      );
      if (initialPlan.replacementItems != null) {
        _replaceShorts(initialPlan.replacementItems!, remapCache: true);
      }
      _log('[Shorts] Liste zaten var (${shorts.length} video) - korunuyor');
      await preloadRange(0, range: 0);
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
    if (isRefreshing.value || isLoading.value) {
      return;
    }

    _log('[Shorts] 🔄 Refresh başlatıldı');
    isRefreshing.value = true;

    try {
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
      );
      final newList = refreshPlan.replacementItems;

      _replaceShorts(newList, remapCache: false);
      await _remapCacheForNewList(
        previous: previousShorts,
        next: newList,
      );

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
    try {
      if (shorts.isEmpty) {
        if (_backgroundPreloadFuture != null) {
          await _backgroundPreloadFuture;
        } else {
          await _runInitialLoadOnce();
        }
      }
      if (shorts.isNotEmpty) {
        await updateCacheTiers(0);
      }
      int loops = 0;
      while (shorts.length < targetCount && hasMore.value && loops < maxPages) {
        await _loadNextPage(trigger: 'warm_start');
        loops++;
      }
    } catch (_) {}
  }

  Future<void> _loadNextPage({String trigger = 'manual'}) async {
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

      if (result.posts.isEmpty) {
        if (shorts.isEmpty) {
          final offlineFallback = await _loadOfflineCachedShorts(
            limit: ContentPolicy.initialPoolLimit(ContentScreenKind.shorts),
            trigger: '${trigger}_offline_cache_fallback',
          );
          if (offlineFallback.isNotEmpty) {
            _replaceShorts(
              _applyStartupShortPresentationOrder(offlineFallback),
            );
            await _shortSnapshotRepository.persistHomeSnapshot(
              userId: _currentUserId,
              posts: offlineFallback,
              limit: ContentPolicy.initialPoolLimit(ContentScreenKind.shorts),
              source: CachedResourceSource.scopedDisk,
            );
            hasMore.value = result.hasMore;
            _recordShortFetchEvent(
              stage: 'completed',
              trigger: trigger,
              metadata: <String, dynamic>{
                'returnedCount': 0,
                'addedCount': offlineFallback.length,
                'currentCount': shorts.length,
                'hasMore': result.hasMore,
                'source': 'offline_cache',
              },
            );
            return;
          }
        }
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
    shorts.assignAll(newItems);
    if (remapCache) {
      unawaited(_remapCacheForNewList(
        previous: previous,
        next: newItems,
      ));
    }
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
    final userId = _currentUserId;
    if (userId.isEmpty || shorts.isEmpty) return;
    await _shortSnapshotRepository.persistHomeSnapshot(
      userId: userId,
      posts: shorts.toList(growable: false),
      limit: ContentPolicy.initialPoolLimit(ContentScreenKind.shorts),
      source: CachedResourceSource.server,
    );
  }

  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  Future<void> _remapCacheForNewList({
    required List<PostsModel> previous,
    required List<PostsModel> next,
  }) async {
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
      try {
        await Future.wait(releaseTasks);
      } catch (_) {}
    }
  }
}
