// ignore_for_file: invalid_use_of_protected_member

part of 'single_short_view.dart';

extension SingleShortViewHelpersPart on _SingleShortViewState {
  void _logSingleShortAdSlots(String message) {
    if (!kDebugMode) return;
    debugPrint('[SingleShortAdSlots] $message');
  }

  void _rebuildSingleShortRenderPlan() {
    _singleShortAdRenderable = AdmobKare.hasRenderableBanner;
    _renderPlan = buildShortAdRenderPlan(
      shorts.toList(growable: false),
      adReady: _singleShortAdRenderable,
    );
    _currentRenderPage = _renderPlan.renderIndexForOrganicIndex(currentPage);
    _logSingleShortAdSlots(
      'render_plan posts=${shorts.length} '
      'adReady=$_singleShortAdRenderable entries=${_renderPlan.length} '
      'currentPage=$currentPage renderPage=$_currentRenderPage '
      'state=${AdmobKare.debugState}',
    );
  }

  int _renderIndexForSingleShortOrganicIndex(int organicIndex) {
    if (_renderPlan.length == 0 || _renderPlan.length < shorts.length) {
      _rebuildSingleShortRenderPlan();
    }
    return _renderPlan.renderIndexForOrganicIndex(organicIndex);
  }

  int? _organicIndexForSingleShortRenderIndex(int renderIndex) {
    if (_renderPlan.length == 0 || _renderPlan.length < shorts.length) {
      _rebuildSingleShortRenderPlan();
    }
    return _renderPlan.organicIndexForRenderIndex(renderIndex);
  }

  void _ensureSingleShortAdWarmupFromBuild() {
    if (_didRequestSingleShortAdWarmupFromBuild) return;
    _didRequestSingleShortAdWarmupFromBuild = true;
    _logSingleShortAdSlots(
      'warmup_request source=fullscreen_build state=${AdmobKare.debugState}',
    );
    unawaited(() async {
      await AdmobKare.warmupPool(
        targetCount: 4,
        maxRequestCount: 2,
        bypassMinInterval: true,
      );
      if (!mounted) return;
      _logSingleShortAdSlots(
        'warmup_complete source=fullscreen_build '
        'adReady=${AdmobKare.hasRenderableBanner} state=${AdmobKare.debugState}',
      );
    }());
  }

