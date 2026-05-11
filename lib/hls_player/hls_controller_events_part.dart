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
            if (_state != PlayerState.playing &&
                _state != PlayerState.buffering &&
                _state != PlayerState.completed) {
              _updateState(PlayerState.ready);
            }
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
              if (_hasVisibleVideoFrame) {
                _hasVisibleVideoFrame = false;
                _emitVisibleVideoFrame(false);
              }
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
              if (_hasVisibleVideoFrame) {
                _hasVisibleVideoFrame = false;
                _emitVisibleVideoFrame(false);
              }
            } else if (phase == 'video_play') {
              _lastPosterLiftedAtEpochMs = phaseStartedAt;
              if (!_hasVisibleVideoFrame) {
                _hasVisibleVideoFrame = true;
                _emitVisibleVideoFrame(true);
              }
              _recordResumePosterTiming(
                'video_play',
                metadata: <String, dynamic>{
                  'previousPhase': event['previousPhase'] ?? '',
                  'previousDurationMs':
                      (event['previousDurationMs'] as num?)?.toInt() ?? -1,
                },
              );
            } else if (phase == 'siyah' && _hasVisibleVideoFrame) {
              _hasVisibleVideoFrame = false;
              _emitVisibleVideoFrame(false);
            }
            recordQALabVideoEvent(
              code: 'playback_visual_$phase',
              message: 'native playback visual phase changed to $phase',
              metadata: <String, dynamic>{
                'viewId': _viewId ?? -1,
                'videoId': _telemetryVideoId ?? '',
                'url': _currentUrl ?? '',
                'phase': phase,
                'phaseSource': phaseSource,
                'previousPhase': event['previousPhase'] ?? '',
                'previousDurationMs':
                    (event['previousDurationMs'] as num?)?.toInt() ?? -1,
                'phaseStartedAtEpochMs': phaseStartedAt,
                'overlayVisible': event['overlayVisible'] == true,
                'didRenderFirstFrame': event['didRenderFirstFrame'] == true,
                'preferResumePoster': event['preferResumePoster'] == true,
                'snapshotCaptureSource':
                    (event['snapshotCaptureSource'] ?? '').toString(),
              },
            );
            if (kDebugMode && !_suppressHlsSmokeLogs) {
              debugPrint(
                '[HLSController][view=$_viewId][video=${_telemetryVideoId ?? '-'}] visualPhase payload=$event url=$_currentUrl',
              );
            }
            break;

          case 'stopped':
            final hadVisualState =
                _hasRenderedFirstFrame || _hasVisibleVideoFrame;
            if (hadVisualState) {
              if (kDebugMode && !_suppressHlsSmokeLogs) {
                debugPrint(
                  '[HLSController][view=$_viewId][video=${_telemetryVideoId ?? '-'}] '
                  'stoppedClearVisualState firstFrame=$_hasRenderedFirstFrame '
                  'visibleFrame=$_hasVisibleVideoFrame '
                  'positionMs=${(_currentPosition * 1000).round()} '
                  'url=$_currentUrl',
                );
              }
              recordQALabVideoEvent(
                code: 'playback_visual_reset_on_stopped',
                message:
                    'native playback stopped; cleared stale Flutter visual frame state',
                metadata: <String, dynamic>{
                  'viewId': _viewId ?? -1,
                  'videoId': _telemetryVideoId ?? '',
                  'url': _currentUrl ?? '',
                  'hadRenderedFirstFrame': _hasRenderedFirstFrame,
                  'hadVisibleVideoFrame': _hasVisibleVideoFrame,
                  'positionMs': (_currentPosition * 1000).round(),
                },
              );
            }
            if (_hasRenderedFirstFrame) {
              _hasRenderedFirstFrame = false;
              _emitFirstFrame(false);
            }
            if (_hasVisibleVideoFrame) {
              _hasVisibleVideoFrame = false;
              _emitVisibleVideoFrame(false);
            }
            if (_state == PlayerState.completed || _isAtPlaybackEnd) {
              _updateState(PlayerState.completed);
            } else {
              _updateState(PlayerState.idle);
            }
            break;

          case 'error':
            final message = event['message'] as String? ??
                'error_handling.category_unknown'.tr;
            final errorCodeName =
                (event['errorCodeName'] as String? ?? '').toUpperCase();
            final shouldFastFallbackToCdn = _fallbackUrl != null &&
                !_fallbackAttempted &&
                (_currentUrl?.startsWith('http://127.0.0.1:') ?? false) &&
                errorCodeName.contains('BAD_HTTP_STATUS');
            if (_telemetryVideoId != null) {
              _telemetry.onError(_telemetryVideoId!, message);
            }
            if (shouldFastFallbackToCdn) {
              _fallbackAttempted = true;
              unawaited(
                loadVideo(
                  _fallbackUrl!,
                  autoPlay: true,
                  loop: _isLooping,
                  preferResumePoster: _preferResumePoster,
                  debugSource: 'controller.fastFallbackToCdn',
                ),
              );
              break;
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
      loadVideo(
        _fallbackUrl!,
        debugSource: 'controller.handleErrorFallback',
      );
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
    final effectiveSeekSeconds =
        defaultTargetPlatform == TargetPlatform.android &&
                seekSeconds != null &&
                seekSeconds <= _androidMinMeaningfulReattachSeekSeconds
            ? null
            : seekSeconds;
    final hasStableVisualResume =
        _hasRenderedFirstFrame && currentPosition > 0.05;
    final seekAlreadyApplied = effectiveSeekSeconds != null &&
        effectiveSeekSeconds > 0.05 &&
        (currentPosition - effectiveSeekSeconds).abs() <= 0.18;
    final restorePayload = <String, dynamic>{
      'viewId': _viewId ?? -1,
      'videoId': _telemetryVideoId ?? '',
      'url': _currentUrl ?? '',
      'seekSeconds': seekSeconds ?? -1,
      'effectiveSeekSeconds': effectiveSeekSeconds ?? -1,
      'resumePlay': resumePlay,
      'shouldRestoreFromReattach': shouldRestoreFromReattach,
      'currentPositionMs': (currentPosition * 1000).round(),
      'hasStableVisualResume': hasStableVisualResume,
      'seekAlreadyApplied': seekAlreadyApplied,
      'state': _state.name,
      'firstFrame': _hasRenderedFirstFrame,
      'visibleFrame': _hasVisibleVideoFrame,
      'awaitingFresh': _awaitingFreshFrameAfterReattach,
    };
    if (kDebugMode && !_suppressHlsSmokeLogs) {
      debugPrint(
        '[HLSController][view=$_viewId][video=${_telemetryVideoId ?? '-'}] '
        'reattachRestoreDecision payload=$restorePayload',
      );
    }
    recordQALabVideoEvent(
      code: 'reattach_restore_decision',
      message: 'reattach playback restore decision',
      metadata: restorePayload,
    );
    if (!shouldRestoreFromReattach) {
      if (resumePlay) {
        try {
          await play();
        } catch (_) {}
      }
      return;
    }
    if (!resumePlay && hasStableVisualResume && seekAlreadyApplied) {
      return;
    }
    if (effectiveSeekSeconds != null &&
        effectiveSeekSeconds > 0.05 &&
        !seekAlreadyApplied) {
      try {
        await seekTo(effectiveSeekSeconds);
      } catch (_) {}
    }
    if (!resumePlay) return;
    if (_state == PlayerState.playing || _state == PlayerState.buffering) {
      return;
    }
    try {
      await play();
    } catch (_) {}
  }
}
