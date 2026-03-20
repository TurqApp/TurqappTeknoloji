// ignore_for_file: invalid_use_of_protected_member

part of 'single_short_view.dart';

extension SingleShortViewHelpersPart on _SingleShortViewState {
  void _requestExclusivePlayback(
    String docId, {
    Duration minSpacing = const Duration(milliseconds: 220),
  }) {
    final trimmed = docId.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    final lastDocId = _lastExclusivePlayDocId;
    final lastAt = _lastExclusivePlayAt;
    if (lastDocId == trimmed &&
        lastAt != null &&
        now.difference(lastAt) < minSpacing) {
      return;
    }
    _lastExclusivePlayDocId = trimmed;
    _lastExclusivePlayAt = now;
    try {
      VideoStateManager.instance.playOnlyThis(trimmed);
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
      if (Get.isRegistered<PlaybackKpiService>()) {
        Get.find<PlaybackKpiService>().track(
          PlaybackKpiEventType.playbackIntent,
          {
            'source': 'single_short_view',
            'docId': shorts[page].docID,
            'audible': volume,
            'stableFocus': true,
          },
        );
      }
      if (Get.isRegistered<PrefetchScheduler>()) {
        try {
          Get.find<PrefetchScheduler>().updateQueue(
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

      if (shouldPersist && Get.isRegistered<SegmentCacheManager>()) {
        try {
          Get.find<SegmentCacheManager>().updateWatchProgress(docId, progress);
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

  Future<void> _releaseControllerAt(
    int index, {
    bool keepWarm = true,
  }) async {
    final adapter = _videoControllers[index];
    if (adapter == null) return;
    _detachCompletionListener(index, adapter);

    final docId =
        (index >= 0 && index < shorts.length) ? shorts[index].docID : null;
    if (docId != null) {
      try {
        videoStateManager.unregisterVideoController(docId);
      } catch (_) {}
    }

    _videoControllers.remove(index);
    if (adapter.isDisposed) return;
    await _videoPool.release(adapter, keepWarm: keepWarm);
  }

  Widget _cachedThumb(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
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
        await ctrl.play();
        _requestExclusivePlayback(docId);
        await Future.delayed(const Duration(milliseconds: 120));
        if (ctrl.value.isPlaying) break;
      }
    } catch (_) {}
  }

  Future<void> _pauseAllControllers() async {
    for (final vp in _videoControllers.values) {
      try {
        if (vp.isDisposed) continue;
        if (vp.value.isInitialized) {
          await _releasePlayback(vp);
        }
      } catch (_) {}
    }
    final injected = widget.injectedController;
    if (injected != null) {
      try {
        if (!injected.isDisposed && injected.value.isInitialized) {
          await _releasePlayback(injected);
        }
      } catch (_) {}
    }
    try {
      VideoStateManager.instance.pauseAllVideos(force: true);
    } catch (_) {}
    try {
      VideoStateManager.instance.exitExclusiveMode();
    } catch (_) {}
  }

  void _primePlaybackForIndex(int index) {
    if (index < 0 || index >= shorts.length) return;
    final ctrl = _videoControllers[index];
    if (ctrl == null || ctrl.isDisposed) return;
    try {
      ctrl.setVolume(volume ? 1 : 0);
    } catch (_) {}
    unawaited(ctrl.play());
    _requestExclusivePlayback(shorts[index].docID);
    if (index == currentPage) {
      _beginTelemetryForCurrentPage(ctrl);
    }
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

  void _configureInitialForList(List<PostsModel> list) {
    int initial = 0;
    if (widget.startModel != null) {
      final idx = list.indexWhere((p) => p.docID == widget.startModel!.docID);
      if (idx != -1) initial = idx;
    } else if (list.isNotEmpty) {
      initial = 0;
    }
    currentPage = initial;
    _pageActivatedAt = DateTime.now();
    _initialIndexForSeek = initial;
    if (widget.injectedController != null &&
        widget.injectedController!.value.isInitialized) {
      _videoControllers[initial] = widget.injectedController!;
      _externallyOwned.add(initial);
      videoStateManager.registerPlaybackHandle(
        list[initial].docID,
        HLSAdapterPlaybackHandle(widget.injectedController!),
      );
      final ctrl = widget.injectedController!;

      ctrl.setLooping(false);
      ctrl.setVolume(volume ? 1 : 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || ctrl.isDisposed || initial >= list.length) return;
        _ensureInjectedInitialPlayback(ctrl, list[initial].docID);
      });

      setState(() {});
    } else {
      _initialIndexForSeek = null;
      _ensureController(initial);
    }
    if (list.isNotEmpty && initial >= 0 && initial < list.length) {
      try {
        VideoStateManager.instance.enterExclusiveMode(list[initial].docID);
      } catch (_) {}
      _primePlaybackForIndex(initial);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.jumpToPage(initial);
      }
    });
    if (list.isNotEmpty) _preloadRange(initial);
    _renderedShorts = List<PostsModel>.from(list);
  }

  void _handleShortsChange(List<PostsModel> list) {
    final previous = List<PostsModel>.from(_renderedShorts);
    if (previous.isEmpty) {
      _configureInitialForList(list);
      return;
    }

    final update = _shortRenderCoordinator.buildUpdate(
      previous: previous,
      next: list,
      currentIndex: currentPage,
    );
    if (update.patch.isEmpty) {
      _renderedShorts = List<PostsModel>.from(list);
      return;
    }

    final oldControllers = Map<int, HLSVideoAdapter>.from(_videoControllers);
    final oldExternallyOwned = Set<int>.from(_externallyOwned);
    final oldCompletionTriggered = Map<int, bool>.from(_completionTriggered);
    _videoControllers.clear();
    _externallyOwned.clear();
    _completionTriggered.clear();

    if (list.isEmpty) {
      for (final entry in oldControllers.entries) {
        final controller = entry.value;
        _detachCompletionListener(entry.key, controller);
        if (widget.injectedController != null &&
            identical(controller, widget.injectedController)) {
          continue;
        }
        unawaited(_videoPool.release(controller, keepWarm: true));
      }
      _renderedShorts = const <PostsModel>[];
      currentPage = 0;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final retained = <int>{};
    for (final entry in oldControllers.entries) {
      final oldIndex = entry.key;
      final controller = entry.value;
      if (oldIndex < 0 || oldIndex >= previous.length) {
        if (!(widget.injectedController != null &&
            identical(controller, widget.injectedController))) {
          unawaited(_videoPool.release(controller, keepWarm: true));
        }
        continue;
      }

      final docId = previous[oldIndex].docID;
      final newIndex = list.indexWhere((item) => item.docID == docId);
      _detachCompletionListener(oldIndex, controller);

      if (newIndex == -1) {
        if (!(widget.injectedController != null &&
            identical(controller, widget.injectedController))) {
          unawaited(_videoPool.release(controller, keepWarm: true));
        }
        continue;
      }

      retained.add(newIndex);
      _videoControllers[newIndex] = controller;
      if (oldExternallyOwned.contains(oldIndex)) {
        _externallyOwned.add(newIndex);
      }
      final wasCompleted = oldCompletionTriggered[oldIndex];
      if (wasCompleted != null) {
        _completionTriggered[newIndex] = wasCompleted;
      }
      _addVideoCompletionListener(controller, newIndex);
    }

    currentPage = update.remappedIndex.clamp(0, list.length - 1);
    _renderedShorts = List<PostsModel>.from(list);

    if (list.isNotEmpty && currentPage >= 0 && currentPage < list.length) {
      try {
        VideoStateManager.instance.enterExclusiveMode(list[currentPage].docID);
      } catch (_) {}
    }

    if (!retained.contains(currentPage)) {
      _ensureController(currentPage);
    }
    _preloadRange(currentPage);
    _disposeOutsideRange(currentPage);
    _primePlaybackForIndex(currentPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !pageController.hasClients) return;
      try {
        pageController.jumpToPage(currentPage);
      } catch (_) {}
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchAndShuffle() async {
    List<PostsModel> items = [];

    try {
      items = await ShortRepository.ensure().fetchRandomReadyPosts(limit: 1000)
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

  void _clearAllControllers() {
    final keys = _videoControllers.keys.toList();
    for (final idx in keys) {
      final c = _videoControllers[idx]!;
      if (_externallyOwned.contains(idx)) {
        continue;
      }
      if (c.isDisposed) {
        _detachCompletionListener(idx, c);
        _videoControllers.remove(idx);
        continue;
      }
      unawaited(_releaseControllerAt(idx));
    }
  }

  void _preloadRange(int center) {
    final len = shorts.length;
    final start = (center - 1).clamp(0, len - 1);
    final end = (center + 5).clamp(0, len - 1);
    for (var i = start; i <= end; i++) {
      _ensureController(i);
    }
  }

  void _ensureController(int index) {
    if (index < 0 || index >= shorts.length) return;
    if (_videoControllers.containsKey(index)) return;

    if (_initialIndexForSeek != null &&
        index == _initialIndexForSeek &&
        widget.injectedController != null &&
        widget.injectedController!.value.isInitialized &&
        !_videoControllers.containsKey(index)) {
      if (index >= 0 && index < shorts.length) {
        try {
          videoStateManager.registerPlaybackHandle(
            shorts[index].docID,
            HLSAdapterPlaybackHandle(widget.injectedController!),
          );
        } catch (_) {}
      }
      _addVideoCompletionListener(widget.injectedController!, index);
      return;
    }

    final url = shorts[index].playbackUrl;
    if (url.isEmpty) return;

    final ctrl = _videoPool.acquire(
      cacheKey: shorts[index].docID,
      url: url,
      autoPlay: false,
      loop: false,
    );
    _videoControllers[index] = ctrl;
    try {
      videoStateManager.registerPlaybackHandle(
        shorts[index].docID,
        HLSAdapterPlaybackHandle(ctrl),
      );
    } catch (_) {}

    ctrl.setLooping(false);
    _addVideoCompletionListener(ctrl, index);

    if (index == currentPage) {
      if (ctrl.isDisposed) return;
      if (_initialIndexForSeek != null &&
          index == _initialIndexForSeek &&
          widget.initialPosition != null &&
          widget.initialPosition! > Duration.zero) {
        final pos = widget.initialPosition!;
        ctrl.seekTo(pos);
      }
      _primePlaybackForIndex(index);
    }
    if (mounted) setState(() {});
  }

  void _addVideoCompletionListener(HLSVideoAdapter ctrl, int index) {
    _detachCompletionListener(index, ctrl);
    void listener() {
      if (!mounted) return;
      if (index != currentPage) return;

      final value = ctrl.value;
      if (!value.isInitialized) return;
      if (_completionTriggered[index] == true) return;

      final position = value.position;
      final duration = value.duration;
      final justActivated =
          DateTime.now().difference(_pageActivatedAt).inMilliseconds < 1200;
      if (justActivated) return;
      if (duration.inMilliseconds > 0 &&
          position >= duration - const Duration(milliseconds: 300) &&
          position.inMilliseconds > 0) {
        _completionTriggered[index] = true;
        if (index >= 0 && index < shorts.length) {
          VideoTelemetryService.instance.onCompleted(shorts[index].docID);
        }

        final nextIndex = currentPage + 1;
        if (nextIndex < shorts.length) {
          if (pageController.hasClients) {
            pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else {
          Future.delayed(const Duration(milliseconds: 100), () {
            final sameController = _videoControllers[index] == ctrl;
            if (mounted && sameController && !ctrl.isDisposed) {
              ctrl.seekTo(Duration.zero);
              if (index >= 0 && index < shorts.length) {
                _requestExclusivePlayback(shorts[index].docID);
              }
              _completionTriggered[index] = false;
            }
          });
        }
      }
    }

    _completionListeners[index] = listener;
    ctrl.addListener(listener);
  }

  void _disposeOutsideRange(int center) {
    final len = shorts.length;
    final start = (center - 10).clamp(0, len - 1);
    final end = (center + 10).clamp(0, len - 1);
    final keys = _videoControllers.keys.toList();
    for (var idx in keys) {
      if (idx < start || idx > end) {
        if (!_externallyOwned.contains(idx)) {
          unawaited(_releaseControllerAt(idx));
        }
      }
    }
  }
}
