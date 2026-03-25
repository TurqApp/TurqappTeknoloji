// ignore_for_file: invalid_use_of_protected_member

part of 'single_short_view.dart';

extension SingleShortViewControllerPart on _SingleShortViewState {
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
    _scheduleVolumeRestore(ctrl);
    unawaited(ctrl.play());
    _requestExclusivePlayback(shorts[index].docID);
    if (index == currentPage) {
      _scheduleFullscreenPlaybackGuard(ctrl, shorts[index].docID);
    }
    if (index == currentPage) {
      _beginTelemetryForCurrentPage(ctrl);
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

    final retainedCurrentPage = retained.contains(currentPage);
    if (!retainedCurrentPage) {
      _ensureController(currentPage);
    }
    _preloadRange(currentPage);
    _disposeOutsideRange(currentPage);
    if (retainedCurrentPage) {
      _primePlaybackForIndex(currentPage);
    }

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
