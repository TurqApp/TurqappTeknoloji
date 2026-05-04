part of 'hls_controller.dart';

extension HLSControllerPlaybackPart on HLSController {
  Future<void> loadVideoWithFallback(
    String url, {
    String? fallbackUrl,
    bool autoPlay = true,
    bool loop = false,
  }) async {
    _fallbackUrl = fallbackUrl;
    _fallbackAttempted = false;
    await loadVideo(url, autoPlay: autoPlay, loop: loop);
  }

  void setTelemetryVideoId(String videoId) {
    if (_telemetryVideoId != null) {
      _telemetry.endSession(_telemetryVideoId!);
    }
    _telemetryVideoId = videoId;
    _firstFrameEmitted = false;
  }

  Future<void> loadVideo(
    String url, {
    bool autoPlay = true,
    bool loop = false,
    bool? preferResumePoster,
    bool? suppressPauseSnapshot,
  }) async {
    if (_isInactive) return;
    if (_viewId == null) {
      throw Exception('Controller not initialized. Call initialize() first.');
    }

    if (preferResumePoster != null) {
      _preferResumePoster = preferResumePoster;
    }

    final previousUrl = _currentUrl;
    final shouldDeferAutoplayForReattach = autoPlay &&
        previousUrl == url &&
        ((_pendingReattachShouldPlay) ||
            ((_pendingReattachSeekSeconds ?? 0.0) > 0.05));
    final sameVideoReload = _currentUrl == url && _shouldPreserveResumeVisual;
    _currentUrl = url;
    _isLooping = loop;
    _resetVisualTimingMarkers();
    _updateState(PlayerState.loading);
    _firstFrameEmitted = false;
    if (_hasVisibleVideoFrame) {
      _hasVisibleVideoFrame = false;
      _emitVisibleVideoFrame(false);
    }
    if (!sameVideoReload) {
      _hasRenderedFirstFrame = false;
      _emitFirstFrame(false);
    }
    _rendererStallCount = 0;
    _surfaceRebindCount = 0;
    if (_telemetryVideoId != null) {
      _telemetry.startSession(_telemetryVideoId!, url);
    }

    try {
      await HLSController._methodChannel.invokeMethod('loadVideo', {
        'viewId': _viewId,
        'url': url,
        'autoPlay': shouldDeferAutoplayForReattach ? false : autoPlay,
        'loop': loop,
        'preferResumePoster': _preferResumePoster,
        'suppressPauseSnapshot': suppressPauseSnapshot ?? false,
      });
    } on PlatformException catch (e) {
      _handleError('Failed to load video: ${e.message}');
    }
  }

  Future<void> play() async {
    if (_isInactive || _viewId == null) return;

    try {
      await HLSController._methodChannel
          .invokeMethod('play', {'viewId': _viewId});
    } on PlatformException catch (e) {
      _handleError('Failed to play: ${e.message}');
    }
  }

  Future<void> pause() async {
    if (_isInactive || _viewId == null) return;
    cancelPendingResume();

    try {
      await HLSController._methodChannel
          .invokeMethod('pause', {'viewId': _viewId});
    } on PlatformException catch (e) {
      _handleError('Failed to pause: ${e.message}');
    }
  }

  Future<void> seekTo(double seconds) async {
    if (_isInactive || _viewId == null) return;

    try {
      await HLSController._methodChannel.invokeMethod('seek', {
        'viewId': _viewId,
        'seconds': seconds,
      });
      _currentPosition = seconds;
      _emitPosition(Duration(milliseconds: (seconds * 1000).toInt()));
    } on PlatformException catch (e) {
      _handleError('Failed to seek: ${e.message}');
    }
  }

  Future<void> setMuted(bool muted) async {
    if (_isInactive || _viewId == null) return;

    try {
      await HLSController._methodChannel.invokeMethod('setMuted', {
        'viewId': _viewId,
        'muted': muted,
      });
      _isMuted = muted;
    } on PlatformException catch (e) {
      _handleError('Failed to set muted: ${e.message}');
    }
  }

  Future<void> setVolume(double volume) async {
    if (_isInactive || _viewId == null) return;

    final clampedVolume = volume.clamp(0.0, 1.0);

    try {
      await HLSController._methodChannel.invokeMethod('setVolume', {
        'viewId': _viewId,
        'volume': clampedVolume,
      });
    } on PlatformException catch (e) {
      _handleError('Failed to set volume: ${e.message}');
    }
  }

  Future<void> stopPlayback({
    bool preserveFrameSnapshot = true,
  }) async {
    if (_isInactive || _viewId == null) return;
    cancelPendingResume();
    try {
      await HLSController._methodChannel.invokeMethod('stopPlayback', {
        'viewId': _viewId,
        'preserveFrameSnapshot': preserveFrameSnapshot,
      });
    } on PlatformException catch (e) {
      _handleError('Failed to stop playback: ${e.message}');
    }
  }

  Future<void> setPreferredBufferDuration(double seconds) async {
    if (_isInactive || _viewId == null) return;
    try {
      await HLSController._methodChannel
          .invokeMethod('setPreferredBufferDuration', {
        'viewId': _viewId,
        'duration': seconds,
      });
    } on PlatformException catch (e) {
      _handleError('Failed to set buffer duration: ${e.message}');
    }
  }

  Future<void> setLoop(bool loop) async {
    if (_isInactive || _viewId == null) return;

    try {
      await HLSController._methodChannel.invokeMethod('setLoop', {
        'viewId': _viewId,
        'loop': loop,
      });
      _isLooping = loop;
    } on PlatformException catch (e) {
      _handleError('Failed to set loop: ${e.message}');
    }
  }

  Future<void> togglePlayPause() async {
    if (_isInactive) return;
    if (_state == PlayerState.playing) {
      await pause();
    } else if (_state == PlayerState.paused || _state == PlayerState.ready) {
      await play();
    }
  }
}
