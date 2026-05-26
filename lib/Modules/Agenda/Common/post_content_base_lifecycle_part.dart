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
    _feedScrollSettlingWorker ??= ever<bool>(
      agendaController.feedScrollSettlingRx,
      (isSettling) {
        if (isSettling) {
          _maybePreloadWarmVideoController(source: 'feed_scroll_started');
          return;
        }
        _keepAliveUpdateCallback?.call();
        _maybePreloadWarmVideoController(source: 'feed_scroll_settled');
      },
    );

    if (widget.model.hasPlayableVideo && widget.shouldPlay) {
      final prefersImmediateVideoInit =
          isStandalonePostInstance || _isFeedStyleInlineSurfaceInstance;
      final shouldEagerInitFeedFamily = _isFeedStyleInlineSurfaceInstance;
      final delay = isStandalonePostInstance
          ? Duration.zero
          : (prefersImmediateVideoInit
              ? Duration.zero
              : const Duration(milliseconds: 150));
      _lazyInitTimer = Timer(delay, () {
        if (!mounted) return;
        if (widget.shouldPlay && _isSurfacePlaybackAllowed) {
          _initVideoController();
          if (shouldEagerInitFeedFamily) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (!widget.shouldPlay || !_isSurfacePlaybackAllowed) return;
              _startPlaybackWhenReady(
                source: 'init_eager_feed_family',
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
    _feedScrollSettlingWorker?.dispose();
    _releaseWarmPreloadFetchOwnership();
    videoValueNotifier.dispose();
  }

  void _handleDidUpdateWidget(T oldWidget) {
    final didChangeModelDoc = oldWidget.model.docID != widget.model.docID;
    controller.syncModelFromWidget(widget.model);
    if (didChangeModelDoc) {
      _lastImmediateFeedNextWarmDocId = null;
      _releasePlaybackForModelRebind(oldWidget);
    }
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
            _shouldKeepAndroidPrimaryFeedSurfaceAliveForRebind ||
                (defaultTargetPlatform == TargetPlatform.android &&
                    _isPrimaryFeedSurfaceInstance &&
                    _surfaceKeepAliveDebounceActive);
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
          isPrimaryFeedSurface: _usesFeedPlaybackPolicy,
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
          _stopPlaybackForSurfaceLoss();
          return;
        }
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            _usesFeedPlaybackPolicy) {
          debugPrint(
            '[PlaybackStopTrace] source=ios_feed_should_play_false_stop '
            'doc=${widget.model.docID} '
            'positionMs=${_videoAdapter?.value.position.inMilliseconds ?? -1}',
          );
          _stopPlaybackForSurfaceLoss();
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
          isPrimaryFeedSurface: _usesFeedPlaybackPolicy,
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
    } else if (didChangeModelDoc && widget.shouldPlay) {
      _cancelSurfaceKeepAliveDebounce();
      _resetAutoplaySegmentGate();
      _lazyInitTimer?.cancel();
      _recordVisibleViewIfNeeded();
      if (isStandalonePostInstance) {
        _playbackRuntimeService.enterExclusiveMode(playbackHandleKey);
      }
      _resumePlaybackIfEligible(source: 'widget_model_changed_should_play');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.shouldPlay || !_isSurfacePlaybackAllowed) {
          return;
        }
        _resumePlaybackIfEligible(
          source: 'widget_model_changed_post_frame',
        );
        _startPlaybackWhenReady(
          source: 'widget_model_changed_post_frame',
        );
      });
    } else if (widget.shouldPlay &&
        _videoAdapter == null &&
        _isSurfacePlaybackAllowed) {
      _cancelSurfaceKeepAliveDebounce();
      _resetAutoplaySegmentGate();
      _lazyInitTimer?.cancel();
      _recordVisibleViewIfNeeded();
      if (isStandalonePostInstance) {
        _playbackRuntimeService.enterExclusiveMode(playbackHandleKey);
      }
      _resumePlaybackIfEligible(source: 'widget_surface_allowed_after_refresh');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.shouldPlay || !_isSurfacePlaybackAllowed) {
          return;
        }
        _resumePlaybackIfEligible(
          source: 'widget_surface_allowed_after_refresh_post_frame',
        );
        _startPlaybackWhenReady(
          source: 'widget_surface_allowed_after_refresh_post_frame',
        );
      });
    }
    _maybePreloadWarmVideoController(source: 'did_update_widget');
    _syncWarmPreloadFetchOwnership();
    _recordPlaybackVisualWarning(
      _videoAdapter?.value ?? const HLSVideoValue(),
      source: 'did_update_widget_post',
    );
  }

  void _releasePlaybackForModelRebind(T oldWidget) {
    final oldPlaybackHandleKey = _playbackHandleKeyForWidget(oldWidget);
    final newPlaybackHandleKey = playbackHandleKey;
    final adapter = _videoAdapter;
    debugPrint(
      '[FeedPlaybackRebind] status=release_old '
      'oldDoc=${oldWidget.model.docID} newDoc=${widget.model.docID} '
      'oldKey=$oldPlaybackHandleKey newKey=$newPlaybackHandleKey '
      'adapterBound=${adapter != null} shouldPlay=${widget.shouldPlay} '
      'surfaceAllowed=$_isSurfacePlaybackAllowed',
    );
    _lazyInitTimer?.cancel();
    _playbackRecoveryTimer?.cancel();
    _cancelFeedStallWatchdog();
    _autoplaySegmentGateTimer?.cancel();
    _replayAdHideTimer?.cancel();
    _releaseWarmPreloadFetchOwnership();
    _warmPreloadInitQueued = false;
    _feedRecoverInFlight = false;
    _hasAutoPlayed = false;
    _manualPauseRequested = false;
    _lastAppliedPlaybackVolume = null;
    _playbackIntentTracked = false;
    _resetAutoplaySegmentGate();
    _syncRuntimeHints(hasStableFocus: false);
    try {
      _playbackRuntimeService.unregisterPlaybackHandle(oldPlaybackHandleKey);
    } catch (_) {}
    if (adapter != null) {
      _videoAdapter = null;
      adapter.removeListener(_onVideoUpdate);
      unawaited(adapterPool.release(adapter));
    }
    _keepAliveUpdateCallback?.call();
    _markPostContentDirty();
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
    if (!widget.shouldPlay &&
        _isPrimaryFeedSurfaceInstance &&
        agendaController.playbackSuspended.value &&
        agendaController.isPrimaryFeedRouteVisible) {
      final nav = maybeFindNavBarController();
      final canReleaseOverlay = nav == null ||
          (nav.selectedIndex.value == 0 && !nav.mediaOverlayActive);
      debugPrint(
        '[FeedOverlayResume] source=route_did_pop_next '
        'doc=${widget.model.docID} shouldPlay=${widget.shouldPlay} '
        'suspended=${agendaController.playbackSuspended.value} '
        'route=${Get.currentRoute} nav=${nav?.selectedIndex.value ?? -1} '
        'canRelease=$canReleaseOverlay',
      );
      if (canReleaseOverlay) {
        agendaController.resumePlaybackAfterOverlay();
      }
    }
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
    recordPosterOverlayDecision(
      v,
      shouldHidePoster: shouldHidePlaybackPoster(v),
      showStartupPlaceholder: shouldShowStartupPlaybackPlaceholder(v),
      source: 'video_update',
    );
    if (_enforceBlockedSurfacePlaybackStop(v, source: 'video_update')) {
      return;
    }
    if (_enforceOffCenterPrimaryFeedPlaybackStop(v, source: 'video_update')) {
      return;
    }
    _syncLiveResumePositionSample(v);
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        _usesFeedPlaybackPolicy &&
        !widget.shouldPlay &&
        (v.isPlaying || v.isBuffering)) {
      final currentOwner = _playbackRuntimeService.currentPlayingDocId;
      if (currentOwner == playbackHandleKey && _isSurfacePlaybackAllowed) {
        debugPrint(
          '[PlaybackStopTrace] source=ios_feed_inactive_video_update_keep_owner '
          'doc=${widget.model.docID} '
          'playing=${v.isPlaying} buffering=${v.isBuffering} '
          'positionMs=${v.position.inMilliseconds} '
          'currentOwner=${currentOwner ?? ''}',
        );
        _applyPlaybackVolume();
        return;
      }
      debugPrint(
        '[PlaybackStopTrace] source=ios_feed_inactive_video_update_stop '
        'doc=${widget.model.docID} '
        'playing=${v.isPlaying} buffering=${v.isBuffering} '
        'positionMs=${v.position.inMilliseconds} '
        'currentOwner=${currentOwner ?? ''}',
      );
      _playbackRuntimeService.requestStop(playbackHandleKey);
      _stopPlaybackForSurfaceLoss();
      return;
    }
    _primeImmediateNextAfterPlaybackStart(v);
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
    final replayRestartSettlingAtEnd = _replayRestartPendingZero &&
        remaining != null &&
        v.position > PostContentBaseState._stableFramePositionThreshold &&
        remaining <= const Duration(milliseconds: 500);
    if (_replayRestartPendingZero &&
        v.position <= PostContentBaseState._stableFramePositionThreshold) {
      debugPrint(
        '[FeedReplayTrace] stage=restart_zero_confirmed '
        'doc=${widget.model.docID} '
        'positionMs=${v.position.inMilliseconds} '
        'durationMs=${v.duration.inMilliseconds}',
      );
    } else if (replayRestartSettlingAtEnd) {
      debugPrint(
        '[FeedReplayTrace] stage=ignore_stale_end_while_restarting '
        'doc=${widget.model.docID} '
        'positionMs=${v.position.inMilliseconds} '
        'durationMs=${v.duration.inMilliseconds}',
      );
      final adapter = _videoAdapter;
      if (adapter != null && !_replayRestartZeroReassertInFlight) {
        _replayRestartZeroReassertInFlight = true;
        unawaited(() async {
          try {
            final zeroed = await _seekReplayRestartToZero(
              adapter,
              source: 'video_update:stale_end_reassert',
              maxAttempts: 2,
            );
            if (!mounted || _videoAdapter != adapter) return;
            if (!widget.shouldPlay || !_isSurfacePlaybackAllowed) return;
            if (zeroed) {
              _startPlaybackWhenReady(
                source: 'video_update:stale_end_reassert:reentry_restart',
              );
            }
          } finally {
            if (mounted) {
              _replayRestartZeroReassertInFlight = false;
            }
          }
        }());
      }
      return;
    } else if (_replayRestartPendingZero) {
      _replayRestartPendingZero = false;
      debugPrint(
        '[FeedReplayTrace] stage=restart_progress_confirmed '
        'doc=${widget.model.docID} '
        'positionMs=${v.position.inMilliseconds} '
        'durationMs=${v.duration.inMilliseconds}',
      );
    }

    if (_isReplayOverlayEnabled &&
        !replayRestartSettlingAtEnd &&
        !_replayAdTailChecked &&
        remaining != null &&
        remaining <= const Duration(seconds: 1) &&
        remaining > Duration.zero) {
      _replayAdTailChecked = true;
      _replayAdAvailableAtTail = AdmobKare.hasRenderableBanner;
      debugPrint(
        '[FeedReplayTrace] stage=tail_ad_snapshot '
        'doc=${widget.model.docID} '
        'available=$_replayAdAvailableAtTail '
        'positionMs=${v.position.inMilliseconds} '
        'durationMs=${v.duration.inMilliseconds} '
        'remainingMs=${remaining.inMilliseconds}',
      );
    }

    final reachedPlaybackEnd = v.isCompleted ||
        (v.duration > Duration.zero &&
            v.position > Duration.zero &&
            v.duration - v.position <= const Duration(milliseconds: 120));

    if (_isReplayOverlayEnabled &&
        !replayRestartSettlingAtEnd &&
        reachedPlaybackEnd) {
      if (!widget.shouldPlay || !_isSurfacePlaybackAllowed) {
        _playbackRuntimeService.clearSavedPlaybackState(playbackHandleKey);
        _replayOverlayLatched = false;
        _replayAdTailChecked = false;
        _replayAdAvailableAtTail = false;
        _replayAdVisible = false;
        _replayButtonVisible = false;
        _replayAdImpressionReceived = false;
        _replayAdHideTimer?.cancel();
        debugPrint(
          '[FeedReplayTrace] stage=ignore_completed_inactive '
          'doc=${widget.model.docID} '
          'isCompleted=${v.isCompleted} '
          'nearEnd=$reachedPlaybackEnd '
          'isPlaying=${v.isPlaying} '
          'positionMs=${v.position.inMilliseconds} '
          'durationMs=${v.duration.inMilliseconds} '
          'shouldPlay=${widget.shouldPlay} '
          'surfaceAllowed=$_isSurfacePlaybackAllowed',
        );
        return;
      }
      final shouldAutorestartCompletedPlayback = widget.shouldPlay &&
          _isSurfacePlaybackAllowed &&
          !_manualPauseRequested &&
          _shouldAutorestartCompletedPlayback;
      if (shouldAutorestartCompletedPlayback) {
        debugPrint(
          '[FeedReplayTrace] stage=completed_visible_autorestart '
          'doc=${widget.model.docID} '
          'isCompleted=${v.isCompleted} '
          'nearEnd=$reachedPlaybackEnd '
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
          'nearEnd=$reachedPlaybackEnd '
          'isPlaying=${v.isPlaying} '
          'positionMs=${v.position.inMilliseconds} '
          'durationMs=${v.duration.inMilliseconds} '
          'replayOverlayLatched=$_replayOverlayLatched '
          'shouldPlay=${widget.shouldPlay}',
        );
        _replayOverlayLatched = true;
        _replayAdHideTimer?.cancel();
        if (!_replayAdTailChecked) {
          _replayAdTailChecked = true;
          _replayAdAvailableAtTail = AdmobKare.hasRenderableBanner;
          debugPrint(
            '[FeedReplayTrace] stage=tail_ad_snapshot_late '
            'doc=${widget.model.docID} '
            'available=$_replayAdAvailableAtTail '
            'positionMs=${v.position.inMilliseconds} '
            'durationMs=${v.duration.inMilliseconds}',
          );
        }
        _replayAdVisible = _replayAdAvailableAtTail;
        _replayButtonVisible = false;
        if (_replayAdVisible) {
          debugPrint(
            '[FeedReplayTrace] stage=completed_ad_visible '
            'doc=${widget.model.docID} '
            'positionMs=${v.position.inMilliseconds} '
            'durationMs=${v.duration.inMilliseconds} '
            'delayMs=3000',
          );
          VideoStateManager.instance.markTransitionResumeReset(
            playbackHandleKey,
            reason: 'feed_replay_completed_ad_visible',
          );
        } else {
          debugPrint(
            '[FeedReplayTrace] stage=completed_no_ad_autoreplay '
            'doc=${widget.model.docID} '
            'positionMs=${v.position.inMilliseconds} '
            'durationMs=${v.duration.inMilliseconds}',
          );
          unawaited(
            _restartCompletedPlaybackForAutoplay(
              source: 'feed_replay_completed_no_ad',
            ),
          );
        }
        _replayAdImpressionReceived = false;
        if (_replayAdVisible) {
          _replayAdHideTimer = Timer(const Duration(seconds: 3), () {
            if (!mounted) return;
            _replayAdVisible = false;
            _replayButtonVisible = false;
            debugPrint(
              '[FeedReplayTrace] stage=completed_ad_autoreplay_after_delay '
              'doc=${widget.model.docID} delayMs=3000',
            );
            unawaited(
              _restartCompletedPlaybackForAutoplay(
                source: 'feed_replay_completed_ad_after_3s',
              ),
            );
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
      _replayAdTailChecked = false;
      _replayAdAvailableAtTail = false;
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
            _usesFeedPlaybackPolicy &&
            widget.shouldPlay &&
            _isSurfacePlaybackAllowed &&
            _surfaceModelIndex() == _surfaceCurrentCenteredIndex() &&
            (v.isPlaying || v.hasVisibleVideoFrame);
    if (shouldFinalizeIosFeedOwnerOnPlay &&
        _playbackRuntimeService.currentPlayingDocId != playbackHandleKey) {
      _playbackRuntimeService.playOnlyThis(playbackHandleKey);
    }

    final disableDartRecoveryForPlatformPrimaryFeed =
        PlaybackSurfacePolicy.shouldDisableDartRecoveryForPrimaryFeed(
      platform: defaultTargetPlatform,
      isPrimaryFeedSurface: _usesFeedPlaybackPolicy,
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
            _usesFeedPlaybackPolicy) {
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
            _usesFeedPlaybackPolicy) {
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
            maxReadySegments:
                SegmentCacheRuntimeService.globalReadySegmentCount,
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

  void _primeImmediateNextAfterPlaybackStart(HLSVideoValue value) {
    if (!widget.model.hasPlayableVideo) return;
    if (!widget.shouldPlay || !_isSurfacePlaybackAllowed) return;
    if (!value.isPlaying && !value.hasRenderedFirstFrame) return;
    final docId = widget.model.docID.trim();
    if (docId.isEmpty || _lastImmediateFeedNextWarmDocId == docId) return;
    _lastImmediateFeedNextWarmDocId = docId;
    if (_isPrimaryFeedSurfaceInstance) {
      agendaController.primeImmediateNextFeedAfterPlaybackStart(docId);
      return;
    }
    if (_isProfileSurfaceInstance) {
      ProfileController.maybeFind()
          ?.primeImmediateNextProfileAfterPlaybackStart(docId);
      return;
    }
    if (_isSocialProfileSurfaceInstance) {
      _resolveSocialProfileController()
          ?.primeImmediateNextProfileAfterPlaybackStart(docId);
      return;
    }
    _primeImmediateNextFeedFamilyAfterPlaybackStart(docId);
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
