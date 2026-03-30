part of 'agenda_controller.dart';

extension AgendaControllerLoadingPart on AgendaController {
  static const int _initialHeadSyncLimit =
      ReadBudgetRegistry.feedHomeInitialLimit;

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

  void _performResetSurfaceForTabTransition() {
    _cancelDeferredInitialNetworkBootstrap();
    _cancelPendingPlaybackReassert();
    _pendingCenteredDocId = null;
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
            pageLimit: ReadBudgetRegistry.feedHomeInitialLimit,
            trigger: 'deferred_initial_bootstrap',
          ),
        );
      },
    );
  }

  bool _shouldDeferInitialNetworkBootstrap() {
    return false;
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
    final preserveVisibleFeedOnInitialBootstrap =
        initial && previousAgenda.isNotEmpty && trigger != 'refresh_agenda';

    if (preserveVisibleFeedOnInitialBootstrap) {
      await syncFeedHeadAfterSurfaceOpen();
      return;
    }

    if (initial) {
      lastDoc = null;
      _usePrimaryFeedPaging = true;
      hasMore.value = true;
      _prefetchedThumbnailPostCount = 0;
      agendaList.clear();
      _shuffleCache.clear();
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
        if (!_shuffleCache.hasMore) {
          hasMore.value = false;
        }
      } finally {
        isLoading.value = false;
      }
      return;
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

    isLoading.value = true;
    recordQALabFeedFetchEvent(
      stage: 'started',
      trigger: trigger,
      metadata: <String, dynamic>{
        'initial': initial,
        'pageLimit': pageLimit ?? 0,
        'currentCount': agendaList.length,
      },
    );
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      final loadLimit = initial ? 30 : (pageLimit ?? fetchLimit);
      final liveConnected = ContentPolicy.isConnected;
      final shouldPreferCacheOnOpen =
          !liveConnected || (initial && agendaList.isEmpty);
      final page = await _loadAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: loadLimit,
        preferCache: shouldPreferCacheOnOpen,
        cacheOnly: !liveConnected,
      );
      final visibleItems = page.items;
      final pageApplyPlan = _agendaFeedApplicationService.buildPageApplyPlan(
        currentItems: agendaList.toList(growable: false),
        pageItems: visibleItems,
        nowMs: nowMs,
        loadLimit: loadLimit,
        lastDoc: page.lastDoc,
        usesPrimaryFeed: page.usesPrimaryFeed,
      );

      _usePrimaryFeedPaging = pageApplyPlan.usesPrimaryFeed;
      lastDoc = pageApplyPlan.lastDoc;

      if (visibleItems.isNotEmpty) {
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
        if (pageApplyPlan.itemsToAdd.isNotEmpty) {
          _addUniqueToAgenda(pageApplyPlan.itemsToAdd);
          _scheduleReshareFetchForPosts(
            pageApplyPlan.itemsToAdd,
            perPostLimit: 1,
          );
        }
      }

      hasMore.value = pageApplyPlan.hasMore;
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
          'usesPrimaryFeed': page.usesPrimaryFeed,
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
          if (centeredIndex.value == -1) {
            primeInitialCenteredPost();
          }
        }
        _scheduleAgendaRetry(initial: initial && agendaList.isEmpty);
      }
    } finally {
      isLoading.value = false; // HER DURUMDA EN SON ÇALIŞIR

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
    if (agendaList.isEmpty && !isLoading.value) {
      await hydrateInitialFeedFromCache(
        targetCount: FeedSnapshotRepository.startupHomeLimit,
      );
    }

    if (agendaList.isNotEmpty) {
      _prepareFeedSurfaceAfterDataReady(
        playbackBootstrapSource: 'ensure_feed_surface_ready',
      );
      return;
    }

    if (!isLoading.value) {
      await ensureInitialFeedLoaded();
      _prepareFeedSurfaceAfterDataReady(
        playbackBootstrapSource: 'ensure_feed_surface_ready_after_load',
      );
    }
  }

  Future<void> syncFeedHeadAfterSurfaceOpen() async {
    if (!ContentPolicy.isConnected || agendaList.isEmpty || isLoading.value) {
      return;
    }

    final inFlight = _headSyncFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final now = DateTime.now();
    if (_lastHeadSyncAt != null &&
        now.difference(_lastHeadSyncAt!) < const Duration(seconds: 12)) {
      return;
    }
    _lastHeadSyncAt = now;

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
      page = await _loadAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: _initialHeadSyncLimit,
        startAfter: null,
        preferCache: false,
        cacheOnly: false,
      );
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
      return;
    }
    if (mutationEpoch != _feedMutationEpoch) {
      return;
    }

    final existingIds = agendaList.map((post) => post.docID).toSet();
    final added = visibleItems
        .where((post) => !existingIds.contains(post.docID))
        .toList(growable: false);
    final liveHeadIds = visibleItems.map((post) => post.docID).toSet();
    final mergedAgenda = <PostsModel>[
      ...visibleItems,
      ...agendaList.where((post) => !liveHeadIds.contains(post.docID)),
    ];
    agendaList.assignAll(mergedAgenda);
    if (playbackAnchor != null && playbackAnchor.isNotEmpty) {
      _pendingCenteredDocId = playbackAnchor;
    }

    if (added.isNotEmpty) {
      _scheduleFeedPrefetch();
      _scheduleReshareFetchForPosts(added, perPostLimit: 1);
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

    await _saveFeedPostsToPool(
      _buildOrderedAgendaSnapshot(limit: 40),
      const <String, Map<String, dynamic>>{},
      source: CachedResourceSource.server,
    );
  }

  Future<void> refreshAgenda() async {
    final refreshEpoch = _feedMutationEpoch + 1;
    _feedMutationEpoch = refreshEpoch;
    try {
      _cancelDeferredInitialNetworkBootstrap();
      // Refresh başlarken tüm oynatımları kesin durdur.
      pauseAll.value = true;
      _pendingCenteredDocId = null;
      lastCenteredIndex = 0;
      _visibleFractions.clear();
      _visibleUpdatedAt.clear();
      _lastPlaybackWindowSignature = null;
      _lastPlaybackRowUpdateDocId = null;
      centeredIndex.value = -1;
      try {
        VideoStateManager.instance.pauseAllVideos(force: true);
      } catch (_) {}

      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }

      // Following/reshare verilerini yenile (SWR)
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isNotEmpty) unawaited(_fetchFollowingAndReshares(uid));

      await _refreshAgendaFromLiveSource();
      await _fetchAndMergeReshareEvents(
        eventLimit: ReadBudgetRegistry.reshareFeedWarmupInitialLimit,
      );
      pauseAll.value = false;
      _resumeFeedPlaybackAfterRefresh(expectedEpoch: refreshEpoch);
    } catch (e) {
      print("refreshAgenda error: $e");
      pauseAll.value = false;
      _resumeFeedPlaybackAfterRefresh(expectedEpoch: refreshEpoch);
    }
  }

  Future<void> _refreshAgendaFromLiveSource() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final previousAgenda = agendaList.toList(growable: false);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cutoffMs = _agendaCutoffMs(nowMs);
      const loadLimit = 30;
      final page = await _loadAgendaSourcePage(
        nowMs: nowMs,
        cutoffMs: cutoffMs,
        limit: loadLimit,
        startAfter: null,
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
      final liveHeadIds = page.items.map((post) => post.docID).toSet();
      final mergedAgenda = <PostsModel>[
        ...page.items,
        ...previousAgenda.where((post) => !liveHeadIds.contains(post.docID)),
      ];

      _usePrimaryFeedPaging = pageApplyPlan.usesPrimaryFeed;
      lastDoc = pageApplyPlan.lastDoc;
      hasMore.value = pageApplyPlan.hasMore;
      _prefetchedThumbnailPostCount = 0;
      _shuffleCache.clear();
      publicReshareEvents.clear();
      feedReshareEntries.clear();
      highlightDocIDs.clear();
      agendaList.assignAll(mergedAgenda);

      if (pageApplyPlan.freshScheduledIds.isNotEmpty) {
        markHighlighted(
          pageApplyPlan.freshScheduledIds,
          keepFor: const Duration(milliseconds: 900),
        );
      }

      await _saveFeedPostsToPool(
        _buildOrderedAgendaSnapshot(limit: 40),
        const <String, Map<String, dynamic>>{},
        source: CachedResourceSource.server,
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
