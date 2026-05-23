// ignore_for_file: invalid_use_of_protected_member

part of 'single_short_view.dart';

extension SingleShortViewPlaybackPart on _SingleShortViewState {
  Future<void> _silenceActiveSingleShortPlaybackForAdPage(int page) async {
    final candidates = <HLSVideoAdapter?>[
      _videoControllers[page],
      widget.injectedController,
    ];
    final seen = <HLSVideoAdapter>{};
    for (final adapter in candidates) {
      if (adapter == null || adapter.isDisposed || !seen.add(adapter)) {
        continue;
      }
      try {
        final shouldStopPlayback = defaultTargetPlatform == TargetPlatform.iOS;
        debugPrint(
          '[PlaybackStopTrace] source=single_short_ad_page_active_silence '
          'cacheIndex=$page stopPlayback=$shouldStopPlayback',
        );
        if (shouldStopPlayback) {
          await adapter.silenceAndStopPlayback();
        } else {
          await adapter.forceSilence();
        }
      } catch (_) {}
    }
  }

  void _resetSingleShortAutoplaySegmentGate() {
    _autoplaySegmentGateTimer?.cancel();
    _autoplaySegmentGateTimer = null;
    _autoplaySegmentGateStartedAt = null;
    _autoplaySegmentGateTimedOut = false;
  }

  bool _hasReadySingleShortSegment(int index) {
    if (index < 0 || index >= shorts.length) return true;
    try {
      return _segmentCacheRuntimeService.hasReadySegment(shorts[index].docID);
    } catch (_) {
      return true;
    }
  }

  Future<void> _playSingleShortWhenReady(
    int index,
    HLSVideoAdapter ctrl, {
    required String source,
  }) async {
    if (!mounted || ctrl.isDisposed || index < 0 || index >= shorts.length) {
      return;
    }
    final shouldGate = !_autoplaySegmentGateTimedOut &&
        ctrl.value.position <= Duration.zero &&
        !ctrl.value.isPlaying &&
        !_hasReadySingleShortSegment(index);
    if (shouldGate) {
      _autoplaySegmentGateStartedAt ??= DateTime.now();
      final elapsed = DateTime.now().difference(_autoplaySegmentGateStartedAt!);
      if (elapsed < _SingleShortViewState._autoplaySegmentGateTimeout) {
        _autoplaySegmentGateTimer?.cancel();
        _autoplaySegmentGateTimer = Timer(
          _SingleShortViewState._autoplaySegmentGatePollInterval,
          () {
            _autoplaySegmentGateTimer = null;
            if (!mounted || ctrl.isDisposed || index != currentPage) return;
            unawaited(
              _playSingleShortWhenReady(
                index,
                ctrl,
                source: source,
              ),
            );
          },
        );
        return;
      }
      _autoplaySegmentGateTimedOut = true;
    } else {
      _resetSingleShortAutoplaySegmentGate();
    }

    _applySingleShortPlaybackPresentation(index, ctrl);
    _scheduleVolumeRestore(
      ctrl,
      preferredIndex: index,
    );
    await _reassertSingleShortAudibility(index, ctrl);
    await _restoreSingleShortPlaybackStateIfNeeded(index, ctrl);
    if (!ctrl.value.isPlaying) {
      _markSingleShortPlaybackAttempt(index, shorts[index].docID);
      await _playbackExecutionService.playAdapter(ctrl);
    }
    _requestExclusivePlayback(shorts[index].docID, adapter: ctrl);
    _scheduleDelayedSingleShortAudibilityReassert(index, ctrl);
    _applySingleShortPlaybackPresentation(index, ctrl);
    if (index == currentPage) {
      _scheduleFullscreenPlaybackGuard(ctrl, shorts[index].docID);
      _schedulePlaybackWatchdog(index, ctrl);
      _scheduleStallWatchdog(index, ctrl);
      _scheduleIosNativePlaybackGuard(index, ctrl);
      _scheduleIosSingleShortAudibilityReassert(index, ctrl);
      _beginTelemetryForCurrentPage(ctrl);
    }
  }

