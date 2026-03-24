// ignore_for_file: invalid_use_of_protected_member

part of 'single_short_view.dart';

extension SingleShortViewPlaybackPart on _SingleShortViewState {
  void _initializeSingleShortView() {
    final hasInjectedPlayingController = widget.injectedController != null &&
        !widget.injectedController!.isDisposed &&
        widget.injectedController!.value.isInitialized;
    if (!hasInjectedPlayingController) {
      try {
        VideoStateManager.instance.pauseAllVideos(force: true);
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
    } else if (widget.startModel != null) {
      final merged = <PostsModel>[widget.startModel!];
      shorts.assignAll(merged);
      _configureInitialForList(merged);
    }

    ever<List<PostsModel>>(shorts, _handleShortsChange);

    final shouldFetch = widget.startList == null || widget.startList!.isEmpty;
    if (shouldFetch) {
      _fetchAndShuffle();
    }
  }

  void _handlePageChanged(int page) {
    if (page == currentPage) return;

    final prev = _videoControllers[currentPage];
    if (prev != null) {
      try {
        _releasePlayback(prev);
      } catch (_) {}
    }
    unawaited(_endActiveTelemetrySession());

    currentPage = page;
    showControls = true;
    _pageActivatedAt = DateTime.now();
    if (currentPage >= 0 && currentPage < shorts.length) {
      try {
        VideoStateManager.instance
            .updateExclusiveModeDoc(shorts[currentPage].docID);
      } catch (_) {}
    }

    for (final entry in _videoControllers.entries) {
      if (entry.key == currentPage) continue;
      try {
        _releasePlayback(entry.value);
      } catch (_) {}
    }

    _completionTriggered[page] = false;

    if (_initialIndexForSeek != null && page != _initialIndexForSeek) {
      _initialIndexForSeek = null;
    }

    final hadCurrentController = _videoControllers.containsKey(currentPage);
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
      if (hadCurrentController) {
        _primePlaybackForIndex(currentPage);
      }

      if (currentPage < shorts.length) {
        try {
          final cm = SegmentCacheManager.maybeFind();
          if (cm != null) {
            cm.markPlaying(shorts[currentPage].docID);
            for (var i = 1; i <= 5; i++) {
              final behindIdx = currentPage - i;
              if (behindIdx < 0) break;
              if (behindIdx < shorts.length) {
                cm.touchEntry(shorts[behindIdx].docID);
              }
            }
          }
        } catch (_) {}
      }
    }
    _preloadRange(currentPage);
    _disposeOutsideRange(currentPage);
    setState(() {});
  }

  void _handleManualVerticalDragStart(DragStartDetails details) {
    _manualGestureDragDy = 0.0;
  }

  void _handleManualVerticalDragUpdate(DragUpdateDetails details) {
    _manualGestureDragDy += details.primaryDelta ?? 0.0;
  }

  void _handleManualVerticalDragEnd(DragEndDetails details) {
    final delta = _manualGestureDragDy;
    final velocity = details.primaryVelocity ?? 0.0;
    _manualGestureDragDy = 0.0;

    if (!mounted || _manualSnapInProgress || shorts.isEmpty) return;

    final goForward =
        velocity < -_SingleShortViewState._manualGestureTriggerVelocity ||
            delta < -_SingleShortViewState._manualGestureTriggerDistance;
    final goBackward =
        velocity > _SingleShortViewState._manualGestureTriggerVelocity ||
            delta > _SingleShortViewState._manualGestureTriggerDistance;
    if (goForward == goBackward) return;

    final targetPage = goForward
        ? (currentPage + 1).clamp(0, shorts.length - 1)
        : (currentPage - 1).clamp(0, shorts.length - 1);
    if (targetPage == currentPage) return;

    unawaited(_animateManualPage(targetPage));
  }

  Future<void> _animateManualPage(int targetPage) async {
    if (!mounted || _manualSnapInProgress || !pageController.hasClients) return;
    _manualSnapInProgress = true;
    try {
      await pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
    } finally {
      _manualSnapInProgress = false;
    }
  }

  void _disposeSingleShortView() {
    try {
      final route = ModalRoute.of(context);
      if (route != null) routeObserver.unsubscribe(this);
    } catch (_) {}
    pageController.dispose();
    unawaited(_endActiveTelemetrySession());
    _fullscreenPlaybackGuardTimer?.cancel();
    _fullscreenPlaybackGuardTimer = null;
    _clearAllControllers();
    try {
      VideoStateManager.instance.exitExclusiveMode();
    } catch (_) {}
  }

  void _handleDidPop() {
    try {
      if (currentPage >= 0 && currentPage < shorts.length) {
        final currentModel = shorts[currentPage];
        final ctrl = _videoControllers[currentPage];

        if (ctrl != null && ctrl.value.isInitialized) {
          final videoStateManager = VideoStateManager.maybeFind();
          if (videoStateManager != null) {
            videoStateManager.saveVideoState(
              currentModel.docID,
              HLSAdapterPlaybackHandle(ctrl),
            );
          }
        }
      }
    } catch (_) {}

    unawaited(_endActiveTelemetrySession());
    _pauseAllControllers();
    try {
      VideoStateManager.instance.exitExclusiveMode();
    } catch (_) {}
  }

  void _handleDidPushNext() {
    unawaited(_endActiveTelemetrySession());
    unawaited(_pauseAllControllers());
  }

  void _handleDidPopNext() {
    final isStillCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isStillCurrent) return;
    if (currentPage < 0 || currentPage >= shorts.length) return;

    final vp = _videoControllers[currentPage];
    if (vp == null || vp.isDisposed) return;

    try {
      VideoStateManager.instance.enterExclusiveMode(shorts[currentPage].docID);
    } catch (_) {}
    _primePlaybackForIndex(currentPage);
  }

  void _handleDidStartUserGesture() {
    _pauseAllControllers();
  }

  void _handleDidStopUserGesture() {
    final isStillCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (isStillCurrent) {
      final vp = _videoControllers[currentPage];
      if (vp != null && vp.value.isInitialized) {
        try {
          if (vp.isDisposed) return;
          vp.setVolume(volume ? 1 : 0);
          _updateTelemetryHintsForCurrentPage(
            isAudible: volume,
            hasStableFocus: false,
          );
          if (currentPage >= 0 && currentPage < shorts.length) {
            _requestExclusivePlayback(shorts[currentPage].docID);
          }
        } catch (_) {}
      }
    }
  }
}
