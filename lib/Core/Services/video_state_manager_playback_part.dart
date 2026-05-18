part of 'video_state_manager.dart';

const int _videoStateManagerMaxPendingPlayRetries = 28;

extension VideoStateManagerPlaybackPart on VideoStateManager {
  String? _playbackSurfaceKind(String? key) {
    final trimmed = key?.trim() ?? '';
    if (trimmed.startsWith('short:')) return 'short';
    if (trimmed.startsWith('feed:')) return 'feed';
    if (trimmed.startsWith('social_')) return 'social';
    if (trimmed.startsWith('profile_')) return 'profile';
    return null;
  }

  bool _isAndroidFeedStyleResumeKey(String docID) {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    final trimmed = docID.trim();
    return trimmed.startsWith('feed:') ||
        trimmed.startsWith('social_post_') ||
        trimmed.startsWith('social_reshare_');
  }

  bool _isAndroidFeedResumeRecoverActive(String docID) {
    final key = docID.trim();
    if (key.isEmpty) return false;
    final until = _androidFeedResumeRecoverUntil[key];
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _androidFeedResumeRecoverUntil.remove(key);
    return false;
  }

  void _markAndroidFeedResumeRecover(
    String docID, {
    required int requestSeq,
    required int attempt,
    required Duration position,
  }) {
    if (!_isAndroidFeedStyleResumeKey(docID)) return;
    _androidFeedResumeRecoverUntil[docID.trim()] = DateTime.now().add(
      const Duration(milliseconds: 1800),
    );
    debugPrint(
      '[FeedPlaybackProof] stage=pending_resume_recover_lock '
      'doc=$docID attempt=$attempt requestSeq=$requestSeq '
      'positionMs=${position.inMilliseconds}',
    );
  }

  void _clearAndroidFeedResumeRecover(String docID, String reason) {
    final key = docID.trim();
    if (key.isEmpty) return;
    if (_androidFeedResumeRecoverUntil.remove(key) == null) return;
    debugPrint(
      '[FeedPlaybackProof] stage=pending_resume_recover_unlock '
      'doc=$docID reason=$reason',
    );
  }

  bool _suppressDuplicateAndroidFeedResumeRequest(
    String docID, {
    required String source,
  }) {
    if (!_isAndroidFeedResumeRecoverActive(docID)) return false;
    if (_currentPlayingDocID != docID || _targetPlaybackDocID != docID) {
      return false;
    }
    debugPrint(
      '[FeedPlaybackProof] stage=pending_resume_recover_suppress '
      'source=$source doc=$docID requestSeq=$_playRequestSeq',
    );
    return true;
  }

  String? _activeOtherAndroidFeedResumeKey(String docID) {
    if (!_isAndroidFeedStyleResumeKey(docID)) return null;
    final currentHandle = _allVideoControllers[docID];
    for (final entry in _allVideoControllers.entries) {
      final key = entry.key.trim();
      if (key == docID) continue;
      if (!_isAndroidFeedStyleResumeKey(key)) continue;
      final handle = entry.value;
      if (currentHandle != null &&
          targetsSamePlaybackResource(currentHandle, handle)) {
        continue;
      }
      if (handle is! HLSAdapterPlaybackHandle) continue;
      final value = handle.adapter.value;
      if (value.isPlaying && !value.isCompleted) {
        return key;
      }
    }
    return null;
  }

