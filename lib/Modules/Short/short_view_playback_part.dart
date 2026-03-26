part of 'short_view.dart';

extension ShortViewPlaybackPart on _ShortViewState {
  void _resetShortAutoplaySegmentGate() {
    _autoplaySegmentGateStartedAt = null;
    _autoplaySegmentGateTimedOut = false;
  }

  bool _hasReadyShortSegment(int page) {
    if (page < 0 || page >= _cachedShorts.length) return true;
    try {
      final entry =
          SegmentCacheManager.maybeFind()?.getEntry(_cachedShorts[page].docID);
      return (entry?.cachedSegmentCount ?? 0) >= 1;
    } catch (_) {
      return true;
    }
  }

  void _boostShortSegments(int page) {
    if (page < 0 || page >= _cachedShorts.length) return;
    try {
      ensurePrefetchScheduler().boostDoc(
        _cachedShorts[page].docID,
        readySegments: 2,
      );
    } catch (_) {}
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

    final update = _shortRenderCoordinator.buildUpdate(
      previous: _cachedShorts,
      next: nextList,
      currentIndex: currentPage,
    );
    if (update.patch.isEmpty) return;
    _shortRenderCoordinator.trackUpdateMetrics(
      previous: _cachedShorts,
      currentIndex: currentPage,
      update: update,
      next: nextList,
    );

    final previousPage = currentPage;
    _shortRenderCoordinator.applyPatch(_cachedShorts, update.patch);
    final remappedPage =
        _initialDisplayIndex(_cachedShorts, update.remappedIndex);
    currentPage = remappedPage;

    _updateShortViewState(() {});

    if (pageController.hasClients && remappedPage != previousPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !pageController.hasClients) return;
        try {
          pageController.jumpToPage(remappedPage);
        } catch (_) {}
      });
    }
  }

  void _onPageChanged(int page) {
    if (_cachedShorts.isEmpty) return;
    if (page == currentPage) return;
    final nextDocId = page >= 0 && page < _cachedShorts.length
        ? _cachedShorts[page].docID
        : '';
    recordQALabScrollEvent(
      surface: 'short',
      phase: 'settled',
      metadata: <String, dynamic>{
        'fromIndex': currentPage,
        'toIndex': page,
        'docId': nextDocId,
        'count': _cachedShorts.length,
      },
    );

    final oldVc = controller.cache[currentPage];
    if (oldVc != null) {
      _persistShortPlaybackState(currentPage, oldVc);
      if (defaultTargetPlatform == TargetPlatform.android) {
        _quietBackgroundPlayback(oldVc);
      } else {
        _releasePlayback(oldVc);
      }
      oldVc.removeListener(_videoEndListener);
      oldVc.removeListener(_telemetryListener);
    }

    if (currentPage < _cachedShorts.length) {
      VideoTelemetryService.instance
          .endSession(_cachedShorts[currentPage].docID);
    }

    _updateShortViewState(() {
      currentPage = page;
      _showOverlayControls = true;
    });
    _resetShortAutoplaySegmentGate();
    if (currentPage >= 0 && currentPage < _cachedShorts.length) {
      try {
        VideoStateManager.instance
            .updateExclusiveModeDoc(_cachedShorts[currentPage].docID);
      } catch (_) {}
    }
    isManuallyPaused = false;
    _isTransitioning = false;
    _telemetryFirstFrame = false;
    _telemetryAdapter = null;
    _lastPersistedProgress = 0.0;
    _lastProgressPersistAt = null;
    _engagementRescoreTimer?.cancel();

    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(
      defaultTargetPlatform == TargetPlatform.android
          ? _shortScrollDebounceAndroid
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

  void _persistShortPlaybackState(int page, HLSVideoAdapter adapter) {
    if (page < 0 || page >= _cachedShorts.length || adapter.isDisposed) return;
    try {
      VideoStateManager.instance.saveVideoState(
        _cachedShorts[page].docID,
        HLSAdapterPlaybackHandle(adapter),
      );
    } catch (_) {}
  }

  void _enforceSingleActiveAudio(int activePage) {
    for (final entry in controller.cache.entries) {
      final idx = entry.key;
      final vc = entry.value;
      if (idx == activePage) continue;
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          _quietBackgroundPlayback(vc);
        } else {
          vc.setVolume(0);
          _releasePlayback(vc);
        }
      } catch (_) {}
    }
  }

  void _scheduleTierUpdate(int page) {
    _tierDebounce?.cancel();
    _tierDebounce = Timer(_shortTierDebounceDelay, () async {
      final hadActiveAdapter = controller.cache[page] != null;
      await controller.updateCacheTiers(page);
      if (!mounted || page != currentPage) return;
      _setStateIfActiveAdapterChanged(page, hadActiveAdapter);
      _schedulePlayForPage(page);
    });
  }

  Future<void> _startAutoPlayCurrentVideo() async {
    if (controller.shorts.isEmpty) return;

    isManuallyPaused = false;
    final hadActiveAdapter = controller.cache[currentPage] != null;
    if (currentPage >= 0 && currentPage < _cachedShorts.length) {
      final docId = _cachedShorts[currentPage].docID;
      try {
        VideoStateManager.instance.updateExclusiveModeDoc(docId);
      } catch (_) {}
      try {
        VideoStateManager.instance.enterExclusiveMode(docId);
      } catch (_) {}
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      await controller.keepOnlyIndex(currentPage);
    }

    await controller.updateCacheTiers(
      currentPage,
      suppressWarmPause: true,
    );
    if (!mounted) return;
    _setStateIfActiveAdapterChanged(currentPage, hadActiveAdapter,
        force: false);

    _schedulePlayForPage(currentPage);
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

  void _schedulePlayForPage(int page) {
    _playDebounce?.cancel();
    _playDebounce = Timer(
      defaultTargetPlatform == TargetPlatform.android
          ? _shortPlayResumeDelayAndroid
          : _shortPlayResumeDelay,
      () {
        if (!mounted || page != currentPage || isManuallyPaused) return;
        _enforceSingleActiveAudio(page);
        final vc = controller.cache[page];
        if (vc == null) return;
        final docId = page >= 0 && page < _cachedShorts.length
            ? _cachedShorts[page].docID
            : '';
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
        vc.setVolume(volume ? 1 : 0);
        _boostShortSegments(page);
        final shouldGate = !_autoplaySegmentGateTimedOut &&
            vc.value.position <= Duration.zero &&
            !vc.value.isPlaying &&
            !_hasReadyShortSegment(page);
        if (shouldGate) {
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
        if (!vc.value.isPlaying) {
          vc.play();
        }
        _setupVideoEndListener(vc);
        _schedulePlaybackWatchdog(page, vc);
        _scheduleStallWatchdog(page, vc);

        if (page < _cachedShorts.length) {
          final post = _cachedShorts[page];
          try {
            VideoStateManager.instance.enterExclusiveMode(post.docID);
          } catch (_) {}
          VideoTelemetryService.instance
              .startSession(post.docID, post.playbackUrl);
          VideoTelemetryService.instance.updateRuntimeHints(
            post.docID,
            isAudible: volume,
            hasStableFocus: false,
          );
          _telemetryFirstFrame = false;
          _telemetryAdapter = vc;
          vc.removeListener(_telemetryListener);
          vc.addListener(_telemetryListener);
          _scheduleEngagementRescore(page);
        }

        if (page < _cachedShorts.length) {
          try {
            final cm = SegmentCacheManager.maybeFind();
            if (cm != null) {
              cm.markPlaying(_cachedShorts[page].docID);
              for (var i = 1; i <= 5; i++) {
                final behindIdx = page - i;
                if (behindIdx < 0) break;
                if (behindIdx < _cachedShorts.length) {
                  cm.touchEntry(_cachedShorts[behindIdx].docID);
                }
              }
            }
          } catch (_) {}
        }
      },
    );
  }

  void _scheduleStallWatchdog(int page, HLSVideoAdapter vc) {
    _stallWatchdogTimer?.cancel();
    _stallWatchdogRetries = 0;
    _stallWatchdogLastPosition = vc.value.position;
    _armStallWatchdog(page, vc);
  }

  void _armStallWatchdog(int page, HLSVideoAdapter vc) {
    _stallWatchdogTimer?.cancel();
    _stallWatchdogTimer = Timer(const Duration(milliseconds: 900), () async {
      if (!mounted ||
          page != currentPage ||
          vc.isDisposed ||
          isManuallyPaused) {
        return;
      }
      final value = vc.value;
      if (!value.isInitialized || !value.hasRenderedFirstFrame) {
        _stallWatchdogLastPosition = value.position;
        _armStallWatchdog(page, vc);
        return;
      }
      final progressed = value.position > _stallWatchdogLastPosition;
      final healthy = progressed || value.isBuffering || value.isCompleted;
      _stallWatchdogLastPosition = value.position;
      if (healthy) {
        _stallWatchdogRetries = 0;
        _armStallWatchdog(page, vc);
        return;
      }
      if (_stallWatchdogRetries >= 2) return;
      _stallWatchdogRetries++;
      try {
        final docId = page >= 0 && page < _cachedShorts.length
            ? _cachedShorts[page].docID
            : '';
        recordQALabPlaybackDispatch(
          surface: 'short',
          stage: 'short_stall_recovery_play',
          metadata: <String, dynamic>{
            'docId': docId,
            'page': page,
            'retry': _stallWatchdogRetries,
          },
        );
        vc.setVolume(volume ? 1 : 0);
        await vc.play();
      } catch (_) {}
      _armStallWatchdog(page, vc);
    });
  }

  void _schedulePlaybackWatchdog(int page, HLSVideoAdapter vc) {
    _playbackWatchdogTimer?.cancel();
    _playWatchdogRetries = 0;
    _armPlaybackWatchdog(page, vc);
  }

  void _armPlaybackWatchdog(int page, HLSVideoAdapter vc) {
    _playbackWatchdogTimer?.cancel();
    _playbackWatchdogTimer = Timer(_shortPlayWatchdogDelay, () async {
      if (!mounted ||
          page != currentPage ||
          vc.isDisposed ||
          isManuallyPaused) {
        return;
      }
      final value = vc.value;
      final hasStarted = value.isPlaying || value.position > Duration.zero;
      if (hasStarted) return;
      if (_playWatchdogRetries >= 2) return;
      _playWatchdogRetries++;
      try {
        final docId = page >= 0 && page < _cachedShorts.length
            ? _cachedShorts[page].docID
            : '';
        recordQALabPlaybackDispatch(
          surface: 'short',
          stage: 'short_watchdog_play_retry',
          metadata: <String, dynamic>{
            'docId': docId,
            'page': page,
            'retry': _playWatchdogRetries,
          },
        );
        vc.setVolume(volume ? 1 : 0);
        await vc.play();
      } catch (_) {}
      _armPlaybackWatchdog(page, vc);
    });
  }

  void _setupVideoEndListener(HLSVideoAdapter vc) {
    vc.removeListener(_videoEndListener);
    vc.addListener(_videoEndListener);
  }

  void _scheduleEngagementRescore(int page) {
    _engagementRescoreTimer?.cancel();
    _engagementRescoreTimer = Timer(_shortEngagementRescoreDelay, () {
      if (!mounted || page != currentPage || isManuallyPaused) return;
      if (page < 0 || page >= _cachedShorts.length) return;
      final vc = controller.cache[page];
      if (vc == null || !vc.value.hasRenderedFirstFrame) return;
      final docId = _cachedShorts[page].docID;
      VideoTelemetryService.instance.updateRuntimeHints(
        docId,
        isAudible: volume,
        hasStableFocus: true,
      );
      final playbackKpi = maybeFindPlaybackKpiService();
      if (playbackKpi != null) {
        playbackKpi.track(
          PlaybackKpiEventType.playbackIntent,
          {
            'source': 'short_view',
            'docId': docId,
            'audible': volume,
            'stableFocus': true,
          },
        );
      }
      try {
        maybeFindPrefetchScheduler()?.updateQueue(
          _cachedShorts.map((s) => s.docID).toList(growable: false),
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

    if (!_telemetryFirstFrame && v.isPlaying) {
      _telemetryFirstFrame = true;
      controller.markPlaybackReady(videoId);
      VideoTelemetryService.instance.onFirstFrame(videoId);
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
    }
  }

  void _videoEndListener() {
    if (!mounted || _isTransitioning) return;

    final vc = controller.cache[currentPage];
    if (vc == null) return;

    final position = vc.value.position.inMilliseconds;
    final duration = vc.value.duration.inMilliseconds;

    if (duration > 0 && position > 0) {
      final progress = position / duration;

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
          final cache = SegmentCacheManager.maybeFind();
          if (cache != null) {
            cache.updateWatchProgress(
              _cachedShorts[currentPage].docID,
              progress,
            );
            _lastProgressPersistAt = now;
            _lastPersistedProgress = progress;
          }
        }
      } catch (_) {}

      if (progress >= 0.98) {
        _isTransitioning = true;
        VideoTelemetryService.instance
            .onCompleted(_cachedShorts[currentPage].docID);
        vc.removeListener(_videoEndListener);
        _goToNextVideo();
      }
    }
  }

  void _goToNextVideo() {
    if (currentPage < _cachedShorts.length - 1) {
      final nextPage = currentPage + 1;
      isManuallyPaused = false;
      pageController
          .animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        _isTransitioning = false;
      });
    } else {
      _isTransitioning = false;
    }
  }
}
