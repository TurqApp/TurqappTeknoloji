part of 'post_content_base.dart';

extension PostContentBasePlaybackPart<T extends PostContentBase>
    on PostContentBaseState<T> {
  void _applyPreferredBufferDurationProfile({
    required String source,
  }) {
    final adapter = _videoAdapter;
    if (adapter == null) return;
    final preferredSeconds = _preferredBufferDurationSecondsForCurrentSurface;
    if (preferredSeconds == null) return;
    _recordPlaybackDispatch(
      'feed_card_buffer_profile_apply',
      source: source,
      dispatchIssued: false,
      metadata: <String, dynamic>{
        'preferredBufferSeconds': preferredSeconds,
        'shouldPlay': widget.shouldPlay,
      },
    );
    unawaited(adapter.setPreferredBufferDuration(preferredSeconds));
  }

  Duration _normalizeFeedResumePosition(Duration savedPosition) {
    final cushion = PlaybackSurfacePolicy.feedResumePositionCushion(
      platform: defaultTargetPlatform,
      isFeedStyleSurface: _usesFeedPlaybackPolicy,
    );
    if (cushion <= Duration.zero) {
      return savedPosition;
    }
    if (savedPosition <= cushion) return Duration.zero;
    return savedPosition - cushion;
  }

  void _syncLiveResumePositionSample(HLSVideoValue value) {
    if (!_usesFeedPlaybackPolicy) return;
    if (!widget.shouldPlay || !_isSurfacePlaybackAllowed) return;
    if (!value.isInitialized || value.isCompleted) return;
    final remaining = value.duration > Duration.zero
        ? value.duration - value.position
        : Duration.zero;
    final isReplayResetWindow = _isReplayOverlayEnabled &&
        (_replayRestartPendingZero ||
            _autoplayReplayInFlight ||
            _replayOverlayLatched ||
            _replayAdVisible ||
            (remaining > Duration.zero &&
                remaining <= const Duration(milliseconds: 500)));
    if (isReplayResetWindow) {
      _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
      debugPrint(
        '[FeedReplayTrace] stage=skip_resume_sample_replay_reset '
        'doc=${widget.model.docID} '
        'positionMs=${value.position.inMilliseconds} '
        'durationMs=${value.duration.inMilliseconds} '
        'pendingZero=$_replayRestartPendingZero '
        'adVisible=$_replayAdVisible '
        'overlayLatched=$_replayOverlayLatched',
      );
      return;
    }
    if (value.position <= PostContentBaseState._stableFramePositionThreshold) {
      return;
    }
    final lastPosition = _lastResumePositionSample;
    if (lastPosition != null &&
        (value.position - lastPosition).inMilliseconds.abs() < 120) {
      return;
    }
    final now = DateTime.now();
    final lastSampleAt = _lastResumePositionSampleAt;
    if (lastSampleAt != null &&
        now.difference(lastSampleAt) <
            PostContentBaseState._resumePositionSampleInterval) {
      return;
    }

    _lastResumePositionSample = value.position;
    _lastResumePositionSampleAt = now;
    _playbackRuntimeService.updatePlaybackPosition(
      playbackHandleKey,
      value.position,
    );
    _rememberFeedResumeActiveDoc();

    final lastLogged = _lastLoggedResumePositionSample;
    final shouldLog = lastLogged == null ||
        (value.position - lastLogged).inMilliseconds.abs() >= 1000;
    if (shouldLog) {
      _lastLoggedResumePositionSample = value.position;
      debugPrint(
        '[FeedPlaybackProof] stage=resume_position_sample '
        'doc=${widget.model.docID} key=$playbackHandleKey '
        'positionMs=${value.position.inMilliseconds} '
        'playing=${value.isPlaying} buffering=${value.isBuffering} '
        'firstFrame=${value.hasRenderedFirstFrame} '
        'visibleFrame=${value.hasVisibleVideoFrame} '
        'shouldPlay=${widget.shouldPlay}',
      );
    }
  }

  void _armSavedResumeRecoveryGuard() {
    _savedResumeRecoveryGuardUntil =
        DateTime.now().add(const Duration(milliseconds: 4200));
  }

  bool get _hasActiveSavedResumeRecoveryGuard {
    final until = _savedResumeRecoveryGuardUntil;
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _savedResumeRecoveryGuardUntil = null;
      return false;
    }
    return true;
  }

  Duration _resolveSavedResumePosition(HLSVideoAdapter adapter) {
    final savedState =
        _playbackRuntimeService.getSavedPlaybackState(playbackHandleKey);
    final savedPosition = savedState?.position ?? Duration.zero;
    if (savedPosition > Duration.zero) {
      return savedPosition;
    }
    if (PlaybackSurfacePolicy.shouldZeroSavedResumePositionFallback(
      platform: defaultTargetPlatform,
      isFeedStyleSurface: _usesFeedPlaybackPolicy,
    )) {
      return Duration.zero;
    }
    final adapterPosition = adapter.value.position;
    if (adapterPosition > PostContentBaseState._stableFramePositionThreshold) {
      return adapterPosition;
    }
    return Duration.zero;
  }

  bool _restoreSavedResumeSeekIfEligible(
    HLSVideoAdapter adapter, {
    required String source,
  }) {
    final shouldUsePlatformResumeSeek =
        PlaybackSurfacePolicy.supportsFeedSavedResumeSeek(
      platform: defaultTargetPlatform,
      isFeedStyleSurface: _usesFeedPlaybackPolicy,
    );
    if (!shouldUsePlatformResumeSeek) return false;
    if (!_controllerOwnsInlinePlayback) return false;
    final resetNonRetainedFeedResume =
        _resetDistantBehindFeedResumeStateIfNeeded(
      adapter.value,
      source: source,
    );
    if (resetNonRetainedFeedResume &&
        widget.shouldPlay &&
        _isSurfacePlaybackAllowed) {
      _distantBehindResumeWasReset = false;
      adapter.queueSeekAndPlay(Duration.zero);
      _lastQueuedSavedResumePosition = Duration.zero;
      _lastQueuedSavedResumeAt = DateTime.now();
      _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
      _recordPlaybackDispatch(
        'feed_card_restore_saved_seek_reset_zero',
        source: source,
        dispatchIssued: false,
        metadata: <String, dynamic>{
          'previousPositionMs': adapter.value.position.inMilliseconds,
          'reason': 'non_retained_feed_resume_reset',
        },
      );
      return true;
    }
    if (adapter.value.isInitialized && adapter.value.position > Duration.zero) {
      if (_distantBehindResumeWasReset &&
          widget.shouldPlay &&
          _isSurfacePlaybackAllowed) {
        _distantBehindResumeWasReset = false;
        adapter.queueSeekAndPlay(Duration.zero);
        _lastQueuedSavedResumePosition = Duration.zero;
        _lastQueuedSavedResumeAt = DateTime.now();
        _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
        _recordPlaybackDispatch(
          'feed_card_restore_saved_seek_reset_zero',
          source: source,
          dispatchIssued: false,
          metadata: <String, dynamic>{
            'previousPositionMs': adapter.value.position.inMilliseconds,
            'reason': 'non_retained_feed_resume_reset',
          },
        );
        return true;
      }
      return false;
    }

    final savedPosition =
        _normalizeFeedResumePosition(_resolveSavedResumePosition(adapter));
    final shouldUseSavedResumeSeek =
        !_shouldBypassSavedResumeHintForPrimaryFeed(
      adapter.value,
      source: source,
    );
    final shouldQueueSavedSeek =
        shouldUseSavedResumeSeek && _shouldQueueSavedResumeSeek(savedPosition);
    if (!shouldQueueSavedSeek) {
      return false;
    }

    adapter.queueSeekAndPlay(savedPosition);
    _lastQueuedSavedResumePosition = savedPosition;
    _lastQueuedSavedResumeAt = DateTime.now();
    _armSavedResumeRecoveryGuard();
    _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
    _recordPlaybackDispatch(
      'feed_card_restore_saved_seek',
      source: source,
      dispatchIssued: false,
      metadata: <String, dynamic>{
        'savedPositionMs': savedPosition.inMilliseconds,
      },
    );
    return true;
  }

  bool _shouldQueueSavedResumeSeek(Duration savedPosition) {
    if (savedPosition <= Duration.zero) return false;
    final lastPosition = _lastQueuedSavedResumePosition;
    final lastQueuedAt = _lastQueuedSavedResumeAt;
    if (lastPosition == null || lastQueuedAt == null) {
      return true;
    }
    final isSamePosition =
        (lastPosition - savedPosition).inMilliseconds.abs() <= 80;
    if (!isSamePosition) {
      return true;
    }
    final elapsed = DateTime.now().difference(lastQueuedAt);
    return elapsed >= PostContentBaseState._androidSavedResumeSeekCooldown;
  }

  bool get _useNativeIosPrimaryFeedRecoveryAuthority =>
      PlaybackSurfacePolicy.useNativeIosFeedRecoveryAuthority(
        platform: defaultTargetPlatform,
        isFeedStyleSurface: _usesFeedPlaybackPolicy,
        useLegacyIosFeedBehavior: _useLegacyIosFeedBehavior,
      );

  bool _shouldThrottleIosPrimaryFeedRecovery({
    required String source,
  }) {
    if (!PlaybackSurfacePolicy.shouldThrottleFeedRecovery(
      platform: defaultTargetPlatform,
      isFeedStyleSurface: _usesFeedPlaybackPolicy,
    )) {
      return false;
    }
    final lastRecoveryAt = _lastIosPrimaryFeedRecoveryAt;
    if (lastRecoveryAt == null) return false;
    final elapsed = DateTime.now().difference(lastRecoveryAt);
    final cooldown = PlaybackSurfacePolicy.feedRecoveryCooldown(
      platform: defaultTargetPlatform,
      defaultDuration: PostContentBaseState._iosPrimaryFeedRecoveryCooldown,
    );
    if (elapsed >= cooldown) {
      return false;
    }
    final remaining = cooldown - elapsed;
    _recordPlaybackDispatch(
      'feed_card_recover_skipped',
      source: source,
      dispatchIssued: false,
      skipReason: 'ios_recover_cooldown',
      metadata: <String, dynamic>{
        'remainingMs': remaining.inMilliseconds,
      },
    );
    return true;
  }

  void _markIosPrimaryFeedRecoveryAttempt() {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!_usesFeedPlaybackPolicy) return;
    _lastIosPrimaryFeedRecoveryAt = DateTime.now();
  }

  bool get _canBootstrapPrimaryFeedOwnershipClaim {
    if (!_usesFeedPlaybackPolicy) return false;
    if (!widget.shouldPlay) return false;
    if (!_isSurfacePlaybackAllowed) return false;
    final modelIndex = _surfaceModelIndex();
    if (modelIndex < 0) return false;
    final centeredIndex = _surfaceCurrentCenteredIndex();
    if (centeredIndex == modelIndex) return true;
    return _shouldPreserveIosPrimaryFeedPlaybackForResumeTransition;
  }

  bool _shouldRecoverFrozenFeedPlayback(HLSVideoValue value) {
    return PlaybackSurfacePolicy.shouldRecoverFrozenFeedPlayback(
      platform: defaultTargetPlatform,
      isFeedStyleSurface: _usesFeedPlaybackPolicy,
      shouldPlay: widget.shouldPlay,
      surfacePlaybackAllowed: _isSurfacePlaybackAllowed,
      manualPauseRequested: _manualPauseRequested,
      isInitialized: value.isInitialized,
      isPlaying: value.isPlaying,
      isBuffering: value.isBuffering,
      isCompleted: value.isCompleted,
      hasRenderedFirstFrame: value.hasRenderedFirstFrame,
      position: value.position,
    );
  }

  Future<void> _runFeedRecoverOnce({
    required HLSVideoAdapter adapter,
    required String source,
    bool preservePosition = true,
  }) async {
    if (_feedRecoverInFlight) {
      _recordPlaybackDispatch(
        'feed_card_recover_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'recover_in_flight',
      );
      return;
    }
    _feedRecoverInFlight = true;
    try {
      await adapter.recoverFrozenPlayback(
        preservePosition: preservePosition,
      );
    } catch (_) {
      // Feed recovery is best-effort.
    } finally {
      _feedRecoverInFlight = false;
    }
  }

  void _recoverFeedPlaybackIfNeeded({
    required HLSVideoAdapter adapter,
    required String source,
  }) {
    if (_shouldThrottleIosPrimaryFeedRecovery(source: source)) {
      return;
    }
    if (!_shouldRecoverFrozenFeedPlayback(adapter.value)) {
      _markIosPrimaryFeedRecoveryAttempt();
      _startPlaybackWhenReady(source: source);
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        _usesFeedPlaybackPolicy) {
      _markIosPrimaryFeedRecoveryAttempt();
      _startPlaybackWhenReady(source: '$source:ios_reassert');
      return;
    }
    _recordPlaybackDispatch(
      'feed_card_recover_frozen_playback',
      source: source,
      dispatchIssued: false,
      metadata: <String, dynamic>{
        'positionMs': adapter.value.position.inMilliseconds,
        'hasRenderedFirstFrame': adapter.value.hasRenderedFirstFrame,
      },
    );
    unawaited(() async {
      await _runFeedRecoverOnce(
        adapter: adapter,
        source: source,
      );
      if (!mounted || _videoAdapter != adapter) return;
      if (!widget.shouldPlay || !_isSurfacePlaybackAllowed) return;
      _startPlaybackWhenReady(source: '$source:post_recover');
    }());
  }

  Duration get _resolvedAutoplaySegmentGateTimeout {
    return PlaybackSurfacePolicy.feedAutoplayGateTimeout(
      platform: defaultTargetPlatform,
      isFeedStyleSurface: _usesFeedPlaybackPolicy,
    );
  }

  Duration get _resolvedAutoplaySegmentGatePollInterval {
    return PlaybackSurfacePolicy.feedAutoplayGatePollInterval(
      platform: defaultTargetPlatform,
      isFeedStyleSurface: _usesFeedPlaybackPolicy,
    );
  }

  void _resetAutoplaySegmentGate() {
    _autoplaySegmentGateTimer?.cancel();
    _autoplaySegmentGateTimer = null;
    _autoplaySegmentGateStartedAt = null;
    _autoplaySegmentGateTimedOut = false;
  }

  void _cancelFeedStallWatchdog() {
    _stallWatchdogTimer?.cancel();
    _stallWatchdogTimer = null;
    _stallWatchdogRetries = 0;
    _stallWatchdogBufferingCycles = 0;
    _stallWatchdogLastPosition = Duration.zero;
  }

  bool _shouldMonitorFeedStall(HLSVideoValue value) {
    return PlaybackSurfacePolicy.shouldMonitorFeedStall(
      platform: defaultTargetPlatform,
      isFeedStyleSurface: _usesFeedPlaybackPolicy,
      shouldPlay: widget.shouldPlay,
      surfacePlaybackAllowed: _isSurfacePlaybackAllowed,
      manualPauseRequested: _manualPauseRequested,
      isInitialized: value.isInitialized,
      isCompleted: value.isCompleted,
    );
  }

  void _ensureFeedStallWatchdog(HLSVideoAdapter adapter) {
    if (_stallWatchdogTimer != null) return;
    _stallWatchdogRetries = 0;
    _stallWatchdogBufferingCycles = 0;
    _stallWatchdogLastPosition = adapter.value.position;
    _armFeedStallWatchdog(adapter);
  }

  void _armFeedStallWatchdog(HLSVideoAdapter adapter) {
    _stallWatchdogTimer?.cancel();
    _stallWatchdogTimer = Timer(const Duration(milliseconds: 900), () async {
      _stallWatchdogTimer = null;
      if (!mounted || _videoAdapter != adapter || adapter.isDisposed) return;
      if (_hasActiveSavedResumeRecoveryGuard) {
        _armFeedStallWatchdog(adapter);
        return;
      }
      final value = adapter.value;
      if (!_shouldMonitorFeedStall(value)) {
        _cancelFeedStallWatchdog();
        return;
      }
      final progressed = value.position > _stallWatchdogLastPosition;
      final prolongedBuffering = value.isBuffering &&
          value.position >= const Duration(milliseconds: 800) &&
          !progressed;
      if (prolongedBuffering) {
        _stallWatchdogBufferingCycles++;
      } else {
        _stallWatchdogBufferingCycles = 0;
      }
      final bufferingHealthy =
          value.isBuffering && _stallWatchdogBufferingCycles < 2;
      final visuallyPlaying = value.isPlaying && value.hasVisibleVideoFrame;
      final healthy = progressed ||
          bufferingHealthy ||
          visuallyPlaying ||
          value.isCompleted;
      _stallWatchdogLastPosition = value.position;
      final shouldDeferIosInitialFeedRecovery =
          PlaybackSurfacePolicy.shouldDeferInitialFeedStallRecovery(
        platform: defaultTargetPlatform,
        isFeedStyleSurface: _usesFeedPlaybackPolicy,
        hasRenderedFirstFrame: value.hasRenderedFirstFrame,
        position: value.position,
        stallRetryCount: _stallWatchdogRetries,
      );
      if (shouldDeferIosInitialFeedRecovery) {
        _stallWatchdogRetries = 0;
        _armFeedStallWatchdog(adapter);
        return;
      }
      if (healthy) {
        _stallWatchdogRetries = 0;
        _armFeedStallWatchdog(adapter);
        return;
      }
      if (_stallWatchdogRetries >= 2) return;
      _stallWatchdogRetries++;
      try {
        final shouldRecoverFrozenPlayback = !value.isPlaying &&
            !value.isBuffering &&
            value.hasRenderedFirstFrame &&
            !value.isCompleted &&
            (_stallWatchdogRetries > 1 ||
                value.position >= const Duration(milliseconds: 2500) ||
                value.duration > const Duration(seconds: 12));
        _recordPlaybackDispatch(
          'feed_card_stall_recovery',
          source: 'stall_watchdog',
          dispatchIssued: false,
          metadata: <String, dynamic>{
            'retry': _stallWatchdogRetries,
            'bufferingCycles': _stallWatchdogBufferingCycles,
            'positionMs': value.position.inMilliseconds,
            'mode': shouldRecoverFrozenPlayback ? 'recover' : 'play',
          },
        );
        if (_controllerOwnsInlinePlayback &&
            _playbackRuntimeService.currentPlayingDocId != playbackHandleKey) {
          _playbackRuntimeService.playOnlyThis(playbackHandleKey);
        }
        if (shouldRecoverFrozenPlayback) {
          if (defaultTargetPlatform == TargetPlatform.iOS &&
              _usesFeedPlaybackPolicy) {
            _markIosPrimaryFeedRecoveryAttempt();
            if (_stallWatchdogRetries >= 2) {
              _playbackRuntimeService.clearSavedPlaybackState(
                playbackHandleKey,
              );
              await _runFeedRecoverOnce(
                adapter: adapter,
                source: 'stall_watchdog:ios_zero_recover',
                preservePosition: false,
              );
              return;
            }
            _startPlaybackWhenReady(source: 'stall_watchdog:ios_reassert');
            return;
          }
          await _runFeedRecoverOnce(
            adapter: adapter,
            source: 'stall_watchdog',
          );
        } else {
          await _playbackExecutionService.playAdapter(adapter);
        }
      } catch (_) {}
      if (!mounted || _videoAdapter != adapter) return;
      if (!_shouldMonitorFeedStall(adapter.value)) {
        _cancelFeedStallWatchdog();
        return;
      }
      _armFeedStallWatchdog(adapter);
    });
  }

  int get _requiredAutoplaySegmentCount {
    return PlaybackSurfacePolicy.feedRequiredAutoplaySegments(
      platform: defaultTargetPlatform,
      isFeedStyleSurface: _usesFeedPlaybackPolicy,
    );
  }

  bool get _hasReadyAutoplaySegment =>
      cachedSegmentCountForCurrentVideo >= _requiredAutoplaySegmentCount;

  bool _shouldDelayAutoplayForSegments(HLSVideoAdapter adapter) {
    if (!widget.model.hasPlayableVideo) return false;
    if (!widget.shouldPlay) return false;
    if (_usesFeedPlaybackPolicy) return false;
    if (_autoplaySegmentGateTimedOut) return false;
    final value = adapter.value;
    if (PlaybackSurfacePolicy.shouldBypassFeedSegmentDelayWhenInitialized(
          platform: defaultTargetPlatform,
          isFeedStyleSurface: _usesFeedPlaybackPolicy,
        ) &&
        value.isInitialized) {
      return false;
    }
    if (value.position > Duration.zero) return false;
    if (value.isPlaying) return false;
    return !_hasReadyAutoplaySegment;
  }

  void _startPlaybackWhenReady({
    required String source,
  }) {
    if (_manualPauseRequested) {
      _recordPlaybackDispatch(
        'feed_card_start_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'manual_pause_requested',
      );
      return;
    }
    if (!widget.shouldPlay) {
      _recordPlaybackDispatch(
        'feed_card_start_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'should_play_false',
      );
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        _usesFeedPlaybackPolicy) {
      final modelIndex = _surfaceModelIndex();
      final centeredIndex = _surfaceCurrentCenteredIndex();
      if (modelIndex >= 0 &&
          centeredIndex >= 0 &&
          modelIndex != centeredIndex) {
        _recordPlaybackDispatch(
          'feed_card_start_skipped',
          source: source,
          dispatchIssued: false,
          skipReason: 'ios_feed_not_centered',
          metadata: <String, dynamic>{
            'modelIndex': modelIndex,
            'centeredIndex': centeredIndex,
          },
        );
        return;
      }
    }
    final adapter = _videoAdapter;
    if (adapter == null) return;
    if (!_shouldBypassSavedResumeSeekForReplayStart(source)) {
      _restoreSavedResumeSeekIfEligible(adapter, source: '$source:prestart');
    }
    if (_requiredAutoplaySegmentCount > 1) {
      try {
        _segmentCacheRuntimeService.ensureMinimumReadySegments(
          widget.model.docID,
          minimumSegmentCount: _requiredAutoplaySegmentCount,
        );
      } catch (_) {}
    }
    if (!_shouldDelayAutoplayForSegments(adapter)) {
      _resetAutoplaySegmentGate();
      _startPlayback(source: source);
      return;
    }

    _autoplaySegmentGateStartedAt ??= DateTime.now();
    final elapsed = DateTime.now().difference(_autoplaySegmentGateStartedAt!);
    if (elapsed >= _resolvedAutoplaySegmentGateTimeout) {
      _autoplaySegmentGateTimedOut = true;
      _recordPlaybackDispatch(
        'feed_card_segment_gate_timeout',
        source: source,
        dispatchIssued: false,
        skipReason: 'segment_gate_timeout',
        metadata: <String, dynamic>{
          'cachedSegmentCount': cachedSegmentCountForCurrentVideo,
          'requiredSegmentCount': _requiredAutoplaySegmentCount,
        },
      );
      _startPlayback(source: '$source:segment_gate_timeout');
      return;
    }

    if (_autoplaySegmentGateTimer?.isActive ?? false) return;
    _recordPlaybackDispatch(
      'feed_card_segment_gate_wait',
      source: source,
      dispatchIssued: false,
      skipReason: 'waiting_for_first_segment',
      metadata: <String, dynamic>{
        'cachedSegmentCount': cachedSegmentCountForCurrentVideo,
        'requiredSegmentCount': _requiredAutoplaySegmentCount,
      },
    );
    _autoplaySegmentGateTimer = Timer(
      _resolvedAutoplaySegmentGatePollInterval,
      () {
        _autoplaySegmentGateTimer = null;
        if (!mounted || !widget.shouldPlay || _videoAdapter != adapter) return;
        if (_manualPauseRequested) return;
        if (_hasAutoPlayed) return;
        _startPlaybackWhenReady(source: source);
      },
    );
  }

  void _safePauseVideo() {
    final v = _videoAdapter;
    if (v != null) {
      if (defaultTargetPlatform == TargetPlatform.android &&
          _isPrimaryFeedSurfaceInstance) {
        debugPrint(
          '[FeedCdnProbe] signal=flutter_quiet_pause '
          'doc=${widget.model.docID} shouldPlay=${widget.shouldPlay} '
          'surfaceAllowed=$_isSurfacePlaybackAllowed '
          'warmWindow=$_shouldKeepPrimaryFeedSurfaceAliveInWarmWindow '
          'keepRebind=$_shouldKeepAndroidPrimaryFeedSurfaceAliveForRebind '
          'offset=${_feedPlaybackOffsetLabel()} '
          'playing=${v.value.isPlaying} buffering=${v.value.isBuffering} '
          'positionMs=${v.value.position.inMilliseconds} '
          'currentOwner=${_playbackRuntimeService.currentPlayingDocId ?? ''}',
        );
      }
      _playbackRecoveryTimer?.cancel();
      _playbackRecoveryTimer = null;
      _cancelFeedStallWatchdog();
      _feedRecoverInFlight = false;
      _lastAppliedPlaybackVolume = null;
      unawaited(_playbackExecutionService.quietBackgroundAdapter(v));
      _hasAutoPlayed = false;
      _resetAutoplaySegmentGate();
      _playbackIntentTracked = false;
      _syncRuntimeHints(hasStableFocus: false);
    }
  }

  void _resetPlaybackSessionForSurfaceExit(
    HLSVideoAdapter adapter, {
    required String source,
  }) {
    if (_isSurfacePlaybackAllowed) return;
    if (!_usesFeedPlaybackPolicy) return;
    _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
    _lastQueuedSavedResumePosition = null;
    _lastQueuedSavedResumeAt = null;
    _savedResumeRecoveryGuardUntil = null;
    debugPrint(
      '[SurfacePlaybackDecision] action=surface_exit_reset '
      'doc=${widget.model.docID} source=$source '
      'surface=$_qaSurfaceName positionMs=${adapter.value.position.inMilliseconds}',
    );
    unawaited(adapter.seekTo(Duration.zero));
  }

  void _stopPlaybackForSurfaceLoss() {
    final v = _videoAdapter;
    if (v != null) {
      if (_isPlaybackTransferredToSingleShort()) {
        debugPrint(
          '[PlaybackStopTrace] source=surface_loss_skip_transferred '
          'doc=${widget.model.docID} '
          'currentOwner=${_playbackRuntimeService.currentPlayingDocId ?? ''}',
        );
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          _usesFeedPlaybackPolicy) {
        v.suppressNextReattachResume(
          reason: 'ios_feed_surface_loss_stop',
        );
        VideoStateManager.instance.markTransitionResumeReset(
          playbackHandleKey,
          reason: 'ios_feed_surface_loss_stop',
        );
        _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
      }
      if (defaultTargetPlatform == TargetPlatform.android &&
          _isPrimaryFeedSurfaceInstance) {
        debugPrint(
          '[FeedCdnProbe] signal=flutter_stop_surface_loss '
          'doc=${widget.model.docID} shouldPlay=${widget.shouldPlay} '
          'surfaceAllowed=$_isSurfacePlaybackAllowed '
          'warmWindow=$_shouldKeepPrimaryFeedSurfaceAliveInWarmWindow '
          'keepRebind=$_shouldKeepAndroidPrimaryFeedSurfaceAliveForRebind '
          'offset=${_feedPlaybackOffsetLabel()} '
          'playing=${v.value.isPlaying} buffering=${v.value.isBuffering} '
          'positionMs=${v.value.position.inMilliseconds} '
          'currentOwner=${_playbackRuntimeService.currentPlayingDocId ?? ''}',
        );
      }
      debugPrint(
        '[PlaybackStopTrace] source=surface_loss doc=${widget.model.docID} '
        'modelIndex=${_surfaceModelIndex()} '
        'offset=${_feedPlaybackOffsetLabel()}',
      );
      _playbackRecoveryTimer?.cancel();
      _playbackRecoveryTimer = null;
      _cancelFeedStallWatchdog();
      _feedRecoverInFlight = false;
      _lastAppliedPlaybackVolume = null;
      unawaited(_playbackExecutionService.stopAdapter(v));
      _resetPlaybackSessionForSurfaceExit(
        v,
        source: 'stop_playback_for_surface_loss',
      );
      _hasAutoPlayed = false;
      _resetAutoplaySegmentGate();
      _playbackIntentTracked = false;
      _syncRuntimeHints(hasStableFocus: false);
    }
  }

  bool _enforceBlockedSurfacePlaybackStop(
    HLSVideoValue value, {
    required String source,
  }) {
    if (_isSurfacePlaybackAllowed) return false;
    if (!_usesFeedPlaybackPolicy) return false;
    if (!value.isPlaying && !value.isBuffering) return false;
    if (_isPlaybackTransferredToSingleShort()) {
      debugPrint(
        '[SurfacePlaybackDecision] action=surface_block_skip_transferred '
        'doc=${widget.model.docID} source=$source '
        'surface=$_qaSurfaceName '
        'currentOwner=${_playbackRuntimeService.currentPlayingDocId ?? ''}',
      );
      return false;
    }
    debugPrint(
      '[SurfacePlaybackDecision] action=surface_block_session_reset '
      'doc=${widget.model.docID} source=$source '
      'surface=$_qaSurfaceName '
      'shouldPlay=${widget.shouldPlay} '
      'allowed=$_isSurfacePlaybackAllowed '
      'playing=${value.isPlaying} buffering=${value.isBuffering} '
      'positionMs=${value.position.inMilliseconds} '
      'currentOwner=${_playbackRuntimeService.currentPlayingDocId ?? ''}',
    );
    _playbackRuntimeService.requestStop(playbackHandleKey);
    _stopPlaybackForSurfaceLoss();
    return true;
  }

  bool _isPlaybackTransferredToSingleShort() {
    if (!_usesFeedPlaybackPolicy) return false;
    final currentOwner =
        _playbackRuntimeService.currentPlayingDocId?.trim() ?? '';
    if (!currentOwner.startsWith('single_short:')) return false;
    final docId = widget.model.docID.trim();
    if (docId.isEmpty) return false;
    return currentOwner == 'single_short:$docId';
  }

  Future<void> _disposePlaybackForSurfaceLoss({
    bool clearSavedState = false,
  }) async {
    final adapter = _videoAdapter;
    if (adapter == null) return;
    final keepWarmWindowSurface = _usesFeedPlaybackPolicy &&
        _shouldKeepPrimaryFeedSurfaceAliveInWarmWindow;
    final shouldKeepWarmForSurfaceLoss =
        (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS) &&
            _usesFeedPlaybackPolicy &&
            keepWarmWindowSurface &&
            !clearSavedState;
    debugPrint(
      '[FeedSurfaceDecision] stage=dispose_for_surface_loss '
      'doc=${widget.model.docID} clearSavedState=$clearSavedState '
      'shouldKeepWarmForSurfaceLoss=$shouldKeepWarmForSurfaceLoss '
      'keepWarmWindowSurface=$keepWarmWindowSurface '
      'modelIndex=${_surfaceModelIndex()} adapterBound=${_videoAdapter != null}',
    );
    if (shouldKeepWarmForSurfaceLoss) {
      debugPrint(
        '[PlaybackStopTrace] source=surface_loss_keepalive '
        'doc=${widget.model.docID} modelIndex=${_surfaceModelIndex()} '
        'offset=${_feedPlaybackOffsetLabel()}',
      );
      _safePauseVideo();
      if (mounted) {
        _markPostContentDirty();
      }
      return;
    }
    _cancelFeedStallWatchdog();
    _feedRecoverInFlight = false;
    _videoAdapter = null;
    _keepAliveUpdateCallback?.call();
    _lastAppliedPlaybackVolume = null;
    adapter.removeListener(_onVideoUpdate);
    _hasAutoPlayed = false;
    _resetAutoplaySegmentGate();
    _playbackIntentTracked = false;
    _syncRuntimeHints(hasStableFocus: false);
    try {
      _playbackRuntimeService.unregisterPlaybackHandle(playbackHandleKey);
    } catch (_) {}
    try {
      await adapterPool.release(
        adapter,
        keepWarm: shouldKeepWarmForSurfaceLoss,
        clearSavedState: clearSavedState,
      );
    } catch (_) {}
    if (mounted) {
      _markPostContentDirty();
    }
  }

  void pauseVideoManually() {
    _manualPauseRequested = true;
    _safePauseVideo();
  }

  void resumeVideoManually() {
    _manualPauseRequested = false;
    _resumePlaybackIfEligible(source: 'manual_play');
  }

  void pauseVideo() => _safePauseVideo();

  bool _isReplayActivationRestartSource(String source) {
    if (source.contains(':reentry_restart')) return false;
    return source.startsWith('widget_should_play_changed') ||
        source.startsWith('route_did_pop_next');
  }

  bool _shouldRestartReplayFromStartOnActivation({
    required String source,
  }) {
    if (!_isReplayOverlayEnabled) return false;
    if (!_isReplayActivationRestartSource(source)) return false;
    if (_replayButtonVisible) return true;
    return false;
  }

  bool _shouldBypassSavedResumeSeekForReplayStart(String source) {
    return source.startsWith('replay_button') ||
        source.contains(':activation_restart') ||
        source.contains(':activation_start') ||
        source.contains(':reentry_restart');
  }

  bool _isReplayOverlayHoldingPlayback(String source) {
    if (!_isReplayOverlayEnabled) return false;
    if (source.startsWith('replay_button')) return false;
    return _replayOverlayLatched || _replayAdVisible || _replayButtonVisible;
  }

  Future<void> _restartCompletedPlaybackForAutoplay({
    required String source,
  }) async {
    if (_autoplayReplayInFlight) return;
    final adapter = _videoAdapter;
    if (adapter == null) return;
    _autoplayReplayInFlight = true;
    _recordPlaybackDispatch(
      'feed_card_autoplay_replay',
      source: source,
      dispatchIssued: false,
    );
    _replayOverlayLatched = false;
    _replayAdTailChecked = false;
    _replayAdAvailableAtTail = false;
    _replayAdVisible = false;
    _replayButtonVisible = false;
    _replayAdImpressionReceived = false;
    _replayAdHideTimer?.cancel();
    _replayRestartPendingZero = true;
    _manualPauseRequested = false;
    _hasAutoPlayed = false;
    _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
    var zeroed = false;
    try {
      await adapter.setLooping(shouldLoopVideo);
      zeroed = await _seekReplayRestartToZero(
        adapter,
        source: source,
        maxAttempts: 3,
      );
    } catch (_) {
      // Surface may be mid-refresh; autoplay re-entry should fail silently.
    } finally {
      _autoplayReplayInFlight = false;
    }
    if (!mounted || _videoAdapter != adapter) return;
    if (!widget.shouldPlay || !_isSurfacePlaybackAllowed) return;
    if (!zeroed) {
      debugPrint(
        '[FeedReplayTrace] stage=restart_zero_failed_defer_play '
        'doc=${widget.model.docID} source=$source '
        'positionMs=${adapter.value.position.inMilliseconds} '
        'durationMs=${adapter.value.duration.inMilliseconds}',
      );
      return;
    }
    _startPlaybackWhenReady(source: '$source:reentry_restart');
  }

  Future<bool> _seekReplayRestartToZero(
    HLSVideoAdapter adapter, {
    required String source,
    required int maxAttempts,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      await adapter.seekTo(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (!mounted || _videoAdapter != adapter) return false;
      final position = adapter.value.position;
      if (position <= PostContentBaseState._stableFramePositionThreshold) {
        debugPrint(
          '[FeedReplayTrace] stage=restart_zero_seek_confirmed '
          'doc=${widget.model.docID} source=$source '
          'attempt=$attempt positionMs=${position.inMilliseconds} '
          'durationMs=${adapter.value.duration.inMilliseconds}',
        );
        return true;
      }
      debugPrint(
        '[FeedReplayTrace] stage=restart_zero_seek_retry '
        'doc=${widget.model.docID} source=$source '
        'attempt=$attempt positionMs=${position.inMilliseconds} '
        'durationMs=${adapter.value.duration.inMilliseconds}',
      );
    }
    return adapter.value.position <=
        PostContentBaseState._stableFramePositionThreshold;
  }

  double _resolvedPlaybackVolume() {
    final value = _videoAdapter?.value ?? const HLSVideoValue();
    final decision = _playbackLifecycleDecision(value);
    final globalFeedMuted =
        !isStandalonePostInstance && agendaController.isMuted.value;
    if (globalFeedMuted) {
      if (kDebugMode && _lastAppliedPlaybackVolume != 0.0) {
        debugPrint(
          '[FeedMute] action=resolve_force_mute key=$playbackHandleKey '
          'doc=${widget.model.docID} shouldPlay=${widget.shouldPlay} '
          'surfaceAllowed=$_isSurfacePlaybackAllowed '
          'lifecycleAudible=${decision.shouldBeAudible}',
        );
      }
      return 0.0;
    }
    if (decision.shouldBeAudible) {
      return 1.0;
    }
    final shouldHoldIosPrimaryFeedAudibility =
        PlaybackSurfacePolicy.shouldHoldFeedAudibilityOnOwnerCandidate(
      platform: defaultTargetPlatform,
      isFeedStyleSurface: _usesFeedPlaybackPolicy,
      shouldPlay: widget.shouldPlay,
      surfacePlaybackAllowed: _isSurfacePlaybackAllowed,
      isOwnerCandidate: decision.isOwnerCandidate,
      hasRenderedFirstFrame: value.hasRenderedFirstFrame,
      position: value.position,
      isCompleted: value.isCompleted,
    );
    return shouldHoldIosPrimaryFeedAudibility ? 1.0 : 0.0;
  }

  void _applyPlaybackVolume() {
    final volume = _resolvedPlaybackVolume();
    if (_lastAppliedPlaybackVolume == volume) {
      _syncRuntimeHints(isAudible: volume > 0.0);
      return;
    }
    _lastAppliedPlaybackVolume = volume;
    final adapter = _videoAdapter;
    if (adapter != null) {
      _playbackExecutionService.applyPresentation(
        adapter,
        shouldBeAudible: volume > 0.0,
      );
    }
    if (kDebugMode) {
      debugPrint(
        '[FeedMute] action=card_apply key=$playbackHandleKey '
        'doc=${widget.model.docID} globalMuted='
        '${!isStandalonePostInstance && agendaController.isMuted.value} '
        'volume=$volume shouldPlay=${widget.shouldPlay} '
        'surfaceAllowed=$_isSurfacePlaybackAllowed',
      );
    }
    _syncRuntimeHints(isAudible: volume > 0.0);
  }

  void _resumePlaybackIfEligible({
    String source = 'resume_unspecified',
  }) {
    if (_manualPauseRequested) {
      _recordPlaybackDispatch(
        'feed_card_resume_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'manual_pause_requested',
      );
      return;
    }
    if (!widget.model.hasPlayableVideo) {
      _recordPlaybackDispatch(
        'feed_card_resume_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'no_playable_video',
      );
      return;
    }
    if (!widget.shouldPlay) {
      _recordPlaybackDispatch(
        'feed_card_resume_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'should_play_false',
      );
      return;
    }
    if (!_isSurfacePlaybackAllowed) {
      _recordPlaybackDispatch(
        'feed_card_resume_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'surface_playback_blocked',
      );
      return;
    }

    final adapter = _videoAdapter;
    if (adapter == null) {
      final shouldHoldReplayOverlay = _isReplayOverlayHoldingPlayback(source);
      if (shouldHoldReplayOverlay) {
        _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
      }
      _recordPlaybackDispatch(
        'feed_card_init_requested',
        source: source,
        dispatchIssued: false,
        skipReason: 'adapter_missing',
      );
      _initVideoController();
      final initializedAdapter = _videoAdapter;
      if (initializedAdapter != null && !shouldHoldReplayOverlay) {
        _restoreSavedResumeSeekIfEligible(
          initializedAdapter,
          source: '$source:init_requested',
        );
      }
      return;
    }

    if (_isReplayOverlayHoldingPlayback(source)) {
      _recordPlaybackDispatch(
        'feed_card_resume_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'replay_overlay_waiting_for_user',
        metadata: <String, dynamic>{
          'positionMs': adapter.value.position.inMilliseconds,
          'replayButton': _replayButtonVisible,
          'adVisible': _replayAdVisible,
        },
      );
      _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
      return;
    }

    if (_shouldRestartReplayFromStartOnActivation(source: source)) {
      debugPrint(
        '[FeedReplayTrace] stage=activation_restart_from_zero '
        'doc=${widget.model.docID} '
        'source=$source '
        'isCompleted=${adapter.value.isCompleted} '
        'positionMs=${adapter.value.position.inMilliseconds} '
        'durationMs=${adapter.value.duration.inMilliseconds} '
        'replayOverlayLatched=$_replayOverlayLatched',
      );
      unawaited(
        _restartCompletedPlaybackForAutoplay(
          source: '$source:activation_restart',
        ),
      );
      return;
    }

    if (_shouldAutorestartCompletedPlayback && adapter.value.isCompleted) {
      debugPrint(
        '[FeedReplayTrace] stage=completed_resume '
        'doc=${widget.model.docID} '
        'source=$source '
        'isCompleted=${adapter.value.isCompleted} '
        'positionMs=${adapter.value.position.inMilliseconds} '
        'durationMs=${adapter.value.duration.inMilliseconds} '
        'replayOverlayLatched=$_replayOverlayLatched',
      );
      unawaited(
        _restartCompletedPlaybackForAutoplay(
          source: '$source:completed_resume',
        ),
      );
      return;
    }

    _applyPlaybackVolume();
    _applyPreferredBufferDurationProfile(source: source);
    final shouldRestartStoppedInlineOwner = _controllerOwnsInlinePlayback &&
        adapter.isStopped &&
        PlaybackSurfacePolicy.shouldRestartStoppedInlineFeedOwner(
          platform: defaultTargetPlatform,
          isFeedStyleSurface: _usesFeedPlaybackPolicy,
        );
    if (shouldRestartStoppedInlineOwner) {
      _recordPlaybackDispatch(
        'feed_card_resume_stopped_restart',
        source: source,
        dispatchIssued: false,
        metadata: <String, dynamic>{
          'currentPlayingDocId':
              _playbackRuntimeService.currentPlayingDocId ?? '',
        },
      );
      _startPlaybackWhenReady(source: '$source:resume_stopped_restart');
      return;
    }
    if (adapter.value.isInitialized) {
      _recordPlaybackDispatch(
        'feed_card_resume_initialized',
        source: source,
        dispatchIssued: false,
        metadata: <String, dynamic>{
          'positionMs': adapter.value.position.inMilliseconds,
        },
      );
      if (_useNativeIosPrimaryFeedRecoveryAuthority) {
        _startPlaybackWhenReady(source: '$source:resume_initialized');
      } else {
        _recoverFeedPlaybackIfNeeded(
          adapter: adapter,
          source: '$source:resume_initialized',
        );
      }
      return;
    }

    if (_useLegacyIosFeedBehavior) {
      _recordPlaybackDispatch(
        'feed_card_legacy_wait_for_init',
        source: source,
        dispatchIssued: false,
        skipReason: 'awaiting_init',
      );
      unawaited(adapter.setLooping(shouldLoopVideo));
      return;
    }

    if (_controllerOwnsInlinePlayback) {
      _recordPlaybackDispatch(
        'feed_card_wait_for_init_controller_owned',
        source: source,
        dispatchIssued: false,
        metadata: <String, dynamic>{
          'currentPlayingDocId':
              _playbackRuntimeService.currentPlayingDocId ?? '',
        },
      );
    }
    _recordPlaybackDispatch(
      'feed_card_wait_for_init',
      source: source,
      dispatchIssued: false,
      skipReason: 'adapter_uninitialized',
    );
    unawaited(adapter.setLooping(shouldLoopVideo));
  }

  void _startPlayback({
    String source = 'start_unspecified',
  }) {
    if (_manualPauseRequested) {
      _recordPlaybackDispatch(
        'feed_card_start_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'manual_pause_requested',
      );
      return;
    }
    _resetAutoplaySegmentGate();
    final adapter = _videoAdapter;
    if (adapter == null) {
      _recordPlaybackDispatch(
        'feed_card_start_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'adapter_missing',
      );
      return;
    }
    if (!_isSurfacePlaybackAllowed) {
      _recordPlaybackDispatch(
        'feed_card_start_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'surface_playback_blocked',
      );
      return;
    }
    if (!widget.shouldPlay) {
      _recordPlaybackDispatch(
        'feed_card_start_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'should_play_false',
      );
      return;
    }
    if (_isReplayOverlayHoldingPlayback(source)) {
      _recordPlaybackDispatch(
        'feed_card_start_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'replay_overlay_waiting_for_user',
        metadata: <String, dynamic>{
          'positionMs': adapter.value.position.inMilliseconds,
          'replayButton': _replayButtonVisible,
          'adVisible': _replayAdVisible,
        },
      );
      _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
      return;
    }
    if (_shouldRestartReplayFromStartOnActivation(source: source)) {
      debugPrint(
        '[FeedReplayTrace] stage=activation_start_from_zero '
        'doc=${widget.model.docID} '
        'source=$source '
        'isCompleted=${adapter.value.isCompleted} '
        'positionMs=${adapter.value.position.inMilliseconds} '
        'durationMs=${adapter.value.duration.inMilliseconds} '
        'replayOverlayLatched=$_replayOverlayLatched',
      );
      unawaited(
        _restartCompletedPlaybackForAutoplay(
          source: '$source:activation_start',
        ),
      );
      return;
    }
    if (_shouldAutorestartCompletedPlayback && adapter.value.isCompleted) {
      debugPrint(
        '[FeedReplayTrace] stage=completed_start '
        'doc=${widget.model.docID} '
        'source=$source '
        'isCompleted=${adapter.value.isCompleted} '
        'positionMs=${adapter.value.position.inMilliseconds} '
        'durationMs=${adapter.value.duration.inMilliseconds} '
        'replayOverlayLatched=$_replayOverlayLatched',
      );
      unawaited(
        _restartCompletedPlaybackForAutoplay(
          source: '$source:completed_start',
        ),
      );
      return;
    }
    _recordPlaybackDispatch(
      'feed_card_start_playback',
      source: source,
      dispatchIssued: false,
      metadata: <String, dynamic>{
        'positionMs': adapter.value.position.inMilliseconds,
      },
    );
    if (_usesFeedPlaybackPolicy) {
      debugPrint(
        '[FeedPlayWindow] event=play doc=${widget.model.docID} '
        'offset=${_feedPlaybackOffsetLabel()} modelIndex=${_surfaceModelIndex()} '
        'centered=${_surfaceSafeCenteredIndex()} source=$source '
        'positionMs=${adapter.value.position.inMilliseconds}',
      );
    }
    if (_isFloodSurfaceInstance) {
      debugPrint(
        '[FloodSeries] status=start_playback doc=${widget.model.docID} source=$source positionMs=${adapter.value.position.inMilliseconds}',
      );
    }
    unawaited(adapter.setLooping(shouldLoopVideo));
    if (_controllerOwnsInlinePlayback) {
      final currentOwner =
          _playbackRuntimeService.currentPlayingDocId == playbackHandleKey;
      final shouldForceAndroidFeedResumeReassert =
          PlaybackSurfacePolicy.shouldReassertStoppedFeedOwner(
        platform: defaultTargetPlatform,
        isFeedStyleSurface: _usesFeedPlaybackPolicy,
        currentOwner: currentOwner,
        position: adapter.value.position,
        isCompleted: adapter.value.isCompleted,
        stableFrameThreshold:
            PostContentBaseState._stableFramePositionThreshold,
      );
      if (shouldForceAndroidFeedResumeReassert) {
        final resumePosition = adapter.value.position;
        _recordPlaybackDispatch(
          'feed_card_resume_reassert_position',
          source: source,
          dispatchIssued: false,
          metadata: <String, dynamic>{
            'positionMs': resumePosition.inMilliseconds,
          },
        );
        unawaited(adapter.seekTo(resumePosition));
        _hasAutoPlayed = true;
        unawaited(_playbackExecutionService.playAdapter(adapter));
        _applyPlaybackVolume();
        _applyPreferredBufferDurationProfile(source: source);
        _syncRuntimeHints(
          isAudible: _resolvedPlaybackVolume() > 0.0,
          hasStableFocus: true,
        );
        _trackPlaybackIntent();
        try {
          _segmentCacheRuntimeService.markPlaying(widget.model.docID);
          _segmentCacheRuntimeService.markServedInFeed(widget.model.docID);
        } catch (_) {}
        return;
      }
      _playbackRuntimeService.registerPlaybackHandle(
        playbackHandleKey,
        HLSAdapterPlaybackHandle(adapter),
      );
      final resumedByManager = _playbackRuntimeService
          .resumeCurrentPlaybackIfReady(playbackHandleKey);
      if (_usesFeedPlaybackPolicy) {
        debugPrint(
          '[FeedPlaybackProof] stage=controller_resume_result '
          'doc=${widget.model.docID} source=$source '
          'resumedByManager=$resumedByManager '
          'currentOwner=${_playbackRuntimeService.currentPlayingDocId ?? ''} '
          'shouldPlay=${widget.shouldPlay} '
          'initialized=${adapter.value.isInitialized} '
          'playing=${adapter.value.isPlaying} '
          'buffering=${adapter.value.isBuffering} '
          'firstFrame=${adapter.value.hasRenderedFirstFrame} '
          'positionMs=${adapter.value.position.inMilliseconds} '
          'durationMs=${adapter.value.duration.inMilliseconds}',
        );
      }
      if (!resumedByManager) {
        final currentOwnerAfterResume =
            _playbackRuntimeService.currentPlayingDocId?.trim() ?? '';
        final pendingClaimAfterResume =
            _playbackRuntimeService.hasPendingPlayFor(playbackHandleKey);
        final shouldClaimFeedOwnerMismatch =
            defaultTargetPlatform == TargetPlatform.iOS &&
                _usesFeedPlaybackPolicy &&
                widget.shouldPlay &&
                _isSurfacePlaybackAllowed &&
                _isFeedStylePlaybackHandleKey(currentOwnerAfterResume) &&
                currentOwnerAfterResume != playbackHandleKey;
        if (shouldClaimFeedOwnerMismatch) {
          debugPrint(
            '[FeedPlaybackProof] stage=owner_mismatch_reclaim '
            'doc=${widget.model.docID} source=$source '
            'from=$currentOwnerAfterResume to=$playbackHandleKey '
            'playing=${adapter.value.isPlaying} '
            'buffering=${adapter.value.isBuffering} '
            'firstFrame=${adapter.value.hasRenderedFirstFrame} '
            'positionMs=${adapter.value.position.inMilliseconds}',
          );
          _recordPlaybackDispatch(
            'feed_card_owner_mismatch_reclaim',
            source: source,
            metadata: <String, dynamic>{
              'from': currentOwnerAfterResume,
              'to': playbackHandleKey,
              'positionMs': adapter.value.position.inMilliseconds,
              'playing': adapter.value.isPlaying,
              'buffering': adapter.value.isBuffering,
              'firstFrame': adapter.value.hasRenderedFirstFrame,
            },
          );
          _hasAutoPlayed = true;
          _playbackRuntimeService.playOnlyThis(playbackHandleKey);
          _applyPlaybackVolume();
          _applyPreferredBufferDurationProfile(source: source);
          _syncRuntimeHints(
            isAudible: _resolvedPlaybackVolume() > 0.0,
            hasStableFocus: true,
          );
          _trackPlaybackIntent();
          try {
            _segmentCacheRuntimeService.markPlaying(widget.model.docID);
            _segmentCacheRuntimeService.markServedInFeed(widget.model.docID);
          } catch (_) {}
          return;
        }
        final shouldBootstrapInitialFeedClaim =
            _canBootstrapPrimaryFeedOwnershipClaim &&
                !pendingClaimAfterResume &&
                currentOwnerAfterResume.isEmpty;
        if (shouldBootstrapInitialFeedClaim) {
          if (defaultTargetPlatform == TargetPlatform.iOS &&
              _usesFeedPlaybackPolicy) {
            debugPrint(
              '[FeedColdStartTrace] stage=bootstrap_claim '
              'doc=${widget.model.docID} '
              'source=$source currentOwner=$currentOwnerAfterResume '
              'pendingClaim=$pendingClaimAfterResume '
              'shouldPlay=${widget.shouldPlay} '
              'surfaceAllowed=$_isSurfacePlaybackAllowed '
              'adapterInit=${adapter.value.isInitialized} '
              'adapterPlaying=${adapter.value.isPlaying}',
            );
          }
          _recordPlaybackDispatch(
            'feed_card_manager_bootstrap_claim',
            source: source,
            dispatchIssued: false,
          );
          if (PlaybackSurfacePolicy.shouldUseDirectFeedBootstrapClaim(
            platform: defaultTargetPlatform,
            isFeedStyleSurface: _usesFeedPlaybackPolicy,
          )) {
            _hasAutoPlayed = true;
            if (!adapter.value.isPlaying) {
              debugPrint(
                '[FeedColdStartTrace] stage=direct_play '
                'doc=${widget.model.docID} source=$source '
                'positionMs=${adapter.value.position.inMilliseconds}',
              );
              unawaited(_playbackExecutionService.playAdapter(adapter));
            }
            _playbackRuntimeService.playOnlyThis(playbackHandleKey);
          } else {
            _playbackRuntimeService.requestPlay(
              playbackHandleKey,
              HLSAdapterPlaybackHandle(adapter),
            );
          }
          _applyPlaybackVolume();
          _applyPreferredBufferDurationProfile(source: source);
          _syncRuntimeHints(
            isAudible: _resolvedPlaybackVolume() > 0.0,
            hasStableFocus: false,
          );
          return;
        }
        final shouldRestartStoppedOwner =
            PlaybackSurfacePolicy.shouldRestartStoppedInlineFeedOwner(
                  platform: defaultTargetPlatform,
                  isFeedStyleSurface: _usesFeedPlaybackPolicy,
                ) &&
                currentOwner &&
                (adapter.isStopped ||
                    (!adapter.value.isInitialized &&
                        adapter.hlsController.canRestartStoppedPlayback));
        if (shouldRestartStoppedOwner) {
          final resetNonRetainedFeedResume =
              _resetDistantBehindFeedResumeStateIfNeeded(
            adapter.value,
            source: source,
          );
          final resetFeedResume =
              _distantBehindResumeWasReset || resetNonRetainedFeedResume;
          if (resetFeedResume) {
            _distantBehindResumeWasReset = false;
            adapter.queueSeekAndPlay(Duration.zero);
            _lastQueuedSavedResumePosition = Duration.zero;
            _lastQueuedSavedResumeAt = DateTime.now();
            _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
            _recordPlaybackDispatch(
              'feed_card_adapter_restart_reset_zero',
              source: source,
              metadata: <String, dynamic>{
                'reason': 'non_retained_feed_resume_reset',
              },
            );
          }
          final savedPosition = resetFeedResume
              ? Duration.zero
              : _normalizeFeedResumePosition(
                  _resolveSavedResumePosition(adapter),
                );
          final shouldUseSavedResumeSeek = !resetFeedResume &&
              !_shouldBypassSavedResumeHintForPrimaryFeed(
                adapter.value,
                source: source,
              );
          final shouldQueueSavedSeek = shouldUseSavedResumeSeek &&
              _shouldQueueSavedResumeSeek(savedPosition);
          if (shouldQueueSavedSeek) {
            adapter.queueSeekAndPlay(savedPosition);
            _lastQueuedSavedResumePosition = savedPosition;
            _lastQueuedSavedResumeAt = DateTime.now();
            _armSavedResumeRecoveryGuard();
            _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
          }
          _recordPlaybackDispatch(
            'feed_card_adapter_restart_stopped',
            source: source,
            metadata: <String, dynamic>{
              'savedPositionMs': savedPosition.inMilliseconds,
              'usedSavedResumeSeek': shouldQueueSavedSeek,
              'savedResumeSeekSuppressed':
                  shouldUseSavedResumeSeek && !shouldQueueSavedSeek,
            },
          );
          _hasAutoPlayed = true;
          unawaited(_playbackExecutionService.playAdapter(adapter));
          _applyPlaybackVolume();
          _applyPreferredBufferDurationProfile(source: source);
          _syncRuntimeHints(
            isAudible: _resolvedPlaybackVolume() > 0.0,
            hasStableFocus: false,
          );
          _trackPlaybackIntent();
          try {
            _segmentCacheRuntimeService.markPlaying(widget.model.docID);
            _segmentCacheRuntimeService.markServedInFeed(widget.model.docID);
          } catch (_) {}
          return;
        }
        _recordPlaybackDispatch(
          'feed_card_manager_wait',
          source: source,
          dispatchIssued: false,
          skipReason: currentOwner
              ? 'manager_not_ready'
              : (pendingClaimAfterResume
                  ? 'manager_pending_handoff'
                  : 'waiting_for_feed_controller_handoff'),
          metadata: <String, dynamic>{
            'currentOwner': currentOwner,
            'pendingClaim': pendingClaimAfterResume,
            'runtimeCurrentOwner': currentOwnerAfterResume,
          },
        );
        _applyPlaybackVolume();
        _applyPreferredBufferDurationProfile(source: source);
        _syncRuntimeHints(
          isAudible: _resolvedPlaybackVolume() > 0.0,
          hasStableFocus: false,
        );
        return;
      } else {
        _recordPlaybackDispatch(
          'feed_card_manager_resume_current',
          source: source,
          dispatchIssued: false,
        );
      }
      _applyPlaybackVolume();
      _applyPreferredBufferDurationProfile(source: source);
      _hasAutoPlayed = true;
      _syncRuntimeHints(
        isAudible: _resolvedPlaybackVolume() > 0.0,
        hasStableFocus: true,
      );
      Future.delayed(const Duration(milliseconds: 70), () {
        if (!mounted || !widget.shouldPlay || _videoAdapter != adapter) return;
        if (!_isSurfacePlaybackAllowed) return;
        _applyPlaybackVolume();
      });
      _trackPlaybackIntent();
      try {
        _segmentCacheRuntimeService.markPlaying(widget.model.docID);
        _segmentCacheRuntimeService.markServedInFeed(widget.model.docID);
      } catch (_) {}
      return;
    }
    _hasAutoPlayed = true;
    final managerPendingPlay = _playbackRuntimeService.hasPendingPlayFor(
      playbackHandleKey,
    );
    final shouldReassertFeedAdapterPlay = _usesFeedPlaybackPolicy &&
        widget.shouldPlay &&
        _isSurfacePlaybackAllowed;
    if (!adapter.value.isPlaying || shouldReassertFeedAdapterPlay) {
      if (managerPendingPlay) {
        _recordPlaybackDispatch(
          'feed_card_adapter_play_skipped',
          source: source,
          dispatchIssued: false,
          skipReason: 'manager_pending_play',
        );
      } else {
        _recordPlaybackDispatch(
          adapter.value.isPlaying
              ? 'feed_card_adapter_reassert_play'
              : 'feed_card_adapter_play',
          source: source,
        );
        unawaited(_playbackExecutionService.playAdapter(adapter));
      }
    } else {
      _recordPlaybackDispatch(
        'feed_card_adapter_play_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'already_playing',
      );
    }
    if (isStandalonePostInstance) {
      _recordPlaybackDispatch(
        'feed_card_exclusive_play_only_this',
        source: source,
      );
      _playbackRuntimeService.playOnlyThis(playbackHandleKey);
    } else if (_playbackRuntimeService.currentPlayingDocId !=
        playbackHandleKey) {
      _recordPlaybackDispatch(
        'feed_card_video_state_request',
        source: source,
      );
      _playbackRuntimeService.requestPlay(
        playbackHandleKey,
        HLSAdapterPlaybackHandle(adapter),
      );
    } else {
      _recordPlaybackDispatch(
        'feed_card_video_state_request_skipped',
        source: source,
        dispatchIssued: false,
        skipReason: 'already_current_playing',
      );
    }
    _applyPlaybackVolume();
    _applyPreferredBufferDurationProfile(source: source);
    _syncRuntimeHints(
      isAudible: _resolvedPlaybackVolume() > 0.0,
      hasStableFocus: true,
    );
    Future.delayed(const Duration(milliseconds: 70), () {
      if (!mounted || !widget.shouldPlay || _videoAdapter != adapter) return;
      if (!_isSurfacePlaybackAllowed) return;
      _applyPlaybackVolume();
    });
    _trackPlaybackIntent();
    try {
      _segmentCacheRuntimeService.markPlaying(widget.model.docID);
      _segmentCacheRuntimeService.markServedInFeed(widget.model.docID);
    } catch (_) {}
  }

  void markSkipNextPause() {
    _skipNextPause = true;
  }

  void setPauseBlocked(bool value) {
    _blockPause = value;
    if (!value) {
      _skipNextPause = false;
    }
  }

  void tryAutoPlayWhenBuffered() {
    if (_videoAdapter != null) {
      if (_useNativeIosPrimaryFeedRecoveryAuthority) {
        _recordPlaybackDispatch(
          'feed_card_buffer_ready_skipped',
          source: 'buffer_ready',
          dispatchIssued: false,
          skipReason: 'ios_native_recovery_authority',
        );
        return;
      }
      _recordPlaybackDispatch(
        'feed_card_buffer_ready_play',
        source: 'buffer_ready',
      );
      _startPlaybackWhenReady(source: 'buffer_ready');
    }
  }

  Future<void> replayVideoFromStart() async {
    final adapter = _videoAdapter;
    if (adapter == null) return;
    _recordPlaybackDispatch(
      'feed_card_replay_from_start',
      source: 'replay_button',
      dispatchIssued: false,
    );
    debugPrint(
      '[FeedReplayTrace] stage=manual_replay_start '
      'doc=${widget.model.docID}',
    );
    _replayOverlayLatched = false;
    _replayAdTailChecked = false;
    _replayAdAvailableAtTail = false;
    _replayRestartPendingZero = false;
    _replayAdVisible = false;
    _replayButtonVisible = false;
    _replayAdImpressionReceived = false;
    _replayAdHideTimer?.cancel();
    _manualPauseRequested = false;
    _hasAutoPlayed = false;
    _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
    await adapter.setLooping(shouldLoopVideo);
    await adapter.seekTo(Duration.zero);
    _startPlaybackWhenReady(source: 'replay_button');
  }

  void _onReplayAdImpression() {
    if (_replayAdImpressionReceived) return;
    _replayAdImpressionReceived = true;
  }

  Widget buildFeedReplayOverlay(HLSVideoValue value) {
    if (!_isReplayOverlayEnabled) return const SizedBox.shrink();
    final showAdPanel = _replayAdVisible;
    if (!_replayOverlayLatched || !showAdPanel) {
      return const SizedBox.shrink();
    }
    const headerClearance = 72.0;
    return Positioned.fill(
      child: Column(
        children: [
          const SizedBox(height: headerClearance),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showAdPanel)
                          Container(
                            width: 300,
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: AdmobKare(
                              showChrome: false,
                              onImpression: _onReplayAdImpression,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