  bool _shouldStopPlaybackForHiddenHandle(String controllerKey) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    final trimmedKey = controllerKey.trim();
    final isShortHandle = trimmedKey.startsWith('short:');
    final isFeedHandle = trimmedKey.startsWith('feed:');
    final isSocialHandle = trimmedKey.startsWith('social_');
    final isProfileHandle = trimmedKey.startsWith('profile_');
    if (isSocialHandle || isProfileHandle) {
      return true;
    }
    if (!isShortHandle &&
        !isFeedHandle &&
        !isSocialHandle &&
        !isProfileHandle) {
      return true;
    }
    final normalizedDocID = HlsSegmentPolicy.normalizeDocId(trimmedKey);
    if (normalizedDocID == null || normalizedDocID.isEmpty) {
      return true;
    }
    final scheduler = maybeFindPrefetchScheduler();
    final tierInfo = isShortHandle
        ? scheduler?.classifyShortTransferDoc(normalizedDocID)
        : (isSocialHandle || isProfileHandle
            ? scheduler?.classifyTransferDoc(normalizedDocID)
            : scheduler?.classifyFeedTransferDoc(normalizedDocID));
    if (tierInfo == null) {
      return true;
    }
    final allowedSegmentWarm = tierInfo['allowedSegmentWarm'] == true;
    final allowedCacheOnly = tierInfo['allowedCacheOnly'] == true;
    return !(allowedSegmentWarm || allowedCacheOnly);
  }

  bool _shouldKeepExternalOnDemandClaimDuringTargetChange(String docID) {
    final normalizedDocID = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalizedDocID == null || normalizedDocID.isEmpty) {
      return false;
    }
    final scheduler = maybeFindPrefetchScheduler();
    final tierInfo = scheduler?.classifyTransferDoc(normalizedDocID);
    if (tierInfo == null) return false;
    return tierInfo['allowedSegmentWarm'] == true ||
        tierInfo['allowedCacheOnly'] == true;
  }

  bool _shouldKeepWarmHandleDuringExclusiveSwitch(
    String? allowedDocID,
    String controllerKey,
    HLSAdapterPlaybackHandle handle,
  ) {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    final allowedKey = allowedDocID?.trim() ?? '';
    final controllerTrimmed = controllerKey.trim();
    final allowedSurface = _playbackSurfaceKind(allowedKey);
    final controllerSurface = _playbackSurfaceKind(controllerTrimmed);
    if (allowedSurface == null || allowedSurface != controllerSurface) {
      return false;
    }
    if (allowedSurface == 'short') {
      return false;
    }
    if (allowedSurface == 'feed') {
      return false;
    }
    return false;
  }

  void _beginFeedRefreshHandoff({
    required Duration keepWarmFor,
    required String reason,
  }) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    final until = DateTime.now().add(keepWarmFor);
    final previous = _feedRefreshHandoffUntil;
    if (previous == null || previous.isBefore(until)) {
      _feedRefreshHandoffUntil = until;
    }
    debugPrint(
      '[FeedRefreshHandoff] action=begin reason=$reason '
      'keepWarmMs=${keepWarmFor.inMilliseconds} '
      'current=${_currentPlayingDocID ?? ''} target=${_targetPlaybackDocID ?? ''}',
    );
  }

  bool _isFeedRefreshHandoffActive() {
    final until = _feedRefreshHandoffUntil;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _feedRefreshHandoffUntil = null;
    return false;
  }

  bool _shouldMarkIosFeedHiddenHandleReset(HLSAdapterPlaybackHandle handle) {
    final value = handle.adapter.value;
    if (value.isCompleted) return true;
    final duration = value.duration;
    if (duration <= Duration.zero) return false;
    final remaining = duration - value.position;
    return value.position >= const Duration(seconds: 1) &&
        remaining <= const Duration(milliseconds: 700);
  }

  bool _isTransitionResumeResetExpired(String key) {
    final reason = _transitionResumeResetReasons[key] ?? '';
    if (reason.startsWith('feed_replay')) return false;
    final markedAt = _transitionResumeResetMarkedAt[key];
    if (markedAt == null) return false;
    return DateTime.now().difference(markedAt) >
        const Duration(milliseconds: 3500);
  }

  bool _pruneExpiredTransitionResumeReset(String key, String source) {
    if (!_transitionResumeResetKeys.contains(key)) return true;
    if (!_isTransitionResumeResetExpired(key)) return false;
    final reason = _transitionResumeResetReasons[key] ?? '';
    _transitionResumeResetKeys.remove(key);
    _transitionResumeResetMarkedAt.remove(key);
    _transitionResumeResetReasons.remove(key);
    debugPrint(
      '[FeedResumeReset] action=expire key=$key source=$source '
      'reason=$reason',
    );
    return true;
  }

  void _pruneExternalOnDemandFetchClaims(String? activeDocID) {
    final normalizedActiveDocID = HlsSegmentPolicy.normalizeDocId(activeDocID);
    if (normalizedActiveDocID == null || normalizedActiveDocID.isEmpty) {
      if (_externalOnDemandFetchClaims.isEmpty) return;
      _externalOnDemandFetchClaims.clear();
      debugPrint(
        '[PlaybackStopTrace] source=target_change_claim_prune active=- cleared=all',
      );
      return;
    }
    final removed = <String>[];
    _externalOnDemandFetchClaims.removeWhere((docID, _) {
      final shouldRemove = docID != normalizedActiveDocID &&
          !_shouldKeepExternalOnDemandClaimDuringTargetChange(docID);
      if (shouldRemove) removed.add(docID);
      return shouldRemove;
    });
    if (removed.isNotEmpty) {
      debugPrint(
        '[PlaybackStopTrace] source=target_change_claim_prune '
        'active=$normalizedActiveDocID removed=${removed.join(",")}',
      );
    }
  }

  void _markTargetPlaybackDoc(String? docID) {
    _targetPlaybackDocID = docID;
    _targetPlaybackUpdatedAt = docID == null ? null : DateTime.now();
    _pruneExternalOnDemandFetchClaims(docID);
  }

  int _setRegisteredHandleVolume({
    required double volume,
    required bool Function(String key) where,
    required String reason,
  }) {
    final entries = _allVideoControllers.entries
        .where((entry) => where(entry.key.trim()))
        .toList(growable: false);
    for (final entry in entries) {
      unawaited(entry.value.setVolume(volume));
    }
    debugPrint(
      '[FeedMute] action=apply_registered_volume reason=$reason '
      'volume=$volume handles=${entries.length} '
      'current=${_currentPlayingDocID ?? ''}',
    );
    return entries.length;
  }

  void _silenceSupersededHandle(
    String docID,
    PlaybackHandle handle,
  ) {
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        docID.trim().startsWith('feed:')) {
      if (handle is HLSAdapterPlaybackHandle) {
        handle.adapter.suppressNextReattachResume(
          reason: 'ios_feed_superseded_stop',
        );
      }
      if (_currentPlayingDocID == docID || _targetPlaybackDocID == docID) {
        debugPrint(
          '[FeedResumeReset] action=skip_mark '
          'key=$docID reason=ios_feed_superseded_stop '
          'current=${_currentPlayingDocID ?? ''} '
          'target=${_targetPlaybackDocID ?? ''}',
        );
      } else {
        _markTransitionResumeReset(
          docID,
          reason: 'ios_feed_superseded_stop',
        );
      }
    }
    _playbackExecutionService.quietHandle(
      handle,
      persistState: () => _saveVideoState(docID, handle),
      stopPlayback: true,
    );
  }

  void _markTransitionResumeReset(
    String docID, {
    required String reason,
  }) {
    final key = docID.trim();
    if (key.isEmpty) return;
    _transitionResumeResetKeys.add(key);
    _transitionResumeResetMarkedAt[key] = DateTime.now();
    _transitionResumeResetReasons[key] = reason;
    _videoStates.remove(key);
    debugPrint(
      '[FeedResumeReset] action=mark key=$key reason=$reason '
      'current=${_currentPlayingDocID ?? ''} target=${_targetPlaybackDocID ?? ''}',
    );
  }

  bool _hasTransitionResumeReset(String docID) {
    final key = docID.trim();
    if (key.isEmpty) return false;
    if (_pruneExpiredTransitionResumeReset(key, 'has')) return false;
    return _transitionResumeResetKeys.contains(key);
  }

  bool _consumeTransitionResumeReset(
    String docID,
    PlaybackHandle handle, {
    required String source,
  }) {
    final key = docID.trim();
    if (key.isEmpty) return false;
    if (_pruneExpiredTransitionResumeReset(key, source)) return false;
    if (!_transitionResumeResetKeys.remove(key)) return false;
    final reason = _transitionResumeResetReasons.remove(key) ?? '';
    _transitionResumeResetMarkedAt.remove(key);
    _videoStates.remove(key);
    debugPrint(
      '[FeedResumeReset] action=consume key=$key source=$source '
      'reason=$reason positionMs=${handle.position.inMilliseconds} '
      'initialized=${handle.isInitialized}',
    );
    return true;
  }

  bool _shouldPrimeIosFeedResetWithoutBlocking(
    String docID,
    PlaybackHandle handle,
    String reason,
  ) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    if (!docID.trim().startsWith('feed:')) return false;
    if (handle is! HLSAdapterPlaybackHandle) return false;
    return reason == 'ios_feed_surface_loss_stop' ||
        reason == 'ios_feed_hidden_handle_stop';
  }

  void _consumeIosFeedResetWithoutBlocking(
    String docID,
    PlaybackHandle handle, {
    required String source,
    required String reason,
  }) {
    _videoStates.remove(docID);
    debugPrint(
      '[FeedResumeReset] action=consume_without_blocking key=$docID '
      'source=$source reason=$reason positionMs=${handle.position.inMilliseconds} '
      'playing=${handle.isPlaying}',
    );
  }

  Future<void> _seekTransitionResumeResetToZero(
    String docID,
    PlaybackHandle handle, {
    required String source,
  }) async {
    if (!handle.isInitialized) return;
    try {
      final isIosFeedHls = defaultTargetPlatform == TargetPlatform.iOS &&
          docID.trim().startsWith('feed:') &&
          handle is HLSAdapterPlaybackHandle;
      if (isIosFeedHls &&
          handle.position <= const Duration(milliseconds: 100)) {
        _videoStates.remove(docID);
        debugPrint(
          '[FeedResumeReset] action=seek_zero_skip_near_start key=$docID '
          'source=$source positionMs=${handle.position.inMilliseconds} '
          'playing=${handle.isPlaying}',
        );
        return;
      }
      final shouldClearTransitionSnapshot = !isIosFeedHls ||
          handle.adapter.value.hasRenderedFirstFrame ||
          handle.adapter.value.hasVisibleVideoFrame;
      if (handle.isPlaying) {
        await handle.pause();
      }
      await handle.seekTo(Duration.zero);
      if (handle is HLSAdapterPlaybackHandle) {
        if (shouldClearTransitionSnapshot) {
          await handle.adapter.clearFrameSnapshot(
            reason: 'transition_resume_reset:$source',
          );
        } else {
          debugPrint(
            '[FeedResumeReset] action=skip_clear_no_frame key=$docID '
            'source=$source positionMs=${handle.position.inMilliseconds}',
          );
        }
      } else if (handle is HLSPlaybackHandle) {
        await handle.controller.clearFrameSnapshot(
          reason: 'transition_resume_reset:$source',
        );
      }
      _videoStates.remove(docID);
      debugPrint(
        '[FeedResumeReset] action=seek_zero_complete key=$docID '
        'source=$source positionMs=${handle.position.inMilliseconds} '
        'playing=${handle.isPlaying}',
      );
    } catch (error) {
      debugPrint(
        '[FeedResumeReset] action=seek_zero_failed key=$docID '
        'source=$source error=$error',
      );
    }
  }

  void _saveVideoState(String docID, PlaybackHandle handle) {
    if (!handle.isInitialized) return;
    if (_hasTransitionResumeReset(docID)) {
      _videoStates.remove(docID);
      debugPrint(
        '[FeedResumeReset] action=suppress_save key=$docID '
        'positionMs=${handle.position.inMilliseconds}',
      );
      return;
    }

    _videoStates[docID] = VideoState(
      position: handle.position,
      isPlaying: handle.isPlaying,
      lastUpdated: DateTime.now(),
    );
  }

  void _saveVideoStateFromController(
    String docID,
    VideoPlayerController controller,
  ) {
    if (!controller.value.isInitialized) return;
    if (_hasTransitionResumeReset(docID)) {
      _videoStates.remove(docID);
      debugPrint(
        '[FeedResumeReset] action=suppress_controller_save key=$docID '
        'positionMs=${controller.value.position.inMilliseconds}',
      );
      return;
    }

    _videoStates[docID] = VideoState(
      position: controller.value.position,
      isPlaying: controller.value.isPlaying,
      lastUpdated: DateTime.now(),
    );
  }

  VideoState? _getVideoState(String docID) {
    return _videoStates[docID];
  }

  void _clearVideoState(String docID) {
    _videoStates.remove(docID);
  }

  void _clearAllStates() {
    _videoStates.clear();
  }

  void _cleanOldStates() {
    final now = DateTime.now();
    _videoStates.removeWhere((key, state) {
      return now.difference(state.lastUpdated).inMinutes > 5;
    });
  }

  Future<void> _restoreVideoState(
    String docID,
    PlaybackHandle handle,
  ) async {
    if (_hasTransitionResumeReset(docID)) {
      _videoStates.remove(docID);
      debugPrint('[FeedResumeReset] action=suppress_restore key=$docID');
      return;
    }
    final state = _getVideoState(docID);
    if (state == null || !handle.isInitialized) return;

    if (state.position.inMilliseconds > 0) {
      await handle.seekTo(state.position);
    }
  }

  Future<void> _restoreVideoStateFromController(
    String docID,
    VideoPlayerController controller,
  ) async {
    if (_hasTransitionResumeReset(docID)) {
      _videoStates.remove(docID);
      debugPrint(
        '[FeedResumeReset] action=suppress_controller_restore key=$docID',
      );
      return;
    }
    final state = _getVideoState(docID);
    if (state == null || !controller.value.isInitialized) return;

    if (state.position.inMilliseconds > 0) {
      await controller.seekTo(state.position);
    }
  }

  void _updatePosition(String docID, Duration position) {
    if (position < Duration.zero) return;
    if (_hasTransitionResumeReset(docID)) {
      _videoStates.remove(docID);
      debugPrint(
        '[FeedResumeReset] action=suppress_position_update key=$docID '
        'positionMs=${position.inMilliseconds}',
      );
      return;
    }
    final state = _videoStates[docID];
    final handle = _allVideoControllers[docID];
    _videoStates[docID] = VideoState(
      position: position,
      isPlaying: state?.isPlaying ?? handle?.isPlaying ?? false,
      lastUpdated: DateTime.now(),
    );
  }

  void _registerPlaybackHandle(String docID, PlaybackHandle handle) {
    final previous = _allVideoControllers[docID];
    if (previous != null && targetsSamePlaybackResource(previous, handle)) {
      _allVideoControllers[docID] = previous;
      return;
    }
    if (previous != null && !identical(previous, handle)) {
      _silenceSupersededHandle(docID, previous);
    }
    _allVideoControllers[docID] = handle;

    if (_allVideoControllers.length > _videoStateManagerMaxTrackedControllers) {
      final toRemove = _allVideoControllers.entries
          .where(
            (e) => e.key != _currentPlayingDocID && e.key != _exclusiveDocID,
          )
          .map((e) => e.key)
          .firstOrNull;
      if (toRemove != null) {
        final removedHandle = _allVideoControllers.remove(toRemove);
        if (removedHandle != null) {
          debugPrint(
            '[PlaybackStopTrace] source=tracked_handle_evict '
            'doc=$toRemove max=$_videoStateManagerMaxTrackedControllers',
          );
          _silenceSupersededHandle(toRemove, removedHandle);
        }
      }
    }
  }

  void _registerVideoController(
    String docID,
    VideoPlayerController controller,
  ) {
    _allVideoControllers[docID] = LegacyPlaybackHandle(controller);
  }

  void _unregisterVideoController(String docID) {
    _allVideoControllers.remove(docID);
    if (_currentPlayingDocID == docID) {
      _pendingPlayTimer?.cancel();
      _pendingPlayTimer = null;
      _currentPlayingDocID = null;
    }
  }

  void _pauseAllExcept(String? allowedDocID) {
    final allowedHandle =
        allowedDocID == null ? null : _allVideoControllers[allowedDocID];
    for (final entry in _allVideoControllers.entries) {
      if (entry.key == allowedDocID) continue;
      if (allowedHandle != null &&
          targetsSamePlaybackResource(entry.value, allowedHandle)) {
        continue;
      }

      try {
        final handle = entry.value;
        if (handle is HLSAdapterPlaybackHandle) {
          final value = handle.adapter.value;
          if (!value.isPlaying && !value.isBuffering) {
            continue;
          }
        }
        if (handle.isInitialized) {
          final controllerKey = entry.key.trim();
          final allowedSurface = _playbackSurfaceKind(allowedDocID);
          final controllerSurface = _playbackSurfaceKind(controllerKey);
          var shouldStopPlayback =
              _shouldStopPlaybackForHiddenHandle(controllerKey);
          if (allowedSurface != null &&
              controllerSurface != null &&
              allowedSurface != controllerSurface) {
            shouldStopPlayback = true;
          }
          if ((controllerSurface == 'social' ||
                  controllerSurface == 'profile') &&
              handle is HLSAdapterPlaybackHandle &&
              handle.adapter.value.isPlaying) {
            shouldStopPlayback = true;
          }
          if ((allowedSurface == 'feed' || allowedSurface == 'short') &&
              controllerSurface == allowedSurface &&
              handle is HLSAdapterPlaybackHandle) {
            shouldStopPlayback = true;
          }
          final keepWarmDuringSurfaceSwitch =
              handle is HLSAdapterPlaybackHandle &&
                  _shouldKeepWarmHandleDuringExclusiveSwitch(
                    allowedDocID,
                    controllerKey,
                    handle,
                  );
          final keepWarmDuringRefreshHandoff =
              defaultTargetPlatform == TargetPlatform.iOS &&
                  allowedSurface == 'feed' &&
                  controllerSurface == 'feed' &&
                  handle is HLSAdapterPlaybackHandle &&
                  _isFeedRefreshHandoffActive();
          if (keepWarmDuringSurfaceSwitch) {
            shouldStopPlayback = false;
          }
          if (keepWarmDuringRefreshHandoff) {
            shouldStopPlayback = false;
          }
          if (defaultTargetPlatform == TargetPlatform.iOS &&
              shouldStopPlayback &&
              controllerSurface == 'feed' &&
              allowedSurface == 'feed') {
            if (handle is HLSAdapterPlaybackHandle) {
              handle.adapter.suppressNextReattachResume(
                reason: 'ios_feed_hidden_handle_stop',
              );
              if (_shouldMarkIosFeedHiddenHandleReset(handle)) {
                _markTransitionResumeReset(
                  controllerKey,
                  reason: 'ios_feed_hidden_handle_stop',
                );
              } else {
                debugPrint(
                  '[FeedResumeReset] action=skip_mark '
                  'key=$controllerKey reason=ios_feed_hidden_handle_stop '
                  'positionMs=${handle.adapter.value.position.inMilliseconds} '
                  'durationMs=${handle.adapter.value.duration.inMilliseconds} '
                  'completed=${handle.adapter.value.isCompleted}',
                );
              }
            } else {
              _markTransitionResumeReset(
                controllerKey,
                reason: 'ios_feed_hidden_handle_stop',
              );
            }
          }
          if (handle is HLSAdapterPlaybackHandle) {
            debugPrint(
              '[PlaybackStopTrace] source=pause_all_except '
              'allowed=$allowedDocID stopping=${entry.key} '
              'playing=${handle.isPlaying} '
              'buffering=${handle.adapter.value.isBuffering} '
              'preferWarm=${handle.adapter.preferWarmPoolPause} '
              'surfaceKeepWarm=$keepWarmDuringSurfaceSwitch '
              'refreshHandoff=$keepWarmDuringRefreshHandoff '
              'stopPlayback=$shouldStopPlayback',
            );
            if (controllerSurface == 'feed' || allowedSurface == 'feed') {
              debugPrint(
                '[FeedCdnProbe] signal=hidden_handle_decision '
                'allowed=$allowedDocID stopping=${entry.key} '
                'surface=$controllerSurface allowedSurface=$allowedSurface '
                'stopPlayback=$shouldStopPlayback '
                'surfaceKeepWarm=$keepWarmDuringSurfaceSwitch '
                'refreshHandoff=$keepWarmDuringRefreshHandoff '
                'preferWarm=${handle.adapter.preferWarmPoolPause} '
                'playing=${handle.isPlaying} '
                'buffering=${handle.adapter.value.isBuffering} '
                'positionMs=${handle.adapter.value.position.inMilliseconds}',
              );
            }
            if (controllerSurface == 'short' || allowedSurface == 'short') {
              debugPrint(
                '[ShortCdnProbe] signal=hidden_handle_decision '
                'allowed=$allowedDocID stopping=${entry.key} '
                'surface=$controllerSurface allowedSurface=$allowedSurface '
                'stopPlayback=$shouldStopPlayback '
                'surfaceKeepWarm=$keepWarmDuringSurfaceSwitch '
                'preferWarm=${handle.adapter.preferWarmPoolPause} '
                'playing=${handle.isPlaying} '
                'buffering=${handle.adapter.value.isBuffering} '
                'positionMs=${handle.adapter.value.position.inMilliseconds}',
              );
            }
          }
          final isIosFeedHiddenStop =
              defaultTargetPlatform == TargetPlatform.iOS &&
                  shouldStopPlayback &&
                  controllerSurface == 'feed' &&
                  allowedSurface == 'feed' &&
                  handle is HLSAdapterPlaybackHandle;
          if (isIosFeedHiddenStop) {
            unawaited(handle.adapter.setVolume(0.0));
          }
          _playbackExecutionService.quietHandle(
            handle,
            persistState: () => _saveVideoState(entry.key, handle),
            stopPlayback: shouldStopPlayback,
          );
          if (isIosFeedHiddenStop) {
            _verifyIosFeedHiddenHandleStopped(
              controllerKey: controllerKey,
              allowedDocID: allowedDocID,
              handle: handle,
              attempt: 0,
            );
          }
        }
      } catch (_) {}
    }

    _currentPlayingDocID = allowedDocID;
    _syncFocusedPrefetchDoc(allowedDocID);
  }

  void _verifyIosFeedHiddenHandleStopped({
    required String controllerKey,
    required String? allowedDocID,
    required HLSAdapterPlaybackHandle handle,
    required int attempt,
  }) {
    final delay = attempt == 0
        ? const Duration(milliseconds: 100)
        : const Duration(milliseconds: 100);
    Future<void>.delayed(delay, () async {
      if (defaultTargetPlatform != TargetPlatform.iOS) return;
      if (_targetPlaybackDocID != allowedDocID ||
          _currentPlayingDocID != allowedDocID) {
        return;
      }
      if (controllerKey == allowedDocID) return;
      final currentHandle = _allVideoControllers[controllerKey];
      if (!identical(currentHandle, handle)) return;
      final value = handle.adapter.value;
      if (!value.isPlaying && !value.isBuffering) return;
      if (kDebugMode) {
        debugPrint(
          '[PlaybackStopTrace] source=ios_feed_hidden_verify_stop '
          'attempt=$attempt allowed=$allowedDocID stopping=$controllerKey '
          'playing=${value.isPlaying} buffering=${value.isBuffering} '
          'positionMs=${value.position.inMilliseconds}',
        );
      }
      try {
        await handle.adapter.setVolume(0.0);
        await _playbackExecutionService.stopAdapter(handle.adapter);
      } catch (_) {}
      if (attempt == 0) {
        _verifyIosFeedHiddenHandleStopped(
          controllerKey: controllerKey,
          allowedDocID: allowedDocID,
          handle: handle,
          attempt: attempt + 1,
        );
      }
    });
  }

  void _syncFocusedPrefetchDoc(String? activeDocID) {
    try {
      final scheduler = maybeFindPrefetchScheduler();
      final cacheManager = SegmentCacheManager.maybeFind();
      final activeKey = activeDocID?.trim() ?? '';
      final normalized = HlsSegmentPolicy.normalizeDocId(activeDocID);
      maybeFindHlsDataUsageProbe()?.setVisibleDoc(normalized);
      if (scheduler == null) return;
      if (normalized == null || normalized.isEmpty) {
        scheduler.unfocusDoc();
        return;
      }
      if (activeKey.startsWith('feed:')) {
        final feedDocIds = scheduler.currentFeedDocIds();
        final activeIndex = feedDocIds.indexOf(normalized);
        if (activeIndex >= 0) {
          unawaited(scheduler.updateFeedQueue(feedDocIds, activeIndex));
          return;
        }
      }
      scheduler.unfocusDoc();
      if (GetPlatform.isAndroid && activeKey.startsWith('feed:')) {
        final initialCachedSegments =
            cacheManager?.getEntry(normalized)?.cachedSegmentCount ?? 0;
        const targetReadySegments =
            HlsSegmentPolicy.playbackWarmMaxSegmentOrdinal;
        debugPrint(
          '[FeedSegmentWarm] stage=boost_start doc=$normalized '
          'targetReadySegments=$targetReadySegments cachedSegments=$initialCachedSegments '
          'queueSize=${scheduler.queueSize} activeDownloads=${scheduler.activeDownloads}',
        );
        scheduler.boostDoc(normalized, readySegments: targetReadySegments);
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (_currentPlayingDocID != activeDocID) return;
          final cachedSegments =
              cacheManager?.getEntry(normalized)?.cachedSegmentCount ?? 0;
          debugPrint(
            '[FeedSegmentWarm] stage=boost_check doc=$normalized '
            'targetReadySegments=$targetReadySegments cachedSegments=$cachedSegments '
            'queueSize=${scheduler.queueSize} activeDownloads=${scheduler.activeDownloads} '
            'feedReadyCount=${scheduler.feedReadyCount} feedWindowCount=${scheduler.feedWindowCount}',
          );
        });
        return;
      }
      scheduler.boostDoc(normalized);
    } catch (_) {}
  }

  void _schedulePendingPlayResume(
    String docID,
    int requestSeq, {
    int attempt = 0,
  }) {
    _pendingPlayTimer?.cancel();
    final isIosFeedPlayback = defaultTargetPlatform == TargetPlatform.iOS &&
        docID.startsWith('feed:');
    final isAndroidFeedStylePlayback = _isAndroidFeedStyleResumeKey(docID);
    final resumeDelay = isIosFeedPlayback && attempt == 0
        ? Duration.zero
        : _videoStateManagerPlayResumeDelay;
    _pendingPlayTimer = Timer(resumeDelay, () {
      if (requestSeq != _playRequestSeq) {
        if (kDebugMode && isIosFeedPlayback) {
          debugPrint(
            '[FeedPlaybackProof] stage=pending_resume_skip '
            'reason=stale_request doc=$docID attempt=$attempt '
            'requestSeq=$requestSeq activeSeq=$_playRequestSeq',
          );
        }
        return;
      }
      if (_currentPlayingDocID != docID || _targetPlaybackDocID != docID) {
        if (kDebugMode && isIosFeedPlayback) {
          debugPrint(
            '[FeedPlaybackProof] stage=pending_resume_skip '
            'reason=owner_target_mismatch doc=$docID attempt=$attempt '
            'current=${_currentPlayingDocID ?? ''} '
            'target=${_targetPlaybackDocID ?? ''}',
          );
        }
        return;
      }
      if (_hasTransitionResumeReset(docID)) {
        if (kDebugMode && isIosFeedPlayback) {
          debugPrint(
            '[FeedPlaybackProof] stage=pending_resume_skip '
            'reason=transition_reset doc=$docID attempt=$attempt',
          );
        }
        return;
      }
      final handle = _allVideoControllers[docID];
      if (handle == null) {
        if (attempt >= _videoStateManagerMaxPendingPlayRetries) return;
        _schedulePendingPlayResume(
          docID,
          requestSeq,
          attempt: attempt + 1,
        );
        return;
      }
      if (!handle.isInitialized) {
        if (attempt >= _videoStateManagerMaxPendingPlayRetries) return;
        _schedulePendingPlayResume(
          docID,
          requestSeq,
          attempt: attempt + 1,
        );
        return;
      }
      final hasMeaningfulProgress = handle.position > Duration.zero;
      final hlsAdapterHandle =
          handle is HLSAdapterPlaybackHandle ? handle.adapter : null;
      final adapterValue = hlsAdapterHandle?.value;
      final hlsHandleAlreadyActivating = adapterValue != null &&
          (adapterValue.isPlaying || adapterValue.isBuffering);
      final hlsActivatingWithoutFrame = adapterValue != null &&
          hlsHandleAlreadyActivating &&
          !adapterValue.hasRenderedFirstFrame &&
          !adapterValue.hasVisibleVideoFrame &&
          !adapterValue.isCompleted;
      final hlsActivationStalledBeforeFirstFrame = adapterValue != null &&
          !adapterValue.hasRenderedFirstFrame &&
          !adapterValue.hasVisibleVideoFrame &&
          !adapterValue.isPlaying &&
          !adapterValue.isBuffering &&
          !adapterValue.isCompleted;
      final hlsActivationStalledAfterVisualReady = adapterValue != null &&
          adapterValue.hasRenderedFirstFrame &&
          !adapterValue.isPlaying &&
          !adapterValue.isBuffering &&
          !adapterValue.isCompleted;
      final shouldForceResumeForHlsStall =
          hlsActivationStalledBeforeFirstFrame ||
              hlsActivationStalledAfterVisualReady ||
              (adapterValue != null &&
                  adapterValue.position > Duration.zero &&
                  !adapterValue.isPlaying &&
                  !adapterValue.isBuffering &&
                  !adapterValue.isCompleted);
      final shouldForceResumeForActivatingHlsStall =
          hlsActivatingWithoutFrame && attempt >= 2;
      final shouldNudgeActivatingHlsSeek = isAndroidFeedStylePlayback &&
          shouldForceResumeForActivatingHlsStall &&
          adapterValue.position > Duration.zero &&
          attempt == 4;
      final shouldRecoverActivatingHlsReload = isAndroidFeedStylePlayback &&
          hlsAdapterHandle != null &&
          shouldForceResumeForActivatingHlsStall &&
          attempt == 5;
      final shouldRestartAndroidFeedResumeFromZero =
          isAndroidFeedStylePlayback &&
              hlsAdapterHandle != null &&
              shouldForceResumeForActivatingHlsStall &&
              adapterValue.position > Duration.zero &&
              attempt == 8;
      var issuedRecoveringReload = false;
      if (!handle.isPlaying &&
          (!hasMeaningfulProgress ||
              shouldForceResumeForHlsStall ||
              shouldForceResumeForActivatingHlsStall) &&
          (!hlsHandleAlreadyActivating ||
              shouldForceResumeForActivatingHlsStall)) {
        if (kDebugMode && hlsAdapterHandle != null) {
          debugPrint(
            '[FeedPlaybackProof] stage=pending_resume_play '
            'doc=$docID attempt=$attempt '
            'positionMs=${adapterValue?.position.inMilliseconds ?? -1} '
            'firstFrame=${adapterValue?.hasRenderedFirstFrame ?? false} '
            'visibleFrame=${adapterValue?.hasVisibleVideoFrame ?? false} '
            'stalledBeforeFirstFrame=$hlsActivationStalledBeforeFirstFrame '
            'stalledAfterVisualReady=$hlsActivationStalledAfterVisualReady '
            'forceActivatingStall=$shouldForceResumeForActivatingHlsStall',
          );
        }
        if (shouldNudgeActivatingHlsSeek) {
          final nudgePosition = adapterValue.position;
          if (kDebugMode) {
            debugPrint(
              '[FeedPlaybackProof] stage=pending_resume_seek_nudge '
              'doc=$docID attempt=$attempt '
              'positionMs=${nudgePosition.inMilliseconds}',
            );
          }
          unawaited(
            handle.seekTo(nudgePosition).then((_) {
              if (requestSeq != _playRequestSeq) return;
              if (_currentPlayingDocID != docID ||
                  _targetPlaybackDocID != docID) {
                return;
              }
              _playbackExecutionService.resumeHandle(handle);
            }),
          );
        } else if (shouldRestartAndroidFeedResumeFromZero) {
          issuedRecoveringReload = true;
          _clearAndroidFeedResumeRecover(docID, 'restart_zero');
          _videoStates.remove(docID);
          if (kDebugMode) {
            debugPrint(
              '[FeedPlaybackProof] stage=pending_resume_restart_zero '
              'doc=$docID attempt=$attempt '
              'stalledPositionMs=${adapterValue.position.inMilliseconds}',
            );
          }
          unawaited(
            hlsAdapterHandle
                .recoverFrozenPlayback(
              preservePosition: false,
              playAfterSeek: false,
            )
                .then((_) {
              if (requestSeq != _playRequestSeq) return;
              if (_currentPlayingDocID != docID ||
                  _targetPlaybackDocID != docID) {
                return;
              }
              _playbackExecutionService.resumeHandle(handle);
              Future<void>.delayed(const Duration(milliseconds: 400), () {
                if (requestSeq != _playRequestSeq) return;
                if (_currentPlayingDocID != docID ||
                    _targetPlaybackDocID != docID) {
                  return;
                }
                final latest = _allVideoControllers[docID];
                final latestAdapter = latest is HLSAdapterPlaybackHandle
                    ? latest.adapter.value
                    : null;
                final recovered = latestAdapter == null ||
                    latestAdapter.isPlaying ||
                    latestAdapter.hasRenderedFirstFrame ||
                    latestAdapter.hasVisibleVideoFrame;
                if (recovered) return;
                _schedulePendingPlayResume(
                  docID,
                  requestSeq,
                  attempt: attempt + 1,
                );
              });
            }),
          );
        } else if (shouldRecoverActivatingHlsReload) {
          issuedRecoveringReload = true;
          final recoverPosition = adapterValue.position;
          _markAndroidFeedResumeRecover(
            docID,
            requestSeq: requestSeq,
            attempt: attempt,
            position: recoverPosition,
          );
          if (kDebugMode) {
            debugPrint(
              '[FeedPlaybackProof] stage=pending_resume_recover_reload '
              'doc=$docID attempt=$attempt '
              'positionMs=${recoverPosition.inMilliseconds}',
            );
          }
          unawaited(
            hlsAdapterHandle
                .recoverFrozenPlayback(
              preservePosition: true,
              forcePreservePosition: true,
              playAfterSeek: true,
            )
                .then((_) {
              if (requestSeq != _playRequestSeq) return;
              if (_currentPlayingDocID != docID ||
                  _targetPlaybackDocID != docID) {
                return;
              }
              _playbackExecutionService.resumeHandle(handle);
              Future<void>.delayed(const Duration(milliseconds: 650), () {
                if (requestSeq != _playRequestSeq) return;
                if (_currentPlayingDocID != docID ||
                    _targetPlaybackDocID != docID) {
                  _clearAndroidFeedResumeRecover(docID, 'target_changed');
                  return;
                }
                final latest = _allVideoControllers[docID];
                final latestAdapter = latest is HLSAdapterPlaybackHandle
                    ? latest.adapter.value
                    : null;
                final recovered = latestAdapter == null ||
                    latestAdapter.isPlaying ||
                    latestAdapter.hasRenderedFirstFrame ||
                    latestAdapter.hasVisibleVideoFrame;
                if (recovered) {
                  _clearAndroidFeedResumeRecover(docID, 'visual_ready');
                  return;
                }
                final otherPlaying = _activeOtherAndroidFeedResumeKey(docID);
                if (otherPlaying != null) {
                  debugPrint(
                    '[FeedPlaybackProof] stage=pending_resume_stale_abort '
                    'doc=$docID other=$otherPlaying requestSeq=$requestSeq',
                  );
                  _clearAndroidFeedResumeRecover(docID, 'other_feed_playing');
                  return;
                }
                _schedulePendingPlayResume(
                  docID,
                  requestSeq,
                  attempt: attempt + 1,
                );
              });
            }),
          );
        } else {
          _playbackExecutionService.resumeHandle(handle);
        }
      } else if (kDebugMode && hlsAdapterHandle != null) {
        debugPrint(
          '[FeedPlaybackProof] stage=pending_resume_skip '
          'doc=$docID attempt=$attempt '
          'playing=${handle.isPlaying} '
          'positionMs=${adapterValue?.position.inMilliseconds ?? -1} '
          'firstFrame=${adapterValue?.hasRenderedFirstFrame ?? false} '
          'visibleFrame=${adapterValue?.hasVisibleVideoFrame ?? false} '
          'activating=$hlsHandleAlreadyActivating '
          'force=$shouldForceResumeForHlsStall '
          'activatingNoFrame=$hlsActivatingWithoutFrame',
        );
      }
      if (hlsAdapterHandle != null &&
          !issuedRecoveringReload &&
          (((!hlsAdapterHandle.value.hasRenderedFirstFrame &&
                      !hlsAdapterHandle.value.hasVisibleVideoFrame &&
                      !hlsAdapterHandle.value.isPlaying &&
                      !hlsAdapterHandle.value.isBuffering &&
                      hlsAdapterHandle.value.position <= Duration.zero) ||
                  hlsActivatingWithoutFrame) &&
              !hlsAdapterHandle.value.isCompleted) &&
          !hlsAdapterHandle.value.isCompleted &&
          attempt < _videoStateManagerMaxPendingPlayRetries) {
        final otherPlaying = _activeOtherAndroidFeedResumeKey(docID);
        if (otherPlaying != null) {
          debugPrint(
            '[FeedPlaybackProof] stage=pending_resume_stale_abort '
            'doc=$docID other=$otherPlaying attempt=$attempt',
          );
          _clearAndroidFeedResumeRecover(docID, 'other_feed_playing');
          return;
        }
        if (kDebugMode) {
          debugPrint(
            '[FeedPlaybackProof] stage=pending_resume_retry '
            'doc=$docID attempt=$attempt '
            'playing=${hlsAdapterHandle.value.isPlaying} '
            'buffering=${hlsAdapterHandle.value.isBuffering} '
            'positionMs=${hlsAdapterHandle.value.position.inMilliseconds}',
          );
        }
        _schedulePendingPlayResume(
          docID,
          requestSeq,
          attempt: attempt + 1,
        );
      }
    });
  }

  void _playOnlyThis(String docID) {
    if (_suppressDuplicateAndroidFeedResumeRequest(
      docID,
      source: 'play_only_this',
    )) {
      return;
    }
    _playRequestSeq++;
    final int requestSeq = _playRequestSeq;

    if (_exclusiveMode && _exclusiveDocID != null && _exclusiveDocID != docID) {
      return;
    }

    final current = _allVideoControllers[docID];
    final hasTransitionReset = _hasTransitionResumeReset(docID);
    if (_currentPlayingDocID == docID &&
        current != null &&
        current.isInitialized &&
        current.isPlaying &&
        !hasTransitionReset) {
      return;
    }
    if (current != null) {
      final transitionResetReason =
          _transitionResumeResetReasons[docID.trim()] ?? '';
      final consumedTransitionReset = _consumeTransitionResumeReset(
        docID,
        current,
        source: 'play_only_this',
      );
      if (consumedTransitionReset) {
        _pauseAllExcept(docID);
        _markTargetPlaybackDoc(docID);
        if (_shouldPrimeIosFeedResetWithoutBlocking(
          docID,
          current,
          transitionResetReason,
        )) {
          _consumeIosFeedResetWithoutBlocking(
            docID,
            current,
            source: 'play_only_this',
            reason: transitionResetReason,
          );
          _schedulePendingPlayResume(docID, requestSeq);
          return;
        }
        unawaited(
          _seekTransitionResumeResetToZero(
            docID,
            current,
            source: 'play_only_this',
          ).then((_) {
            if (_playRequestSeq != requestSeq) return;
            if (_targetPlaybackDocID != docID) return;
            _schedulePendingPlayResume(docID, requestSeq);
          }),
        );
        return;
      }
    }

    _markTargetPlaybackDoc(docID);
    _pauseAllExcept(docID);
    _schedulePendingPlayResume(docID, requestSeq);
  }

  void _reassertOnlyThis(String docID) {
    if (_suppressDuplicateAndroidFeedResumeRequest(
      docID,
      source: 'reassert_only_this',
    )) {
      return;
    }
    if (_exclusiveMode && _exclusiveDocID != null && _exclusiveDocID != docID) {
      return;
    }

    final handle = _allVideoControllers[docID];
    if (handle == null || !handle.isInitialized) return;
    final transitionResetReason =
        _transitionResumeResetReasons[docID.trim()] ?? '';
    final consumedTransitionReset = _consumeTransitionResumeReset(
      docID,
      handle,
      source: 'reassert_only_this',
    );

    _playRequestSeq++;
    final int requestSeq = _playRequestSeq;
    _markTargetPlaybackDoc(docID);
    _pauseAllExcept(docID);
    if (consumedTransitionReset) {
      if (_shouldPrimeIosFeedResetWithoutBlocking(
        docID,
        handle,
        transitionResetReason,
      )) {
        _consumeIosFeedResetWithoutBlocking(
          docID,
          handle,
          source: 'reassert_only_this',
          reason: transitionResetReason,
        );
        _schedulePendingPlayResume(docID, requestSeq);
        return;
      }
      unawaited(
        _seekTransitionResumeResetToZero(
          docID,
          handle,
          source: 'reassert_only_this',
        ).then((_) {
          if (_playRequestSeq != requestSeq) return;
          if (_targetPlaybackDocID != docID) return;
          _schedulePendingPlayResume(docID, requestSeq);
        }),
      );
      return;
    }
    _schedulePendingPlayResume(docID, requestSeq);
  }

  void _requestPlayVideo(String docID, PlaybackHandle handle) {
    if (_suppressDuplicateAndroidFeedResumeRequest(
      docID,
      source: 'request_play',
    )) {
      return;
    }
    _playRequestSeq++;
    final int requestSeq = _playRequestSeq;
    final previous = _allVideoControllers[docID];
    final effectiveHandle =
        previous != null && targetsSamePlaybackResource(previous, handle)
            ? previous
            : handle;
    _allVideoControllers[docID] = effectiveHandle;
    final transitionResetReason =
        _transitionResumeResetReasons[docID.trim()] ?? '';
    final consumedTransitionReset = _consumeTransitionResumeReset(
      docID,
      effectiveHandle,
      source: 'request_play',
    );
    _markTargetPlaybackDoc(docID);
    _pauseAllExcept(docID);
    _currentPlayingDocID = docID;
    if (consumedTransitionReset) {
      if (_shouldPrimeIosFeedResetWithoutBlocking(
        docID,
        effectiveHandle,
        transitionResetReason,
      )) {
        _consumeIosFeedResetWithoutBlocking(
          docID,
          effectiveHandle,
          source: 'request_play',
          reason: transitionResetReason,
        );
        _schedulePendingPlayResume(docID, requestSeq);
        return;
      }
      unawaited(
        _seekTransitionResumeResetToZero(
          docID,
          effectiveHandle,
          source: 'request_play',
        ).then((_) {
          if (_playRequestSeq != requestSeq) return;
          if (_targetPlaybackDocID != docID) return;
          _schedulePendingPlayResume(docID, requestSeq);
        }),
      );
      return;
    }
    _schedulePendingPlayResume(docID, requestSeq);
  }

  void _requestPlayVideoFromController(
    String docID,
    VideoPlayerController controller,
  ) {
    _requestPlayVideo(docID, LegacyPlaybackHandle(controller));
  }

  void _requestStopVideo(String docID) {
    final wasCurrent = _currentPlayingDocID == docID;
    final wasTarget = _targetPlaybackDocID == docID;
    if (wasCurrent || wasTarget) {
      _pendingPlayTimer?.cancel();
      _pendingPlayTimer = null;
      _playRequestSeq++;
      if (kDebugMode) {
        debugPrint(
          '[FeedPlaybackProof] stage=request_stop_cancel_pending '
          'doc=$docID wasCurrent=$wasCurrent wasTarget=$wasTarget',
        );
      }
    }
    if (wasCurrent) {
      _currentPlayingDocID = null;
    }
    if (wasTarget) {
      _markTargetPlaybackDoc(null);
    }
  }

  void _pauseAllVideos({bool force = false}) {
    final currentPlayingDocId = _currentPlayingDocID?.trim() ?? '';
    if (currentPlayingDocId.isNotEmpty) {
      debugPrint(
        '[PlaybackStopTrace] source=pause_all_videos '
        'force=$force current=$currentPlayingDocId '
        'target=${_targetPlaybackDocID ?? ''} '
        'exclusive=${_exclusiveDocID ?? ''}',
      );
    }
    if (!force && _exclusiveMode) {
      if (_exclusiveDocID != null) {
        _pauseAllExcept(_exclusiveDocID);
      }
      return;
    }
    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = null;
    _playRequestSeq++;
    _pauseAllExcept(null);
    _markTargetPlaybackDoc(null);
    try {
      AudioFocusCoordinator.instance.pauseAllAudioPlayers();
    } catch (_) {}
  }

  void _enterExclusiveMode(String docID) {
    _exclusiveMode = true;
    _exclusiveDocID = docID;
    _playOnlyThis(docID);
  }

  void _updateExclusiveModeDoc(String docID) {
    if (!_exclusiveMode) return;
    _exclusiveDocID = docID;
    _playOnlyThis(docID);
  }

  void _exitExclusiveMode() {
    _exclusiveMode = false;
    _exclusiveDocID = null;
  }

  Map<String, dynamic> debugSnapshot() {
    return <String, dynamic>{
      'currentPlayingDocID': _currentPlayingDocID ?? '',
      'targetPlaybackDocID': _targetPlaybackDocID ?? '',
      'targetPlaybackUpdatedAt':
          _targetPlaybackUpdatedAt?.toIso8601String() ?? '',
      'exclusiveMode': _exclusiveMode,
      'exclusiveDocID': _exclusiveDocID ?? '',
      'registeredHandleCount': _allVideoControllers.length,
      'registeredHandleKeys':
          _allVideoControllers.keys.take(24).toList(growable: false),
      'transitionResumeResetKeys':
          _transitionResumeResetKeys.take(24).toList(growable: false),
      'savedStateCount': _videoStates.length,
      'savedStateKeys': _videoStates.keys.take(24).toList(growable: false),
    };
  }
}

