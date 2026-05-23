part of 'single_short_view.dart';

extension SingleShortViewControllerBootstrapPart on _SingleShortViewState {
  void _preloadRange(int center) {
    final len = shorts.length;
    _primeSingleShortPlaybackWindowReadySegments(center);

    final safeCenter = center.clamp(0, len - 1);
    final ensuredIndices = <int>{};
    void ensureIndex(int index) {
      if (index < 0 || index >= len) return;
      if (!ensuredIndices.add(index)) return;
      _ensureController(index);
    }

    ensureIndex(safeCenter);
    for (var offset = 1;
        offset <= StartupPreloadPolicy.aheadFirstSegmentCount;
        offset++) {
      ensureIndex(safeCenter + offset);
    }
    for (var offset = 1;
        offset <= StartupPreloadPolicy.behindFirstSegmentCount;
        offset++) {
      ensureIndex(safeCenter - offset);
    }
  }

  void _primeSingleShortPlaybackWindowReadySegments(
    int anchorIndex, {
    int aheadCount = StartupPreloadPolicy.aheadFirstSegmentCount,
    int behindCount = StartupPreloadPolicy.behindFirstSegmentCount,
  }) {
    if (shorts.isEmpty) return;
    final safeAnchor = anchorIndex.clamp(0, shorts.length - 1);
    final primedIndices = <int>{};

    void primeIndex(int index) {
      if (index < 0 || index >= shorts.length) return;
      if (!primedIndices.add(index)) return;
      final post = shorts[index];
      final docId = post.docID.trim();
      final playbackUrl = post.playbackUrl.trim();
      if (docId.isEmpty || playbackUrl.isEmpty) return;
      try {
        final cacheManager = maybeFindSegmentCacheManager();
        if (cacheManager != null && cacheManager.isReady) {
          cacheManager.cachePostCards(<PostsModel>[post]);
          cacheManager.cacheHlsEntry(docId, playbackUrl);
        }
      } catch (_) {}
      try {
        _segmentCacheRuntimeService.ensureMinimumReadySegments(
          docId,
          minimumSegmentCount: index == safeAnchor
              ? StartupPreloadPolicy.activeReadySegments
              : StartupPreloadPolicy.neighborReadySegments,
        );
      } catch (_) {}
    }

    primeIndex(safeAnchor);
    for (var offset = 1; offset <= aheadCount; offset++) {
      primeIndex(safeAnchor + offset);
    }
    for (var offset = 1; offset <= behindCount; offset++) {
      primeIndex(safeAnchor - offset);
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
        _playbackRuntimeService.unregisterPlaybackHandle(
          _playbackHandleKeyForDoc(docId),
        );
      } catch (_) {}
    }

    _videoControllers.remove(index);
    if (adapter.isDisposed) return;
    await _videoPool.release(adapter, keepWarm: keepWarm);
  }

  void _configureInitialForList(List<PostsModel> list) {
    int initial = 0;
    var usesInjectedInitialPlayback = false;
    if (widget.startModel != null) {
      final idx = list.indexWhere((p) => p.docID == widget.startModel!.docID);
      if (idx != -1) initial = idx;
    } else if (list.isNotEmpty) {
      initial = 0;
    }
    currentPage = initial;
    _rebuildSingleShortRenderPlan();
    _currentRenderPage = _renderIndexForSingleShortOrganicIndex(initial);
    _isSingleShortAdPageActive = false;
    _pageActivatedAt = DateTime.now();
    _initialIndexForSeek = initial;
    if (widget.injectedController != null &&
        widget.injectedController!.value.isInitialized) {
      usesInjectedInitialPlayback = true;
      _suspendInjectedFeedPlaybackHandle(list[initial].docID);
      _videoControllers[initial] = widget.injectedController!;
      _externallyOwned.add(initial);
      _playbackRuntimeService.registerPlaybackHandle(
        _playbackHandleKeyForDoc(list[initial].docID),
        HLSAdapterPlaybackHandle(widget.injectedController!),
      );
      final ctrl = widget.injectedController!;

      ctrl.setLooping(false);
      _applySingleShortPlaybackPresentation(initial, ctrl);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || ctrl.isDisposed || initial >= list.length) return;
        _ensureInjectedInitialPlayback(ctrl, list[initial].docID);
      });

      _refreshView();
    } else {
      _initialIndexForSeek = null;
      _ensureController(initial);
    }
    if (list.isNotEmpty && initial >= 0 && initial < list.length) {
      try {
        _playbackRuntimeService.enterExclusiveMode(
          _playbackHandleKeyForDoc(list[initial].docID),
        );
      } catch (_) {}
      if (usesInjectedInitialPlayback) {
        _requestExclusivePlayback(
          list[initial].docID,
          adapter: widget.injectedController,
          minSpacing: Duration.zero,
        );
      }
      if (!usesInjectedInitialPlayback) {
        _primePlaybackForIndex(initial);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.jumpToPage(_currentRenderPage);
      }
    });
    if (list.isNotEmpty) {
      _warmFullscreenPosterWindowAround(
        initial,
        behindCount: StartupPreloadPolicy.posterBehindCount,
        aheadCount: StartupPreloadPolicy.posterAheadCount,
      );
      _preloadRange(initial);
    }
    _renderedShorts = List<PostsModel>.from(list);
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
          _playbackRuntimeService.registerPlaybackHandle(
            _playbackHandleKeyForDoc(shorts[index].docID),
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
      cacheKey: _playbackHandleKeyForDoc(shorts[index].docID),
      url: url,
      autoPlay: false,
      loop: false,
      preferWarmPoolPauseOnAndroid: true,
    );
    _videoControllers[index] = ctrl;
    try {
      _playbackRuntimeService.registerPlaybackHandle(
        _playbackHandleKeyForDoc(shorts[index].docID),
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
    _refreshView();
  }
}
