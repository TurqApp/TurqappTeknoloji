part of 'video_state_manager.dart';

const int _videoStateManagerMaxPendingPlayRetries = 28;

extension VideoStateManagerPlaybackPart on VideoStateManager {
  void _markTargetPlaybackDoc(String? docID) {
    _targetPlaybackDocID = docID;
    _targetPlaybackUpdatedAt = docID == null ? null : DateTime.now();
  }

  void _silenceSupersededHandle(
    String docID,
    PlaybackHandle handle,
  ) {
    _playbackExecutionService.quietHandle(
      handle,
      persistState: () => _saveVideoState(docID, handle),
      stopPlayback: true,
    );
  }

  void _saveVideoState(String docID, PlaybackHandle handle) {
    if (!handle.isInitialized) return;

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
    final state = _getVideoState(docID);
    if (state == null || !controller.value.isInitialized) return;

    if (state.position.inMilliseconds > 0) {
      await controller.seekTo(state.position);
    }
  }

  void _updatePosition(String docID, Duration position) {
    final state = _videoStates[docID];
    if (state != null) {
      _videoStates[docID] = VideoState(
        position: position,
        isPlaying: state.isPlaying,
        lastUpdated: DateTime.now(),
      );
    }
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
        _allVideoControllers.remove(toRemove);
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
    for (final entry in _allVideoControllers.entries) {
      if (entry.key == allowedDocID) continue;

      try {
        final handle = entry.value;
        if (handle is HLSAdapterPlaybackHandle &&
            handle.adapter.preferWarmPoolPause) {
          final value = handle.adapter.value;
          if (!value.isPlaying && !value.isBuffering) {
            continue;
          }
        }
        if (handle.isInitialized) {
          _playbackExecutionService.quietHandle(
            handle,
            persistState: () => _saveVideoState(entry.key, handle),
            stopPlayback: true,
          );
        }
      } catch (_) {}
    }

    _currentPlayingDocID = allowedDocID;
    _syncFocusedPrefetchDoc(allowedDocID);
  }

  void _syncFocusedPrefetchDoc(String? activeDocID) {
    try {
      final scheduler = maybeFindPrefetchScheduler();
      if (scheduler == null) return;
      scheduler.unfocusDoc();
      final normalized = HlsSegmentPolicy.normalizeDocId(activeDocID);
      if (normalized == null || normalized.isEmpty) return;
      scheduler.boostDoc(normalized);
    } catch (_) {}
  }

  void _schedulePendingPlayResume(
    String docID,
    int requestSeq, {
    int attempt = 0,
  }) {
    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = Timer(_videoStateManagerPlayResumeDelay, () {
      if (requestSeq != _playRequestSeq) return;
      if (_currentPlayingDocID != docID) return;
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
      if (!handle.isPlaying) {
        _playbackExecutionService.resumeHandle(handle);
      }
    });
  }

  void _playOnlyThis(String docID) {
    _playRequestSeq++;
    final int requestSeq = _playRequestSeq;

    if (_exclusiveMode && _exclusiveDocID != null && _exclusiveDocID != docID) {
      return;
    }

    final current = _allVideoControllers[docID];
    if (_currentPlayingDocID == docID &&
        current != null &&
        current.isInitialized &&
        current.isPlaying) {
      return;
    }

    _pauseAllExcept(docID);
    _markTargetPlaybackDoc(docID);
    _schedulePendingPlayResume(docID, requestSeq);
  }

  void _reassertOnlyThis(String docID) {
    if (_exclusiveMode && _exclusiveDocID != null && _exclusiveDocID != docID) {
      return;
    }

    final handle = _allVideoControllers[docID];
    if (handle == null || !handle.isInitialized) return;

    _playRequestSeq++;
    final int requestSeq = _playRequestSeq;
    _pauseAllExcept(docID);
    _markTargetPlaybackDoc(docID);
    _schedulePendingPlayResume(docID, requestSeq);
  }

  void _requestPlayVideo(String docID, PlaybackHandle handle) {
    final previous = _allVideoControllers[docID];
    final effectiveHandle = previous != null &&
            targetsSamePlaybackResource(previous, handle)
        ? previous
        : handle;
    _allVideoControllers[docID] = effectiveHandle;
    _pauseAllExcept(docID);
    _currentPlayingDocID = docID;
    _markTargetPlaybackDoc(docID);
  }

  void _requestPlayVideoFromController(
    String docID,
    VideoPlayerController controller,
  ) {
    _requestPlayVideo(docID, LegacyPlaybackHandle(controller));
  }

  void _requestStopVideo(String docID) {
    if (_currentPlayingDocID == docID) {
      _currentPlayingDocID = null;
    }
    if (_targetPlaybackDocID == docID) {
      _markTargetPlaybackDoc(null);
    }
  }

  void _pauseAllVideos({bool force = false}) {
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
  if (existing != null) return existing;
  return Get.put(VideoStateManager());
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

  void enterExclusiveMode(String docID) =>
      VideoStateManagerPlaybackPart(this)._enterExclusiveMode(docID);

  void updateExclusiveModeDoc(String docID) =>
      VideoStateManagerPlaybackPart(this)._updateExclusiveModeDoc(docID);

  void exitExclusiveMode() =>
      VideoStateManagerPlaybackPart(this)._exitExclusiveMode();
}