/// Instagram tarzı akıcı video deneyimi için video durumu yöneticisi
/// Her videonun oynatma pozisyonunu ve durumunu bellekte tutar
class VideoStateManager extends GetxController {
  static VideoStateManager get instance => ensureVideoStateManager();

  final _VideoStateManagerState _state = _VideoStateManagerState();

  @override
  void onClose() {
    _handleVideoStateManagerClose(this);
    super.onClose();
  }
}

VideoStateManager? maybeFindVideoStateManager() {
  final isRegistered = Get.isRegistered<VideoStateManager>();
  if (!isRegistered) return null;
  return Get.find<VideoStateManager>();
}

VideoStateManager ensureVideoStateManager() {
  final existing = maybeFindVideoStateManager();
  if (existing != null) {
    existing.ensureStaleStateCleanupTimer();
    return existing;
  }
  final manager = Get.put(VideoStateManager());
  manager.ensureStaleStateCleanupTimer();
  return manager;
}

extension VideoStateManagerFacadePart on VideoStateManager {
  void saveVideoState(String docID, PlaybackHandle handle) =>
      VideoStateManagerPlaybackPart(this)._saveVideoState(docID, handle);

  void saveVideoStateFromController(
    String docID,
    VideoPlayerController controller,
  ) =>
      VideoStateManagerPlaybackPart(this)
          ._saveVideoStateFromController(docID, controller);

