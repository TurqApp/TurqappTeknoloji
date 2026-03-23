part of 'post_content_base.dart';

extension PostContentBaseLifecyclePart<T extends PostContentBase>
    on PostContentBaseState<T> {
  void _handleLifecycleInit() {
    controller = PostContentController.ensure(
      tag: controllerTag,
      create: widget.createController,
    );

    if (widget.showArchivePost) {
      controller.arsiv.value = false;
    }

    if (widget.model.hasPlayableVideo && widget.shouldPlay) {
      final delay = isStandalonePostInstance
          ? Duration.zero
          : const Duration(milliseconds: 150);
      _lazyInitTimer = Timer(delay, () {
        if (!mounted) return;
        if (widget.shouldPlay && _isSurfacePlaybackAllowed) {
          _initVideoController();
          if (isStandalonePostInstance) {
            Future.delayed(const Duration(milliseconds: 220), () {
              if (!mounted || _videoAdapter == null || !widget.shouldPlay) {
                return;
              }
              _videoAdapter!.setVolume(1.0);
              _videoAdapter!.play();
              videoStateManager.playOnlyThis(playbackHandleKey);
              Future.delayed(const Duration(milliseconds: 220), () {
                if (!mounted || _videoAdapter == null || !widget.shouldPlay) {
                  return;
                }
                _videoAdapter!.setVolume(1.0);
              });
            });
          }
        }
      });
    }

    if (widget.showComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          controller.showPostCommentsBottomSheet();
          _videoAdapter?.setLooping(false);
        });
      });
    }

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

    _lazyInitTimer?.cancel();
    _playbackRecoveryTimer?.cancel();
    _replayAdHideTimer?.cancel();
    _videoAdapter?.removeListener(_onVideoUpdate);
    if (isStandalonePostInstance) {
      videoStateManager.exitExclusiveMode();
    }
    videoStateManager.unregisterVideoController(playbackHandleKey);
    final adapter = _videoAdapter;
    if (adapter != null) {
      unawaited(adapterPool.release(adapter));
    }
    _muteWorker?.dispose();
    _pauseAllWorker?.dispose();
    _playbackSuspendedWorker?.dispose();
    _navSelectionWorker?.dispose();
    videoValueNotifier.dispose();
  }

  void _handleDidUpdateWidget(T oldWidget) {
    if (oldWidget.shouldPlay != widget.shouldPlay) {
      if (widget.shouldPlay) {
        _lazyInitTimer?.cancel();
        if (_videoAdapter == null && widget.model.hasPlayableVideo) {
          _initVideoController();
        }
        if (isStandalonePostInstance) {
          videoStateManager.enterExclusiveMode(playbackHandleKey);
        }
        if (_videoAdapter?.value.isInitialized == true) {
          _startPlayback();
        }
      } else {
        _lazyInitTimer?.cancel();
        if (_blockPause) return;
        if (_skipNextPause) {
          _skipNextPause = false;
          return;
        }
        _safePauseVideo();
      }
    }
  }

  void _handleDidPushNext() {
    if (_blockPause) return;
    if (_skipNextPause) {
      _skipNextPause = false;
      return;
    }
    _safePauseVideo();
  }

  void _handleDidPopNext() {
    if (widget.shouldPlay && _videoAdapter != null) {
      if (isStandalonePostInstance) {
        videoStateManager.enterExclusiveMode(playbackHandleKey);
      }
      if (_videoAdapter!.value.isInitialized) {
        _startPlayback();
      }
    }
  }

  void _handleVideoUpdate() {
    if (!mounted) return;
    final v = _videoAdapter!.value;
    final remaining =
        v.duration > Duration.zero ? v.duration - v.position : null;
    const replayAdWarmupLead = Duration(seconds: 2);
    final replayAdWarmupTarget =
        Theme.of(context).platform == TargetPlatform.iOS ? 4 : 3;

    if (!isStandalonePostInstance &&
        !_replayAdPrewarmed &&
        remaining != null &&
        remaining <= replayAdWarmupLead &&
        remaining > Duration.zero) {
      _replayAdPrewarmed = true;
      unawaited(AdmobKare.warmupPool(targetCount: replayAdWarmupTarget));
    }

    if (v.isCompleted) {
      if (!_replayOverlayLatched) {
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
    } else if (_replayOverlayLatched &&
        (v.isPlaying || v.position == Duration.zero)) {
      _replayOverlayLatched = false;
      _replayAdPrewarmed = false;
      _replayAdVisible = false;
      _replayButtonVisible = false;
      _replayAdImpressionReceived = false;
      _replayAdHideTimer?.cancel();
    }

    if (v.isInitialized && !_hasAutoPlayed) {
      if (widget.shouldPlay && _isSurfacePlaybackAllowed) {
        _startPlayback();
      } else {
        _applyPlaybackVolume();
      }
    }

    final shouldRecoverPlayback = widget.shouldPlay &&
        _isSurfacePlaybackAllowed &&
        v.isInitialized &&
        !v.isPlaying &&
        !v.isBuffering &&
        !v.isCompleted &&
        v.position > Duration.zero;
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
        _startPlayback();
      });
    } else {
      _playbackRecoveryTimer?.cancel();
      _playbackRecoveryTimer = null;
    }

    if (v.isInitialized && v.duration.inMilliseconds > 0) {
      final progress = v.position.inMilliseconds / v.duration.inMilliseconds;
      if (progress > 0) {
        try {
          SegmentCacheManager.maybeFind()
              ?.updateWatchProgress(widget.model.docID, progress);
        } catch (_) {}
      }
    }

    videoValueNotifier.value = v;
  }
}
