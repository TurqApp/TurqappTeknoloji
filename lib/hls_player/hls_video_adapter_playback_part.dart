part of 'hls_video_adapter.dart';

extension _HlsVideoAdapterPlaybackPart on HLSVideoAdapter {
  Future<void> _performRestartStoppedPlayback({
    required bool autoPlay,
  }) async {
    if (_disposed) return;
    _refreshProxyUrlIfNeeded();
    if (!_isStopped) return;
    if (!_hls.canRestartStoppedPlayback) {
      _pendingReloadOnReady = true;
      return;
    }

    final pendingSeek = _pendingSeek;
    final hasPendingVolume = _hasPendingVolume;
    final pendingVolume = _pendingVolume;

    _pendingReloadOnReady = false;
    _isStopped = false;
    _wantPlay = autoPlay;
    _wantPause = false;

    await _hls.loadVideo(url, autoPlay: autoPlay, loop: loop);

    if (hasPendingVolume) {
      await _hls.setVolume(pendingVolume);
      _hasPendingVolume = false;
    }
    if (pendingSeek != null) {
      await _hls.seekTo(pendingSeek.inMilliseconds / 1000.0);
      _pendingSeek = null;
    }

    if (autoPlay) {
      _wantPlay = false;
      _wantPause = false;
    }
  }

  Future<void> _performRecoverFrozenPlayback({
    required bool preservePosition,
  }) async {
    if (_disposed) return;
    final shouldPreservePosition = preservePosition &&
        !(defaultTargetPlatform == TargetPlatform.android &&
            preferWarmPoolPause);
    final resumeAt = shouldPreservePosition ? _value.position : Duration.zero;
    await _performStopPlayback(preserveFrameSnapshot: false);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await reloadVideo();
    if (resumeAt > Duration.zero) {
      _pendingSeek = resumeAt;
    }
    _wantPlay = true;
    _wantPause = false;
    if (_viewReady) {
      await _hls.loadVideo(url, autoPlay: true, loop: loop);
      if (resumeAt > Duration.zero) {
        await _hls.seekTo(resumeAt.inMilliseconds / 1000.0);
      }
      await _hls.play();
    }
  }

  Future<void> _performPlay() {
    if (_disposed) return Future.value();
    return _playWithAudioFocus();
  }

  Future<void> _performPlayWithAudioFocus() async {
    if (_disposed) return;
    if (coordinateAudioFocus) {
      try {
        await AudioFocusCoordinator.instance.requestPlay(this);
      } catch (_) {}
    }
    _refreshProxyUrlIfNeeded();
    if (_isStopped) {
      _wantPlay = true;
      _wantPause = false;
      await _performRestartStoppedPlayback(autoPlay: true);
      return;
    }
    if (_viewReady) {
      _wantPlay = false;
      _wantPause = false;
      await _hls.play();
      return;
    }
    _wantPlay = true;
    _wantPause = false;
  }

  Future<void> _performPause() {
    if (_disposed) return Future.value();
    if (coordinateAudioFocus) {
      try {
        AudioFocusCoordinator.instance.requestPause(this);
      } catch (_) {}
    }
    if (_viewReady) {
      _wantPlay = false;
      _wantPause = false;
      return _hls.pause();
    }
    _wantPause = true;
    _wantPlay = false;
    return Future.value();
  }

  Future<void> _performForceSilence() async {
    if (_disposed) return;
    _wantPlay = false;
    _wantPause = true;
    _pendingVolume = 0.0;
    _hasPendingVolume = true;
    _hls.cancelPendingResume();

    try {
      if (_viewReady) {
        await _hls.setVolume(0.0);
        await _hls.pause();
      }
    } catch (_) {}
  }

  Future<void> _performSetVolume(double v) {
    if (_disposed) return Future.value();
    final requestedVolume = v.clamp(0.0, 1.0).toDouble();
    final previousRequestedVolume = _pendingVolume;
    final shouldRecheckIosAudibility = defaultTargetPlatform == TargetPlatform.iOS &&
        requestedVolume > 0.001 &&
        _viewReady &&
        _value.isInitialized &&
        _value.hasRenderedFirstFrame &&
        !_value.isCompleted;
    if (_hasPendingVolume &&
        (_pendingVolume - requestedVolume).abs() < 0.001 &&
        !shouldRecheckIosAudibility) {
      return Future.value();
    }
    _pendingVolume = requestedVolume;
    _hasPendingVolume = true;
    if (_viewReady) {
      return (() async {
        await _hls.setVolume(requestedVolume);
        var stillMuted = false;
        final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
        final isUnmute = previousRequestedVolume <= 0.001 &&
            requestedVolume > 0.001;
        final shouldReassertPlayback = isIOS &&
            (isUnmute || shouldRecheckIosAudibility) &&
            _value.isInitialized &&
            _value.hasRenderedFirstFrame &&
            !_value.isCompleted;
        if (shouldRecheckIosAudibility) {
          try {
            stillMuted = await _hls.isMutedNative();
          } catch (_) {}
        }
        if (!shouldReassertPlayback) return;
        final shouldForcePlay = stillMuted || !_value.isPlaying;
        if (!shouldForcePlay) return;
        try {
          await _hls.play();
        } catch (_) {}
      })();
    }
    return Future.value();
  }