  void _scheduleSingleShortAdAutoAdvance(int renderPage) {
    _singleShortAdAutoAdvanceTimer?.cancel();
    final nextRenderPage = renderPage + 1;
    if (nextRenderPage >= _renderPlan.length) return;
    final nextOrganicPage =
        _organicIndexForSingleShortRenderIndex(nextRenderPage);
    if (nextOrganicPage == null) return;
    _singleShortAdAutoAdvanceTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted ||
          !_isSingleShortRoutePlaybackActive ||
          !_isSingleShortAdPageActive ||
          _currentRenderPage != renderPage ||
          !pageController.hasClients) {
        return;
      }
      try {
        pageController.animateToPage(
          nextRenderPage,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {
        try {
          pageController.jumpToPage(nextRenderPage);
        } catch (_) {}
      }
    });
  }

  void _cancelSingleShortAdAutoAdvance() {
    _singleShortAdAutoAdvanceTimer?.cancel();
    _singleShortAdAutoAdvanceTimer = null;
  }

  Future<void> _requestSingleShortAutoAdvancePageChange(
    int nextOrganicIndex,
  ) async {
    if (!pageController.hasClients) return;
    final targetRenderPage =
        _renderIndexForSingleShortOrganicIndex(nextOrganicIndex);
    final page = pageController.page;
    final alreadyAtTarget = currentPage == nextOrganicIndex ||
        (page != null && (page - targetRenderPage).abs() < 0.01);
    if (alreadyAtTarget) return;
    try {
      await pageController.animateToPage(
        targetRenderPage,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } catch (_) {
      try {
        pageController.jumpToPage(targetRenderPage);
      } catch (_) {}
    }
  }

  void _suspendInjectedFeedPlaybackHandle(String docId) {
    final injected = widget.injectedController;
    if (injected == null || injected.isDisposed) return;
    final handleKey = _feedPlaybackHandleKeyForDoc(docId);
    _playbackRuntimeService.unregisterPlaybackHandle(handleKey);
    _suspendedFeedPlaybackHandleKey = handleKey;
  }

  void _restoreInjectedFeedPlaybackHandleIfNeeded() {
    final handleKey = _suspendedFeedPlaybackHandleKey;
    final injected = widget.injectedController;
    if (handleKey == null || injected == null || injected.isDisposed) return;
    if (!injected.value.isInitialized) return;
    try {
      _playbackRuntimeService.registerPlaybackHandle(
        handleKey,
        HLSAdapterPlaybackHandle(injected),
      );
    } catch (_) {}
    _suspendedFeedPlaybackHandleKey = null;
  }

  bool _hasThumbCandidate(PostsModel post, {String? overrideUrl}) {
    final resolvedUrl = (overrideUrl ?? post.thumbnail).trim();
    final candidates = <String>[
      if (resolvedUrl.isNotEmpty) resolvedUrl,
      ...post.preferredVideoPosterUrls,
    ]..removeWhere((url) => url.trim().isEmpty);
    if (candidates.isNotEmpty) {
      return true;
    }
    return false;
  }

  void _scheduleFullscreenPlaybackGuard(HLSVideoAdapter ctrl, String docId) {
    _fullscreenPlaybackGuardTimer?.cancel();
    _fullscreenPlaybackGuardTimer = Timer(
      const Duration(milliseconds: 1400),
      () async {
        if (!mounted || ctrl.isDisposed) return;
        if (currentPage < 0 || currentPage >= shorts.length) return;
        if (shorts[currentPage].docID != docId) return;

        final before = ctrl.value.position;
        final beforeDiag = await ctrl.getPlaybackDiagnostics();
        final beforePlaying = (beforeDiag['isPlaying'] as bool?) ?? false;
        final beforeSilenceMs =
            (beforeDiag['rendererFrameSilenceMs'] as num?)?.toInt() ?? 0;

        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted || ctrl.isDisposed) return;
        if (currentPage < 0 || currentPage >= shorts.length) return;
        if (shorts[currentPage].docID != docId) return;

        final after = ctrl.value.position;
        final afterDiag = await ctrl.getPlaybackDiagnostics();
        final afterPlaying = (afterDiag['isPlaying'] as bool?) ?? false;
        final afterSilenceMs =
            (afterDiag['rendererFrameSilenceMs'] as num?)?.toInt() ?? 0;
        final advancedMs = after.inMilliseconds - before.inMilliseconds;

        final likelyFrozen = (beforePlaying || afterPlaying) &&
            advancedMs < 180 &&
            afterSilenceMs >= 1500 &&
            afterSilenceMs >= beforeSilenceMs;

        if (!likelyFrozen) return;

        try {
          await ctrl.recoverFrozenPlayback();
        } catch (_) {}
        _applySingleShortPlaybackPresentation(currentPage, ctrl);
        _scheduleVolumeRestore(
          ctrl,
          preferredIndex: currentPage,
        );
        try {
          await _playbackExecutionService.playAdapter(ctrl);
        } catch (_) {}
        _requestExclusivePlayback(docId, adapter: ctrl);
        _applySingleShortPlaybackPresentation(currentPage, ctrl);
      },
    );
  }

  int? _indexForSingleShortController(
    HLSVideoAdapter ctrl, {
    int? preferredIndex,
  }) {
    if (preferredIndex != null &&
        preferredIndex >= 0 &&
        preferredIndex < shorts.length &&
        identical(_videoControllers[preferredIndex], ctrl)) {
      return preferredIndex;
    }
    for (final entry in _videoControllers.entries) {
      if (identical(entry.value, ctrl)) {
        return entry.key;
      }
    }
    return null;
  }

  void _scheduleVolumeRestore(
    HLSVideoAdapter ctrl, {
    int? preferredIndex,
  }) {
    void restore() {
      if (!mounted || ctrl.isDisposed) return;
      final page = _indexForSingleShortController(
        ctrl,
        preferredIndex: preferredIndex,
      );
      if (page == null) return;
      _applySingleShortPlaybackPresentation(page, ctrl);
    }

    Future<void>.microtask(() async {
      restore();
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () async {
      restore();
    });
    Future<void>.delayed(const Duration(milliseconds: 320), () async {
      restore();
    });
  }

  void _recordSingleShortPlaybackDispatch(
    String event, {
    required int index,
    required String docId,
    required String source,
    Map<String, dynamic>? metadata,
  }) {
    debugPrint(
      '[SingleShortPlayback] event=$event index=$index doc=$docId '
      'source=$source metadata=${metadata ?? const <String, dynamic>{}}',
    );
  }

  bool _shouldSuppressSingleShortPlaybackAttempt(
    int index,
    String docId, {
    required String source,
    Duration minSpacing = const Duration(milliseconds: 650),
  }) {
    final trimmed = docId.trim();
    if (trimmed.isEmpty) return false;
    final token = '$index:$trimmed';
    final lastToken = _lastSingleShortPlaybackAttemptToken;
    final lastAt = _lastSingleShortPlaybackAttemptAt;
    final now = DateTime.now();
    if (lastToken == token &&
        lastAt != null &&
        now.difference(lastAt) < minSpacing) {
      _recordSingleShortPlaybackDispatch(
        'play_suppressed',
        index: index,
        docId: trimmed,
        source: source,
        metadata: <String, dynamic>{
          'ageMs': now.difference(lastAt).inMilliseconds,
        },
      );
      return true;
    }
    _lastSingleShortPlaybackAttemptToken = token;
    _lastSingleShortPlaybackAttemptAt = now;
    return false;
  }

  void _markSingleShortPlaybackAttempt(
    int index,
    String docId,
  ) {
    final trimmed = docId.trim();
    if (trimmed.isEmpty) return;
    _lastSingleShortPlaybackAttemptToken = '$index:$trimmed';
    _lastSingleShortPlaybackAttemptAt = DateTime.now();
  }

  void _requestExclusivePlayback(
    String docId, {
    HLSVideoAdapter? adapter,
    Duration minSpacing = const Duration(milliseconds: 220),
  }) {
    final trimmed = docId.trim();
    if (trimmed.isEmpty) return;
    final playbackHandleKey = _playbackHandleKeyForDoc(trimmed);
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
      final shouldUseDirectOwnershipRequest = adapter != null &&
          PlaybackSurfacePolicy.shouldUseDirectShortOwnershipRequest(
            platform: defaultTargetPlatform,
            isPlaying: adapter.value.isPlaying,
            isBuffering: adapter.value.isBuffering,
            hasRenderedFirstFrame: adapter.value.hasRenderedFirstFrame,
            position: adapter.value.position,
          );
      if (shouldUseDirectOwnershipRequest) {
        _playbackRuntimeService.requestPlay(
          playbackHandleKey,
          HLSAdapterPlaybackHandle(adapter),
        );
      } else {
        _playbackRuntimeService.playOnlyThis(playbackHandleKey);
      }
    } catch (_) {}
  }

  void _scheduleIosSingleShortAudibilityReassert(
    int index,
    HLSVideoAdapter ctrl, {
    int attempt = 0,
  }) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    const maxAudibilityAttempts = 6;
    final safeAttempt = attempt.clamp(0, maxAudibilityAttempts);
    final delay = PlaybackSurfacePolicy.shortIosAudibilityReassertDelay(
      attempt: safeAttempt,
    );
    Future<void>.delayed(delay, () async {
      if (!mounted ||
          index != currentPage ||
          !_isSingleShortRoutePlaybackActive ||
          ctrl.isDisposed) {
        return;
      }
      final decision = _singleShortPlaybackDecisionFor(index, ctrl.value);
      if (!decision.shouldBeAudible) return;
      _applySingleShortPlaybackPresentation(index, ctrl);
      var stillMuted = false;
      try {
        stillMuted = await ctrl.isMutedNative();
      } catch (_) {}
      final shouldKickPlayback = ctrl.value.hasRenderedFirstFrame &&
          ctrl.value.position > Duration.zero &&
          !ctrl.value.isPlaying &&
          !ctrl.value.isBuffering;
      final shouldRetrySoon = attempt < maxAudibilityAttempts &&
          (!ctrl.value.hasRenderedFirstFrame ||
              stillMuted ||
              (ctrl.value.position > Duration.zero &&
                  !ctrl.value.isPlaying &&
                  !ctrl.value.isBuffering) ||
              ctrl.value.position < const Duration(milliseconds: 2500));
      final docId =
          index >= 0 && index < shorts.length ? shorts[index].docID.trim() : '';
      if (!stillMuted && !shouldKickPlayback) {
        if (shouldRetrySoon) {
          _scheduleIosSingleShortAudibilityReassert(
            index,
            ctrl,
            attempt: attempt + 1,
          );
        }
        return;
      }
      try {
        final shouldRecoverFrozenPlayback = ctrl.value.hasRenderedFirstFrame &&
            !ctrl.value.isCompleted &&
            ctrl.value.position >= const Duration(milliseconds: 2500);
        if (_shouldSuppressSingleShortPlaybackAttempt(
          index,
          docId,
          source: 'ios_audibility_reassert',
        )) {
          return;
        }
        if (shouldRecoverFrozenPlayback) {
          await ctrl.recoverFrozenPlayback();
        } else {
          await _playbackExecutionService.playAdapter(ctrl);
        }
      } catch (_) {}
      if (!mounted ||
          index != currentPage ||
          !_isSingleShortRoutePlaybackActive ||
          ctrl.isDisposed) {
        return;
      }
      _applySingleShortPlaybackPresentation(index, ctrl);
      if (docId.isNotEmpty) {
        _requestExclusivePlayback(docId, adapter: ctrl);
      }
      if (attempt < maxAudibilityAttempts) {
        _scheduleIosSingleShortAudibilityReassert(
          index,
          ctrl,
          attempt: attempt + 1,
        );
      }
    });
  }

  void _scheduleIosNativePlaybackGuard(
    int index,
    HLSVideoAdapter ctrl, {
    int attempt = 0,
  }) {
    _iosNativePlaybackGuardTimer?.cancel();
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    final guardDelay = PlaybackSurfacePolicy.shortIosNativePlaybackGuardDelay(
      attempt: attempt,
    );
    _iosNativePlaybackGuardTimer = Timer(guardDelay, () async {
      if (!mounted ||
          index != currentPage ||
          !_isSingleShortRoutePlaybackActive ||
          ctrl.isDisposed) {
        return;
      }

      final beforePosition = ctrl.value.position;
      Map<String, dynamic> beforeDiag = const <String, dynamic>{};
      try {
        beforeDiag = await ctrl.getPlaybackDiagnostics();
      } catch (_) {}
      final beforeSilenceMs =
          (beforeDiag['rendererFrameSilenceMs'] as num?)?.toInt() ?? 0;
      final beforePlaying = (beforeDiag['isPlaying'] as bool?) ?? false;

      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted ||
          index != currentPage ||
          !_isSingleShortRoutePlaybackActive ||
          ctrl.isDisposed) {
        return;
      }

      final afterPosition = ctrl.value.position;
      Map<String, dynamic> afterDiag = const <String, dynamic>{};
      try {
        afterDiag = await ctrl.getPlaybackDiagnostics();
      } catch (_) {}
      final afterSilenceMs =
          (afterDiag['rendererFrameSilenceMs'] as num?)?.toInt() ?? 0;
      final afterPlaying = (afterDiag['isPlaying'] as bool?) ?? false;
      final advancedMs =
          afterPosition.inMilliseconds - beforePosition.inMilliseconds;
      final likelyFrozen = ctrl.value.hasRenderedFirstFrame &&
          afterPosition >= const Duration(milliseconds: 800) &&
          advancedMs < 180 &&
          afterSilenceMs >= 1500 &&
          afterSilenceMs >= beforeSilenceMs &&
          (beforePlaying || afterPlaying || !ctrl.value.isPlaying);
      if (likelyFrozen) {
        final docId = index >= 0 && index < shorts.length
            ? shorts[index].docID.trim()
            : '';
        if (_shouldSuppressSingleShortPlaybackAttempt(
          index,
          docId,
          source: 'ios_native_guard',
        )) {
          return;
        }
        final shouldRecoverFrozenPlayback =
            afterPosition >= const Duration(milliseconds: 2500);
        try {
          if (shouldRecoverFrozenPlayback) {
            await ctrl.recoverFrozenPlayback();
          } else {
            await _playbackExecutionService.playAdapter(ctrl);
          }
        } catch (_) {}
        if (!mounted ||
            index != currentPage ||
            !_isSingleShortRoutePlaybackActive ||
            ctrl.isDisposed) {
          return;
        }
        _applySingleShortPlaybackPresentation(index, ctrl);
        if (docId.isNotEmpty) {
          _requestExclusivePlayback(docId, adapter: ctrl);
        }
      }

      final shouldRetryGuard = attempt < 2 &&
          ctrl.value.hasRenderedFirstFrame &&
          !ctrl.value.isCompleted &&
          (ctrl.value.position < const Duration(milliseconds: 2500) ||
              !ctrl.value.isPlaying);
      if (shouldRetryGuard) {
        _scheduleIosNativePlaybackGuard(
          index,
          ctrl,
          attempt: attempt + 1,
        );
      }
    });
  }

  void _schedulePlaybackWatchdog(int index, HLSVideoAdapter ctrl) {
    _playbackWatchdogTimer?.cancel();
    _playWatchdogRetries = 0;
    _playbackWatchdogBaselinePosition = ctrl.value.position;
    _armPlaybackWatchdog(
      index,
      ctrl,
      defaultTargetPlatform == TargetPlatform.android
          ? _SingleShortViewState._playWatchdogDelayAndroid
          : _SingleShortViewState._playWatchdogDelayIOS,
    );
  }

  void _armPlaybackWatchdog(
    int index,
    HLSVideoAdapter ctrl,
    Duration delay,
  ) {
    _playbackWatchdogTimer?.cancel();
    _playbackWatchdogTimer = Timer(delay, () async {
      if (!mounted ||
          index != currentPage ||
          !_isSingleShortRoutePlaybackActive ||
          ctrl.isDisposed) {
        return;
      }
      final value = ctrl.value;
      final hasProgressedPastBaseline = value.position >=
          _playbackWatchdogBaselinePosition + const Duration(milliseconds: 220);
      final hasStarted = value.isPlaying || hasProgressedPastBaseline;
      if (hasStarted) return;
      if (_playWatchdogRetries >= 2) return;
      _playWatchdogRetries++;
      final docId =
          index >= 0 && index < shorts.length ? shorts[index].docID.trim() : '';
      if (_shouldSuppressSingleShortPlaybackAttempt(
        index,
        docId,
        source: 'watchdog',
      )) {
        _armPlaybackWatchdog(index, ctrl, delay);
        return;
      }
      try {
        _recordSingleShortPlaybackDispatch(
          'watchdog_play_retry',
          index: index,
          docId: docId,
          source: 'play_watchdog',
          metadata: <String, dynamic>{'retry': _playWatchdogRetries},
        );
        _applySingleShortPlaybackPresentation(index, ctrl);
        await _playbackExecutionService.playAdapter(ctrl);
        if (docId.isNotEmpty) {
          _requestExclusivePlayback(docId, adapter: ctrl);
          await _reassertSingleShortAudibility(index, ctrl);
          _scheduleDelayedSingleShortAudibilityReassert(index, ctrl);
          _applySingleShortPlaybackPresentation(index, ctrl);
        }
      } catch (_) {}
      _armPlaybackWatchdog(index, ctrl, delay);
    });
  }

  void _scheduleStallWatchdog(int index, HLSVideoAdapter ctrl) {
    _stallWatchdogTimer?.cancel();
    _stallWatchdogRetries = 0;
    _stallWatchdogBufferingCycles = 0;
    _stallWatchdogLastPosition = ctrl.value.position;
    if (defaultTargetPlatform == TargetPlatform.android) return;
    _armStallWatchdog(index, ctrl);
  }

  void _armStallWatchdog(int index, HLSVideoAdapter ctrl) {
    _stallWatchdogTimer?.cancel();
    _stallWatchdogTimer = Timer(const Duration(milliseconds: 900), () async {
      if (!mounted ||
          index != currentPage ||
          !_isSingleShortRoutePlaybackActive ||
          ctrl.isDisposed) {
        return;
      }
      final value = ctrl.value;
      if (!value.isInitialized || !value.hasRenderedFirstFrame) {
        _stallWatchdogBufferingCycles = 0;
        _stallWatchdogLastPosition = value.position;
        _armStallWatchdog(index, ctrl);
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
        _armStallWatchdog(index, ctrl);
        return;
      }
      final remaining = value.duration > Duration.zero
          ? value.duration - value.position
          : Duration.zero;
      final shouldNudgeNearEndCompletion =
          PlaybackSurfacePolicy.shouldNudgeShortNearEndCompletion(
        platform: defaultTargetPlatform,
        duration: value.duration,
        remaining: remaining,
        position: value.position,
      );
      if (shouldNudgeNearEndCompletion) {
        try {
          await ctrl.seekTo(value.duration);
        } catch (_) {}
        _armStallWatchdog(index, ctrl);
        return;
      }
      final maxRetries = PlaybackSurfacePolicy.shortStallMaxRetries(
        platform: defaultTargetPlatform,
      );
      if (_stallWatchdogRetries >= maxRetries) return;
      _stallWatchdogRetries++;
      final docId =
          index >= 0 && index < shorts.length ? shorts[index].docID.trim() : '';
      try {
        final shouldRecoverFrozenPlayback =
            PlaybackSurfacePolicy.shouldRecoverFrozenShortOnStall(
          platform: defaultTargetPlatform,
          hasRenderedFirstFrame: value.hasRenderedFirstFrame,
          isCompleted: value.isCompleted,
          stallRetryCount: _stallWatchdogRetries,
          position: value.position,
        );
        _recordSingleShortPlaybackDispatch(
          'stall_recovery_play',
          index: index,
          docId: docId,
          source: 'stall_watchdog',
          metadata: <String, dynamic>{
            'retry': _stallWatchdogRetries,
            'bufferingCycles': _stallWatchdogBufferingCycles,
            'mode': shouldRecoverFrozenPlayback ? 'recover' : 'play',
          },
        );
        _applySingleShortPlaybackPresentation(index, ctrl);
        final shouldHardRestartShort =
            PlaybackSurfacePolicy.shouldHardRestartShortAfterStall(
          platform: defaultTargetPlatform,
          stallRetryCount: _stallWatchdogRetries,
          position: value.position,
        );
        if (shouldHardRestartShort) {
          try {
            await ctrl.seekTo(Duration.zero);
          } catch (_) {}
        }
        if (shouldRecoverFrozenPlayback) {
          await ctrl.recoverFrozenPlayback();
        } else {
          await _playbackExecutionService.playAdapter(ctrl);
        }
        if (docId.isNotEmpty) {
          _requestExclusivePlayback(docId, adapter: ctrl);
          _applySingleShortPlaybackPresentation(index, ctrl);
        }
      } catch (_) {}
      _armStallWatchdog(index, ctrl);
    });
  }

  void _recordSingleShortSwipeSegmentBoundary(
    int index, {
    required String reason,
  }) {
    if (index < 0 || index >= shorts.length) return;
    final docId = shorts[index].docID.trim();
    if (docId.isEmpty) return;
    final adapter = _videoControllers[index];
    final value = adapter?.value;
    final position = value?.position ?? Duration.zero;
    final duration = value?.duration ?? Duration.zero;
    final cacheManager = maybeFindSegmentCacheManager();
    final entry = cacheManager?.getEntry(docId);
    final totalSegmentCount = entry?.totalSegmentCount ?? 0;
    final boundarySegment = ShortSwipeSegmentGuard.estimateBoundarySegment(
      position: position,
      duration: duration,
      totalSegmentCount: totalSegmentCount,
    );
    final cachedOrdinals = (entry?.segments.keys ?? const <String>[])
        .map(ShortSwipeSegmentGuard.segmentOrdinalFromKey)
        .whereType<int>()
        .toList(growable: false);
    int? maxCachedSegment;
    var cachedAfterBoundary = 0;
    for (final ordinal in cachedOrdinals) {
      if (maxCachedSegment == null || ordinal > maxCachedSegment) {
        maxCachedSegment = ordinal;
      }
      if (boundarySegment != null && ordinal > boundarySegment) {
        cachedAfterBoundary += 1;
      }
    }
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    ShortSwipeSegmentGuard.recordSwipeAway(
      docId: docId,
      page: index,
      reason: reason,
      position: position,
      duration: duration,
      progress: progress,
      boundarySegmentOrdinal: boundarySegment,
      cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
      cachedAfterBoundaryCount: cachedAfterBoundary,
      maxCachedSegmentOrdinal: maxCachedSegment,
      totalSegmentCount: totalSegmentCount,
    );
  }

  Duration? _savedPlaybackPositionForSingleShort(
    int index,
    HLSVideoAdapter ctrl,
  ) {
    if (index < 0 || index >= shorts.length || ctrl.isDisposed) return null;
    final handleKey = _playbackHandleKeyForDoc(shorts[index].docID);
    final state = _playbackRuntimeService.getSavedPlaybackState(handleKey);
    if (state == null || state.position <= const Duration(milliseconds: 50)) {
      return null;
    }
    final duration = ctrl.value.duration;
    var target = state.position;
    if (duration > Duration.zero) {
      final maxSeek = duration - const Duration(milliseconds: 120);
      if (maxSeek <= Duration.zero) return null;
      if (target > maxSeek) {
        target = maxSeek;
      }
    }
    final currentPosition = ctrl.value.position;
    final currentMs = currentPosition.inMilliseconds;
    final targetMs = target.inMilliseconds;
    final forwardSkewMs = targetMs - currentMs;
    final hasMeaningfulCurrentPosition = currentMs > 50;
    if (hasMeaningfulCurrentPosition && forwardSkewMs <= 250) {
      _playbackRuntimeService.clearSavedPlaybackState(handleKey);
      return null;
    }
    if (ctrl.isStopped || !ctrl.value.isInitialized) {
      return target;
    }
    final deltaMs =
        (currentPosition.inMilliseconds - target.inMilliseconds).abs();
    if (deltaMs <= 250) {
      _playbackRuntimeService.clearSavedPlaybackState(handleKey);
      return null;
    }
    return target;
  }

  Future<void> _restoreSingleShortPlaybackStateIfNeeded(
    int index,
    HLSVideoAdapter ctrl,
  ) async {
    if (index < 0 || index >= shorts.length || ctrl.isDisposed) return;
    final docId = shorts[index].docID;
    final handleKey = _playbackHandleKeyForDoc(docId);
    final target = _savedPlaybackPositionForSingleShort(index, ctrl);
    debugPrint(
      '[SingleShortResume] restore_check index=$index doc=$docId handle=$handleKey '
      'savedMs=${target?.inMilliseconds ?? -1} '
      'currentMs=${ctrl.value.position.inMilliseconds} '
      'init=${ctrl.value.isInitialized}',
    );
    if (target == null) return;
    try {
      debugPrint(
        '[SingleShortResume] restore_apply index=$index doc=$docId handle=$handleKey '
        'targetMs=${target.inMilliseconds}',
      );
      await ctrl.seekTo(target);
      _playbackRuntimeService.clearSavedPlaybackState(handleKey);
    } catch (_) {}
  }

  Future<void> _releasePlayback(HLSVideoAdapter adapter) async {
    if (adapter.isDisposed) return;
    await _playbackExecutionService.stopAdapter(adapter);
  }

  void _updateTelemetryHintsForCurrentPage({
    bool? isAudible,
    bool? hasStableFocus,
  }) {
    final docId = _activeTelemetryVideoId;
    if (docId == null) return;
    VideoTelemetryService.instance.updateRuntimeHints(
      docId,
      isAudible: isAudible,
      hasStableFocus: hasStableFocus,
    );
  }

  Future<void> _endActiveTelemetrySession() async {
    _engagementRescoreTimer?.cancel();
    _engagementRescoreTimer = null;
    final adapter = _telemetryAdapter;
    if (adapter != null) {
      adapter.removeListener(_telemetryListener);
    }

    final docId = _activeTelemetryVideoId;
    _telemetryAdapter = null;
    _activeTelemetryVideoId = null;
    _telemetryFirstFrame = false;
    _lastProgressPersistAt = null;
    _lastPersistedProgress = 0.0;

    if (docId != null) {
      await VideoTelemetryService.instance.endSession(docId);
    }
  }

  void _scheduleEngagementRescore(int page) {
    _engagementRescoreTimer?.cancel();
    _engagementRescoreTimer =
        Timer(_SingleShortViewState._engagementRescoreDelay, () {
      if (!mounted || page != currentPage) return;
      if (page < 0 || page >= shorts.length) return;
      final vp = _videoControllers[page];
      if (vp == null || vp.isDisposed || !vp.value.hasRenderedFirstFrame) {
        return;
      }
      final decision = _singleShortPlaybackDecisionFor(page, vp.value);
      _updateTelemetryHintsForCurrentPage(
        isAudible: decision.shouldBeAudible,
        hasStableFocus: true,
      );
      final playbackKpi = maybeFindPlaybackKpiService();
      if (playbackKpi != null) {
        playbackKpi.track(
          PlaybackKpiEventType.playbackIntent,
          {
            'source': 'single_short_view',
            'docId': shorts[page].docID,
            'audible': decision.shouldBeAudible,
            'stableFocus': true,
          },
        );
      }
      final prefetch = maybeFindPrefetchScheduler();
      if (prefetch != null) {
        try {
          prefetch.updateQueueForPosts(
            shorts,
            currentPage,
          );
        } catch (_) {}
      }
    });
  }

  void _beginTelemetryForCurrentPage(HLSVideoAdapter ctrl) {
    if (currentPage < 0 || currentPage >= shorts.length) return;
    final post = shorts[currentPage];
    if (_activeTelemetryVideoId == post.docID &&
        identical(_telemetryAdapter, ctrl)) {
      _updateTelemetryHintsForCurrentPage(isAudible: volume);
      return;
    }

    unawaited(_endActiveTelemetrySession());
    VideoTelemetryService.instance.startSession(post.docID, post.playbackUrl);
    final decision = _singleShortPlaybackDecisionFor(currentPage, ctrl.value);
    VideoTelemetryService.instance.updateRuntimeHints(
      post.docID,
      isAudible: decision.shouldBeAudible,
      hasStableFocus: false,
    );
    _telemetryFirstFrame = false;
    _telemetryAdapter = ctrl;
    _activeTelemetryVideoId = post.docID;
    ctrl.removeListener(_telemetryListener);
    ctrl.addListener(_telemetryListener);
    _scheduleEngagementRescore(currentPage);
  }

  void _telemetryListener() {
    final adapter = _telemetryAdapter;
    final docId = _activeTelemetryVideoId;
    if (adapter == null || docId == null) return;
    if (currentPage < 0 || currentPage >= shorts.length) return;
    if (shorts[currentPage].docID != docId) return;

    final value = adapter.value;
    _applySingleShortPlaybackPresentation(currentPage, adapter);
    final decision = _singleShortPlaybackDecisionFor(currentPage, value);
    _updateTelemetryHintsForCurrentPage(
      isAudible: decision.shouldBeAudible,
    );

    if (!_telemetryFirstFrame &&
        (value.hasRenderedFirstFrame || value.isPlaying)) {
      _telemetryFirstFrame = true;
      VideoTelemetryService.instance.onFirstFrame(docId);
    }

    if (value.isBuffering) {
      VideoTelemetryService.instance.onBufferingStart(docId);
    } else if (!value.isBuffering && value.isPlaying) {
      VideoTelemetryService.instance.onBufferingEnd(docId);
    }

    final pos = value.position.inMilliseconds / 1000.0;
    final dur = value.duration.inMilliseconds / 1000.0;
    if (dur > 0) {
      VideoTelemetryService.instance.onPositionUpdate(docId, pos, dur);
      final progress = (pos / dur).clamp(0.0, 1.0);
      try {
        _segmentCacheRuntimeService.ensureNextSegmentReady(
          docId,
          progress,
          positionSeconds: pos,
        );
      } catch (_) {}
      final now = DateTime.now();
      final shouldPersistByTime = _lastProgressPersistAt == null ||
          now.difference(_lastProgressPersistAt!) >=
              _SingleShortViewState._progressPersistInterval;
      final shouldPersistByDelta = (progress - _lastPersistedProgress).abs() >=
          _SingleShortViewState._progressPersistDelta;
      final shouldPersist =
          shouldPersistByTime || shouldPersistByDelta || progress >= 0.98;

      if (shouldPersist) {
        try {
          debugPrint(
            '[SingleShortResume] tick_save index=$currentPage doc=$docId '
            'posMs=${value.position.inMilliseconds} '
            'durMs=${value.duration.inMilliseconds} '
            'progress=${progress.toStringAsFixed(3)}',
          );
          _segmentCacheRuntimeService.updateWatchProgress(docId, progress);
          _playbackRuntimeService.savePlaybackState(
            _playbackHandleKeyForDoc(docId),
            HLSAdapterPlaybackHandle(adapter),
          );
          final currentSegment =
              _segmentCacheRuntimeService.estimateCurrentSegmentForDoc(
            docId,
            progress: progress,
            positionSeconds: pos,
          );
          if (currentSegment != null &&
              currentPage >= 0 &&
              currentPage < shorts.length) {
            _segmentCacheRuntimeService.markFeedConsumed(docId);
            FeedDiversityMemoryService.ensure().noteWatchedPost(
              shorts[currentPage],
              currentSegment: currentSegment,
            );
          }
          _lastProgressPersistAt = now;
          _lastPersistedProgress = progress;
        } catch (_) {}
      }
    }
  }

  void _detachCompletionListener(int index, HLSVideoAdapter adapter) {
    final listener = _completionListeners.remove(index);
    if (listener != null) {
      adapter.removeListener(listener);
    }
  }

  Widget _cachedThumb(PostsModel post, {String? overrideUrl}) {
    const fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF101316),
            Color(0xFF1A2026),
            Color(0xFF232B33),
          ],
        ),
      ),
      child: SizedBox.expand(),
    );
    final candidates = _fullscreenPosterWarmUrlsForPost(
      post,
      overrideUrl: overrideUrl,
    );
    if (candidates.isEmpty) {
      return fallback;
    }
    return CacheFirstNetworkImage(
      imageUrl: candidates.first,
      candidateUrls: candidates
          .skip(1)
          .where((url) => url != candidates.first)
          .toList(growable: false),
      cacheManager: TurqImageCacheManager.instance,
      fit: BoxFit.cover,
      fallback: fallback,
      eagerPrecache: true,
      retryExhaustedCandidates: true,
    );
  }

  List<String> _fullscreenPosterWarmUrlsForPost(
    PostsModel post, {
    String? overrideUrl,
  }) {
    final urls = <String>[];

    void addUrl(String rawUrl) {
      final normalized = CdnUrlBuilder.toCdnUrl(rawUrl.trim());
      if (normalized.isEmpty || urls.contains(normalized)) return;
      urls.add(normalized);
    }

    addUrl(overrideUrl ?? post.thumbnail);
    addUrl(post.thumbnail);
    for (final posterUrl in post.preferredVideoPosterUrls) {
      addUrl(posterUrl);
    }
    for (final imageUrl in post.img) {
      addUrl(imageUrl);
    }
    for (final cdnUrl
        in CdnUrlBuilder.buildThumbnailUrlCandidates(post.docID)) {
      addUrl(cdnUrl);
    }
    return urls;
  }

  void _warmFullscreenPosterWindowAround(
    int anchorIndex, {
    int behindCount = 1,
    int aheadCount = 5,
  }) {
    if (shorts.isEmpty) return;
    final safeAnchor = anchorIndex.clamp(0, shorts.length - 1);
    final start = (safeAnchor - behindCount).clamp(0, shorts.length - 1);
    final endExclusive = (safeAnchor + aheadCount + 1).clamp(
      0,
      shorts.length,
    );
    for (int i = start; i < endExclusive; i++) {
      final post = shorts[i];
      final docId = post.docID.trim();
      if (docId.isEmpty || !_prefetchedFullscreenPosterDocIds.add(docId)) {
        continue;
      }
      for (final url in _fullscreenPosterWarmUrlsForPost(post)) {
        TurqImageCacheManager.warmUrl(url).ignore();
      }
    }
  }

  Future<void> _ensureInjectedInitialPlayback(
      HLSVideoAdapter ctrl, String docId) async {
    try {
      if (ctrl.isDisposed) return;
      ctrl.setLooping(false);
      _applySingleShortPlaybackPresentation(currentPage, ctrl);
      _scheduleVolumeRestore(
        ctrl,
        preferredIndex: currentPage,
      );

      final targetPos = widget.initialPosition;
      if (targetPos != null) {
        Duration safePos = targetPos.isNegative ? Duration.zero : targetPos;
        final total = ctrl.value.duration;
        if (total > Duration.zero) {
          final maxSeek = total - const Duration(milliseconds: 400);
          if (maxSeek > Duration.zero && safePos > maxSeek) {
            safePos = maxSeek;
          }
        }
        await ctrl.seekTo(safePos);
      }

      for (var i = 0; i < 3; i++) {
        if (!mounted || ctrl.isDisposed) return;
        await _playSingleShortWhenReady(
          currentPage,
          ctrl,
          source: 'single_short_injected_initial',
        );
        await Future.delayed(const Duration(milliseconds: 120));
        if (ctrl.value.isPlaying) break;
      }
      _scheduleFullscreenPlaybackGuard(ctrl, docId);
    } catch (_) {}
  }

  HLSVideoAdapter? _resolveFullscreenReturnPreservedController({
    int? preferredIndex,
    HLSVideoAdapter? preferredController,
  }) {
    final injected = widget.injectedController;
    if (injected == null ||
        injected.isDisposed ||
        !injected.value.isInitialized) {
      return null;
    }
    final idx = preferredIndex ?? currentPage;
    final candidate =
        preferredController ?? (idx >= 0 ? _videoControllers[idx] : null);
    if (candidate != null && identical(candidate, injected)) {
      return injected;
    }
    final current = currentPage >= 0 ? _videoControllers[currentPage] : null;
    if (current != null && identical(current, injected)) {
      return injected;
    }
    return null;
  }

  void _unregisterShortHandlesForController(HLSVideoAdapter controller) {
    for (final entry in _videoControllers.entries) {
      if (!identical(entry.value, controller)) continue;
      if (entry.key < 0 || entry.key >= shorts.length) continue;
      try {
        _playbackRuntimeService.unregisterPlaybackHandle(
          _playbackHandleKeyForDoc(shorts[entry.key].docID),
        );
      } catch (_) {}
    }
  }

  Future<void> _pauseAllControllers({
    HLSVideoAdapter? preserveController,
  }) async {
    final preserved = preserveController != null &&
            !preserveController.isDisposed &&
            preserveController.value.isInitialized
        ? preserveController
        : null;
    final seen = <HLSVideoAdapter>{};
    for (final vp in _videoControllers.values) {
      if (!seen.add(vp)) continue;
      if (preserved != null && identical(vp, preserved)) continue;
      try {
        if (vp.isDisposed) continue;
        if (vp.value.isInitialized) {
          await _releasePlayback(vp);
        }
      } catch (_) {}
    }
    final injected = widget.injectedController;
    if (injected != null && seen.add(injected)) {
      if (preserved != null && identical(injected, preserved)) {
        _unregisterShortHandlesForController(injected);
      } else {
        try {
          if (!injected.isDisposed && injected.value.isInitialized) {
            await _releasePlayback(injected);
          }
        } catch (_) {}
      }
    } else if (preserved != null) {
      _unregisterShortHandlesForController(preserved);
    }
    if (preserved == null) {
      try {
        _playbackRuntimeService.pauseAll(force: true);
      } catch (_) {}
    }
    try {
      _playbackRuntimeService.exitExclusiveMode();
    } catch (_) {}
  }

  void _primePlaybackForIndex(int index) {
    if (index < 0 || index >= shorts.length) return;
    final ctrl = _videoControllers[index];
    if (ctrl == null || ctrl.isDisposed) return;
    unawaited(
      _playSingleShortWhenReady(
        index,
        ctrl,
        source: 'single_short_prime_playback',
      ),
    );
  }

  Widget _buildFullscreenVideoSurface(
    HLSVideoAdapter adapter,
    String keyId, {
    bool? overrideAutoPlay,
    double? modelAspectRatio,
    bool? preferResumePosterOverride,
  }) {
    final ar = (modelAspectRatio != null && modelAspectRatio > 0)
        ? modelAspectRatio
        : (9 / 16);

    final preferResumePoster = preferResumePosterOverride ?? false;

    final player = adapter.buildPlayer(
      key: ValueKey(keyId),
      useAspectRatio: false,
      overrideAutoPlay: overrideAutoPlay,
      forceFullscreenOnAndroid: true,
      preferWarmPoolPauseOnAndroid: true,
      suppressLoadingOverlay: true,
      preferResumePoster: preferResumePoster,
      preferStableStartupBuffer:
          PlaybackSurfacePolicy.preferStableShortStartupBuffer(
        platform: defaultTargetPlatform,
      ),
    );

    if (ar > 1.2) {
      return Center(
        child: AspectRatio(
          aspectRatio: ar,
          child: player,
        ),
      );
    } else if (ar >= 0.8) {
      return Center(
        child: AspectRatio(
          aspectRatio: 1.0,
          child: player,
        ),
      );
    } else {
      return SizedBox.expand(child: player);
    }
  }

  bool _shouldPreferResumePosterForSingleShort(
    int index,
    HLSVideoAdapter adapter,
  ) {
    if (index < 0 || index >= shorts.length) return false;
    if (_forceResumePosterOnReturn && index == currentPage) {
      return true;
    }
    if (widget.initialPosition != null &&
        widget.initialPosition! > Duration.zero &&
        index == currentPage) {
      return true;
    }
    return false;
  }

  Future<void> _fetchAndShuffle() async {
    final merged = <PostsModel>[];

    if (widget.startList != null && widget.startList!.isNotEmpty) {
      if (widget.startModel != null &&
          widget.startList!.every((p) => p.docID != widget.startModel!.docID)) {
        merged.add(widget.startModel!);
      }
      merged.addAll(widget.startList!);
    } else if (widget.startModel != null) {
      merged.add(widget.startModel!);
    }

    shorts.assignAll(merged);
  }
}
