part of 'short_view.dart';

extension ShortViewPlaybackPart on _ShortViewState {
  Future<void> _reassertActiveShortAudibility(
    int page,
    HLSVideoAdapter adapter,
  ) async {
    if (!mounted ||
        page != currentPage ||
        !_isShortRoutePlaybackActive ||
        adapter.isDisposed) {
      return;
    }
    try {
      await adapter.setVolume(volume ? 1.0 : 0.0);
    } catch (_) {}
    _applyShortPlaybackPresentation(page, adapter);
  }

  void _scheduleDelayedShortAudibilityReassert(
    int page,
    HLSVideoAdapter adapter, {
    Duration delay = const Duration(milliseconds: 260),
  }) {
    Future<void>.delayed(delay, () async {
      await _reassertActiveShortAudibility(page, adapter);
    });
  }

  void _syncShortExclusivePlaybackOwner([int? preferredPage]) {
    if (!_isShortRoutePlaybackActive || _cachedShorts.isEmpty) return;
    final page = preferredPage ?? currentPage;
    if (page < 0 || page >= _cachedShorts.length) return;
    final docId = _cachedShorts[page].docID.trim();
    if (docId.isEmpty) return;
    try {
      _playbackRuntimeService.enterExclusiveMode(
        controller.playbackHandleKeyForDoc(docId),
      );
    } catch (_) {}
  }

