part of 'post_content_base.dart';

extension PostContentBasePlaybackPart<T extends PostContentBase>
    on PostContentBaseState<T> {
  void _resetAutoplaySegmentGate() {
    _autoplaySegmentGateTimer?.cancel();
    _autoplaySegmentGateTimer = null;
    _autoplaySegmentGateStartedAt = null;
    _autoplaySegmentGateTimedOut = false;
  }

  bool get _hasReadyAutoplaySegment => cachedSegmentCountForCurrentVideo >= 1;

  void _boostAutoplaySegments({int readySegments = 2}) {
    try {
      ensurePrefetchScheduler().boostDoc(
        widget.model.docID,
        readySegments: readySegments,
      );
    } catch (_) {}
  }

  bool _shouldDelayAutoplayForSegments(HLSVideoAdapter adapter) {
    if (!widget.model.hasPlayableVideo) return false;
    if (!widget.shouldPlay) return false;
    if (_isPrimaryFeedSurfaceInstance && _qaScrollToken.isEmpty) {
      return false;
    }
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
    _boostAutoplaySegments();
    if (!_shouldDelayAutoplayForSegments(adapter)) {
      _resetAutoplaySegmentGate();
      _startPlayback(source: source);
      return;
    }

    _autoplaySegmentGateStartedAt ??= DateTime.now();
    final elapsed = DateTime.now().difference(_autoplaySegmentGateStartedAt!);
    if (elapsed >= PostContentBaseState._autoplaySegmentGateTimeout) {
      _autoplaySegmentGateTimedOut = true;
      _recordPlaybackDispatch(
        'feed_card_segment_gate_timeout',
        source: source,
        dispatchIssued: false,
        skipReason: 'segment_gate_timeout',
        metadata: <String, dynamic>{
          'cachedSegmentCount': cachedSegmentCountForCurrentVideo,
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
      unawaited(v.forceSilence());
      _hasAutoPlayed = false;
      _resetAutoplaySegmentGate();
      _playbackIntentTracked = false;
      _syncRuntimeHints(hasStableFocus: false);
    }
  }

  void _stopPlaybackForSurfaceLoss() {
    final v = _videoAdapter;
    if (v != null) {
      unawaited(v.silenceAndStopPlayback());
      _hasAutoPlayed = false;
      _resetAutoplaySegmentGate();
      _playbackIntentTracked = false;
      _syncRuntimeHints(hasStableFocus: false);
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

  void _applyPlaybackVolume() {
    _videoAdapter?.setVolume(
      isStandalonePostInstance
          ? 1.0
          : (agendaController.isMuted.value ? 0.0 : 1.0),
    );
    _syncRuntimeHints(isAudible: _currentIsAudible());
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

    _boostAutoplaySegments();
    final adapter = _videoAdapter;
    if (adapter == null) {
      _recordPlaybackDispatch(
        'feed_card_init_requested',
        source: source,
        dispatchIssued: false,
        skipReason: 'adapter_missing',
      );
      _initVideoController();
      return;
    }

    if (!shouldLoopVideo && adapter.value.isCompleted) {
      _recordPlaybackDispatch(
        'feed_card_completion_blocked',
        source: source,
        dispatchIssued: false,
        skipReason: 'completed',
        metadata: <String, dynamic>{
          'positionMs': adapter.value.position.inMilliseconds,
          'durationMs': adapter.value.duration.inMilliseconds,
        },
      );
      return;
    }

    _applyPlaybackVolume();
    if (adapter.value.isInitialized) {
      _recordPlaybackDispatch(
        'feed_card_resume_initialized',
        source: source,
        dispatchIssued: false,
        metadata: <String, dynamic>{
          'positionMs': adapter.value.position.inMilliseconds,
        },
      );
      _startPlaybackWhenReady(source: '$source:resume_initialized');
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

    final controllerOwnedListPlayback = !isStandalonePostInstance &&
        (_qaSurfaceName == 'feed' || _qaSurfaceName == 'profile');
    if (controllerOwnedListPlayback) {
      _recordPlaybackDispatch(
        'feed_card_wait_for_init_pending_play',
        source: source,
        dispatchIssued: false,
        metadata: <String, dynamic>{
          'currentPlayingDocId':
              _playbackRuntimeService.currentPlayingDocId ?? '',
        },
      );
      _playbackRuntimeService.playOnlyThis(playbackHandleKey);
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
      _recordPlaybackDispatch(
        'feed_card_start_blocked_completed',
        source: source,
        dispatchIssued: false,
        skipReason: 'completed',
        metadata: <String, dynamic>{
          'positionMs': adapter.value.position.inMilliseconds,
          'durationMs': adapter.value.duration.inMilliseconds,
        },
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
    _applyPlaybackVolume();
    final controllerOwnedListPlayback = !isStandalonePostInstance &&
        (_qaSurfaceName == 'feed' ||
            _qaSurfaceName == 'profile' ||
            _qaSurfaceName == 'social_profile');
    if (controllerOwnedListPlayback) {
      if (_playbackRuntimeService.currentPlayingDocId != playbackHandleKey) {
        _playbackRuntimeService.playOnlyThis(playbackHandleKey);
      }
      final resumedByManager = _playbackRuntimeService
          .resumeCurrentPlaybackIfReady(playbackHandleKey);
      if (!resumedByManager) {
        _recordPlaybackDispatch(
          'feed_card_start_skipped',
          source: source,
          dispatchIssued: false,
          skipReason:
              _playbackRuntimeService.currentPlayingDocId == playbackHandleKey
                  ? 'manager_not_ready'
                  : 'manager_not_current',
        );
        return;
      }
      _hasAutoPlayed = true;
      _recordPlaybackDispatch(
        'feed_card_manager_resume_current',
        source: source,
        dispatchIssued: false,
      );
      _syncRuntimeHints(
        isAudible: _currentIsAudible(),
        hasStableFocus: true,
      );
      Future.delayed(const Duration(milliseconds: 140), () {
        if (!mounted || !widget.shouldPlay || _videoAdapter != adapter) return;
        if (!_isSurfacePlaybackAllowed) return;
        _applyPlaybackVolume();
      });
      _trackPlaybackIntent();
      try {
        _segmentCacheRuntimeService.markPlaying(widget.model.docID);
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
        unawaited(adapter.play());
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
    _syncRuntimeHints(
      isAudible: _currentIsAudible(),
      hasStableFocus: true,
    );
    Future.delayed(const Duration(milliseconds: 140), () {
      if (!mounted || !widget.shouldPlay || _videoAdapter != adapter) return;
      if (!_isSurfacePlaybackAllowed) return;
      _applyPlaybackVolume();
    });
    _trackPlaybackIntent();
    try {
      _segmentCacheRuntimeService.markPlaying(widget.model.docID);
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
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: showReplayButton ? 0.28 : 0.18),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (showAdPanel) ...[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                              if (showReplayButton) const SizedBox(height: 16),
                              if (showReplayButton)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      unawaited(replayVideoFromStart()),
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
                                ),
                            ],
                          ),
                          ColoredBox(
                            color: Colors.black.withValues(alpha: 0.10),
                          ),
                        ],
                        if (showReplayButton && !showAdPanel)
                          Center(
                            child: GestureDetector(
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
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
