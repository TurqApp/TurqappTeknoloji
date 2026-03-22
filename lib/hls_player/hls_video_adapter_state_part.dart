part of 'hls_video_adapter.dart';

extension _HlsVideoAdapterStatePart on HLSVideoAdapter {
  void _performRefreshProxyUrlIfNeeded() {
    final next = HLSVideoAdapter._resolveToProxy(_originalUrl);
    if (next != _effectiveUrl) {
      _effectiveUrl = next;
      debugPrint('[HLSAdapter] Proxy URL aktif: $_effectiveUrl');
    }
  }

  void _performPrepareForReuse() {
    if (_disposed) return;
    _viewReady = false;
    _isStopped = false;
    _value = HLSVideoValue(
      isInitialized: false,
      isPlaying: false,
      isBuffering: false,
      isCompleted: false,
      hasRenderedFirstFrame: false,
      position: _value.position,
      duration: _value.duration,
      size: _value.size,
      aspectRatio: _value.aspectRatio,
      buffered: _value.buffered,
    );
    notifyListeners();
  }

  void _performSubscribeToStreams() {
    _stateSub = _hls.onStateChanged.listen((state) {
      if (_disposed) return;

      final wasReady = _viewReady;
      _viewReady = state != PlayerState.idle && state != PlayerState.loading;

      _value = HLSVideoValue(
        isInitialized: _viewReady,
        isPlaying: state == PlayerState.playing,
        isBuffering: state == PlayerState.buffering,
        isCompleted: state == PlayerState.completed,
        hasRenderedFirstFrame: _value.hasRenderedFirstFrame,
        position: _value.position,
        duration: _value.duration,
        size: _value.size,
        aspectRatio: _value.aspectRatio,
        buffered: _value.buffered,
      );
      notifyListeners();

      if (_viewReady && !wasReady) {
        _executePendingCommands();
      }
    });

    _posSub = _hls.onPositionChanged.listen((pos) {
      if (_disposed) return;
      _value = HLSVideoValue(
        isInitialized: _value.isInitialized,
        isPlaying: _value.isPlaying,
        isBuffering: _value.isBuffering,
        isCompleted: _value.isCompleted,
        hasRenderedFirstFrame: _value.hasRenderedFirstFrame,
        position: pos,
        duration: _value.duration,
        size: _value.size,
        aspectRatio: _value.aspectRatio,
        buffered: _value.buffered,
      );
      notifyListeners();
    });

    _durSub = _hls.onDurationChanged.listen((dur) {
      if (_disposed) return;
      _value = HLSVideoValue(
        isInitialized: _value.isInitialized,
        isPlaying: _value.isPlaying,
        isBuffering: _value.isBuffering,
        isCompleted: _value.isCompleted,
        hasRenderedFirstFrame: _value.hasRenderedFirstFrame,
        position: _value.position,
        duration: dur,
        size: _value.size,
        aspectRatio: _value.aspectRatio,
        buffered: _value.buffered,
      );
      notifyListeners();
    });

    _firstFrameSub = _hls.onFirstFrameChanged.listen((hasRenderedFirstFrame) {
      if (_disposed) return;
      _value = HLSVideoValue(
        isInitialized: _value.isInitialized,
        isPlaying: _value.isPlaying,
        isBuffering: _value.isBuffering,
        isCompleted: _value.isCompleted,
        hasRenderedFirstFrame: hasRenderedFirstFrame,
        position: _value.position,
        duration: _value.duration,
        size: _value.size,
        aspectRatio: _value.aspectRatio,
        buffered: _value.buffered,
      );
      notifyListeners();
    });
  }

  void _performExecutePendingCommands() {
    if (_pendingPreferredBufferDurationSeconds != null) {
      _hls.setPreferredBufferDuration(_pendingPreferredBufferDurationSeconds!);
      _pendingPreferredBufferDurationSeconds = null;
    }
    if (_hasPendingVolume) {
      _hls.setVolume(_pendingVolume);
      _hasPendingVolume = false;
    }
    if (_pendingSeek != null) {
      _hls.seekTo(_pendingSeek!.inMilliseconds / 1000.0);
      _pendingSeek = null;
    }
    if (_wantPlay) {
      _hls.play();
      _wantPlay = false;
      _wantPause = false;
    } else if (_wantPause) {
      _hls.pause();
      _wantPause = false;
    }
  }
}
