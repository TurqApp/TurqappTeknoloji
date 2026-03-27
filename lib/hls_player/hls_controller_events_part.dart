part of 'hls_controller.dart';

extension HLSControllerEventsPart on HLSController {
  void _listenToEvents() {
    if (_eventChannel == null) return;

    _eventSubscription = _eventChannel!.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map) return;

        final eventType = event['event'] as String?;
        if (kDebugMode && !_suppressHlsSmokeLogs) {
          debugPrint(
            '[HLSController][view=$_viewId][video=${_telemetryVideoId ?? '-'}] event=$eventType payload=$event url=$_currentUrl',
          );
        }

        switch (eventType) {
          case 'ready':
            final durationSeconds =
                (event['duration'] as num?)?.toDouble() ?? 0.0;
            _duration = durationSeconds;
            _durationController
                .add(Duration(milliseconds: (durationSeconds * 1000).toInt()));
            _updateState(PlayerState.ready);
            final pendingSeek = _pendingReattachSeekSeconds;
            final pendingPlay = _pendingReattachShouldPlay;
            _pendingReattachSeekSeconds = null;
            _pendingReattachShouldPlay = false;
            if ((pendingSeek != null && pendingSeek > 0.05) || pendingPlay) {
              unawaited(
                _restorePlaybackAfterReattach(
                  seekSeconds: pendingSeek,
                  resumePlay: pendingPlay,
                ),
              );
            }
            break;

          case 'play':
            _updateState(PlayerState.playing);
            break;

          case 'firstFrame':
            _markFirstFrameRendered();
            break;

          case 'surfaceDetached':
            _hasRenderedFirstFrame = false;
            _firstFrameController.add(false);
            break;

          case 'pause':
            if (_state == PlayerState.completed || _isAtPlaybackEnd) {
              _updateState(PlayerState.completed);
            } else {
              _updateState(PlayerState.paused);
            }
            break;

          case 'buffering':
            final isBuffering = (event['isBuffering'] as bool?) ?? false;
            _bufferingController.add(isBuffering);
            if (isBuffering) {
              if (_telemetryVideoId != null) {
                _telemetry.onBufferingStart(_telemetryVideoId!);
              }
              _updateState(PlayerState.buffering);
            } else if (_state == PlayerState.buffering) {
              if (_telemetryVideoId != null) {
                _telemetry.onBufferingEnd(_telemetryVideoId!);
              }
              _updateState(PlayerState.playing);
            }
            break;

          case 'timeUpdate':
            final position = (event['position'] as num?)?.toDouble() ?? 0.0;
            final duration = (event['duration'] as num?)?.toDouble() ?? 0.0;
            _currentPosition = position;
            _duration = duration;
            _positionController
                .add(Duration(milliseconds: (position * 1000).toInt()));
            _durationController
                .add(Duration(milliseconds: (duration * 1000).toInt()));
            if (_telemetryVideoId != null) {
              _telemetry.onPositionUpdate(
                _telemetryVideoId!,
                position,
                duration,
              );
            }
            if (_state != PlayerState.completed &&
                duration.isFinite &&
                duration > 0 &&
                (duration - position) <= 0.2) {
              _updateState(PlayerState.completed);
            }
            if (_state == PlayerState.loading || _state == PlayerState.idle) {
              _updateState(
                position > 0 ? PlayerState.playing : PlayerState.ready,
              );
            }
            break;

          case 'completed':
            if (_telemetryVideoId != null) {
              _telemetry.onCompleted(_telemetryVideoId!);
            }
            _updateState(PlayerState.completed);
            break;

          case 'rendererStall':
            _rendererStallCount += 1;
            if (kDebugMode && !_suppressHlsSmokeLogs) {
              debugPrint(
                '[HLSController][view=$_viewId][video=${_telemetryVideoId ?? '-'}] rendererStall payload=$event url=$_currentUrl',
              );
            }
            break;

          case 'surfaceRebind':
            _surfaceRebindCount += 1;
            if (kDebugMode && !_suppressHlsSmokeLogs) {
              debugPrint(
                '[HLSController][view=$_viewId][video=${_telemetryVideoId ?? '-'}] surfaceRebind payload=$event url=$_currentUrl',
              );
            }
            break;

          case 'stopped':
            _updateState(PlayerState.idle);
            break;

          case 'error':
            final message = event['message'] as String? ??
                'error_handling.category_unknown'.tr;
            if (_telemetryVideoId != null) {
              _telemetry.onError(_telemetryVideoId!, message);
            }
            _handleError(message);
            break;

          case 'seekCompleted':
            final position = (event['position'] as num?)?.toDouble() ?? 0.0;
            _currentPosition = position;
            _positionController
                .add(Duration(milliseconds: (position * 1000).toInt()));
            if (_telemetryVideoId != null) {
              _telemetry.onSeek(_telemetryVideoId!);
            }
            break;
        }
      },
      onError: (dynamic error) {
        if (kDebugMode && !_suppressHlsSmokeLogs) {
          debugPrint(
            '[HLSController][view=$_viewId][video=${_telemetryVideoId ?? '-'}] streamError=$error url=$_currentUrl',
          );
        }
        _handleError('Event stream error: $error');
      },
    );
  }

  void _updateState(PlayerState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  void _markFirstFrameRendered() {
    if (_hasRenderedFirstFrame) return;
    _hasRenderedFirstFrame = true;
    _firstFrameController.add(true);
    if (!_firstFrameEmitted && _telemetryVideoId != null) {
      _firstFrameEmitted = true;
      _telemetry.onFirstFrame(_telemetryVideoId!);
    }
  }

  void _handleError(String message) {
    if (kDebugMode && !_suppressHlsSmokeLogs) {
      debugPrint(
        '[HLSController][view=$_viewId][video=${_telemetryVideoId ?? '-'}] error=$message url=$_currentUrl fallback=$_fallbackUrl attempted=$_fallbackAttempted',
      );
    }
    if (_fallbackUrl != null && !_fallbackAttempted) {
      _fallbackAttempted = true;
      loadVideo(_fallbackUrl!);
      return;
    }

    _errorMessage = message;
    _updateState(PlayerState.error);
    _errorController.add(message);
  }

  Future<void> _restorePlaybackAfterReattach({
    required double? seekSeconds,
    required bool resumePlay,
  }) async {
    if (_viewId == null) return;
    if (seekSeconds != null && seekSeconds > 0.05) {
      try {
        await seekTo(seekSeconds);
      } catch (_) {}
    }
    if (!resumePlay) return;
    try {
      await play();
    } catch (_) {}
  }
}