  Future<void> _performSetLooping(bool v) {
    if (_disposed) return Future.value();
    if (_viewReady) return _hls.setLoop(v);
    return Future.value();
  }

  Future<bool> _performIsMutedNative() {
    if (_disposed) return Future.value(false);
    return _hls.isMutedNative();
  }

  Future<void> _performSeekTo(Duration pos) {
    if (_disposed) return Future.value();
    if (_isStopped) {
      _pendingSeek = pos;
      return Future.value();
    }
    final shouldClearCompleted = _value.isCompleted &&
        (_value.duration == Duration.zero || pos < _value.duration);
    if (shouldClearCompleted) {
      _value = HLSVideoValue(
        isInitialized: _value.isInitialized,
        isPlaying: false,
        isBuffering: _value.isBuffering,
        isCompleted: false,
        hasRenderedFirstFrame: _value.hasRenderedFirstFrame,
        position: pos,
        duration: _value.duration,
        size: _value.size,
        aspectRatio: _value.aspectRatio,
        buffered: _value.buffered,
      );
      _notifyAdapterListeners();
    }
    if (_viewReady) return _hls.seekTo(pos.inMilliseconds / 1000.0);
    _pendingSeek = pos;
    return Future.value();
  }

  Future<void> _performStopPlayback({
    bool preserveFrameSnapshot = true,
  }) {
    if (_disposed) return Future.value();
    _isStopped = true;
    _pendingReloadOnReady = false;
    _wantPlay = false;
    _wantPause = false;
    _hls.cancelPendingResume();
    if (_viewReady || _hls.currentUrl != null) {
      return _hls.stopPlayback(
        preserveFrameSnapshot: preserveFrameSnapshot,
      );
    }
    return Future.value();
  }

  Future<void> _performSilenceAndStopPlayback() async {
    if (_disposed) return;
    await _performForceSilence();
    await _performStopPlayback(preserveFrameSnapshot: false);
  }

  Future<void> _performReloadVideo() async {
    if (_disposed) return;
    _refreshProxyUrlIfNeeded();
    if (!_isStopped) return;
    await _performRestartStoppedPlayback(autoPlay: false);
  }

  Future<void> _performSetPreferredBufferDuration(double seconds) {
    if (_disposed) return Future.value();
    if (_viewReady) return _hls.setPreferredBufferDuration(seconds);
    _pendingPreferredBufferDurationSeconds = seconds;
    return Future.value();
  }

  void _performQueueSeekAndPlay(Duration position) {
    _wantPlay = true;
    _wantPause = false;
    if (position > Duration.zero) {
      _pendingSeek = position;
    }
  }

  Widget _performBuildPlayer({
    Key? key,
    required double aspectRatio,
    required bool useAspectRatio,
    required bool? overrideAutoPlay,
    required bool forceFullscreenOnAndroid,
    required bool isPrimaryFeedSurface,
    required bool preferResumePoster,
    bool startupRecoveryWatchdogEnabled = true,
    bool suppressLoadingOverlay = false,
  }) {
    if (_disposed) return const SizedBox.shrink();
    updateWarmPoolPausePreference(
      defaultTargetPlatform == TargetPlatform.android &&
          isPrimaryFeedSurface,
    );
    return HLSPlayer(
      key: key,
      url: url,
      controller: _hls,
      autoPlay: overrideAutoPlay ?? autoPlay,
      loop: loop,
      showControls: false,
      suppressLoadingOverlay: suppressLoadingOverlay,
      aspectRatio: aspectRatio,
      useAspectRatio: useAspectRatio,
      forceFullscreenOnAndroid: forceFullscreenOnAndroid,
      isPrimaryFeedSurface: isPrimaryFeedSurface,
      preferResumePoster: preferResumePoster,
      startupRecoveryWatchdogEnabled: startupRecoveryWatchdogEnabled,
    );
  }
}
