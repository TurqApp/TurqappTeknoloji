part of 'post_content_base.dart';

extension PostContentBaseLifecyclePart<T extends PostContentBase>
    on PostContentBaseState<T> {
  void _handleLifecycleInit() {
    controller = ensurePostContentController(
      tag: controllerTag,
      create: widget.createController,
    );

    if (widget.showArchivePost) {
      controller.arsiv.value = false;
    }

    _keepAliveWindowWorker ??= ever<int>(
      _surfaceCenteredIndexSignal(),
      (_) {
        _keepAliveUpdateCallback?.call();
        _maybePreloadWarmVideoController(source: 'warm_window_changed');
      },
    );
    _warmPreloadAnchorWorker ??= ever<String>(
      agendaController.feedWarmPreloadAnchorKeyRx,
      (_) {
        _keepAliveUpdateCallback?.call();
        _maybePreloadWarmVideoController(source: 'warm_anchor_ready');
      },
    );

    if (widget.model.hasPlayableVideo && widget.shouldPlay) {
      final prefersImmediateVideoInit =
          isStandalonePostInstance || _isFeedStyleInlineSurfaceInstance;
      final shouldEagerInitAndroidPrimaryFeed =
          defaultTargetPlatform == TargetPlatform.android &&
              _isPrimaryFeedSurfaceInstance;
      final shouldEagerInitAndroidProfileFamily =
          defaultTargetPlatform == TargetPlatform.android &&
              (_isProfileSurfaceInstance || _isSocialProfileSurfaceInstance);
      final delay = isStandalonePostInstance
          ? Duration.zero
          : (prefersImmediateVideoInit
              ? (_isFeedStyleInlineSurfaceInstance &&
                      defaultTargetPlatform == TargetPlatform.android &&
                      !shouldEagerInitAndroidPrimaryFeed &&
                      !shouldEagerInitAndroidProfileFamily
                  ? const Duration(milliseconds: 220)
                  : Duration.zero)
              : const Duration(milliseconds: 150));
      _lazyInitTimer = Timer(delay, () {
        if (!mounted) return;
        if (widget.shouldPlay && _isSurfacePlaybackAllowed) {
          _initVideoController();
          if (shouldEagerInitAndroidPrimaryFeed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (!widget.shouldPlay || !_isSurfacePlaybackAllowed) return;
              _startPlaybackWhenReady(
                source: 'init_eager_android_primary_feed',
              );
            });
          }
          if (isStandalonePostInstance) {
            Future.delayed(const Duration(milliseconds: 220), () {
              if (!mounted || _videoAdapter == null || !widget.shouldPlay) {
                return;
              }
              _applyPlaybackVolume();
              _resumePlaybackIfEligible(source: 'standalone_init_delay');
              Future.delayed(const Duration(milliseconds: 220), () {
                if (!mounted || _videoAdapter == null || !widget.shouldPlay) {
                  return;
                }
                _applyPlaybackVolume();
              });
            });
          }
        }
      });
    }

    _maybePreloadWarmVideoController(source: 'init_state');
    _syncWarmPreloadFetchOwnership();

    if (widget.showComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          controller.showPostCommentsBottomSheet();
          _videoAdapter?.setLooping(false);
        });
      });
    }

    _recordPlaybackVisualWarning(
      _videoAdapter?.value ?? const HLSVideoValue(),
      source: 'init',
    );
    _recordVisibleViewIfNeeded();
    onPostInitialized();
  }

  void _handleDidChangeDependencies() {
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  void _handleLifecycleDispose() {
    try {
      final route = ModalRoute.of(context);
      if (route != null) routeObserver.unsubscribe(this);
    } catch (_) {}

    _cancelSurfaceKeepAliveDebounce();
    _lazyInitTimer?.cancel();
    _playbackRecoveryTimer?.cancel();
    _cancelFeedStallWatchdog();
    _autoplaySegmentGateTimer?.cancel();
    _replayAdHideTimer?.cancel();
    _videoAdapter?.removeListener(_onVideoUpdate);
    if (isStandalonePostInstance) {
      _playbackRuntimeService.exitExclusiveMode();
    }
    _playbackRuntimeService.unregisterPlaybackHandle(playbackHandleKey);
    final adapter = _videoAdapter;
    if (adapter != null) {
      unawaited(adapterPool.release(adapter));
    }
    _muteWorker?.dispose();
    _pauseAllWorker?.dispose();
    _playbackSuspendedWorker?.dispose();
    _navSelectionWorker?.dispose();
    _keepAliveWindowWorker?.dispose();
    _warmPreloadAnchorWorker?.dispose();
    _releaseWarmPreloadFetchOwnership();
    videoValueNotifier.dispose();
  }

  void _handleDidUpdateWidget(T oldWidget) {
    _recordPlaybackVisualWarning(
      _videoAdapter?.value ?? const HLSVideoValue(),
      source: 'did_update_widget_pre',
    );
    if (oldWidget.shouldPlay != widget.shouldPlay) {
      if (widget.shouldPlay) {
        _cancelSurfaceKeepAliveDebounce();
        _resetAutoplaySegmentGate();
        _lazyInitTimer?.cancel();
        _recordVisibleViewIfNeeded();
        if (isStandalonePostInstance) {
          _playbackRuntimeService.enterExclusiveMode(playbackHandleKey);
        }
        _resumePlaybackIfEligible(source: 'widget_should_play_changed');
      } else {
        _scheduleSurfaceKeepAliveDebounce();
        _manualPauseRequested = false;
        _resetAutoplaySegmentGate();
        _lazyInitTimer?.cancel();
        final shouldKeepAndroidSurfaceAlive =
            _shouldKeepAndroidPrimaryFeedSurfaceAliveForRebind;
        if (defaultTargetPlatform == TargetPlatform.android &&
            _isPrimaryFeedSurfaceInstance) {
          debugPrint(
            '[FeedSurfaceDecision] stage=did_update_should_play_false '
            'doc=${widget.model.docID} shouldKeepAndroidSurfaceAlive='
            '$shouldKeepAndroidSurfaceAlive '
            'shouldPlay=${widget.shouldPlay} '
            'surfaceAllowed=$_isSurfacePlaybackAllowed '
            'adapterBound=${_videoAdapter != null}',
          );
        }
        final shouldStopRuntimeHandle =
            !PlaybackSurfacePolicy.shouldKeepFeedRuntimeHandleOnPause(
          platform: defaultTargetPlatform,
          isPrimaryFeedSurface: _isPrimaryFeedSurfaceInstance,
          keepAndroidSurfaceAlive: shouldKeepAndroidSurfaceAlive,
        );
        if (shouldStopRuntimeHandle) {
          if (defaultTargetPlatform == TargetPlatform.iOS &&
              _isPrimaryFeedSurfaceInstance) {
            debugPrint(
              '[FeedColdStartTrace] stage=request_stop '
              'doc=${widget.model.docID} shouldPlay=${widget.shouldPlay} '
              'surfaceAllowed=$_isSurfacePlaybackAllowed',
            );
          }
          _playbackRuntimeService.requestStop(playbackHandleKey);
        }
        if (_blockPause) return;
        if (_skipNextPause) {
          _skipNextPause = false;
          return;
        }
        if (shouldKeepAndroidSurfaceAlive) {
          _safePauseVideo();
          return;
        }
        if (_shouldPreserveIosPrimaryFeedPlaybackForResumeTransition) {
          _safePauseVideo();
          return;
        }
        if (_shouldKeepIosPrimaryFeedSurfaceAliveForBackScroll) {
          _safePauseVideo();
          return;
        }
        if (PlaybackSurfacePolicy.shouldDisposeFeedPlaybackForSurfaceLoss(
          platform: defaultTargetPlatform,
          isPrimaryFeedSurface: _isPrimaryFeedSurfaceInstance,
          isFloodSurface: _isFloodSurfaceInstance,
        )) {
          unawaited(
            _disposePlaybackForSurfaceLoss(
              clearSavedState: _isFloodSurfaceInstance,
            ),
          );
          return;
        }
        _safePauseVideo();
      }
    }
    _maybePreloadWarmVideoController(source: 'did_update_widget');
    _syncWarmPreloadFetchOwnership();
    _recordPlaybackVisualWarning(
      _videoAdapter?.value ?? const HLSVideoValue(),
      source: 'did_update_widget_post',
    );
  }

  void _handleDidPushNext() {
    _manualPauseRequested = false;
    if (_blockPause) return;
    if (_skipNextPause) {
      _skipNextPause = false;
      return;
    }
    _recordPlaybackVisualWarning(
      _videoAdapter?.value ?? const HLSVideoValue(),
      source: 'did_push_next',
    );
    if (PlaybackSurfacePolicy.shouldSuspendFeedPlaybackForOverlay(
      platform: defaultTargetPlatform,
      isPrimaryFeedSurface: _isPrimaryFeedSurfaceInstance,
    )) {
      agendaController.suspendPlaybackForOverlay();
      return;
    }
    _safePauseVideo();
  }

  void _handleDidPopNext() {
    if (!widget.shouldPlay) return;
    _recordPlaybackVisualWarning(
      _videoAdapter?.value ?? const HLSVideoValue(),
      source: 'did_pop_next',
    );
    if (isStandalonePostInstance) {
      if (_videoAdapter == null) return;
      _playbackRuntimeService.enterExclusiveMode(playbackHandleKey);
      _resumePlaybackIfEligible(source: 'route_did_pop_next');
      return;
    }
    if (_controllerOwnsInlinePlayback) {
      agendaController.resumeFeedPlayback();
      return;
    }
    if (_videoAdapter != null) {
      _resumePlaybackIfEligible(source: 'route_did_pop_next');
    }
  }

  void _handleVideoUpdate() {
    if (!mounted) return;
    final v = _videoAdapter!.value;
    _recordPlaybackVisualWarning(v);
    if (defaultTargetPlatform == TargetPlatform.android &&
        _isPrimaryFeedSurfaceInstance &&
        widget.shouldPlay &&
        _isSurfacePlaybackAllowed &&
        (v.hasRenderedFirstFrame || v.isInitialized)) {
      agendaController.markFeedWarmPreloadAnchorReady(playbackHandleKey);
    }
    _applyPlaybackVolume();
    final remaining =
        v.duration > Duration.zero ? v.duration - v.position : null;
    const replayAdWarmupLead = Duration(seconds: 2);
    final replayAdWarmupTarget = PlaybackSurfacePolicy.replayAdWarmupTarget(
      platform: defaultTargetPlatform,
      defaultTarget: 3,
    );

    if (_isReplayOverlayEnabled &&
        !_replayAdPrewarmed &&
        remaining != null &&
        remaining <= replayAdWarmupLead &&
        remaining > Duration.zero) {
      _replayAdPrewarmed = true;
      unawaited(AdmobKare.warmupPool(targetCount: replayAdWarmupTarget));
    }

    if (_isReplayOverlayEnabled && v.isCompleted) {
      final shouldAutorestartCompletedPlayback = widget.shouldPlay &&
          _isSurfacePlaybackAllowed &&
          !_manualPauseRequested &&
          _shouldAutorestartCompletedPlayback;
      if (shouldAutorestartCompletedPlayback) {
        debugPrint(
          '[FeedReplayTrace] stage=completed_visible_autorestart '
          'doc=${widget.model.docID} '
          'isCompleted=${v.isCompleted} '
          'isPlaying=${v.isPlaying} '
          'positionMs=${v.position.inMilliseconds} '
          'durationMs=${v.duration.inMilliseconds} '
          'replayOverlayLatched=$_replayOverlayLatched '
          'shouldPlay=${widget.shouldPlay}',
        );
        unawaited(
          _restartCompletedPlaybackForAutoplay(
            source: 'video_update:completed_visible',
          ),
        );
        return;
      }
      if (!_replayOverlayLatched) {
        debugPrint(
          '[FeedReplayTrace] stage=latch_completed '
          'doc=${widget.model.docID} '
          'isCompleted=${v.isCompleted} '
          'isPlaying=${v.isPlaying} '
          'positionMs=${v.position.inMilliseconds} '
          'durationMs=${v.duration.inMilliseconds} '
          'replayOverlayLatched=$_replayOverlayLatched '
          'shouldPlay=${widget.shouldPlay}',
        );
        _replayOverlayLatched = true;
        _replayAdHideTimer?.cancel();
        _replayAdVisible = AdmobKare.hasRenderableBanner;
        _replayButtonVisible = !_replayAdVisible;
        _replayAdImpressionReceived = false;
        if (!isStandalonePostInstance) {
          unawaited(AdmobKare.warmupPool(targetCount: replayAdWarmupTarget));
        }
        if (_replayAdVisible) {
          _replayAdHideTimer = Timer(const Duration(seconds: 3), () {
            if (!mounted) return;
            _replayAdVisible = false;
            _replayButtonVisible = true;
            _markPostContentDirty();
          });
        }
        _markPostContentDirty();
      }
    } else if (_isReplayOverlayEnabled &&
        _replayOverlayLatched &&
        v.isPlaying) {
      debugPrint(
        '[FeedReplayTrace] stage=clear_latch_playing '
        'doc=${widget.model.docID} '
        'isCompleted=${v.isCompleted} '
        'isPlaying=${v.isPlaying} '
        'positionMs=${v.position.inMilliseconds} '
        'durationMs=${v.duration.inMilliseconds} '
        'replayOverlayLatched=$_replayOverlayLatched '
        'shouldPlay=${widget.shouldPlay}',
      );
      _replayOverlayLatched = false;
      _replayAdPrewarmed = false;
      _replayAdVisible = false;
      _replayButtonVisible = false;
      _replayAdImpressionReceived = false;
      _replayAdHideTimer?.cancel();
    }

    if (v.isInitialized && !_hasAutoPlayed) {
      if (widget.shouldPlay && _isSurfacePlaybackAllowed) {
        if (!_manualPauseRequested) {
          _startPlaybackWhenReady(source: 'video_initialized');
        }
      } else {
        _applyPlaybackVolume();
      }
    }

    final shouldFinalizeIosFeedOwnerOnPlay =
        defaultTargetPlatform == TargetPlatform.iOS &&
            _isPrimaryFeedSurfaceInstance &&
            widget.shouldPlay &&
            _isSurfacePlaybackAllowed &&
            (v.isPlaying || v.hasVisibleVideoFrame);
    if (shouldFinalizeIosFeedOwnerOnPlay &&
        _playbackRuntimeService.currentPlayingDocId != playbackHandleKey) {
      _playbackRuntimeService.playOnlyThis(playbackHandleKey);
    }

    final disableDartRecoveryForPlatformPrimaryFeed =
        PlaybackSurfacePolicy.shouldDisableDartRecoveryForPrimaryFeed(
      platform: defaultTargetPlatform,
      isPrimaryFeedSurface: _isPrimaryFeedSurfaceInstance,
    );
    final shouldRecoverPlayback = !disableDartRecoveryForPlatformPrimaryFeed &&
        !_useLegacyIosFeedBehavior &&
        widget.shouldPlay &&
        _isSurfacePlaybackAllowed &&
        !_manualPauseRequested &&
        v.isInitialized &&
        !v.isPlaying &&
        !v.isBuffering &&
        !v.isCompleted &&
        (v.position > Duration.zero || v.hasRenderedFirstFrame);
    if (shouldRecoverPlayback) {
      _playbackRecoveryTimer ??= Timer(const Duration(milliseconds: 260), () {
        _playbackRecoveryTimer = null;
        if (!mounted) return;
        final adapter = _videoAdapter;
        final current = adapter?.value;
        if (adapter == null || current == null) return;
        final stillNeedsRecovery = widget.shouldPlay &&
            _isSurfacePlaybackAllowed &&
            current.isInitialized &&
            !current.isPlaying &&
            !current.isBuffering &&
            !current.isCompleted;
        if (!stillNeedsRecovery) return;
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            _isPrimaryFeedSurfaceInstance) {
          if (_shouldThrottleIosPrimaryFeedRecovery(source: 'recovery_timer')) {
            return;
          }
        }
        if (_shouldRecoverFrozenFeedPlayback(current)) {
          _recoverFeedPlaybackIfNeeded(
            adapter: adapter,
            source: 'recovery_timer',
          );
          return;
        }
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            _isPrimaryFeedSurfaceInstance) {
          _markIosPrimaryFeedRecoveryAttempt();
        }
        _startPlayback(source: 'recovery_timer');
      });
    } else {
      _playbackRecoveryTimer?.cancel();
      _playbackRecoveryTimer = null;
    }

    if (_videoAdapter != null && _shouldMonitorFeedStall(v)) {
      _ensureFeedStallWatchdog(_videoAdapter!);
    } else {
      _cancelFeedStallWatchdog();
    }

    if (v.isInitialized && v.duration.inMilliseconds > 0) {
      final progress = v.position.inMilliseconds / v.duration.inMilliseconds;
      final positionSeconds = v.position.inMilliseconds / 1000.0;
      if (progress > 0) {
        try {
          _segmentCacheRuntimeService.ensureNextSegmentReady(
            widget.model.docID,
            progress,
            positionSeconds: positionSeconds,
          );
        } catch (_) {}
        try {
          _segmentCacheRuntimeService.updateWatchProgress(
            widget.model.docID,
            progress,
          );
        } catch (_) {}
        final currentSegment =
            _segmentCacheRuntimeService.estimateCurrentSegmentForDoc(
          widget.model.docID,
          progress: progress,
          positionSeconds: positionSeconds,
        );
        if (currentSegment != null) {
          if (!_isOwnProfileSurfaceInstance) {
            _segmentCacheRuntimeService.markFeedConsumed(widget.model.docID);
            FeedDiversityMemoryService.ensure().noteWatchedPost(
              widget.model,
              currentSegment: currentSegment,
            );
          }
        }
      }
    }

    if (_shouldSyncVideoNotifier(v)) {
      videoValueNotifier.value = v;
    }
  }

  void _maybePreloadWarmVideoController({
    required String source,
  }) {
    if (_videoAdapter != null) return;
    if (_warmPreloadInitQueued) return;
    if (!_shouldPreloadWarmController) return;
    _claimWarmPreloadFetchOwnership();
    _warmPreloadInitQueued = true;
    _recordPlaybackDispatch(
      'feed_card_warm_preload_init_requested',
      source: source,
      dispatchIssued: false,
      metadata: <String, dynamic>{
        'centeredPlaybackHandleKey': _currentCenteredFeedPlaybackHandleKey(),
        'playableDistance': _surfaceDirectionalAheadPlayableVideoDistance(),
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmPreloadInitQueued = false;
      if (!mounted || _videoAdapter != null) return;
      if (!_shouldPreloadWarmController) {
        _releaseWarmPreloadFetchOwnership();
        return;
      }
      _initVideoController();
      _syncWarmPreloadFetchOwnership();
    });
  }

  void _claimWarmPreloadFetchOwnership() {
    if (_warmPreloadFetchClaimed) return;
    claimExternalOnDemandFetchForDoc(widget.model.docID);
    _warmPreloadFetchClaimed = true;
  }

  void _releaseWarmPreloadFetchOwnership() {
    if (!_warmPreloadFetchClaimed) return;
    releaseExternalOnDemandFetchForDoc(widget.model.docID);
    _warmPreloadFetchClaimed = false;
  }

  void _syncWarmPreloadFetchOwnership() {
    if (_shouldPreloadWarmController) {
      _claimWarmPreloadFetchOwnership();
      return;
    }
    _releaseWarmPreloadFetchOwnership();
  }
}