  VideoState? getVideoState(String docID) =>
      VideoStateManagerPlaybackPart(this)._getVideoState(docID);

  void clearVideoState(String docID) =>
      VideoStateManagerPlaybackPart(this)._clearVideoState(docID);

  void markTransitionResumeReset(
    String docID, {
    required String reason,
  }) =>
      VideoStateManagerPlaybackPart(this)
          ._markTransitionResumeReset(docID, reason: reason);

  void beginFeedRefreshHandoff({
    required Duration keepWarmFor,
    required String reason,
  }) =>
      VideoStateManagerPlaybackPart(this)._beginFeedRefreshHandoff(
        keepWarmFor: keepWarmFor,
        reason: reason,
      );

  void clearAllStates() =>
      VideoStateManagerPlaybackPart(this)._clearAllStates();

  void cleanOldStates() =>
      VideoStateManagerPlaybackPart(this)._cleanOldStates();

  Future<void> restoreVideoState(
    String docID,
    PlaybackHandle handle,
  ) =>
      VideoStateManagerPlaybackPart(this)._restoreVideoState(docID, handle);

  Future<void> restoreVideoStateFromController(
    String docID,
    VideoPlayerController controller,
  ) =>
      VideoStateManagerPlaybackPart(this)
          ._restoreVideoStateFromController(docID, controller);