  Future<void> _parkShortAfterPageExit(
    int page,
    HLSVideoAdapter adapter,
  ) async {
    if (page < 0 || page >= _cachedShorts.length || adapter.isDisposed) {
      return;
    }
    _persistShortPlaybackState(page, adapter);
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await adapter.pause();
      } catch (_) {}
      try {
        await adapter.setVolume(0.0);
      } catch (_) {}
      return;
    }
    await _releasePlayback(adapter);
    if (!adapter.isStopped) {
      return;
    }
    try {
      await adapter.seekTo(Duration.zero);
    } catch (_) {}
  }

  void _markStartupPlaybackSettled() {
    if (_startupPlaybackSettled) return;
    _startupPlaybackSettled = true;
    final pending = _pendingStartupRenderList;
    if (pending == null) return;
    _pendingStartupRenderList = null;
    _applyRenderListUpdate(pending);
  }

  void _rebindActiveRenderPage({
    bool forceState = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_isShortRoutePlaybackActive || _cachedShorts.isEmpty) {
        return;
      }
      final page = currentPage;
      if (page < 0 || page >= _cachedShorts.length) return;
      final hadActiveAdapter = controller.cache[page] != null;
      await controller.ensureActiveAdapterReady(page);
      if (!mounted ||
          !_isShortRoutePlaybackActive ||
          _cachedShorts.isEmpty ||
          page != currentPage) {
        return;
      }
      _setStateIfActiveAdapterChanged(
        page,
        hadActiveAdapter,
        force: forceState,
      );
      _scheduleTierReconcile(
        page,
        suppressWarmPause: true,
      );
      if (!isManuallyPaused && controller.cache[page] != null) {
        _schedulePlayForPage(page);
      }
    });
  }

  bool _shouldSuppressDuplicateAutoplayBootstrap(
    int page, {
    Duration minSpacing = const Duration(milliseconds: 450),
  }) {
    if (page < 0 || page >= _cachedShorts.length) return false;
    final docId = _cachedShorts[page].docID.trim();
    if (docId.isEmpty) return false;
    final token = '$page:$docId';
    final lastToken = _lastAutoplayBootstrapToken;
    final lastAt = _lastAutoplayBootstrapAt;
    final now = DateTime.now();
    _lastAutoplayBootstrapToken = token;
    _lastAutoplayBootstrapAt = now;
    if (lastToken != token || lastAt == null) {
      return false;
    }
    return now.difference(lastAt) < minSpacing;
  }

  bool _shouldSuppressDuplicatePrimaryPlay(
    String docId,
    HLSVideoAdapter adapter, {
    Duration minSpacing = const Duration(milliseconds: 450),
  }) {
    final trimmed = docId.trim();
    if (trimmed.isEmpty) return false;
    final lastDocId = _lastPrimaryPlayDocId;
    final lastAt = _lastPrimaryPlayAt;
    if (lastDocId != trimmed || lastAt == null) {
      return false;
    }
    final isRecent = DateTime.now().difference(lastAt) < minSpacing;
    if (!isRecent) return false;
    return true;
  }

  bool _shouldSuppressShortPlaybackAttempt(
    int page,
    String docId, {
    required String source,
    Duration minSpacing = const Duration(milliseconds: 650),
  }) {
    final trimmed = docId.trim();
    if (trimmed.isEmpty) return false;
    final token = '$page:$trimmed';
    final lastToken = _lastShortPlaybackAttemptToken;
    final lastAt = _lastShortPlaybackAttemptAt;
    final now = DateTime.now();
    if (lastToken == token &&
        lastAt != null &&
        now.difference(lastAt) < minSpacing) {
      return true;
    }
    _lastShortPlaybackAttemptToken = token;
    _lastShortPlaybackAttemptAt = now;
    return false;
  }

  void _requestExclusivePlayback(
    String docId,
    HLSVideoAdapter adapter, {
    Duration minSpacing = const Duration(milliseconds: 220),
  }) {
    final trimmed = docId.trim();
    if (trimmed.isEmpty) return;
    final playbackHandleKey = controller.playbackHandleKeyForDoc(trimmed);
    final now = DateTime.now();
    final lastDocId = _lastExclusivePlayDocId;
    final lastAt = _lastExclusivePlayAt;
    if (lastDocId == playbackHandleKey &&
        lastAt != null &&
        now.difference(lastAt) < minSpacing) {
      return;
    }
    _lastExclusivePlayDocId = playbackHandleKey;
    _lastExclusivePlayAt = now;
    try {
      _playbackRuntimeService.playOnlyThis(playbackHandleKey);
    } catch (_) {}
  }

  bool _shouldTrimShortAttachedPlayers(int page) {
    if (!_isShortRoutePlaybackActive) return false;
    final maxAttachedPlayers =
        ShortPlaybackCoordinator.forCurrentPlatform().maxAttachedPlayers;
    final attachedPlayerCount = controller.cache.length;
    if (attachedPlayerCount > maxAttachedPlayers) {
      return true;
    }
    final activePlayerCount = controller.cache.values
        .where((adapter) => !adapter.isStopped && !adapter.isDisposed)
        .length;
    return activePlayerCount > maxAttachedPlayers;
  }

  Future<void> _trimShortAttachedPlayers(int page) async {
    if (!_shouldTrimShortAttachedPlayers(page)) return;
    try {
      await controller.trimOverflowAroundIndex(page);
    } catch (_) {}
  }

  void _resetShortAutoplaySegmentGate() {
    _autoplaySegmentGateStartedAt = null;
    _autoplaySegmentGateTimedOut = false;
  }

  bool _hasReadyShortSegment(int page) {
    if (page < 0 || page >= _cachedShorts.length) return true;
    try {
      return _segmentCacheRuntimeService.hasReadySegment(
        _cachedShorts[page].docID,
      );
    } catch (_) {
      return true;
    }
  }

  bool _hasRenderableListChanged(
    List<PostsModel> previous,
    List<PostsModel> next,
  ) {
    if (previous.length != next.length) return true;
    for (int i = 0; i < previous.length; i++) {
      if (previous[i].docID != next[i].docID) {
        return true;
      }
    }
    return false;
  }

  void _applyRenderListUpdate(List<PostsModel> nextList) {
    if (!_hasRenderableListChanged(_cachedShorts, nextList)) {
      return;
    }

    final previousList = List<PostsModel>.from(_cachedShorts);
    final update = _shortRenderCoordinator.buildUpdate(
      previous: previousList,
      next: nextList,
      currentIndex: currentPage,
    );
    if (update.patch.isEmpty) return;
    final previousPage = _initialDisplayIndex(previousList, currentPage);
    final previousActiveDocId = previousList.isEmpty ||
            previousPage < 0 ||
            previousPage >= previousList.length
        ? ''
        : previousList[previousPage].docID.trim();
    final remappedPage = _initialDisplayIndex(nextList, update.remappedIndex);
    final nextActiveDocId =
        nextList.isEmpty || remappedPage < 0 || remappedPage >= nextList.length
            ? ''
            : nextList[remappedPage].docID.trim();
    final shouldDeferStartupSwap = !_startupPlaybackSettled &&
        previousActiveDocId.isNotEmpty &&
        nextActiveDocId.isNotEmpty &&
        previousActiveDocId != nextActiveDocId;
    if (shouldDeferStartupSwap) {
      _pendingStartupRenderList = List<PostsModel>.from(nextList);
      return;
    }
    _shortRenderCoordinator.trackUpdateMetrics(
      previous: previousList,
      currentIndex: currentPage,
      update: update,
      next: nextList,
    );

    _shortRenderCoordinator.applyPatch(_cachedShorts, update.patch);
    currentPage = remappedPage;
    controller.lastIndex.value = currentPage;

    _updateShortViewState(() {});

    if (pageController.hasClients && remappedPage != previousPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !pageController.hasClients) return;
        try {
          pageController.jumpToPage(remappedPage);
        } catch (_) {}
      });
    }

    final activeDocChanged = previousActiveDocId != nextActiveDocId;
    _rebindActiveRenderPage(
      forceState: activeDocChanged,
    );
  }

  void _onPageChanged(int page) {
    if (_cachedShorts.isEmpty) return;
    if (page == currentPage) return;
    _forceResumePosterOnReturn = false;
    final isAutoAdvance = _pendingAutoAdvancePage == page;
    if (isAutoAdvance) {
      _pendingAutoAdvancePage = null;
    }
    if (_preparedAutoAdvancePage == page) {
      _preparedAutoAdvancePage = null;
    }
    _playDebounce?.cancel();
    _tierDebounce?.cancel();
    _tierReconcileDebounce?.cancel();
    _playbackWatchdogTimer?.cancel();
    _completionWatchdogTimer?.cancel();
    _stallWatchdogTimer?.cancel();
    _iosNativePlaybackGuardTimer?.cancel();
    final nextDocId = page >= 0 && page < _cachedShorts.length
        ? _cachedShorts[page].docID
        : '';
    _currentScrollToken = nextDocId.isEmpty
        ? ''
        : '${DateTime.now().microsecondsSinceEpoch}:$page:$nextDocId';
    recordQALabScrollEvent(
      surface: 'short',
      phase: 'settled',
      metadata: <String, dynamic>{
        'fromIndex': currentPage,
        'toIndex': page,
        'docId': nextDocId,
        'count': _cachedShorts.length,
        'scrollToken': _currentScrollToken,
      },
    );

    final oldVc = controller.cache[currentPage];
    if (oldVc != null) {
      unawaited(_parkShortAfterPageExit(currentPage, oldVc));
      _detachVideoEndListener(oldVc);
      oldVc.removeListener(_telemetryListener);
    }

    if (currentPage < _cachedShorts.length) {
      VideoTelemetryService.instance
          .endSession(_cachedShorts[currentPage].docID);
    }

    _updateShortViewState(() {
      currentPage = page;
      controller.lastIndex.value = currentPage;
      _showOverlayControls = true;
    });
    controller.primeForwardReadyMagazine(
      currentPage,
      aheadCount: 5,
      minimumSegmentCount: 1,
    );
    controller.primePlaybackWindowReadySegments(
      currentPage,
      minimumSegmentCount: 2,
    );
    unawaited(
      controller.ensureShortMotorStageForViewedIndex(
        currentPage,
        trigger: 'page_changed',
      ),
    );
    _syncShortExclusivePlaybackOwner(page);
    _pendingPageActivation = true;
    _lastPrimaryPlayDocId = null;
    _lastPrimaryPlayAt = null;
    _resetShortAutoplaySegmentGate();
    isManuallyPaused = false;
    _isTransitioning = false;
    _telemetryFirstFrame = false;
    _telemetryAdapter = null;
    _lastPersistedProgress = 0.0;
    _lastProgressPersistAt = null;
    _engagementRescoreTimer?.cancel();

    _ensureActivePageAdapterAfterBuild(page);
    _prepareUpcomingVideoForSwipe(activePageOverride: page);

    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(
      defaultTargetPlatform == TargetPlatform.android
          ? (isAutoAdvance ? Duration.zero : _shortScrollDebounceAndroid)
          : const Duration(milliseconds: 60),
      () {
        if (!mounted) return;

        _enforceSingleActiveAudio(page);
        _schedulePlayForPage(currentPage);
        _scheduleTierUpdate(currentPage);
        controller.loadMoreIfNeeded(currentPage);
      },
    );
  }

  Future<void> _prepareNextVideoForAutoAdvance(
    int activePage,
    int nextPage,
  ) async {
    if (nextPage < 0 || nextPage >= _cachedShorts.length) return;
    final hadActiveAdapter = controller.cache[nextPage] != null;
    await controller.prepareNeighborAdapter(activePage, nextPage);
    if (!mounted) return;
    _setStateIfActiveAdapterChanged(nextPage, hadActiveAdapter);
  }

  void _prepareUpcomingVideoForSwipe({
    int? activePageOverride,
  }) {
    final activePage = activePageOverride ?? currentPage;
    final nextPage = activePage + 1;
    if (nextPage >= _cachedShorts.length) return;
    if (_preparedAutoAdvancePage == nextPage) return;
    _preparedAutoAdvancePage = nextPage;
    unawaited(() async {
      try {
        await _prepareNextVideoForAutoAdvance(activePage, nextPage);
      } catch (_) {
        if (_preparedAutoAdvancePage == nextPage) {
          _preparedAutoAdvancePage = null;
        }
      }
    }());
  }

  void _maybePrepareNextVideoForAutoAdvance(double progress) {
    if (progress < 0.90) return;
    final nextPage = currentPage + 1;
    if (nextPage >= _cachedShorts.length) {
      unawaited(controller.loadMoreIfNeeded(currentPage));
      return;
    }
    if (_preparedAutoAdvancePage == nextPage) return;
    _preparedAutoAdvancePage = nextPage;
    unawaited(() async {
      try {
        await _prepareNextVideoForAutoAdvance(currentPage, nextPage);
      } catch (_) {
        if (_preparedAutoAdvancePage == nextPage) {
          _preparedAutoAdvancePage = null;
        }
      }
    }());
  }

  Future<bool> _ensureNextVideoAvailableForAutoAdvance(int activePage) async {
    final nextPage = activePage + 1;
    if (nextPage < _cachedShorts.length) return true;
    try {
      await controller.loadMoreIfNeeded(activePage);
    } catch (_) {}
    if (!mounted) return false;
    final controllerShorts = controller.shorts;
    if (controllerShorts.length > _cachedShorts.length) {
      _applyRenderListUpdate(List<PostsModel>.from(controllerShorts));
    }
    return nextPage < _cachedShorts.length;
  }

  void _scheduleAutoAdvanceRetry(
    int activePage,
    int nextPage, {
    int attempt = 0,
  }) {
    if (attempt >= 3) return;
    Future<void>.delayed(const Duration(milliseconds: 140), () async {
      if (!mounted ||
          !_isShortRoutePlaybackActive ||
          currentPage != activePage ||
          _pendingAutoAdvancePage != nextPage) {
        return;
      }
      if (!pageController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scheduleAutoAdvanceRetry(
            activePage,
            nextPage,
            attempt: attempt + 1,
          );
        });
        return;
      }
      try {
        pageController.jumpToPage(nextPage);
      } catch (_) {}
      if (currentPage == activePage) {
        _scheduleAutoAdvanceRetry(
          activePage,
          nextPage,
          attempt: attempt + 1,
        );
      }
    });
  }

  void _prepareUpcomingVideoAfterFirstFrame() {
    _prepareUpcomingVideoForSwipe();
  }

  void _persistShortPlaybackState(int page, HLSVideoAdapter adapter) {
    if (page < 0 || page >= _cachedShorts.length || adapter.isDisposed) return;
    try {
      final docId = _cachedShorts[page].docID;
      final handleKey = controller.playbackHandleKeyForDoc(docId);
      debugPrint(
        '[ShortResume] save page=$page doc=$docId handle=$handleKey '
        'posMs=${adapter.value.position.inMilliseconds} '
        'durMs=${adapter.value.duration.inMilliseconds} '
        'playing=${adapter.value.isPlaying}',
      );
      _playbackRuntimeService.savePlaybackState(
        handleKey,
        HLSAdapterPlaybackHandle(adapter),
      );
    } catch (_) {}
  }

  Duration? _savedPlaybackPositionForPage(int page, HLSVideoAdapter adapter) {
    if (page < 0 || page >= _cachedShorts.length || adapter.isDisposed) {
      return null;
    }
    final handleKey =
        controller.playbackHandleKeyForDoc(_cachedShorts[page].docID);
    final state = VideoStateManager.instance.getVideoState(
      handleKey,
    );
    if (state == null || state.position <= const Duration(milliseconds: 50)) {
      return null;
    }
    final duration = adapter.value.duration;
    var target = state.position;
    if (duration > Duration.zero) {
      final maxSeek = duration - const Duration(milliseconds: 120);
      if (maxSeek <= Duration.zero) return null;
      if (target > maxSeek) {
        target = maxSeek;
      }
    }
    final currentPosition = adapter.value.position;
    final currentMs = currentPosition.inMilliseconds;
    final targetMs = target.inMilliseconds;
    final forwardSkewMs = targetMs - currentMs;
    final hasMeaningfulCurrentPosition = currentMs > 50;
    // Resume should recover lost position, not rewind or micro-adjust an
    // adapter that is already effectively at/after the saved timestamp.
    if (hasMeaningfulCurrentPosition && forwardSkewMs <= 250) {
      _playbackRuntimeService.clearSavedPlaybackState(handleKey);
      return null;
    }
    if (adapter.isStopped || !adapter.value.isInitialized) {
      return target;
    }
    _playbackRuntimeService.clearSavedPlaybackState(handleKey);
    return null;
  }

  Future<void> _restoreShortPlaybackStateIfNeeded(
    int page,
    HLSVideoAdapter adapter,
  ) async {
    if (page < 0 || page >= _cachedShorts.length || adapter.isDisposed) return;
    final docId = _cachedShorts[page].docID;
    final handleKey = controller.playbackHandleKeyForDoc(docId);
    final target = _savedPlaybackPositionForPage(page, adapter);
    debugPrint(
      '[ShortResume] restore_check page=$page doc=$docId handle=$handleKey '
      'savedMs=${target?.inMilliseconds ?? -1} '
      'currentMs=${adapter.value.position.inMilliseconds} '
      'init=${adapter.value.isInitialized}',
    );
    if (target == null) return;
    try {
      debugPrint(
        '[ShortResume] restore_apply page=$page doc=$docId handle=$handleKey '
        'targetMs=${target.inMilliseconds}',
      );
      await adapter.seekTo(target);
      _playbackRuntimeService.clearSavedPlaybackState(handleKey);
    } catch (_) {}
  }

  bool _shouldRestartShortFromBeginning(
    int page,
    HLSVideoAdapter adapter,
  ) {
    if (page < 0 || page >= _cachedShorts.length || adapter.isDisposed) {
      return false;
    }
    final docId = _cachedShorts[page].docID;
    final handleKey = controller.playbackHandleKeyForDoc(docId);
    final savedState = _playbackRuntimeService.getSavedPlaybackState(handleKey);
    final savedPosition = savedState?.position ?? Duration.zero;
    if (savedPosition > Duration.zero) {
      return false;
    }
    final value = adapter.value;
    final duration = value.duration;
    final position = value.position;
    if (duration <= Duration.zero || position <= Duration.zero) {
      return false;
    }
    final remainingMs = duration.inMilliseconds - position.inMilliseconds;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    return value.isCompleted || remainingMs <= 160 || progress >= 0.985;
  }

  bool _shouldRecoverShortPlaybackOnRevisit(
    int page,
    HLSVideoAdapter adapter,
  ) {
    if (defaultTargetPlatform != TargetPlatform.iOS ||
        page < 0 ||
        page >= _cachedShorts.length ||
        adapter.isDisposed) {
      return false;
    }
    final docId = _cachedShorts[page].docID;
    final handleKey = controller.playbackHandleKeyForDoc(docId);
    final savedState = _playbackRuntimeService.getSavedPlaybackState(handleKey);
    final savedPosition = savedState?.position ?? Duration.zero;
    if (savedPosition > Duration.zero) {
      return false;
    }
    final value = adapter.value;
    return value.hasRenderedFirstFrame &&
        value.position >= const Duration(milliseconds: 800) &&
        !value.isCompleted;
  }

  bool _shouldResetArrivingShortToStart(
    int page,
    HLSVideoAdapter adapter,
  ) {
    if (!_pendingPageActivation ||
        page < 0 ||
        page >= _cachedShorts.length ||
        adapter.isDisposed) {
      return false;
    }
    final docId = _cachedShorts[page].docID;
    final handleKey = controller.playbackHandleKeyForDoc(docId);
    final savedState = _playbackRuntimeService.getSavedPlaybackState(handleKey);
    final savedPosition = savedState?.position ?? Duration.zero;
    if (savedPosition > Duration.zero) {
      return false;
    }
    return adapter.value.position > Duration.zero;
  }

  void _enforceSingleActiveAudio(int activePage) {
    for (final entry in controller.cache.entries) {
      final idx = entry.key;
      final vc = entry.value;
      if (idx == activePage) continue;
      try {
        _applyShortPlaybackPresentation(idx, vc);
        if (defaultTargetPlatform == TargetPlatform.android) {
          unawaited(vc.forceSilence());
        } else {
          _releasePlayback(vc);
        }
      } catch (_) {}
    }
  }

  void _scheduleTierUpdate(int page) {
    _tierDebounce?.cancel();
    _tierReconcileDebounce?.cancel();
    _tierDebounce = Timer(_shortTierDebounceDelay, () async {
      if (!_isShortRoutePlaybackActive) return;
      final hadActiveAdapter = controller.cache[page] != null;
      await controller.ensureActiveAdapterReady(page);
      if (!mounted || page != currentPage || !_isShortRoutePlaybackActive) {
        return;
      }
      _setStateIfActiveAdapterChanged(page, hadActiveAdapter);
      _schedulePlayForPage(page);
      _scheduleTierReconcile(page);
    });
  }

  void _scheduleTierReconcile(
    int page, {
    bool suppressWarmPause = false,
  }) {
    _tierReconcileDebounce?.cancel();
    _tierReconcileDebounce = Timer(_shortTierReconcileDelay, () async {
      if (!_isShortRoutePlaybackActive) return;
      final hadActiveAdapter = controller.cache[page] != null;
      await controller.updateCacheTiers(
        page,
        suppressWarmPause: suppressWarmPause,
      );
      await _trimShortAttachedPlayers(page);
      if (!mounted || page != currentPage || !_isShortRoutePlaybackActive) {
        return;
      }
      _setStateIfActiveAdapterChanged(page, hadActiveAdapter);
      if (!isManuallyPaused && controller.cache[page] != null) {
        _schedulePlayForPage(page);
      }
    });
  }

  Future<void> _startAutoPlayCurrentVideo() async {
    if (controller.shorts.isEmpty || !_isShortRoutePlaybackActive) return;
    if (_shouldSuppressDuplicateAutoplayBootstrap(currentPage)) return;

    isManuallyPaused = false;
    _syncShortExclusivePlaybackOwner(currentPage);
    if (currentPage >= 0 && currentPage < _cachedShorts.length) {
      final docId = _cachedShorts[currentPage].docID.trim();
      if (docId.isNotEmpty) {
        try {
          _segmentCacheRuntimeService.ensureMinimumReadySegments(docId);
        } catch (_) {}
      }
    }
    final hadActiveAdapter = controller.cache[currentPage] != null;
    final shouldPreserveCurrentAdapterOnRouteReturn =
        defaultTargetPlatform != TargetPlatform.android &&
            _forceResumePosterOnReturn &&
            hadActiveAdapter;
    if (defaultTargetPlatform != TargetPlatform.android &&
        !shouldPreserveCurrentAdapterOnRouteReturn) {
      await controller.keepOnlyIndex(currentPage);
    }

    await controller.ensureActiveAdapterReady(currentPage);
    if (!mounted) return;
    final currentAdapter = controller.cache[currentPage];
    if (currentAdapter != null) {
      await _reassertActiveShortAudibility(currentPage, currentAdapter);
    }
    _setStateIfActiveAdapterChanged(currentPage, hadActiveAdapter,
        force: false);
    _scheduleTierReconcile(
      currentPage,
      suppressWarmPause: true,
    );
    _prepareUpcomingVideoForSwipe(activePageOverride: currentPage);

    _schedulePlayForPage(currentPage);
    if (currentAdapter != null) {
      _scheduleDelayedShortAudibilityReassert(currentPage, currentAdapter);
    }
  }

  void _setStateIfActiveAdapterChanged(
    int page,
    bool hadActiveAdapter, {
    bool force = false,
  }) {
    if (!mounted) return;
    final hasActiveAdapter = controller.cache[page] != null;
    if (force || hadActiveAdapter != hasActiveAdapter) {
      _updateShortViewState(() {});
    }
  }

  void _ensureActivePageAdapterAfterBuild(int page) {
    if (!mounted || page != currentPage) return;
    if (page < 0 || page >= _cachedShorts.length) return;
    final docId = _cachedShorts[page].docID.trim();
    if (docId.isEmpty) return;
    final token = '$page:$docId';
    if (_pendingActiveAdapterEnsureToken == token) return;
    _pendingActiveAdapterEnsureToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted || page != currentPage || !_isShortRoutePlaybackActive) {
          return;
        }
        try {
          _segmentCacheRuntimeService.ensureMinimumReadySegments(docId);
        } catch (_) {}
        final hadActiveAdapter = controller.cache[page] != null;
        await controller.ensureActiveAdapterReady(page);
        await _trimShortAttachedPlayers(page);
        if (!mounted || page != currentPage || !_isShortRoutePlaybackActive) {
          return;
        }
        _setStateIfActiveAdapterChanged(page, hadActiveAdapter);
        _scheduleTierReconcile(
          page,
          suppressWarmPause: true,
        );
        if (!isManuallyPaused && controller.cache[page] != null) {
          _schedulePlayForPage(page);
        }
      } finally {
        if (_pendingActiveAdapterEnsureToken == token) {
          _pendingActiveAdapterEnsureToken = null;
        }
      }
    });
  }

  void _schedulePlayForPage(int page) {
    final scheduledDocId = page >= 0 && page < _cachedShorts.length
        ? _cachedShorts[page].docID.trim()
        : '';
    if (_playDebounce?.isActive == true &&
        _pendingPlayPage == page &&
        _pendingPlayDocId == scheduledDocId) {
      return;
    }
    _playDebounce?.cancel();
    _pendingPlayPage = page;
    _pendingPlayDocId = scheduledDocId;
    _playDebounce = Timer(
      defaultTargetPlatform == TargetPlatform.android
          ? _shortPlayResumeDelayAndroid
          : _shortPlayResumeDelay,
      () async {
        if (_pendingPlayPage == page) {
          _pendingPlayPage = null;
        }
        if (_pendingPlayDocId == scheduledDocId) {
          _pendingPlayDocId = null;
        }
        if (!mounted ||
            page != currentPage ||
            isManuallyPaused ||
            !_isShortRoutePlaybackActive) {
          return;
        }
        _enforceSingleActiveAudio(page);
        final hadActiveAdapter = controller.cache[page] != null;
        await controller.ensureActiveAdapterReady(page);
        if (!mounted ||
            page != currentPage ||
            isManuallyPaused ||
            !_isShortRoutePlaybackActive) {
          return;
        }
        _setStateIfActiveAdapterChanged(page, hadActiveAdapter);
        final vc = controller.cache[page];
        if (vc == null) return;
        final docId = page >= 0 && page < _cachedShorts.length
            ? _cachedShorts[page].docID
            : '';
        if (_shouldSuppressShortPlaybackAttempt(
          page,
          docId,
          source: 'primary',
        )) {
          _applyShortPlaybackPresentation(page, vc);
          return;
        }
        if (_shouldSuppressDuplicatePrimaryPlay(docId, vc)) {
          _applyShortPlaybackPresentation(page, vc);
          return;
        }
        _applyShortPlaybackPresentation(page, vc);
        if (docId.trim().isNotEmpty) {
          _segmentCacheRuntimeService.markServedInShort(docId);
        }
        await _reassertActiveShortAudibility(page, vc);
        final shouldGate = !_autoplaySegmentGateTimedOut &&
            vc.value.position <= Duration.zero &&
            !vc.value.isPlaying &&
            !vc.value.isInitialized &&
            !vc.value.hasRenderedFirstFrame &&
            !_hasReadyShortSegment(page);
        if (shouldGate) {
          if (docId.isNotEmpty) {
            try {
              _segmentCacheRuntimeService.ensureMinimumReadySegments(docId);
            } catch (_) {}
          }
          _autoplaySegmentGateStartedAt ??= DateTime.now();
          final elapsed =
              DateTime.now().difference(_autoplaySegmentGateStartedAt!);
          if (elapsed < _ShortViewState._shortAutoplaySegmentGateTimeout) {
            _playDebounce = Timer(
              _ShortViewState._shortAutoplaySegmentGatePollInterval,
              () {
                if (!mounted || page != currentPage || isManuallyPaused) {
                  return;
                }
                _schedulePlayForPage(page);
              },
            );
            return;
          }
          _autoplaySegmentGateTimedOut = true;
        } else {
          _resetShortAutoplaySegmentGate();
        }
        if (isManuallyPaused) return;
        _lastPrimaryPlayDocId = docId.trim().isEmpty ? null : docId.trim();
        _lastPrimaryPlayAt = DateTime.now();
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            docId.trim().isNotEmpty &&
            _recordedVisibleShortDocIds.add(docId.trim())) {
          unawaited(ensurePostInteractionService().recordView(docId.trim()));
        }
        recordQALabPlaybackDispatch(
          surface: 'short',
          stage: 'short_page_play',
          metadata: <String, dynamic>{
            'docId': docId,
            'page': page,
            'isPlaying': vc.value.isPlaying,
            'isInitialized': vc.value.isInitialized,
          },
        );
        await _restoreShortPlaybackStateIfNeeded(page, vc);
        if (_shouldResetArrivingShortToStart(page, vc)) {
          try {
            await vc.seekTo(Duration.zero);
          } catch (_) {}
        }
        if (_shouldRestartShortFromBeginning(page, vc)) {
          try {
            await vc.seekTo(Duration.zero);
          } catch (_) {}
        }
        var recoveredRevisitPlayback = false;
        if (_shouldRecoverShortPlaybackOnRevisit(page, vc)) {
          try {
            await vc.recoverFrozenPlayback();
            recoveredRevisitPlayback = true;
          } catch (_) {}
        }
        if (!recoveredRevisitPlayback && !vc.value.isPlaying) {
          await _playbackExecutionService.playAdapter(vc);
        }
        _pendingPageActivation = false;
        if (docId.isNotEmpty) {
          _requestExclusivePlayback(docId, vc);
          await _reassertActiveShortAudibility(page, vc);
          _scheduleDelayedShortAudibilityReassert(page, vc);
          _applyShortPlaybackPresentation(page, vc);
        }
        _scheduleIosShortPresentationRestore(page, vc);
        _scheduleIosShortAudibilityReassert(page, vc);
        _scheduleIosNativePlaybackGuard(page, vc);
        _setupVideoEndListener(page, vc);
        _schedulePlaybackWatchdog(page, vc);
        _scheduleCompletionWatchdog(page);
        _scheduleStallWatchdog(page, vc);

        if (page < _cachedShorts.length) {
          final post = _cachedShorts[page];
          VideoTelemetryService.instance
              .startSession(post.docID, post.playbackUrl);
          final decision = _shortPlaybackDecisionFor(page, vc.value);
          VideoTelemetryService.instance.updateRuntimeHints(
            post.docID,
            isAudible: decision.shouldBeAudible,
            hasStableFocus: false,
          );
          _telemetryFirstFrame = false;
          _telemetryAdapter = vc;
          vc.removeListener(_telemetryListener);
          vc.addListener(_telemetryListener);
          _reportStableShortFrameIfNeeded(
            page,
            vc,
            decision.hasStableVisualFrame,
          );
          _scheduleEngagementRescore(page);
        }

        if (page < _cachedShorts.length) {
          try {
            _segmentCacheRuntimeService.markPlayingAndTouchRecent(
              _cachedShorts.map((short) => short.docID).toList(growable: false),
              page,
            );
          } catch (_) {}
        }
      },
    );
  }

  void _scheduleIosShortAudibilityReassert(
    int page,
    HLSVideoAdapter vc, {
    int attempt = 0,
  }) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    const attemptDelays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 110),
      Duration(milliseconds: 260),
      Duration(milliseconds: 520),
      Duration(milliseconds: 900),
      Duration(milliseconds: 1400),
      Duration(milliseconds: 2000),
    ];
    final safeAttempt = attempt.clamp(0, attemptDelays.length - 1);
    final delay = attemptDelays[safeAttempt];
    Future<void>.delayed(delay, () async {
      if (!mounted ||
          page != currentPage ||
          isManuallyPaused ||
          !_isShortRoutePlaybackActive ||
          vc.isDisposed) {
        return;
      }
      final decision = _shortPlaybackDecisionFor(page, vc.value);
      if (!decision.shouldBeAudible) return;
      _applyShortPlaybackPresentation(page, vc);
      var stillMuted = false;
      try {
        stillMuted = await vc.isMutedNative();
      } catch (_) {}
      final shouldKickPlayback = vc.value.hasRenderedFirstFrame &&
          vc.value.position > Duration.zero &&
          !vc.value.isPlaying;
      final shouldRetrySoon = attempt < attemptDelays.length - 1 &&
          (!vc.value.hasRenderedFirstFrame ||
              stillMuted ||
              (vc.value.position > Duration.zero && !vc.value.isPlaying) ||
              vc.value.position < const Duration(milliseconds: 2500));
      if (!stillMuted && !shouldKickPlayback) {
        if (shouldRetrySoon) {
          _scheduleIosShortAudibilityReassert(
            page,
            vc,
            attempt: attempt + 1,
          );
        }
        return;
      }
      try {
        final shouldRecoverFrozenPlayback = vc.value.hasRenderedFirstFrame &&
            !vc.value.isCompleted &&
            vc.value.position >= const Duration(milliseconds: 2500);
        if (shouldRecoverFrozenPlayback) {
          await vc.recoverFrozenPlayback();
        } else {
          await _playbackExecutionService.playAdapter(vc);
        }
      } catch (_) {}
      if (!mounted ||
          page != currentPage ||
          isManuallyPaused ||
          !_isShortRoutePlaybackActive ||
          vc.isDisposed) {
        return;
      }
      _applyShortPlaybackPresentation(page, vc);
      final docId = page >= 0 && page < _cachedShorts.length
          ? _cachedShorts[page].docID.trim()
          : '';
      if (docId.isNotEmpty) {
        _requestExclusivePlayback(docId, vc);
      }
      if (attempt < attemptDelays.length - 1) {
        _scheduleIosShortAudibilityReassert(
          page,
          vc,
          attempt: attempt + 1,
        );
      }
    });
  }

  void _scheduleIosShortPresentationRestore(
    int page,
    HLSVideoAdapter vc,
  ) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    for (final delay in const <Duration>[
      Duration.zero,
      Duration(milliseconds: 120),
      Duration(milliseconds: 320),
    ]) {
      Future<void>.delayed(delay, () {
        if (!mounted ||
            page != currentPage ||
            vc.isDisposed ||
            isManuallyPaused ||
            !_isShortRoutePlaybackActive) {
          return;
        }
        _applyShortPlaybackPresentation(page, vc);
      });
    }
  }

  void _scheduleIosNativePlaybackGuard(
    int page,
    HLSVideoAdapter vc, {
    int attempt = 0,
  }) {
    _iosNativePlaybackGuardTimer?.cancel();
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    _iosNativePlaybackGuardTimer = Timer(
      attempt == 0
          ? const Duration(milliseconds: 1400)
          : const Duration(milliseconds: 900),
      () async {
        if (!mounted ||
            page != currentPage ||
            vc.isDisposed ||
            isManuallyPaused ||
            !_isShortRoutePlaybackActive) {
          return;
        }

        final beforePosition = vc.value.position;
        Map<String, dynamic> beforeDiag = const <String, dynamic>{};
        try {
          beforeDiag = await vc.getPlaybackDiagnostics();
        } catch (_) {}
        final beforeSilenceMs =
            (beforeDiag['rendererFrameSilenceMs'] as num?)?.toInt() ?? 0;
        final beforePlaying = (beforeDiag['isPlaying'] as bool?) ?? false;

        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted ||
            page != currentPage ||
            vc.isDisposed ||
            isManuallyPaused ||
            !_isShortRoutePlaybackActive) {
          return;
        }

        final afterPosition = vc.value.position;
        Map<String, dynamic> afterDiag = const <String, dynamic>{};
        try {
          afterDiag = await vc.getPlaybackDiagnostics();
        } catch (_) {}
        final afterSilenceMs =
            (afterDiag['rendererFrameSilenceMs'] as num?)?.toInt() ?? 0;
        final afterPlaying = (afterDiag['isPlaying'] as bool?) ?? false;
        final advancedMs =
            afterPosition.inMilliseconds - beforePosition.inMilliseconds;

        final likelyFrozen = vc.value.hasRenderedFirstFrame &&
            afterPosition >= const Duration(milliseconds: 800) &&
            advancedMs < 180 &&
            afterSilenceMs >= 1500 &&
            afterSilenceMs >= beforeSilenceMs &&
            (beforePlaying || afterPlaying || !vc.value.isPlaying);
        if (likelyFrozen) {
          final shouldRecoverFrozenPlayback =
              afterPosition >= const Duration(milliseconds: 2500);
          try {
            if (shouldRecoverFrozenPlayback) {
              await vc.recoverFrozenPlayback();
            } else {
              await _playbackExecutionService.playAdapter(vc);
            }
          } catch (_) {}
          if (!mounted ||
              page != currentPage ||
              vc.isDisposed ||
              isManuallyPaused ||
              !_isShortRoutePlaybackActive) {
            return;
          }
          _applyShortPlaybackPresentation(page, vc);
          final docId = page >= 0 && page < _cachedShorts.length
              ? _cachedShorts[page].docID.trim()
              : '';
          if (docId.isNotEmpty) {
            _requestExclusivePlayback(docId, vc);
            _applyShortPlaybackPresentation(page, vc);
          }
        }

        final shouldRetryGuard = attempt < 2 &&
            vc.value.hasRenderedFirstFrame &&
            !vc.value.isCompleted &&
            (vc.value.position < const Duration(milliseconds: 2500) ||
                !vc.value.isPlaying);
        if (shouldRetryGuard) {
          _scheduleIosNativePlaybackGuard(
            page,
            vc,
            attempt: attempt + 1,
          );
        }
      },
    );
  }

  void _scheduleStallWatchdog(int page, HLSVideoAdapter vc) {
    _stallWatchdogTimer?.cancel();
    _stallWatchdogRetries = 0;
    _stallWatchdogBufferingCycles = 0;
    _stallWatchdogLastPosition = vc.value.position;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return;
    }
    _armStallWatchdog(page, vc);
  }

  void _armStallWatchdog(int page, HLSVideoAdapter vc) {
    _stallWatchdogTimer?.cancel();
    _stallWatchdogTimer = Timer(const Duration(milliseconds: 900), () async {
      if (!mounted ||
          page != currentPage ||
          vc.isDisposed ||
          isManuallyPaused ||
          !_isShortRoutePlaybackActive) {
        return;
      }
      final value = vc.value;
      if (!value.isInitialized || !value.hasRenderedFirstFrame) {
        _stallWatchdogBufferingCycles = 0;
        _stallWatchdogLastPosition = value.position;
        _armStallWatchdog(page, vc);
        return;
      }
      final progressed = value.position > _stallWatchdogLastPosition;
      final prolongedBuffering = value.isBuffering &&
          value.position >= const Duration(milliseconds: 800) &&
          !progressed;
      if (prolongedBuffering) {
        _stallWatchdogBufferingCycles++;
      } else {
        _stallWatchdogBufferingCycles = 0;
      }
      final bufferingHealthy =
          value.isBuffering && _stallWatchdogBufferingCycles < 2;
      final healthy = progressed || bufferingHealthy || value.isCompleted;
      _stallWatchdogLastPosition = value.position;
      if (healthy) {
        _stallWatchdogRetries = 0;
        _armStallWatchdog(page, vc);
        return;
      }
      final remaining = value.duration > Duration.zero
          ? value.duration - value.position
          : Duration.zero;
      final shouldNudgeNearEndCompletion =
          defaultTargetPlatform == TargetPlatform.iOS &&
              value.duration > Duration.zero &&
              remaining > Duration.zero &&
              remaining <= const Duration(milliseconds: 700) &&
              value.position >= const Duration(milliseconds: 800);
      if (shouldNudgeNearEndCompletion) {
        try {
          await vc.seekTo(value.duration);
        } catch (_) {}
        _armStallWatchdog(page, vc);
        return;
      }
      final maxRetries = defaultTargetPlatform == TargetPlatform.iOS ? 4 : 2;
      if (_stallWatchdogRetries >= maxRetries) return;
      _stallWatchdogRetries++;
      try {
        final docId = page >= 0 && page < _cachedShorts.length
            ? _cachedShorts[page].docID
            : '';
        final shouldRecoverFrozenPlayback =
            defaultTargetPlatform == TargetPlatform.iOS &&
                value.hasRenderedFirstFrame &&
                !value.isCompleted &&
                (_stallWatchdogRetries > 1 ||
                    value.position >= const Duration(milliseconds: 2500));
        recordQALabPlaybackDispatch(
          surface: 'short',
          stage: 'short_stall_recovery_play',
          metadata: <String, dynamic>{
            'docId': docId,
            'page': page,
            'retry': _stallWatchdogRetries,
            'bufferingCycles': _stallWatchdogBufferingCycles,
            'mode': shouldRecoverFrozenPlayback ? 'recover' : 'play',
          },
        );
        _applyShortPlaybackPresentation(page, vc);
        final shouldHardRestartShort =
            defaultTargetPlatform == TargetPlatform.iOS &&
                _stallWatchdogRetries > 1 &&
                value.position > Duration.zero &&
                value.position < const Duration(milliseconds: 2000);
        if (shouldHardRestartShort) {
          try {
            await vc.seekTo(Duration.zero);
          } catch (_) {}
        }
        if (shouldRecoverFrozenPlayback) {
          await vc.recoverFrozenPlayback();
        } else {
          await _playbackExecutionService.playAdapter(vc);
        }
        if (docId.isNotEmpty) {
          _requestExclusivePlayback(docId, vc);
          _applyShortPlaybackPresentation(page, vc);
        }
      } catch (_) {}
      _armStallWatchdog(page, vc);
    });
  }

  void _schedulePlaybackWatchdog(int page, HLSVideoAdapter vc) {
    _playbackWatchdogTimer?.cancel();
    _playWatchdogRetries = 0;
    _playbackWatchdogBaselinePosition = vc.value.position;
    _armPlaybackWatchdog(
      page,
      vc,
      defaultTargetPlatform == TargetPlatform.android
          ? _shortPlayWatchdogDelayAndroid
          : _shortPlayWatchdogDelayIOS,
    );
  }

  void _scheduleCompletionWatchdog(int page) {
    _completionWatchdogTimer?.cancel();
    _armCompletionWatchdog(page);
  }

  void _armCompletionWatchdog(int page) {
    _completionWatchdogTimer?.cancel();
    _completionWatchdogTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted ||
          page != currentPage ||
          isManuallyPaused ||
          !_isShortRoutePlaybackActive) {
        return;
      }
      final vc = controller.cache[page];
      if (vc == null || vc.isDisposed) {
        _armCompletionWatchdog(page);
        return;
      }
      final value = vc.value;
      final durationMs = value.duration.inMilliseconds;
      final positionMs = value.position.inMilliseconds;
      final progress =
          durationMs > 0 && positionMs > 0 ? positionMs / durationMs : 0.0;
      final isNearEnd = durationMs > 0 &&
          positionMs > 0 &&
          ((durationMs - positionMs) <= 100 || progress >= 0.995);

      if (!_isTransitioning && (value.isCompleted || isNearEnd)) {
        final expectedDocId = page >= 0 && page < _cachedShorts.length
            ? _cachedShorts[page].docID
            : '';
        _handleVideoEndForAdapter(
          page,
          vc,
          expectedDocId: expectedDocId,
        );
        return;
      }
      _armCompletionWatchdog(page);
    });
  }

  void _armPlaybackWatchdog(
    int page,
    HLSVideoAdapter vc,
    Duration delay,
  ) {
    _playbackWatchdogTimer?.cancel();
    _playbackWatchdogTimer = Timer(delay, () async {
      if (!mounted ||
          page != currentPage ||
          vc.isDisposed ||
          isManuallyPaused ||
          !_isShortRoutePlaybackActive) {
        return;
      }
      final value = vc.value;
      final hasProgressedPastBaseline = value.position >=
          _playbackWatchdogBaselinePosition + const Duration(milliseconds: 220);
      final hasStarted = value.isPlaying || hasProgressedPastBaseline;
      if (hasStarted) return;
      if (_playWatchdogRetries >= 2) return;
      _playWatchdogRetries++;
      try {
        final docId = page >= 0 && page < _cachedShorts.length
            ? _cachedShorts[page].docID
            : '';
        if (_shouldSuppressShortPlaybackAttempt(
          page,
          docId,
          source: 'watchdog',
        )) {
          _armPlaybackWatchdog(page, vc, delay);
          return;
        }
        recordQALabPlaybackDispatch(
          surface: 'short',
          stage: 'short_watchdog_play_retry',
          metadata: <String, dynamic>{
            'docId': docId,
            'page': page,
            'retry': _playWatchdogRetries,
          },
        );
        _applyShortPlaybackPresentation(page, vc);
        await _playbackExecutionService.playAdapter(vc);
        if (docId.isNotEmpty) {
          _requestExclusivePlayback(docId, vc);
          await _reassertActiveShortAudibility(page, vc);
          _scheduleDelayedShortAudibilityReassert(page, vc);
          _applyShortPlaybackPresentation(page, vc);
        }
      } catch (_) {}
      _armPlaybackWatchdog(page, vc, delay);
    });
  }

  void _detachVideoEndListener(HLSVideoAdapter vc) {
    final listener = _videoEndListeners.remove(vc);
    if (listener == null) return;
    vc.removeListener(listener);
  }

  void _setupVideoEndListener(int page, HLSVideoAdapter vc) {
    _detachVideoEndListener(vc);
    final expectedDocId = page >= 0 && page < _cachedShorts.length
        ? _cachedShorts[page].docID
        : '';
    void listener() {
      _handleVideoEndForAdapter(
        page,
        vc,
        expectedDocId: expectedDocId,
      );
    }

    _videoEndListeners[vc] = listener;
    vc.addListener(listener);
  }

  void _scheduleEngagementRescore(int page) {
    _engagementRescoreTimer?.cancel();
    _engagementRescoreTimer = Timer(_shortEngagementRescoreDelay, () {
      if (!mounted ||
          page != currentPage ||
          isManuallyPaused ||
          !_isShortRoutePlaybackActive) {
        return;
      }
      if (page < 0 || page >= _cachedShorts.length) return;
      final vc = controller.cache[page];
      if (vc == null || !vc.value.hasRenderedFirstFrame) return;
      final docId = _cachedShorts[page].docID;
      final decision = _shortPlaybackDecisionFor(page, vc.value);
      VideoTelemetryService.instance.updateRuntimeHints(
        docId,
        isAudible: decision.shouldBeAudible,
        hasStableFocus: true,
      );
      final playbackKpi = maybeFindPlaybackKpiService();
      if (playbackKpi != null) {
        playbackKpi.track(
          PlaybackKpiEventType.playbackIntent,
          {
            'source': 'short_view',
            'docId': docId,
            'audible': decision.shouldBeAudible,
            'stableFocus': true,
          },
        );
      }
      try {
        maybeFindPrefetchScheduler()?.updateQueueForPosts(
          _cachedShorts,
          currentPage,
        );
      } catch (_) {}
    });
  }

  void _telemetryListener() {
    final vc = _telemetryAdapter;
    if (vc == null || currentPage >= _cachedShorts.length) return;
    final videoId = _cachedShorts[currentPage].docID;
    final v = vc.value;
    _applyShortPlaybackPresentation(currentPage, vc);
    _reportStableShortFrameIfNeeded(
      currentPage,
      vc,
      _shortPlaybackDecisionFor(currentPage, v).hasStableVisualFrame,
    );

    if (!_isTransitioning && v.isCompleted) {
      _handleVideoEndForAdapter(
        currentPage,
        vc,
        expectedDocId: videoId,
      );
      return;
    }

    if (!_telemetryFirstFrame && v.isPlaying) {
      _telemetryFirstFrame = true;
      controller.markPlaybackReady(videoId);
      VideoTelemetryService.instance.onFirstFrame(videoId);
      _markStartupPlaybackSettled();
      _prepareUpcomingVideoAfterFirstFrame();
    }

    if (v.isBuffering) {
      VideoTelemetryService.instance.onBufferingStart(videoId);
    } else if (!v.isBuffering && v.isPlaying) {
      VideoTelemetryService.instance.onBufferingEnd(videoId);
    }

    final pos = v.position.inMilliseconds / 1000.0;
    final dur = v.duration.inMilliseconds / 1000.0;
    if (dur > 0) {
      VideoTelemetryService.instance.onPositionUpdate(videoId, pos, dur);
      try {
        _segmentCacheRuntimeService.ensureNextSegmentReady(
          videoId,
          (pos / dur).clamp(0.0, 1.0),
          positionSeconds: pos,
        );
      } catch (_) {}
    }
  }

  void _handleVideoEndForAdapter(
    int page,
    HLSVideoAdapter vc, {
    required String expectedDocId,
  }) {
    if (!mounted || _isTransitioning) return;
    if (page != currentPage) return;
    if (page < 0 || page >= _cachedShorts.length) return;
    final currentDocId = _cachedShorts[page].docID;
    if (currentDocId != expectedDocId) return;

    final value = vc.value;
    final position = value.position.inMilliseconds;
    final duration = value.duration.inMilliseconds;
    final progress = duration > 0 && position > 0 ? position / duration : 0.0;
    final isNearEnd = duration > 0 &&
        position > 0 &&
        ((duration - position) <= 100 || progress >= 0.995);
    final shouldAutoAdvance = value.isCompleted || isNearEnd;

    if (duration > 0 && position > 0) {
      try {
        final now = DateTime.now();
        final shouldPersistByTime = _lastProgressPersistAt == null ||
            now.difference(_lastProgressPersistAt!) >=
                _shortProgressPersistInterval;
        final shouldPersistByDelta =
            (progress - _lastPersistedProgress).abs() >=
                _shortProgressPersistDelta;
        final shouldPersist =
            shouldPersistByTime || shouldPersistByDelta || progress >= 0.98;

        if (shouldPersist) {
          final currentShort = _cachedShorts[currentPage];
          debugPrint(
            '[ShortResume] tick_save page=$currentPage doc=${currentShort.docID} '
            'posMs=$position durMs=$duration progress=${progress.toStringAsFixed(3)}',
          );
          _segmentCacheRuntimeService.updateWatchProgress(
            currentShort.docID,
            progress,
          );
          _playbackRuntimeService.savePlaybackState(
            controller.playbackHandleKeyForDoc(currentShort.docID),
            HLSAdapterPlaybackHandle(vc),
          );
          final currentSegment =
              _segmentCacheRuntimeService.estimateCurrentSegmentForDoc(
            currentShort.docID,
            progress: progress,
            positionSeconds: position / 1000.0,
          );
          if (currentSegment != null) {
            FeedDiversityMemoryService.ensure().noteWatchedPost(
              currentShort,
              currentSegment: currentSegment,
            );
            if (currentSegment >= 3 || progress >= 0.80) {
              _segmentCacheRuntimeService.markShortConsumed(
                currentShort.docID,
              );
            }
          }
          _lastProgressPersistAt = now;
          _lastPersistedProgress = progress;
        }
      } catch (_) {}

      _maybePrepareNextVideoForAutoAdvance(progress);
    }

    if (shouldAutoAdvance) {
      _isTransitioning = true;
      _segmentCacheRuntimeService.markShortConsumed(currentDocId);
      VideoTelemetryService.instance.onCompleted(currentDocId);
      _detachVideoEndListener(vc);
      unawaited(_goToNextVideo());
    }
  }

  Future<void> _goToNextVideo() async {
    final activePage = currentPage;
    final hasNextPage =
        await _ensureNextVideoAvailableForAutoAdvance(activePage);
    if (!mounted || currentPage != activePage) {
      _isTransitioning = false;
      return;
    }
    if (hasNextPage) {
      final nextPage = activePage + 1;
      isManuallyPaused = false;
      _pendingAutoAdvancePage = nextPage;
      if (_preparedAutoAdvancePage != nextPage) {
        _preparedAutoAdvancePage = nextPage;
        unawaited(() async {
          try {
            await _prepareNextVideoForAutoAdvance(activePage, nextPage);
          } catch (_) {
            if (_preparedAutoAdvancePage == nextPage) {
              _preparedAutoAdvancePage = null;
            }
          }
        }());
      }
      if (!mounted) {
        _isTransitioning = false;
        return;
      }
      try {
        if (pageController.hasClients) {
          pageController.jumpToPage(nextPage);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !pageController.hasClients) return;
            try {
              pageController.jumpToPage(nextPage);
            } catch (_) {}
          });
        }
      } catch (_) {}
      _scheduleAutoAdvanceRetry(activePage, nextPage);
      _isTransitioning = false;
    } else {
      _isTransitioning = false;
    }
  }
}
