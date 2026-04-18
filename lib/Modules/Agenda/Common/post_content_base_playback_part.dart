part of 'post_content_base.dart';

extension PostContentBasePlaybackPart<T extends PostContentBase>
    on PostContentBaseState<T> {
  Duration _resolveSavedResumePosition(HLSVideoAdapter adapter) {
    final savedState =
        VideoStateManager.instance.getVideoState(playbackHandleKey);
    final savedPosition = savedState?.position ?? Duration.zero;
    if (savedPosition > Duration.zero) {
      return savedPosition;
    }
    final adapterPosition = adapter.value.position;
    if (adapterPosition > Duration.zero) {
      return adapterPosition;
    }
    return Duration.zero;
  }

  bool _restoreSavedResumeSeekIfEligible(
    HLSVideoAdapter adapter, {
    required String source,
  }) {
    if (!GetPlatform.isAndroid) return false;
    if (!_controllerOwnsInlinePlayback) return false;
    if (adapter.value.isInitialized && adapter.value.position > Duration.zero) {
      return false;
    }

    final savedPosition = _resolveSavedResumePosition(adapter);
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
    VideoStateManager.instance.clearVideoState(playbackHandleKey);
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
      defaultTargetPlatform == TargetPlatform.iOS &&
      _isPrimaryFeedSurfaceInstance &&
      !_useLegacyIosFeedBehavior;

  bool _shouldThrottleIosPrimaryFeedRecovery({
    required String source,
  }) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    if (!_isPrimaryFeedSurfaceInstance) return false;
    final lastRecoveryAt = _lastIosPrimaryFeedRecoveryAt;
    if (lastRecoveryAt == null) return false;
    final elapsed = DateTime.now().difference(lastRecoveryAt);
    if (elapsed >= PostContentBaseState._iosPrimaryFeedRecoveryCooldown) {
      return false;
    }
    final remaining =
        PostContentBaseState._iosPrimaryFeedRecoveryCooldown - elapsed;
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
    if (!_isPrimaryFeedSurfaceInstance) return;
    _lastIosPrimaryFeedRecoveryAt = DateTime.now();
  }

  bool get _canBootstrapPrimaryFeedOwnershipClaim {
    if (!_isPrimaryFeedSurfaceInstance) return false;
    if (!widget.shouldPlay) return false;
    if (!_isSurfacePlaybackAllowed) return false;
    final modelIndex = _surfaceModelIndex();
    if (modelIndex < 0) return false;
    final centeredIndex = _surfaceCurrentCenteredIndex();
    if (centeredIndex == modelIndex) return true;
    return _shouldPreserveIosPrimaryFeedPlaybackForResumeTransition;
  }

  bool _shouldRecoverFrozenFeedPlayback(HLSVideoValue value) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    if (!_isPrimaryFeedSurfaceInstance) return false;
    if (!widget.shouldPlay) return false;
    if (!_isSurfacePlaybackAllowed) return false;
    if (_manualPauseRequested) return false;
    if (!value.isInitialized) return false;
    if (value.isPlaying || value.isBuffering || value.isCompleted) return false;
    return value.hasRenderedFirstFrame ||
        value.position >= const Duration(milliseconds: 800);
  }

  Future<void> _runFeedRecoverOnce({
    required HLSVideoAdapter adapter,
    required String source,
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
      await adapter.recoverFrozenPlayback();
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
        _isPrimaryFeedSurfaceInstance) {
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
    if (defaultTargetPlatform == TargetPlatform.android &&
        _isPrimaryFeedSurfaceInstance &&
        _requiredAutoplaySegmentCount > 1) {
      return const Duration(milliseconds: 900);
    }
    return PostContentBaseState._autoplaySegmentGateTimeout;
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
    if (!_isPrimaryFeedSurfaceInstance) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) return false;
    if (defaultTargetPlatform == TargetPlatform.android) return false;
    if (!widget.shouldPlay) return false;
    if (!_isSurfacePlaybackAllowed) return false;
    if (_manualPauseRequested) return false;
    if (!value.isInitialized) return false;
    if (value.isCompleted) return false;
    return true;
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
      final healthy = progressed || bufferingHealthy || value.isCompleted;
      _stallWatchdogLastPosition = value.position;
      if (healthy) {
        _stallWatchdogRetries = 0;
        _armFeedStallWatchdog(adapter);
        return;
      }
      if (_stallWatchdogRetries >= 2) return;
      _stallWatchdogRetries++;
      try {
        final shouldRecoverFrozenPlayback = value.hasRenderedFirstFrame &&
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
    if (defaultTargetPlatform == TargetPlatform.android &&
        _isPrimaryFeedSurfaceInstance) {
      if (shouldEnableStartupRecoveryWatchdog) {
        return 1;
      }
      return SegmentCacheRuntimeService.globalReadySegmentCount;
    }
    return 1;
  }

  bool get _hasReadyAutoplaySegment =>
      cachedSegmentCountForCurrentVideo >= _requiredAutoplaySegmentCount;

  bool _shouldDelayAutoplayForSegments(HLSVideoAdapter adapter) {
    if (!widget.model.hasPlayableVideo) return false;
    if (!widget.shouldPlay) return false;
    if (_autoplaySegmentGateTimedOut) return false;
    final value = adapter.value;
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
    final adapter = _videoAdapter;
    if (adapter == null) return;
    _restoreSavedResumeSeekIfEligible(adapter, source: '$source:prestart');
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
      PostContentBaseState._autoplaySegmentGatePollInterval,
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

  void _stopPlaybackForSurfaceLoss() {
    final v = _videoAdapter;
    if (v != null) {
      debugPrint(
        '[PlaybackStopTrace] source=surface_loss doc=${widget.model.docID} '
        'modelIndex=${_surfaceModelIndex()}',
      );
      _cancelFeedStallWatchdog();
      _feedRecoverInFlight = false;
      _lastAppliedPlaybackVolume = null;
      unawaited(_playbackExecutionService.stopAdapter(v));
      _hasAutoPlayed = false;
      _resetAutoplaySegmentGate();
      _playbackIntentTracked = false;
      _syncRuntimeHints(hasStableFocus: false);
    }
  }

  Future<void> _disposePlaybackForSurfaceLoss({
    bool clearSavedState = false,
  }) async {
    final adapter = _videoAdapter;
    if (adapter == null) return;
    final shouldKeepWarmForSurfaceLoss =
        defaultTargetPlatform == TargetPlatform.android &&
        _isPrimaryFeedSurfaceInstance &&
        !clearSavedState;
    debugPrint(
      '[FeedSurfaceDecision] stage=dispose_for_surface_loss '
      'doc=${widget.model.docID} clearSavedState=$clearSavedState '
      'shouldKeepWarmForSurfaceLoss=$shouldKeepWarmForSurfaceLoss '
      'modelIndex=${_surfaceModelIndex()} adapterBound=${_videoAdapter != null}',
    );
    if (shouldKeepWarmForSurfaceLoss) {
      debugPrint(
        '[PlaybackStopTrace] source=surface_loss_keepalive '
        'doc=${widget.model.docID} modelIndex=${_surfaceModelIndex()}',
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
    _replayAdPrewarmed = false;
    _replayAdVisible = false;
    _replayButtonVisible = false;
    _replayAdImpressionReceived = false;
    _replayAdHideTimer?.cancel();
    _manualPauseRequested = false;
    _hasAutoPlayed = false;
    try {
      await adapter.setLooping(shouldLoopVideo);
      await adapter.seekTo(Duration.zero);
    } catch (_) {
      // Surface may be mid-refresh; autoplay re-entry should fail silently.
    } finally {
      _autoplayReplayInFlight = false;
    }
    if (!mounted || _videoAdapter != adapter) return;
    if (!widget.shouldPlay || !_isSurfacePlaybackAllowed) return;
    _startPlaybackWhenReady(source: '$source:reentry_restart');
  }

  double _resolvedPlaybackVolume() {
    final value = _videoAdapter?.value ?? const HLSVideoValue();
    final decision = _playbackLifecycleDecision(value);
    if (decision.shouldBeAudible) {
      return 1.0;
    }
    final shouldHoldIosPrimaryFeedAudibility =
        defaultTargetPlatform == TargetPlatform.iOS &&
            _isPrimaryFeedSurfaceInstance &&
            widget.shouldPlay &&
            _isSurfacePlaybackAllowed &&
            decision.isOwnerCandidate &&
            value.hasRenderedFirstFrame &&
            value.position > Duration.zero &&
            !value.isCompleted;
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
      _recordPlaybackDispatch(
        'feed_card_init_requested',
        source: source,
        dispatchIssued: false,
        skipReason: 'adapter_missing',
      );
      _initVideoController();
      final initializedAdapter = _videoAdapter;
      if (initializedAdapter != null) {
        _restoreSavedResumeSeekIfEligible(
          initializedAdapter,
          source: '$source:init_requested',
        );
      }
      return;
    }

    if (!shouldLoopVideo && adapter.value.isCompleted) {
      unawaited(
        _restartCompletedPlaybackForAutoplay(
          source: '$source:completed_resume',
        ),
      );
      return;
    }

    _applyPlaybackVolume();
    if (GetPlatform.isAndroid &&
        _controllerOwnsInlinePlayback &&
        adapter.isStopped) {
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
    if (!shouldLoopVideo && adapter.value.isCompleted) {
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
    unawaited(adapter.setLooping(shouldLoopVideo));
    if (_controllerOwnsInlinePlayback) {
      final currentOwner =
          _playbackRuntimeService.currentPlayingDocId == playbackHandleKey;
      final runtimeCurrentOwner =
          _playbackRuntimeService.currentPlayingDocId?.trim() ?? '';
      final pendingClaim = _playbackRuntimeService.hasPendingPlayFor(
        playbackHandleKey,
      );
      final shouldForceAndroidFeedResumeReassert = GetPlatform.isAndroid &&
          _isPrimaryFeedSurfaceInstance &&
          currentOwner &&
          adapter.value.position >=
              PostContentBaseState._stableFramePositionThreshold &&
          !adapter.value.isCompleted;
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
      final resumedByManager = _playbackRuntimeService
          .resumeCurrentPlaybackIfReady(playbackHandleKey);
      if (!resumedByManager) {
        final shouldBootstrapInitialFeedClaim =
            _canBootstrapPrimaryFeedOwnershipClaim &&
                !pendingClaim &&
                runtimeCurrentOwner.isEmpty;
        if (shouldBootstrapInitialFeedClaim) {
          _recordPlaybackDispatch(
            'feed_card_manager_bootstrap_claim',
            source: source,
            dispatchIssued: false,
          );
          _playbackRuntimeService.requestPlay(
            playbackHandleKey,
            HLSAdapterPlaybackHandle(adapter),
          );
          _applyPlaybackVolume();
          _syncRuntimeHints(
            isAudible: _resolvedPlaybackVolume() > 0.0,
            hasStableFocus: false,
          );
          return;
        }
        final shouldRestartStoppedOwner = GetPlatform.isAndroid &&
            currentOwner &&
            (adapter.isStopped ||
                (!adapter.value.isInitialized &&
                    adapter.hlsController.canRestartStoppedPlayback));
        if (shouldRestartStoppedOwner) {
          final savedPosition = _resolveSavedResumePosition(adapter);
          final shouldUseSavedResumeSeek =
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
            VideoStateManager.instance.clearVideoState(playbackHandleKey);
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
              : (pendingClaim
                  ? 'manager_pending_handoff'
                  : 'waiting_for_feed_controller_handoff'),
          metadata: <String, dynamic>{
            'currentOwner': currentOwner,
            'pendingClaim': pendingClaim,
          },
        );
        _applyPlaybackVolume();
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
    if (!adapter.value.isPlaying) {
      if (managerPendingPlay) {
        _recordPlaybackDispatch(
          'feed_card_adapter_play_skipped',
          source: source,
          dispatchIssued: false,
          skipReason: 'manager_pending_play',
        );
      } else {
        _recordPlaybackDispatch(
          'feed_card_adapter_play',
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
    _replayOverlayLatched = false;
    _replayAdPrewarmed = false;
    _replayAdVisible = false;
    _replayButtonVisible = false;
    _replayAdImpressionReceived = false;
    _replayAdHideTimer?.cancel();
    _manualPauseRequested = false;
    _hasAutoPlayed = false;
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
    if (!_replayOverlayLatched && !_replayAdVisible && !_replayButtonVisible) {
      return const SizedBox.shrink();
    }
    final showReplayButton = _replayButtonVisible;
    final showAdPanel = _replayAdVisible;
    const headerClearance = 72.0;
    final replayButton = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => unawaited(replayVideoFromStart()),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 17,
        ),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(34),
        ),
        child: const Text(
          'Tekrar izle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'MontserratSemiBold',
            height: 1.0,
          ),
        ),
      ),
    );
    return Positioned.fill(
      child: Column(
        children: [
          const SizedBox(height: headerClearance),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: showReplayButton && !showAdPanel
                  ? () => unawaited(replayVideoFromStart())
                  : () {},
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
                        if (showAdPanel && showReplayButton)
                          const SizedBox(height: 16),
                        if (showReplayButton) replayButton,
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
