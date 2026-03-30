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
    final preserveInlineFrame =
        _value.hasRenderedFirstFrame && _value.position > const Duration(milliseconds: 50);
    // Warm pool'dan dönen adapter'da stale play/pause/volume/seek komutlarını
    // bırakmazsak sonraki kart eski sessize alma veya pause isteğini devralıyor.
    _wantPlay = false;
    _wantPause = false;
    _pendingVolume = 1.0;
    _hasPendingVolume = false;
    _pendingSeek = null;
    _pendingPreferredBufferDurationSeconds = null;
    _hls.cancelPendingResume();
    _value = HLSVideoValue(
      isInitialized: false,
      isPlaying: false,
      isBuffering: false,
      isCompleted: false,
      hasRenderedFirstFrame: preserveInlineFrame,
      position: _value.position,
      duration: _value.duration,
      size: _value.size,
      aspectRatio: _value.aspectRatio,
      buffered: _value.buffered,
    );
    _notifyAdapterListeners();
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
      _notifyAdapterListeners();

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
      _notifyAdapterListeners();
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
      _notifyAdapterListeners();
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
      _notifyAdapterListeners();
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
