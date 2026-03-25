part of 'post_content_base.dart';

extension PostContentBasePlaybackPart<T extends PostContentBase>
    on PostContentBaseState<T> {
  void _safePauseVideo() {
    final v = _videoAdapter;
    if (v != null) {
      v.pause();
      _hasAutoPlayed = false;
      _playbackIntentTracked = false;
      _syncRuntimeHints(hasStableFocus: false);
    }
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
      _startPlayback(source: '$source:resume_initialized');
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
    _hasAutoPlayed = true;
    if (!adapter.value.isPlaying) {
      _recordPlaybackDispatch(
        'feed_card_adapter_play',
        source: source,
      );
      unawaited(adapter.play());
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
      videoStateManager.playOnlyThis(playbackHandleKey);
    } else if (videoStateManager.currentPlayingDocID != playbackHandleKey) {
      _recordPlaybackDispatch(
        'feed_card_video_state_request',
        source: source,
      );
      videoStateManager.requestPlayVideo(
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
      SegmentCacheManager.maybeFind()?.markPlaying(widget.model.docID);
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
      unawaited(_videoAdapter!.setLooping(shouldLoopVideo));
      _videoAdapter!.play();
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
    await adapter.setLooping(shouldLoopVideo);
    await adapter.seekTo(Duration.zero);
    _startPlayback(source: 'replay_button');
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
                                    width: 148,
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Tekrar izle',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontFamily: 'MontserratSemiBold',
                                          height: 1.0,
                                        ),
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
                                width: 148,
                                height: 44,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Tekrar izle',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'MontserratSemiBold',
                                      height: 1.0,
                                    ),
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
