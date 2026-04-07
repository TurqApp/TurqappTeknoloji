part of 'agenda_controller.dart';

extension AgendaControllerLoadingPart on AgendaController {
  Future<T> _profileFeedHeadSyncStep<T>(
    String label,
    Future<T> Function() action,
  ) async {
    final startedAt = DateTime.now();
    debugPrint('[FeedStartupHeadSync] step_start:$label');
    try {
      final result = await action();
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint('[FeedStartupHeadSync] step_end:$label elapsedMs=$elapsedMs');
      return result;
    } catch (error) {
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint(
        '[FeedStartupHeadSync] step_fail:$label elapsedMs=$elapsedMs error=$error',
      );
      rethrow;
    }
  }

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

  int get _initialHeadSyncLimit => ReadBudgetRegistry.feedHomeInitialLimitValue;
  int get _refreshHeadSyncLimit => min(8, ReadBudgetRegistry.feedLivePageLimit);

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

    if (centeredIndex.value == -1) {
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

  bool _shouldRecomposeStartupHeadOnInitialBootstrap(
    List<PostsModel> currentAgenda,
  ) {
    return currentAgenda.isNotEmpty &&
        _startupPresentationApplied &&
        !_startupLiveHeadApplied;
  }

  bool _shouldLockStartupHeadOnly(
    List<PostsModel> currentAgenda,
  ) {
    return _shouldRecomposeStartupHeadOnInitialBootstrap(currentAgenda) &&
        currentAgenda.length <= FeedSnapshotRepository.startupHomeLimitValue;
  }

  List<PostsModel> _composeLockedStartupHead({
    required List<PostsModel> currentAgenda,
    required List<PostsModel> liveItems,
  }) {
    final shouldPreferLiveStartupHead =
        _agendaFeedApplicationService.shouldPreferLiveStartupHeadForMerge(
      currentItems: currentAgenda,
      liveItems: liveItems,
      targetCount: FeedSnapshotRepository.startupHomeLimitValue,
    );
    if (!shouldPreferLiveStartupHead) {
      return currentAgenda
          .take(FeedSnapshotRepository.startupHomeLimitValue)
          .toList(growable: false);
    }
    return _composeStartupFeedItems(
      cacheCandidates: const <PostsModel>[],
      liveCandidates: liveItems,
      targetCount: FeedSnapshotRepository.startupHomeLimitValue,
    );
  }

  bool _hasSameAgendaDocOrder(
    List<PostsModel> left,
    List<PostsModel> right,
  ) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index].docID != right[index].docID) {
        return false;
      }
    }
    return true;
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

  void _cancelDeferredInitialNetworkBootstrap() {
    _deferredInitialNetworkBootstrapTimer?.cancel();
    _deferredInitialNetworkBootstrapTimer = null;
  }

  void _scheduleDeferredInitialNetworkBootstrap() {
    if (_deferredInitialNetworkBootstrapTimer?.isActive == true) return;
    final now = DateTime.now();
    if (_lastDeferredInitialNetworkBootstrapAt != null &&
        now.difference(_lastDeferredInitialNetworkBootstrapAt!) <
            const Duration(seconds: 8)) {
      return;
    }
    _lastDeferredInitialNetworkBootstrapAt = now;
    _deferredInitialNetworkBootstrapTimer = Timer(
      const Duration(milliseconds: 3200),
      () {
        _deferredInitialNetworkBootstrapTimer = null;
        if (isClosed || isLoading.value || !hasMore.value) return;
        if (agendaList.isEmpty) {
          unawaited(
            fetchAgendaBigData(
              initial: true,
              trigger: 'deferred_initial_bootstrap',
            ),
          );
          return;
        }
        unawaited(
          fetchAgendaBigData(
            pageLimit: ReadBudgetRegistry.feedHomeInitialLimitValue,
            trigger: 'deferred_initial_bootstrap',
          ),
        );
      },
    );
  }

  bool _shouldDeferInitialNetworkBootstrap() {
    return false;
  }

  void _resetBufferedFeedBlock() {
    _bufferedFeedBlockItems.clear();
    _bufferedFeedBlockBaseCount = 0;
    _bufferedFeedBlockPrefetchBaseCount = 0;
    _bufferedFeedBlockPrefetchFuture = null;
  }

  int? _resolveBufferedFeedPrefetchBaseCount(int agendaCount) {
    final initialCount = FeedSnapshotRepository.startupHomeLimitValue;
    final blockSize = ReadBudgetRegistry.feedLivePageLimit;
    if (agendaCount < initialCount) {
      return null;
    }
    final normalized = max(agendaCount, initialCount) - initialCount;
    return initialCount + ((normalized ~/ blockSize) * blockSize);
  }

  bool _hasBufferedFeedBlockReadyForBase(int blockBaseCount) {
    return _bufferedFeedBlockItems.isNotEmpty &&
        _bufferedFeedBlockBaseCount == blockBaseCount;
  }

  bool _hasBufferedFeedBlockPrefetchInFlightForBase(int blockBaseCount) {
    return _bufferedFeedBlockPrefetchFuture != null &&
        _bufferedFeedBlockPrefetchBaseCount == blockBaseCount;
  }

  void _scheduleBufferedFeedBlockPrefetchAfterFrame({
    required String reason,
  }) {
    if (agendaList.length < FeedSnapshotRepository.startupHomeLimitValue) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      unawaited(_prefetchBufferedFeedBlock(reason: reason));
    });
  }

  Future<void> _prefetchBufferedFeedBlock({
    required String reason,
  }) async {
    final blockBaseCount =
        _resolveBufferedFeedPrefetchBaseCount(agendaList.length);
    if (blockBaseCount == null) return;
    if (_bufferedFeedBlockItems.isNotEmpty) {
      if (_bufferedFeedBlockBaseCount == blockBaseCount) {
        return;
      }
      return;
    }
    if (_bufferedFeedBlockBaseCount == blockBaseCount) {
      return;
    }
    final inFlight = _bufferedFeedBlockPrefetchFuture;
    if (inFlight != null &&
        _bufferedFeedBlockPrefetchBaseCount == blockBaseCount) {
      return;
    }

    final future = () async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      final liveConnected = ContentPolicy.isConnected;
      final shouldPreferCacheOnOpen = !liveConnected;
      debugPrint(
        '[FeedBufferedBlock] status=prefetch_begin reason=$reason '
        'blockBaseCount=$blockBaseCount agendaCount=${agendaList.length}',
      );
      final blockLoadResult = await _loadBufferedFeedBlock(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        blockSize: ReadBudgetRegistry.feedLivePageLimit,
        pageLimit: fetchLimit,
        preferCache: shouldPreferCacheOnOpen,
        cacheOnly: !liveConnected,
      );
      if (isClosed) return;
      if (_bufferedFeedBlockItems.isNotEmpty &&
          _bufferedFeedBlockBaseCount != blockBaseCount) {
        return;
      }
      if (blockLoadResult.blockItems.isNotEmpty) {
        _bufferedFeedBlockItems
          ..clear()
          ..addAll(blockLoadResult.blockItems);
        _bufferedFeedBlockBaseCount = blockBaseCount;
        lastDoc = blockLoadResult.lastDoc;
        _usePrimaryFeedPaging = blockLoadResult.usesPrimaryFeed;
        hasMore.value =
            blockLoadResult.hasMore || _bufferedFeedBlockItems.isNotEmpty;
        debugPrint(
          '[FeedBufferedBlock] status=prefetch_ready reason=$reason '
          'blockBaseCount=$blockBaseCount count=${_bufferedFeedBlockItems.length}',
        );
      } else {
        debugPrint(
          '[FeedBufferedBlock] status=prefetch_empty reason=$reason '
          'blockBaseCount=$blockBaseCount',
        );
      }
    }();

    _bufferedFeedBlockPrefetchBaseCount = blockBaseCount;
    _bufferedFeedBlockPrefetchFuture = future;
    try {
      await future;
    } finally {
      if (identical(_bufferedFeedBlockPrefetchFuture, future)) {
        _bufferedFeedBlockPrefetchFuture = null;
        _bufferedFeedBlockPrefetchBaseCount = 0;
      }
    }
    if (isClosed || !_hasBufferedFeedBlockReadyForBase(blockBaseCount)) {
      return;
    }
    final centered = centeredIndex.value;
    final viewedCount =
        centered >= 0 && centered < agendaList.length ? centered + 1 : 0;
    final remainingAfterCentered = centered >= 0 && centered < agendaList.length
        ? agendaList.length - centered - 1
        : agendaList.length;
    final leadRevealRemainingCount =
        max(1, ReadBudgetRegistry.feedBufferedFetchLimit ~/ 2);
    if (viewedCount <= 0 || remainingAfterCentered > leadRevealRemainingCount) {
      return;
    }
    unawaited(
      fetchAgendaBigData(
        trigger: 'buffered_prefetch_ready_tail',
        pageLimit: ReadBudgetRegistry.feedBufferedFetchLimit,
        targetAgendaCount:
            agendaList.length + ReadBudgetRegistry.feedBufferedFetchLimit,
        bufferedBlockBaseCount: blockBaseCount,
      ),
    );
  }

  List<PostsModel> _takeBufferedFeedBlockItems(int count) {
    if (count <= 0 || _bufferedFeedBlockItems.isEmpty) {
      return const <PostsModel>[];
    }
    final takeCount = min(count, _bufferedFeedBlockItems.length);
    final items =
        _bufferedFeedBlockItems.take(takeCount).toList(growable: false);
    _bufferedFeedBlockItems.removeRange(0, takeCount);
    return items;
  }

  bool _canBypassLoadingForBufferedReveal({
    required bool initial,
    int? targetAgendaCount,
    int? bufferedBlockBaseCount,
  }) {
    if (initial ||
        targetAgendaCount == null ||
        bufferedBlockBaseCount == null ||
        bufferedBlockBaseCount < FeedSnapshotRepository.startupHomeLimitValue) {
      return false;
    }
    if (_bufferedFeedBlockItems.isNotEmpty &&
        _bufferedFeedBlockBaseCount == bufferedBlockBaseCount) {
      return true;
    }
    return _bufferedFeedBlockPrefetchFuture != null &&
        _bufferedFeedBlockPrefetchBaseCount == bufferedBlockBaseCount;
  }

  Future<_AgendaBufferedFeedBlockLoadResult> _loadBufferedFeedBlock({
    required int nowMs,
    required int cutoffMs,
    required int blockSize,
    required int pageLimit,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final currentAgendaDocIds = agendaList
        .map((post) => post.docID.trim())
        .where((docId) => docId.isNotEmpty)
        .toSet();
    final seenDocIds = <String>{...currentAgendaDocIds};
    final liveCandidates = <PostsModel>[];
    var cursor = lastDoc is DocumentSnapshot<Map<String, dynamic>>
        ? lastDoc as DocumentSnapshot<Map<String, dynamic>>?
        : null;
    var usesStoredCursor = true;
    var effectiveLastDoc = cursor;
    var effectiveUsesPrimaryFeed = _usePrimaryFeedPaging;
    var effectiveHasMore = hasMore.value;

    while (liveCandidates.length < blockSize) {
      final page = await _loadAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: pageLimit,
        startAfter: usesStoredCursor ? null : cursor,
        useStoredCursor: usesStoredCursor,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      effectiveLastDoc = page.lastDoc;
      effectiveUsesPrimaryFeed = page.usesPrimaryFeed;
      effectiveHasMore = page.lastDoc != null && page.items.length >= pageLimit;

      for (final post in page.items) {
        final docId = post.docID.trim();
        if (docId.isEmpty || !seenDocIds.add(docId)) continue;
        liveCandidates.add(post);
      }

      if (page.lastDoc == null || page.items.length < pageLimit) {
        break;
      }
      cursor = page.lastDoc;
      usesStoredCursor = false;
    }

    var blockCandidates = liveCandidates.toList(growable: true);
    var usedBroadUniqueScan = false;

    if (blockCandidates.length < blockSize) {
      final uniqueScanLimit = max(_startupSeedLoadLimit(blockSize), blockSize);
      final broadPage = await _loadAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: uniqueScanLimit,
        startAfter: null,
        useStoredCursor: false,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      final broadSeenDocIds = agendaList
          .map((post) => post.docID.trim())
          .where((docId) => docId.isNotEmpty)
          .toSet();
      final broadUniqueCandidates = <PostsModel>[];
      var addedFromBroadScan = 0;
      for (final post in broadPage.items) {
        final docId = post.docID.trim();
        if (docId.isEmpty || !broadSeenDocIds.add(docId)) continue;
        broadUniqueCandidates.add(post);
        if (blockCandidates.length < blockSize) {
          if (!seenDocIds.add(docId)) continue;
          blockCandidates.add(post);
        }
        addedFromBroadScan++;
      }
      if (broadUniqueCandidates.length > blockCandidates.length) {
        blockCandidates = broadUniqueCandidates;
      }
      usedBroadUniqueScan = broadUniqueCandidates.isNotEmpty;
      debugPrint(
        '[FeedBufferedBlock] status=broaden_unique_scan '
        'currentUnique=${blockCandidates.length} target=$blockSize '
        'added=$addedFromBroadScan broadVisible=${broadPage.items.length}',
      );
      effectiveHasMore = effectiveHasMore ||
          broadPage.lastDoc != null ||
          blockCandidates.length >= blockSize;
    }

    if (blockCandidates.isEmpty) {
      return _AgendaBufferedFeedBlockLoadResult(
        blockItems: const <PostsModel>[],
        lastDoc: effectiveLastDoc,
        usesPrimaryFeed: effectiveUsesPrimaryFeed,
        hasMore: effectiveHasMore,
      );
    }

    final supportExcludeDocIds = <String>{...currentAgendaDocIds};
    final augmentedCandidates = await _augmentStartupSupportCandidates(
      candidates: blockCandidates,
      nowMs: nowMs,
      primaryCutoffMs: cutoffMs,
      targetCount: blockSize,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      allowNetworkFallbackFetch: !usedBroadUniqueScan,
      excludeDocIds: supportExcludeDocIds,
    );
    final blockSeenDocIds = <String>{...currentAgendaDocIds};
    final composedBlockItems = _composeStartupFeedItems(
      cacheCandidates: augmentedCandidates,
      liveCandidates: const <PostsModel>[],
      targetCount: blockSize,
      allowSparseSlotFallback: true,
    );
    final blockItems = <PostsModel>[];
    for (final post in composedBlockItems) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !blockSeenDocIds.add(docId)) continue;
      blockItems.add(post);
      if (blockItems.length >= blockSize) break;
    }
    debugPrint(
      '[FeedBufferedBlock] status=compose_block '
      'candidateCount=${blockCandidates.length} '
      'augmentedCount=${augmentedCandidates.length} '
      'composedCount=${blockItems.length} '
      'target=$blockSize',
    );

    return _AgendaBufferedFeedBlockLoadResult(
      blockItems: blockItems,
      lastDoc: effectiveLastDoc,
      usesPrimaryFeed: effectiveUsesPrimaryFeed,
      hasMore: effectiveHasMore,
    );
  }

  Future<List<PostsModel>> _revealBufferedFeedBlockForTarget({
    required int targetAgendaCount,
    required int blockBaseCount,
    required int nowMs,
    required int cutoffMs,
    required int pageLimit,
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final inFlightPrefetch = _bufferedFeedBlockPrefetchFuture;
    if (inFlightPrefetch != null &&
        _bufferedFeedBlockPrefetchBaseCount == blockBaseCount) {
      await inFlightPrefetch;
    }
    if (_bufferedFeedBlockBaseCount != blockBaseCount) {
      final blockLoadResult = await _loadBufferedFeedBlock(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        blockSize: ReadBudgetRegistry.feedLivePageLimit,
        pageLimit: pageLimit,
        preferCache: preferCache,
        cacheOnly: cacheOnly,
      );
      _bufferedFeedBlockItems
        ..clear()
        ..addAll(blockLoadResult.blockItems);
      _bufferedFeedBlockBaseCount =
          blockLoadResult.blockItems.isNotEmpty ? blockBaseCount : 0;
      lastDoc = blockLoadResult.lastDoc;
      _usePrimaryFeedPaging = blockLoadResult.usesPrimaryFeed;
      hasMore.value =
          blockLoadResult.hasMore || _bufferedFeedBlockItems.isNotEmpty;
      if (blockLoadResult.blockItems.isNotEmpty) {
        unawaited(
          _saveFeedPostsToPool(
            blockLoadResult.blockItems,
            const <String, Map<String, dynamic>>{},
          ),
        );
      }
    }

    final neededCount = max(0, targetAgendaCount - agendaList.length);
    final revealedItems = _takeBufferedFeedBlockItems(neededCount);
    hasMore.value = _bufferedFeedBlockItems.isNotEmpty || lastDoc != null;
    return revealedItems;
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

  bool _isTransientAgendaPermissionDenied(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return true;
    }
    final message = normalizeLowercase(error.toString());
    return message.contains('cloud_firestore/permission-denied') ||
        message.contains('permission denied');
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
    int? targetAgendaCount,
    int? bufferedBlockBaseCount,
  }) async {
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
    final previousBufferedFeedBlockItems =
        _bufferedFeedBlockItems.toList(growable: false);
    final previousBufferedFeedBlockBaseCount = _bufferedFeedBlockBaseCount;
    final preserveVisibleFeedOnInitialBootstrap =
        initial && previousAgenda.isNotEmpty && trigger != 'refresh_agenda';

    if (preserveVisibleFeedOnInitialBootstrap) {
      await syncFeedHeadAfterSurfaceOpen();
      return;
    }

    if (initial) {
      _resetBufferedFeedFetchTrigger();
      lastDoc = null;
      _usePrimaryFeedPaging = true;
      hasMore.value = true;
      _startupPresentationApplied = false;
      _startupLiveHeadApplied = false;
      _startupPromoRevealUnlockedByScroll = false;
      _startupPromoRevealSawUserDrag = false;
      _prefetchedThumbnailPostCount = 0;
      _prefetchedThumbnailDocIds.clear();
      agendaList.clear();
      _shuffleCache.clear();
      _resetBufferedFeedBlock();
      // Eski yeniden paylaşım meta verilerini sıfırla
      publicReshareEvents.clear();
      feedReshareEntries.clear();

      // 🎯 INSTAGRAM STYLE: İlk açılışta centered index'i sıfırla
      centeredIndex.value = -1;

      // Hızlı ilk boya için: cache'ten doldurmayı dene (gizlilik güvenli)
      try {
        await _tryQuickFillFromCache();
      } catch (e) {
        // Sessizce devam et, sunucu isteğine geçilecek
        // print("quick cache fill error: $e");
      }

      // Reshare yüklemelerini ilk render sonrasına ertele; launch jank'i azaltır.
      _scheduleInitialReshareMerge();

      if (agendaList.isNotEmpty && _startupLiveHeadApplied) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
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
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        });
        return;
      }

      if (agendaList.isNotEmpty && _shouldDeferInitialNetworkBootstrap()) {
        _scheduleDeferredInitialNetworkBootstrap();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        });
        return;
      }
    }

    // Eğer shuffle edilmiş postlar varsa onlardan devam et
    if (_shuffleCache.hasBufferedItems) {
      if (!hasMore.value || isLoading.value) return;
      isLoading.value = true;
      recordQALabFeedFetchEvent(
        stage: 'buffered_page',
        trigger: trigger,
        metadata: <String, dynamic>{
          'initial': initial,
          'pageLimit': pageLimit ?? 0,
          'currentCount': agendaList.length,
        },
      );

      try {
        final nextBatch = _shuffleCache.takeNext(fetchLimit);
        _addUniqueToAgenda(nextBatch);
        hasMore.value = _shuffleCache.hasMore || lastDoc != null;
      } finally {
        isLoading.value = false;
      }
      return;
    }

    final canBypassLoadingForBufferedReveal =
        _canBypassLoadingForBufferedReveal(
      initial: initial,
      targetAgendaCount: targetAgendaCount,
      bufferedBlockBaseCount: bufferedBlockBaseCount,
    );

    if ((!hasMore.value && !canBypassLoadingForBufferedReveal) ||
        (isLoading.value && !canBypassLoadingForBufferedReveal)) {
      recordQALabFeedFetchEvent(
        stage: 'skipped',
        trigger: trigger,
        metadata: <String, dynamic>{
          'initial': initial,
          'pageLimit': pageLimit ?? 0,
          'isLoading': isLoading.value,
          'hasMore': hasMore.value,
          'canBypassLoadingForBufferedReveal':
              canBypassLoadingForBufferedReveal,
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
        'canBypassLoadingForBufferedReveal': canBypassLoadingForBufferedReveal,
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
      final shouldPreferCacheOnOpen = !liveConnected;
      final desiredAgendaCount = !initial &&
              targetAgendaCount != null &&
              targetAgendaCount > currentAgenda.length
          ? targetAgendaCount
          : null;
      if (!initial &&
          desiredAgendaCount != null &&
          bufferedBlockBaseCount != null &&
          bufferedBlockBaseCount >=
              FeedSnapshotRepository.startupHomeLimitValue) {
        final revealedItems = await _revealBufferedFeedBlockForTarget(
          targetAgendaCount: desiredAgendaCount,
          blockBaseCount: bufferedBlockBaseCount,
          nowMs: nowMs,
          cutoffMs: cutoffMs,
          pageLimit: pageLimit ?? fetchLimit,
          preferCache: shouldPreferCacheOnOpen,
          cacheOnly: !liveConnected,
        );
        final pageApplyPlan = _agendaFeedApplicationService.buildPageApplyPlan(
          currentItems: currentAgenda,
          pageItems: revealedItems,
          nowMs: nowMs,
          loadLimit: pageLimit ?? fetchLimit,
          lastDoc: lastDoc is DocumentSnapshot<Map<String, dynamic>>
              ? lastDoc as DocumentSnapshot<Map<String, dynamic>>?
              : null,
          usesPrimaryFeed: _usePrimaryFeedPaging,
        );
        if (pageApplyPlan.freshScheduledIds.isNotEmpty) {
          markHighlighted(
            pageApplyPlan.freshScheduledIds,
            keepFor: const Duration(milliseconds: 900),
          );
        }
        if (pageApplyPlan.itemsToAdd.isNotEmpty) {
          _addUniqueToAgenda(pageApplyPlan.itemsToAdd);
          _scheduleInitialFeedVideoPosterWarmup(pageApplyPlan.itemsToAdd);
          _scheduleReshareFetchForPosts(
            pageApplyPlan.itemsToAdd,
            perPostLimit: 1,
          );
        }
        recordQALabFeedFetchEvent(
          stage: 'completed',
          trigger: trigger,
          metadata: <String, dynamic>{
            'initial': initial,
            'loadLimit': pageLimit ?? fetchLimit,
            'visibleItemCount': revealedItems.length,
            'agendaCount': agendaList.length,
            'hasMore': hasMore.value,
            'usesPrimaryFeed': _usePrimaryFeedPaging,
            'bufferedBlockBaseCount': bufferedBlockBaseCount,
            'bufferedRemainingCount': _bufferedFeedBlockItems.length,
          },
        );
        _clearAgendaRetry();
        return;
      }
      final requiredAdditionalCount = desiredAgendaCount == null
          ? null
          : max(0, desiredAgendaCount - currentAgenda.length);
      final seenDocIds = currentAgenda
          .map((post) => post.docID.trim())
          .where((docId) => docId.isNotEmpty)
          .toSet();
      final bufferedVisibleItems = <PostsModel>[];
      final storedCursor = lastDoc is DocumentSnapshot<Map<String, dynamic>>
          ? lastDoc as DocumentSnapshot<Map<String, dynamic>>?
          : null;
      var cursor = storedCursor;
      var usesStoredCursor = true;
      var effectiveLastDoc = storedCursor;
      var effectiveUsesPrimaryFeed = _usePrimaryFeedPaging;
      var effectiveHasMore = hasMore.value;
      List<PostsModel> visibleItems = const <PostsModel>[];

      while (true) {
        final pageStartCursor = usesStoredCursor ? storedCursor : cursor;
        final page = await _loadAgendaSourcePage(
          nowMs: nowMs,
          cutoffMs: cutoffMs,
          limit: loadLimit,
          startAfter: usesStoredCursor ? null : cursor,
          useStoredCursor: usesStoredCursor,
          preferCache: shouldPreferCacheOnOpen,
          cacheOnly: !liveConnected,
        );
        effectiveLastDoc = page.lastDoc;
        effectiveUsesPrimaryFeed = page.usesPrimaryFeed;
        effectiveHasMore =
            page.lastDoc != null && page.items.length >= loadLimit;

        final rawPageVisibleItems = initial
            ? await _augmentStartupSupportCandidates(
                candidates: page.items,
                nowMs: nowMs,
                primaryCutoffMs: cutoffMs,
                targetCount: FeedSnapshotRepository.startupHomeLimitValue,
                preferCache: shouldPreferCacheOnOpen,
                cacheOnly: !liveConnected,
                allowNetworkFallbackFetch: true,
              )
            : page.items;
        final pageVisibleItems =
            initial && currentAgenda.isEmpty && rawPageVisibleItems.isNotEmpty
                ? _applyStartupFeedPresentationOrder(rawPageVisibleItems)
                : rawPageVisibleItems;
        if (initial &&
            currentAgenda.isEmpty &&
            rawPageVisibleItems.length != pageVisibleItems.length) {
          debugPrint(
            '[FeedStartupHeadSync] source=initial_bootstrap '
            'status=compose_before_page_apply '
            'rawCount=${rawPageVisibleItems.length} '
            'composedCount=${pageVisibleItems.length}',
          );
        }

        if (initial) {
          visibleItems = pageVisibleItems;
          break;
        }

        var partiallyConsumedPage = false;
        for (var index = 0; index < pageVisibleItems.length; index++) {
          if (requiredAdditionalCount != null &&
              bufferedVisibleItems.length >= requiredAdditionalCount) {
            partiallyConsumedPage = true;
            break;
          }
          final post = pageVisibleItems[index];
          final docId = post.docID.trim();
          if (docId.isEmpty || !seenDocIds.add(docId)) continue;
          bufferedVisibleItems.add(post);
          if (requiredAdditionalCount != null &&
              bufferedVisibleItems.length >= requiredAdditionalCount &&
              index < pageVisibleItems.length - 1) {
            partiallyConsumedPage = true;
            break;
          }
        }
        visibleItems = bufferedVisibleItems;

        if (requiredAdditionalCount == null) {
          break;
        }
        if (bufferedVisibleItems.length >= requiredAdditionalCount) {
          if (partiallyConsumedPage) {
            effectiveLastDoc = pageStartCursor;
            effectiveHasMore = true;
          }
          break;
        }
        if (page.lastDoc == null || page.items.length < loadLimit) {
          break;
        }
        cursor = page.lastDoc;
        usesStoredCursor = false;
      }

      final pageApplyPlan = _agendaFeedApplicationService.buildPageApplyPlan(
        currentItems: agendaList.toList(growable: false),
        pageItems: visibleItems,
        nowMs: nowMs,
        loadLimit: loadLimit,
        lastDoc: effectiveLastDoc,
        usesPrimaryFeed: effectiveUsesPrimaryFeed,
      );

      _usePrimaryFeedPaging = effectiveUsesPrimaryFeed;
      lastDoc = effectiveLastDoc;

      final shouldProtectBufferedStartupExpansion = initial &&
          agendaList.isNotEmpty &&
          (_bufferedFeedBlockPrefetchFuture != null ||
              _bufferedFeedBlockItems.isNotEmpty);

      if (visibleItems.isNotEmpty && shouldProtectBufferedStartupExpansion) {
        debugPrint(
          '[FeedStartupHeadSync] source=initial_bootstrap '
          'status=skip_during_buffered_prefetch '
          'agendaCount=${agendaList.length} visibleCount=${visibleItems.length} '
          'bufferedReadyCount=${_bufferedFeedBlockItems.length} '
          'bufferedPrefetchBaseCount=$_bufferedFeedBlockPrefetchBaseCount',
        );
        unawaited(
          _saveFeedPostsToPool(
            visibleItems,
            const <String, Map<String, dynamic>>{},
          ),
        );
      } else if (visibleItems.isNotEmpty) {
        final lockStartupHeadOnly =
            initial && _shouldLockStartupHeadOnly(currentAgenda);
        final shouldPreferLiveStartupHead = initial &&
            _agendaFeedApplicationService.shouldPreferLiveStartupHeadForMerge(
              currentItems: currentAgenda,
              liveItems: visibleItems,
              targetCount: FeedSnapshotRepository.startupHomeLimitValue,
            );
        final shouldRecomposeStartupHead = initial &&
            _shouldRecomposeStartupHeadOnInitialBootstrap(currentAgenda) &&
            shouldPreferLiveStartupHead &&
            !lockStartupHeadOnly;
        unawaited(
          _saveFeedPostsToPool(
            visibleItems,
            const <String, Map<String, dynamic>>{},
          ),
        );
        if (pageApplyPlan.freshScheduledIds.isNotEmpty) {
          markHighlighted(pageApplyPlan.freshScheduledIds,
              keepFor: const Duration(milliseconds: 900));
        }
        if (lockStartupHeadOnly) {
          final lockedAgenda = _composeLockedStartupHead(
            currentAgenda: currentAgenda,
            liveItems: visibleItems,
          );
          debugPrint(
            '[FeedStartupHeadSync] source=initial_bootstrap '
            'status=apply_locked_startup_head '
            'currentCount=${currentAgenda.length} liveCount=${visibleItems.length} '
            'nextCount=${lockedAgenda.length} '
            'preferLive=$shouldPreferLiveStartupHead',
          );
          final shouldActivateStartupStages =
              initial && currentAgenda.isEmpty && lockedAgenda.isNotEmpty;
          if (shouldActivateStartupStages) {
            _startupRenderBootstrapHold = true;
            _activateStartupRenderStages(
              reason: 'initial_locked_assign',
            );
          }
          if (!_hasSameAgendaDocOrder(currentAgenda, lockedAgenda)) {
            agendaList.assignAll(lockedAgenda);
            _debugAgendaKinds('initial_locked_assign', agendaList);
            _applyStartupRenderStagesNow();
            _scheduleInitialFeedVideoPosterWarmup(
              _initialVisibleVideoWarmupWindow(lockedAgenda),
            );
            _scheduleBufferedFeedBlockPrefetchAfterFrame(
              reason: 'initial_locked_assign',
            );
          }
          _startupLiveHeadApplied = true;
        } else if (shouldRecomposeStartupHead) {
          final recomposedAgenda = lockStartupHeadOnly
              ? _composeLockedStartupHead(
                  currentAgenda: currentAgenda,
                  liveItems: visibleItems,
                )
              : _mergeStartupHeadWithCurrentItems(
                  currentItems: currentAgenda,
                  liveItems: visibleItems,
                  targetCount: FeedSnapshotRepository.startupHomeLimitValue,
                  nowMs: nowMs,
                );
          debugPrint(
            '[FeedStartupHeadSwap] source=initial_bootstrap '
            'currentCount=${currentAgenda.length} liveCount=${visibleItems.length} '
            'nextCount=${recomposedAgenda.length} '
            'currentHead=${currentAgenda.take(5).map((post) => post.docID).join(",")} '
            'liveHead=${visibleItems.take(5).map((post) => post.docID).join(",")} '
            'nextHead=${recomposedAgenda.take(5).map((post) => post.docID).join(",")}',
          );
          final shouldActivateStartupStages =
              initial && currentAgenda.isEmpty && recomposedAgenda.isNotEmpty;
          if (shouldActivateStartupStages) {
            _startupRenderBootstrapHold = true;
            _activateStartupRenderStages(
              reason: 'initial_recomposed_assign',
            );
          }
          agendaList.assignAll(recomposedAgenda);
          _debugAgendaKinds('initial_recomposed_assign', agendaList);
          _applyStartupRenderStagesNow();
          _startupLiveHeadApplied = true;
          _scheduleInitialFeedVideoPosterWarmup(
            _initialVisibleVideoWarmupWindow(recomposedAgenda),
          );
          _scheduleBufferedFeedBlockPrefetchAfterFrame(
            reason: 'initial_recomposed_assign',
          );
          if (pageApplyPlan.itemsToAdd.isNotEmpty) {
            _scheduleReshareFetchForPosts(
              pageApplyPlan.itemsToAdd,
              perPostLimit: 1,
            );
          }
        } else if (pageApplyPlan.itemsToAdd.isNotEmpty) {
          if (initial &&
              _startupPresentationApplied &&
              !_startupLiveHeadApplied &&
              !shouldPreferLiveStartupHead) {
            _startupLiveHeadApplied = true;
          }
          final shouldActivateStartupStages = initial && agendaList.isEmpty;
          if (initial && currentAgenda.isEmpty) {
            final startupItems = _applyStartupFeedPresentationOrder(
              pageApplyPlan.itemsToAdd,
            );
            if (shouldActivateStartupStages && startupItems.isNotEmpty) {
              _startupRenderBootstrapHold = true;
              _activateStartupRenderStages(
                reason: 'initial_items_to_add',
              );
            }
            debugPrint(
              '[FeedStartupHeadSync] source=initial_bootstrap '
              'status=apply_composed_startup_items '
              'rawCount=${pageApplyPlan.itemsToAdd.length} '
              'composedCount=${startupItems.length}',
            );
            agendaList.assignAll(startupItems);
            _debugAgendaKinds('initial_items_to_add', agendaList);
            _applyStartupRenderStagesNow();
            _scheduleInitialFeedVideoPosterWarmup(startupItems);
            _scheduleReshareFetchForPosts(
              startupItems,
              perPostLimit: 1,
            );
            _scheduleBufferedFeedBlockPrefetchAfterFrame(
              reason: 'initial_items_to_add',
            );
          } else {
            if (initial &&
                shouldActivateStartupStages &&
                pageApplyPlan.itemsToAdd.isNotEmpty) {
              _startupRenderBootstrapHold = true;
              _activateStartupRenderStages(
                reason: 'initial_items_to_add',
              );
            }
            _addUniqueToAgenda(pageApplyPlan.itemsToAdd);
            if (initial) {
              _reorderAgendaForStartupPresentationIfNeeded();
              _applyStartupRenderStagesNow();
            }
            _scheduleInitialFeedVideoPosterWarmup(pageApplyPlan.itemsToAdd);
            _scheduleReshareFetchForPosts(
              pageApplyPlan.itemsToAdd,
              perPostLimit: 1,
            );
            _scheduleBufferedFeedBlockPrefetchAfterFrame(
              reason: initial ? 'initial_add_unique' : 'paged_add_unique',
            );
          }
        }
      }

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
        if (agendaList.isEmpty && previousAgenda.isNotEmpty) {
          agendaList.assignAll(previousAgenda);
          publicReshareEvents.assignAll(previousReshares);
          feedReshareEntries.assignAll(previousFeedReshares);
          lastDoc = previousLastDoc;
          hasMore.value = previousHasMore;
          _usePrimaryFeedPaging = previousUsePrimaryFeedPaging;
          _bufferedFeedBlockItems
            ..clear()
            ..addAll(previousBufferedFeedBlockItems);
          _bufferedFeedBlockBaseCount = previousBufferedFeedBlockBaseCount;
          if (centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        }
        _scheduleAgendaRetry(initial: initial && agendaList.isEmpty);
      }
    } finally {
      if (startedLoading) {
        isLoading.value = false; // HER DURUMDA EN SON ÇALIŞIR
      }

      // 🎯 INSTAGRAM STYLE: İlk açılışta ilk videoyu otomatik centered yap
      if (initial && agendaList.isNotEmpty) {
        // Bir frame bekle ki VisibilityDetector build olsun
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (agendaList.isNotEmpty && centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        });
      }
    }
  }

  Future<void> ensureInitialFeedLoaded() async {
    if (agendaList.isNotEmpty) {
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
    final future = fetchAgendaBigData(
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

  Future<void> ensureFeedSurfaceReady() async {
    final inFlight = _surfaceBootstrapFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    final future = _performEnsureFeedSurfaceReady();
    _surfaceBootstrapFuture = future;
    try {
      await future;
    } finally {
      if (identical(_surfaceBootstrapFuture, future)) {
        _surfaceBootstrapFuture = null;
      }
    }
  }

  Future<void> _performEnsureFeedSurfaceReady() async {
    final connectedStartup = ContentPolicy.isConnected;
    if (!connectedStartup && agendaList.isEmpty && !isLoading.value) {
      await _profileFeedStartupSurfaceStep('hydrate_initial_feed_from_cache',
          () {
        return hydrateInitialFeedFromCache(
          targetCount: FeedSnapshotRepository.startupHomeLimitValue,
        );
      });
    }

    if (agendaList.isNotEmpty) {
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

  Future<void> syncFeedHeadAfterSurfaceOpen() async {
    if (!ContentPolicy.isConnected || agendaList.isEmpty || isLoading.value) {
      debugPrint(
        '[FeedStartupHeadSync] source=surface_open_sync status=early_return '
        'connected=${ContentPolicy.isConnected} '
        'agendaEmpty=${agendaList.isEmpty} isLoading=${isLoading.value}',
      );
      return;
    }

    final inFlight = _headSyncFuture;
    if (inFlight != null) {
      debugPrint(
        '[FeedStartupHeadSync] source=surface_open_sync status=join_inflight',
      );
      await inFlight;
      return;
    }

    final now = DateTime.now();
    if (_lastHeadSyncAt != null &&
        now.difference(_lastHeadSyncAt!) < const Duration(seconds: 12)) {
      debugPrint(
        '[FeedStartupHeadSync] source=surface_open_sync status=throttled '
        'elapsedMs=${now.difference(_lastHeadSyncAt!).inMilliseconds}',
      );
      return;
    }
    _lastHeadSyncAt = now;

    debugPrint(
      '[FeedStartupHeadSync] source=surface_open_sync status=begin '
      'startupPresentationApplied=$_startupPresentationApplied '
      'startupLiveHeadApplied=$_startupLiveHeadApplied '
      'agendaCount=${agendaList.length}',
    );

    final future = _performSyncFeedHeadAfterSurfaceOpen();
    _headSyncFuture = future;
    try {
      await future;
    } finally {
      if (identical(_headSyncFuture, future)) {
        _headSyncFuture = null;
      }
    }
  }

  Future<void> _performSyncFeedHeadAfterSurfaceOpen() async {
    final mutationEpoch = _feedMutationEpoch;
    final playbackAnchor = _agendaFeedApplicationService.capturePlaybackAnchor(
      agendaList: agendaList.toList(growable: false),
      centeredIndex: centeredIndex.value,
      lastCenteredIndex: lastCenteredIndex,
    );
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = _agendaCutoffMs(nowMs);
    _AgendaSourcePage page;
    try {
      page = await _profileFeedHeadSyncStep('load_live_page', () {
        return _loadAgendaSourcePage(
          nowMs: nowMs,
          cutoffMs: cutoffMs,
          limit: _initialHeadSyncLimit,
          startAfter: null,
          useStoredCursor: false,
          preferCache: false,
          cacheOnly: false,
          includeSupplementalSources: false,
        );
      });
    } catch (error) {
      final signedOut =
          CurrentUserService.instance.effectiveUserId.trim().isEmpty;
      if (signedOut && _isTransientAgendaPermissionDenied(error)) {
        debugPrint(
          '[agenda] ignored head sync permission loss after sign-out: $error',
        );
        return;
      }
      rethrow;
    }
    final visibleItems = page.items;

    _usePrimaryFeedPaging = page.usesPrimaryFeed;
    if (page.lastDoc != null) {
      lastDoc = page.lastDoc;
      hasMore.value = true;
    } else if (visibleItems.length < _initialHeadSyncLimit) {
      hasMore.value = false;
    }

    if (visibleItems.isEmpty) {
      debugPrint(
        '[FeedStartupHeadSync] source=surface_open_sync status=no_visible_items',
      );
      return;
    }
    if (mutationEpoch != _feedMutationEpoch) {
      debugPrint(
        '[FeedStartupHeadSync] source=surface_open_sync status=mutation_changed '
        'requestEpoch=$mutationEpoch currentEpoch=$_feedMutationEpoch',
      );
      return;
    }

    final currentAgenda = agendaList.toList(growable: false);
    final shouldReplaceStartupHead =
        _startupPresentationApplied && !_startupLiveHeadApplied;
    final shouldLockStartupHeadOnly = _shouldLockStartupHeadOnly(currentAgenda);
    final mergedAgenda =
        await _profileFeedHeadSyncStep('compose_next_head', () async {
      if (shouldLockStartupHeadOnly) {
        return _composeLockedStartupHead(
          currentAgenda: currentAgenda,
          liveItems: visibleItems,
        );
      }
      return shouldReplaceStartupHead
          ? _mergeStartupHeadWithCurrentItems(
              currentItems: currentAgenda,
              liveItems: visibleItems,
              targetCount: FeedSnapshotRepository.startupHomeLimitValue,
              nowMs: nowMs,
            )
          : (() {
              final fetchedById = <String, PostsModel>{
                for (final post in visibleItems) post.docID: post,
              };
              return currentAgenda
                  .map((post) => fetchedById[post.docID] ?? post)
                  .toList(growable: false);
            })();
    });
    if (shouldReplaceStartupHead) {
      debugPrint(
        '[FeedStartupHeadSwap] source=surface_open_sync '
        'currentCount=${currentAgenda.length} liveCount=${visibleItems.length} '
        'nextCount=${mergedAgenda.length} '
        'currentHead=${currentAgenda.take(5).map((post) => post.docID).join(",")} '
        'liveHead=${visibleItems.take(5).map((post) => post.docID).join(",")} '
        'nextHead=${mergedAgenda.take(5).map((post) => post.docID).join(",")}',
      );
    } else {
      debugPrint(
        '[FeedStartupHeadSync] source=surface_open_sync status=merge_without_swap '
        'startupPresentationApplied=$_startupPresentationApplied '
        'startupLiveHeadApplied=$_startupLiveHeadApplied '
        'liveCount=${visibleItems.length}',
      );
    }
    await _profileFeedHeadSyncStep('apply_head', () async {
      if (currentAgenda.isEmpty && mergedAgenda.isNotEmpty) {
        _startupRenderBootstrapHold = true;
        _activateStartupRenderStages(
          reason: 'surface_open_sync_apply_head',
        );
      }
      agendaList.assignAll(mergedAgenda);
      _debugAgendaKinds('surface_open_sync_apply_head', agendaList);
      _applyStartupRenderStagesNow();
    });
    if (shouldReplaceStartupHead) {
      _startupLiveHeadApplied = true;
    }
    _scheduleInitialFeedVideoPosterWarmup(visibleItems);
    if (playbackAnchor != null && playbackAnchor.isNotEmpty) {
      _pendingCenteredDocId = playbackAnchor;
    }

    if (playbackAnchor != null &&
        playbackAnchor.isNotEmpty &&
        !pauseAll.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isClosed ||
            pauseAll.value ||
            agendaList.isEmpty ||
            mutationEpoch != _feedMutationEpoch) {
          return;
        }
        resumeFeedPlayback();
      });
    }

    await _profileFeedHeadSyncStep('persist_head_snapshot', () {
      return _saveFeedPostsToPool(
        _buildOrderedAgendaSnapshot(
          limit: ReadBudgetRegistry.feedPersistSnapshotLimit,
        ),
        const <String, Map<String, dynamic>>{},
        source: CachedResourceSource.server,
      );
    });
  }

  Future<void> refreshAgenda() async {
    final refreshEpoch = _feedMutationEpoch + 1;
    _feedMutationEpoch = refreshEpoch;
    try {
      _resetBufferedFeedFetchTrigger();
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
      final loadLimit = _refreshHeadSyncLimit;
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
      final mergedAgenda = _mergeStartupHeadWithCurrentItems(
        currentItems: previousAgenda,
        liveItems: page.items,
        targetCount: FeedSnapshotRepository.startupHomeLimitValue,
        nowMs: nowMs,
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
      _prefetchedThumbnailPostCount = 0;
      _startupPromoRevealUnlockedByScroll = false;
      _startupPromoRevealSawUserDrag = false;
      _resetStartupRenderStages();
      _prefetchedThumbnailDocIds.clear();
      _shuffleCache.clear();
      publicReshareEvents.clear();
      feedReshareEntries.clear();
      highlightDocIDs.clear();
      agendaList.assignAll(mergedAgenda);
      try {
        maybeFindPrefetchScheduler()?.seedFeedBankCandidates(
          mergedAgenda,
          currentIndex: 0,
        );
      } catch (_) {}
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
      unawaited(Future<void>(() async {
        try {
          await _saveFeedPostsToPool(
            _buildOrderedAgendaSnapshot(
              limit: ReadBudgetRegistry.feedPersistSnapshotLimit,
            ),
            const <String, Map<String, dynamic>>{},
            source: CachedResourceSource.server,
          );
        } catch (_) {}
      }));

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

class _AgendaBufferedFeedBlockLoadResult {
  const _AgendaBufferedFeedBlockLoadResult({
    required this.blockItems,
    required this.lastDoc,
    required this.usesPrimaryFeed,
    required this.hasMore,
  });

  final List<PostsModel> blockItems;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool usesPrimaryFeed;
  final bool hasMore;
}