  void _initializeSingleShortView() {
    try {
      maybeFindNavBarController()?.pushMediaOverlayLock();
    } catch (_) {}
    final hasInjectedPlayingController = widget.injectedController != null &&
        !widget.injectedController!.isDisposed &&
        widget.injectedController!.value.isInitialized;
    if (!hasInjectedPlayingController) {
      try {
        _playbackRuntimeService.pauseAll(force: true);
      } catch (_) {}
    }

    if (widget.startList != null && widget.startList!.isNotEmpty) {
      final merged = <PostsModel>[];
      if (widget.startModel != null &&
          widget.startList!.every((p) => p.docID != widget.startModel!.docID)) {
        merged.add(widget.startModel!);
      }
      merged.addAll(widget.startList!);
      shorts.assignAll(merged);
      _configureInitialForList(merged);
    }

    ever<List<PostsModel>>(shorts, _handleShortsChange);

    final shouldFetch = widget.startList == null || widget.startList!.isEmpty;
    if (shouldFetch) {
      _fetchAndShuffle();
    }
  }

  void _handlePageChanged(int renderPage) async {
    if (_renderPlan.length == 0 || _renderPlan.length < shorts.length) {
      _rebuildSingleShortRenderPlan();
    }
    final entry = renderPage >= 0 && renderPage < _renderPlan.entries.length
        ? _renderPlan.entries[renderPage]
        : null;
    if (entry == null) return;
    if (entry.isAd) {
      if (_isSingleShortAdPageActive && renderPage == _currentRenderPage) {
        return;
      }
      await _silenceActiveSingleShortPlaybackForAdPage(currentPage);
      _currentRenderPage = renderPage;
      _isSingleShortAdPageActive = true;
      showControls = false;
      _playbackWatchdogTimer?.cancel();
      _stallWatchdogTimer?.cancel();
      _iosNativePlaybackGuardTimer?.cancel();
      _resetSingleShortAutoplaySegmentGate();
      unawaited(_endActiveTelemetrySession());
      unawaited(_pauseAllControllers());
      _scheduleSingleShortAdAutoAdvance(renderPage);
      setState(() {});
      return;
    }

    final page = entry.organicIndex!;
    if (page == currentPage &&
        renderPage == _currentRenderPage &&
        !_isSingleShortAdPageActive) {
      return;
    }

    final previousPage = currentPage;
    _cancelSingleShortAdAutoAdvance();
    final prev = _videoControllers[currentPage];
    if (prev != null) {
      try {
        _releasePlayback(prev);
      } catch (_) {}
    }
    unawaited(_endActiveTelemetrySession());

    currentPage = page;
    _currentRenderPage = renderPage;
    _isSingleShortAdPageActive = false;
    showControls = true;
    _playbackWatchdogTimer?.cancel();
    _stallWatchdogTimer?.cancel();
    _iosNativePlaybackGuardTimer?.cancel();
    _resetSingleShortAutoplaySegmentGate();
    _pageActivatedAt = DateTime.now();
    if (currentPage >= 0 && currentPage < shorts.length) {
      if (page > previousPage) {
        _recordSingleShortSwipeSegmentBoundary(
          previousPage,
          reason: 'fullscreen_page_changed_forward',
        );
        final previousDocId = previousPage >= 0 && previousPage < shorts.length
            ? shorts[previousPage].docID.trim()
            : '';
        if (previousDocId.isNotEmpty) {
          maybeFindPrefetchScheduler()?.abortShortSwipeBoundaryDoc(
            previousDocId,
            reason: 'fullscreen_page_changed_forward',
          );
        }
      }
      try {
        _playbackRuntimeService.updateExclusiveModeDoc(
          _playbackHandleKeyForDoc(shorts[currentPage].docID),
        );
      } catch (_) {}
    }

    _completionTriggered[page] = false;

    if (_initialIndexForSeek != null && page != _initialIndexForSeek) {
      _initialIndexForSeek = null;
    }

    _ensureController(currentPage);
    final vp = _videoControllers[currentPage];

    final injected = widget.injectedController;
    if (injected != null && (vp == null || !identical(injected, vp))) {
      try {
        _releasePlayback(injected);
      } catch (_) {}
    }

    if (vp != null) {
      if (vp.isDisposed) return;
      _primePlaybackForIndex(currentPage);

      if (currentPage < shorts.length) {
        try {
          _segmentCacheRuntimeService.markPlayingAndTouchRecent(
            shorts.map((short) => short.docID).toList(growable: false),
            currentPage,
          );
        } catch (_) {}
      }
    }
    _preloadRange(currentPage);
    _warmFullscreenPosterWindowAround(
      currentPage,
      behindCount: StartupPreloadPolicy.posterBehindCount,
      aheadCount: StartupPreloadPolicy.posterAheadCount,
    );
    _disposeOutsideRange(currentPage);
    setState(() {});
  }

