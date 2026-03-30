// ignore_for_file: invalid_use_of_protected_member

part of 'single_short_view.dart';

extension SingleShortViewHelpersPart on _SingleShortViewState {
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
        try {
          await ctrl.setVolume(volume ? 1 : 0);
        } catch (_) {}
        _scheduleVolumeRestore(ctrl);
        try {
          await ctrl.play();
        } catch (_) {}
        _requestExclusivePlayback(docId);
      },
    );
  }

  void _scheduleVolumeRestore(HLSVideoAdapter ctrl) {
    final targetVolume = volume ? 1.0 : 0.0;
    Future<void>.microtask(() async {
      if (!mounted || ctrl.isDisposed) return;
      try {
        await ctrl.setVolume(targetVolume);
      } catch (_) {}
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () async {
      if (!mounted || ctrl.isDisposed) return;
      try {
        await ctrl.setVolume(targetVolume);
      } catch (_) {}
    });
    Future<void>.delayed(const Duration(milliseconds: 320), () async {
      if (!mounted || ctrl.isDisposed) return;
      try {
        await ctrl.setVolume(targetVolume);
      } catch (_) {}
    });
  }

  void _requestExclusivePlayback(
    String docId, {
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
      _playbackRuntimeService.playOnlyThis(playbackHandleKey);
    } catch (_) {}
  }

  Future<void> _releasePlayback(HLSVideoAdapter adapter) async {
    if (adapter.isDisposed) return;
    await adapter.pause();
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
      _updateTelemetryHintsForCurrentPage(
        isAudible: volume,
        hasStableFocus: true,
      );
      final playbackKpi = maybeFindPlaybackKpiService();
      if (playbackKpi != null) {
        playbackKpi.track(
          PlaybackKpiEventType.playbackIntent,
          {
            'source': 'single_short_view',
            'docId': shorts[page].docID,
            'audible': volume,
            'stableFocus': true,
          },
        );
      }
      final prefetch = maybeFindPrefetchScheduler();
      if (prefetch != null) {
        try {
          prefetch.updateQueue(
            shorts.map((s) => s.docID).toList(growable: false),
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
    VideoTelemetryService.instance.updateRuntimeHints(
      post.docID,
      isAudible: volume,
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

    if (!_telemetryFirstFrame && value.isPlaying) {
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
          _segmentCacheRuntimeService.updateWatchProgress(docId, progress);
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

  Widget _cachedThumb(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Future<void> _ensureInjectedInitialPlayback(
      HLSVideoAdapter ctrl, String docId) async {
    try {
      if (ctrl.isDisposed) return;
      ctrl.setLooping(false);
      ctrl.setVolume(volume ? 1 : 0);
      _scheduleVolumeRestore(ctrl);

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
    final current =
        currentPage >= 0 ? _videoControllers[currentPage] : null;
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
  }) {
    final ar = (modelAspectRatio != null && modelAspectRatio > 0)
        ? modelAspectRatio
        : (9 / 16);

    final player = adapter.buildPlayer(
      key: ValueKey(keyId),
      useAspectRatio: false,
      overrideAutoPlay: overrideAutoPlay,
      forceFullscreenOnAndroid: true,
      suppressLoadingOverlay: true,
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

  Future<void> _fetchAndShuffle() async {
    List<PostsModel> items = [];

    try {
      items = await ensureShortRepository().fetchRandomReadyPosts(limit: 1000)
        ..shuffle();
    } catch (_) {}

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

    merged.addAll(items);

    shorts.assignAll(merged);
  }
}
