part of 'hls_controller.dart';

extension HLSControllerEventsPart on HLSController {
  int _eventNowEpochMs() => DateTime.now().millisecondsSinceEpoch;

  void _recordResumePosterTiming(
    String trigger, {
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final resumePosterAt = _lastResumePosterAtEpochMs;
    if (resumePosterAt == null) return;
    final phaseSource = _lastNativeVisualPhaseSource ?? '';
    final posterLiftedAt = _lastPosterLiftedAtEpochMs;
    final firstFrameAt = _lastFirstFrameAtEpochMs;
    final playAt = _lastPlayAtEpochMs;
    final payload = <String, dynamic>{
      'viewId': _viewId ?? -1,
      'videoId': _telemetryVideoId ?? '',
      'url': _currentUrl ?? '',
      'trigger': trigger,
      'resumePosterAtEpochMs': resumePosterAt,
      'posterLiftedAtEpochMs': posterLiftedAt ?? -1,
      'firstFrameAtEpochMs': firstFrameAt ?? -1,
      'playAtEpochMs': playAt ?? -1,
      'posterToLiftMs':
          posterLiftedAt == null ? -1 : posterLiftedAt - resumePosterAt,
      'posterToFirstFrameMs':
          firstFrameAt == null ? -1 : firstFrameAt - resumePosterAt,
      'posterToPlayMs': playAt == null ? -1 : playAt - resumePosterAt,
      'phase': _lastNativeVisualPhase ?? '',
      'phaseSource': phaseSource,
      'phaseAtEpochMs': _lastNativeVisualPhaseAtEpochMs ?? -1,
      'positionMs': (_currentPosition * 1000).round(),
      ...metadata,
    };
    if (kDebugMode && !_suppressHlsSmokeLogs) {
      debugPrint(
        '[HLSController][view=$_viewId][video=${_telemetryVideoId ?? '-'}] resumePosterTiming payload=$payload url=$_currentUrl',
      );
    }
    recordQALabVideoEvent(
      code: 'resume_poster_timing',
      message: 'resume poster timing snapshot',
      metadata: payload,
    );
  }

  void _listenToEvents() {
    if (_eventChannel == null) return;

    _eventSubscription = _eventChannel!.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map) return;
        if (_isInactive) return;

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
            _emitDuration(
              Duration(milliseconds: (durationSeconds * 1000).toInt()),
            );
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
            _lastPlayAtEpochMs = _eventNowEpochMs();
            _recordResumePosterTiming('play');
            _updateState(PlayerState.playing);
            break;

          case 'firstFrame':
            _lastFirstFrameAtEpochMs = _eventNowEpochMs();
            _markFirstFrameRendered();
            _recordResumePosterTiming('first_frame');
            break;

          case 'surfaceDetached':
            if (!_shouldPreserveResumeVisual) {
              _hasRenderedFirstFrame = false;
              _emitFirstFrame(false);
            }
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
            _emitBuffering(isBuffering);
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
            _emitPosition(
              Duration(milliseconds: (position * 1000).toInt()),
            );
            _emitDuration(
              Duration(milliseconds: (duration * 1000).toInt()),
            );
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
                (duration - position) <= 0.05) {
              _updateState(PlayerState.completed);
            }
            if (_state == PlayerState.loading || _state == PlayerState.idle) {
              _updateState(
                position > 0 ? PlayerState.playing : PlayerState.ready,
              );
            }
            if (!_hasRenderedFirstFrame &&
                defaultTargetPlatform == TargetPlatform.android &&
                position > 0.05) {
              _lastFirstFrameAtEpochMs ??= _eventNowEpochMs();
              _markFirstFrameRendered();
              _recordResumePosterTiming(
                'synthetic_first_frame_from_time_update',
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

          case 'visualPhase':
            final phase = event['phase'] as String? ?? '';
            final phaseSource = event['source'] as String? ?? '';
            final phaseStartedAt =
                (event['phaseStartedAtEpochMs'] as num?)?.toInt() ??
                    _eventNowEpochMs();
            _lastNativeVisualPhase = phase;
            _lastNativeVisualPhaseSource = phaseSource;
            _lastNativeVisualPhaseAtEpochMs = phaseStartedAt;
            if (phase == 'resume_poster') {
              _lastResumePosterAtEpochMs = phaseStartedAt;
              _lastPosterLiftedAtEpochMs = null;
              _lastFirstFrameAtEpochMs = null;
              _lastPlayAtEpochMs = null;
            } else if (phase == 'video_play') {
              _lastPosterLiftedAtEpochMs = phaseStartedAt;
              _recordResumePosterTiming(
                'video_play',
                metadata: <String, dynamic>{
                  'previousPhase': event['previousPhase'] ?? '',
                  'previousDurationMs':
                      (event['previousDurationMs'] as num?)?.toInt() ?? -1,
                },
              );
            }
            if (kDebugMode && !_suppressHlsSmokeLogs) {
              debugPrint(
                '[HLSController][view=$_viewId][video=${_telemetryVideoId ?? '-'}] visualPhase payload=$event url=$_currentUrl',
              );
            }
            break;

          case 'stopped':
            if (_state == PlayerState.completed || _isAtPlaybackEnd) {
              _updateState(PlayerState.completed);
            } else {
              _updateState(PlayerState.idle);
            }
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
        if (_isInactive) return;
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
      _emitState(_state);
    }
  }

  void _markFirstFrameRendered() {
    _awaitingFreshFrameAfterReattach = false;
    if (_hasRenderedFirstFrame) return;
    _hasRenderedFirstFrame = true;
    _emitFirstFrame(true);
    if (!_firstFrameEmitted && _telemetryVideoId != null) {
      _firstFrameEmitted = true;
      _telemetry.onFirstFrame(_telemetryVideoId!);
    }
  }

  void _handleError(String message) {
    if (_isInactive) return;
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
    _emitError(message);
  }

  Future<void> _restorePlaybackAfterReattach({
    required double? seekSeconds,
    required bool resumePlay,
  }) async {
    if (_viewId == null) return;
    final shouldRestoreFromReattach = _awaitingFreshFrameAfterReattach;
    final currentPosition = _currentPosition.isFinite ? _currentPosition : 0.0;
    final hasStableVisualResume =
        _hasRenderedFirstFrame && currentPosition > 0.05;
    final seekAlreadyApplied = seekSeconds != null &&
        seekSeconds > 0.05 &&
        (currentPosition - seekSeconds).abs() <= 0.18;
    if (!shouldRestoreFromReattach) {
      if (resumePlay) {
        try {
          await play();
        } catch (_) {}
      }
      return;
    }
    if (hasStableVisualResume && seekAlreadyApplied) {
      return;
    }
    if (seekSeconds != null && seekSeconds > 0.05 && !seekAlreadyApplied) {
      try {
        await seekTo(seekSeconds);
      } catch (_) {}
    }
    if (!resumePlay) return;
    if (hasStableVisualResume && seekAlreadyApplied) {
      return;
    }
    try {
      await play();
    } catch (_) {}
  }
}