  void _disposeSingleShortView() {
    _restoreInjectedFeedPlaybackHandleIfNeeded();
    if (_routeObserverSubscribed) {
      try {
        routeObserver.unsubscribe(this);
      } catch (_) {}
      _routeObserverSubscribed = false;
    }
    pageController.dispose();
    unawaited(_endActiveTelemetrySession());
    _fullscreenPlaybackGuardTimer?.cancel();
    _autoplaySegmentGateTimer?.cancel();
    _singleShortAdAutoAdvanceTimer?.cancel();
    _fullscreenPlaybackGuardTimer = null;
    _singleShortAdAutoAdvanceTimer = null;
    _fullscreenReturnPreservedController = null;
    _clearAllControllers();
    try {
      maybeFindNavBarController()?.popMediaOverlayLock();
    } catch (_) {}
    try {
      _playbackRuntimeService.exitExclusiveMode();
    } catch (_) {}
  }

  void _handleDidPop() {
    final preserved = _fullscreenReturnPreservedController;
    _fullscreenReturnPreservedController = null;
    try {
      if (currentPage >= 0 && currentPage < shorts.length) {
        final currentModel = shorts[currentPage];
        final ctrl = _videoControllers[currentPage];

        if (ctrl != null && ctrl.value.isInitialized) {
          _playbackRuntimeService.savePlaybackState(
            _playbackHandleKeyForDoc(currentModel.docID),
            HLSAdapterPlaybackHandle(ctrl),
          );
        }
      }
    } catch (_) {}

    unawaited(_endActiveTelemetrySession());
    _pauseAllControllers(preserveController: preserved);
    try {
      _playbackRuntimeService.exitExclusiveMode();
    } catch (_) {}
    _restoreInjectedFeedPlaybackHandleIfNeeded();
  }

  void _handleDidPushNext() {
    unawaited(_endActiveTelemetrySession());
    unawaited(_pauseAllControllers());
  }

  void _handleDidPopNext() {
    if (!_isSingleShortRoutePlaybackActive) return;
    if (currentPage < 0 || currentPage >= shorts.length) return;

    final vp = _videoControllers[currentPage];
    if (vp == null || vp.isDisposed) return;

    try {
      _playbackRuntimeService.enterExclusiveMode(
        _playbackHandleKeyForDoc(shorts[currentPage].docID),
      );
    } catch (_) {}
    _primePlaybackForIndex(currentPage);
  }

  void _handleDidStartUserGesture() {
    _pauseAllControllers();
  }

  void _handleDidStopUserGesture() {
    if (_isSingleShortRoutePlaybackActive) {
      final vp = _videoControllers[currentPage];
      if (vp != null && vp.value.isInitialized) {
        try {
          if (vp.isDisposed) return;
          _applySingleShortPlaybackPresentation(currentPage, vp);
          final decision =
              _singleShortPlaybackDecisionFor(currentPage, vp.value);
          _updateTelemetryHintsForCurrentPage(
            isAudible: decision.shouldBeAudible,
            hasStableFocus: false,
          );
          if (currentPage >= 0 && currentPage < shorts.length) {
            _requestExclusivePlayback(shorts[currentPage].docID, adapter: vp);
          }
        } catch (_) {}
      }
    }
  }
}
