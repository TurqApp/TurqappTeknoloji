part of 'single_short_view.dart';

extension SingleShortViewControllerBootstrapPart on _SingleShortViewState {
  void _preloadRange(int center) {
    final len = shorts.length;
    final start = (center - 1).clamp(0, len - 1);
    final end = (center + 5).clamp(0, len - 1);
    for (var i = start; i <= end; i++) {
      _ensureController(i);
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
      _playbackRuntimeService.registerPlaybackHandle(
        _playbackHandleKeyForDoc(list[initial].docID),
        HLSAdapterPlaybackHandle(widget.injectedController!),
      );
      final ctrl = widget.injectedController!;

      ctrl.setLooping(false);
      ctrl.setVolume(volume ? 1 : 0);
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