  void updatePosition(String docID, Duration position) =>
      VideoStateManagerPlaybackPart(this)._updatePosition(docID, position);

  void registerPlaybackHandle(String docID, PlaybackHandle handle) =>
      VideoStateManagerPlaybackPart(this)
          ._registerPlaybackHandle(docID, handle);

  void registerVideoController(
    String docID,
    VideoPlayerController controller,
  ) =>
      VideoStateManagerPlaybackPart(this)
          ._registerVideoController(docID, controller);

  void unregisterVideoController(String docID) =>
      VideoStateManagerPlaybackPart(this)._unregisterVideoController(docID);

  void pauseAllExcept(String? allowedDocID) =>
      VideoStateManagerPlaybackPart(this)._pauseAllExcept(allowedDocID);

  void playOnlyThis(String docID) =>
      VideoStateManagerPlaybackPart(this)._playOnlyThis(docID);

  void reassertOnlyThis(String docID) =>
      VideoStateManagerPlaybackPart(this)._reassertOnlyThis(docID);

  void requestPlayVideo(String docID, PlaybackHandle handle) =>
      VideoStateManagerPlaybackPart(this)._requestPlayVideo(docID, handle);

  void requestPlayVideoFromController(
    String docID,
    VideoPlayerController controller,
  ) =>
      VideoStateManagerPlaybackPart(this)
          ._requestPlayVideoFromController(docID, controller);

  void requestStopVideo(String docID) =>
      VideoStateManagerPlaybackPart(this)._requestStopVideo(docID);

  void pauseAllVideos({bool force = false}) =>
      VideoStateManagerPlaybackPart(this)._pauseAllVideos(force: force);

  int setFeedVolume(double volume, {required String reason}) =>
      VideoStateManagerPlaybackPart(this)._setRegisteredHandleVolume(
        volume: volume,
        where: (key) => key.startsWith('feed:'),
        reason: reason,
      );

  void enterExclusiveMode(String docID) =>
      VideoStateManagerPlaybackPart(this)._enterExclusiveMode(docID);

  void updateExclusiveModeDoc(String docID) =>
      VideoStateManagerPlaybackPart(this)._updateExclusiveModeDoc(docID);

  void exitExclusiveMode() =>
      VideoStateManagerPlaybackPart(this)._exitExclusiveMode();
}
