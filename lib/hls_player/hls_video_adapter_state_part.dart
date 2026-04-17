part of 'hls_video_adapter.dart';

extension _HlsVideoAdapterStatePart on HLSVideoAdapter {
  void _performRefreshProxyUrlIfNeeded() {
    final next = HLSVideoAdapter._resolvePlaybackUrl(
      _originalUrl,
      useLocalProxy: _useLocalProxy,
    );
    if (_useLocalProxy &&
        _originalUrl.contains('cdn.turqapp.com') &&
        next == _originalUrl &&
        !_loggedProxyFallback) {
      final proxy = maybeFindHlsProxyServer();
      final cache = SegmentCacheManager.maybeFind();
      debugPrint(
        '[HLSAdapter] Proxy fallback kept original url='
        '$_originalUrl proxyRegistered=${proxy != null} '
        'proxyStarted=${proxy?.isStarted ?? false} '
        'cacheReady=${cache?.isReady ?? false}',
      );
      _loggedProxyFallback = true;
    }
    if (next != _effectiveUrl) {
      _effectiveUrl = next;
      _loggedProxyFallback = false;
      debugPrint('[HLSAdapter] Proxy URL aktif: $_effectiveUrl');
    }
  }

  void _performPrepareForReuse() {
    if (_disposed) return;
    _viewReady = false;
    _isStopped = false;
    _hls.resetSurfaceVisualStateForReuse();
    // Warm pool'dan dönen adapter'da stale play/pause/volume/seek komutlarını
    // bırakmazsak sonraki kart eski sessize alma veya pause isteğini devralıyor.
    _wantPlay = false;
    _wantPause = false;
    _pendingReloadOnReady = false;
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
      hasRenderedFirstFrame: false,
      awaitingFreshFrameAfterReattach: false,
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
      final hadVisualReadySignal =
          _value.hasRenderedFirstFrame || _value.position > Duration.zero;
      final inferredReady = _viewReady ||
          _value.isInitialized ||
          (defaultTargetPlatform == TargetPlatform.iOS && hadVisualReadySignal);

      _value = HLSVideoValue(
        isInitialized: inferredReady,
        isPlaying: state == PlayerState.playing,
        isBuffering: state == PlayerState.buffering,
        isCompleted: state == PlayerState.completed,
        hasRenderedFirstFrame: _value.hasRenderedFirstFrame,
        awaitingFreshFrameAfterReattach: _hls.awaitingFreshFrameAfterReattach,
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
      final inferredReady =
          defaultTargetPlatform == TargetPlatform.iOS && pos > Duration.zero;
      _value = HLSVideoValue(
        isInitialized: _value.isInitialized || inferredReady,
        isPlaying: _value.isPlaying,
        isBuffering: _value.isBuffering,
        isCompleted: _value.isCompleted,
        hasRenderedFirstFrame: _value.hasRenderedFirstFrame,
        awaitingFreshFrameAfterReattach: _hls.awaitingFreshFrameAfterReattach,
        position: pos,
        duration: _value.duration,
        size: _value.size,
        aspectRatio: _value.aspectRatio,
        buffered: _value.buffered,
      );
      _notifyAdapterListeners();
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          pos > Duration.zero &&
          pos <= const Duration(milliseconds: 180) &&
          _pendingVolume > 0.001) {
        unawaited(_hls.setVolume(_pendingVolume));
        if (_value.hasRenderedFirstFrame &&
            !_value.isCompleted &&
            !_value.isPlaying) {
          unawaited(_hls.play());
        }
      }
    });

    _durSub = _hls.onDurationChanged.listen((dur) {
      if (_disposed) return;
      _value = HLSVideoValue(
        isInitialized: _value.isInitialized,
        isPlaying: _value.isPlaying,
        isBuffering: _value.isBuffering,
        isCompleted: _value.isCompleted,
        hasRenderedFirstFrame: _value.hasRenderedFirstFrame,
        awaitingFreshFrameAfterReattach: _hls.awaitingFreshFrameAfterReattach,
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
      final inferredReady =
          defaultTargetPlatform == TargetPlatform.iOS && hasRenderedFirstFrame;
      _value = HLSVideoValue(
        isInitialized: _value.isInitialized || inferredReady,
        isPlaying: _value.isPlaying,
        isBuffering: _value.isBuffering,
        isCompleted: _value.isCompleted,
        hasRenderedFirstFrame: hasRenderedFirstFrame,
        awaitingFreshFrameAfterReattach: _hls.awaitingFreshFrameAfterReattach,
        position: _value.position,
        duration: _value.duration,
        size: _value.size,
        aspectRatio: _value.aspectRatio,
        buffered: _value.buffered,
      );
      _notifyAdapterListeners();
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          hasRenderedFirstFrame &&
          _hasPendingVolume &&
          _pendingVolume > 0.001) {
        unawaited(_performSetVolume(_pendingVolume));
      }
    });
  }

  void _performExecutePendingCommands() {
    if (_pendingReloadOnReady && _isStopped) {
      final shouldAutoPlay = _wantPlay && !_wantPause;
      unawaited(_performRestartStoppedPlayback(autoPlay: shouldAutoPlay));
      return;
    }
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
