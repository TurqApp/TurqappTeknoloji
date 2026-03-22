part of 'hls_video_adapter.dart';

extension _HlsVideoAdapterPlaybackPart on HLSVideoAdapter {
  Future<void> _performRecoverFrozenPlayback() async {
    if (_disposed) return;
    final resumeAt = _value.position;
    await stopPlayback();
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
      _isStopped = false;
      _wantPlay = true;
      _wantPause = false;
      if (_viewReady) {
        await _hls.loadVideo(url, autoPlay: true, loop: loop);
        return;
      }
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
    if (_viewReady) return _hls.setVolume(v);
    _pendingVolume = v;
    _hasPendingVolume = true;
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
    if (_viewReady) return _hls.seekTo(pos.inMilliseconds / 1000.0);
    _pendingSeek = pos;
    return Future.value();
  }

  Future<void> _performStopPlayback() {
    if (_disposed) return Future.value();
    _isStopped = true;
    _wantPlay = false;
    _wantPause = false;
    _hls.cancelPendingResume();
    if (_viewReady) {
      return _hls.stopPlayback();
    }
    return Future.value();
  }

  Future<void> _performReloadVideo() async {
    if (_disposed) return;
    _refreshProxyUrlIfNeeded();
    if (!_isStopped) return;
    _isStopped = false;
    if (_viewReady) {
      await _hls.loadVideo(url, autoPlay: false, loop: loop);
    }
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
  }) {
    if (_disposed) return const SizedBox.shrink();
    _refreshProxyUrlIfNeeded();
    return HLSPlayer(
      key: key,
      url: url,
      controller: _hls,
      autoPlay: overrideAutoPlay ?? autoPlay,
      loop: loop,
      showControls: false,
      aspectRatio: aspectRatio,
      useAspectRatio: useAspectRatio,
      forceFullscreenOnAndroid: forceFullscreenOnAndroid,
    );
  }
}
