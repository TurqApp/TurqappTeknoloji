part of 'video_state_manager.dart';

extension VideoStateManagerPlaybackPart on VideoStateManager {
  void saveVideoState(String docID, PlaybackHandle handle) {
    if (!handle.isInitialized) return;

    _videoStates[docID] = VideoState(
      position: handle.position,
      isPlaying: handle.isPlaying,
      lastUpdated: DateTime.now(),
    );
  }

  void saveVideoStateFromController(
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

  VideoState? getVideoState(String docID) {
    return _videoStates[docID];
  }

  void clearVideoState(String docID) {
    _videoStates.remove(docID);
  }

  void clearAllStates() {
    _videoStates.clear();
  }

  void cleanOldStates() {
    final now = DateTime.now();
    _videoStates.removeWhere((key, state) {
      return now.difference(state.lastUpdated).inMinutes > 5;
    });
  }

  Future<void> restoreVideoState(
    String docID,
    PlaybackHandle handle,
  ) async {
    final state = getVideoState(docID);
    if (state == null || !handle.isInitialized) return;

    if (state.position.inMilliseconds > 0) {
      await handle.seekTo(state.position);
    }
  }

  Future<void> restoreVideoStateFromController(
    String docID,
    VideoPlayerController controller,
  ) async {
    final state = getVideoState(docID);
    if (state == null || !controller.value.isInitialized) return;

    if (state.position.inMilliseconds > 0) {
      await controller.seekTo(state.position);
    }
  }

  void updatePosition(String docID, Duration position) {
    final state = _videoStates[docID];
    if (state != null) {
      _videoStates[docID] = VideoState(
        position: position,
        isPlaying: state.isPlaying,
        lastUpdated: DateTime.now(),
      );
    }
  }

  void registerPlaybackHandle(String docID, PlaybackHandle handle) {
    _allVideoControllers[docID] = handle;

    if (_allVideoControllers.length >
        VideoStateManager._maxTrackedControllers) {
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

  void registerVideoController(String docID, VideoPlayerController controller) {
    _allVideoControllers[docID] = LegacyPlaybackHandle(controller);
  }

  void unregisterVideoController(String docID) {
    _allVideoControllers.remove(docID);
    if (_currentPlayingDocID == docID) {
      _pendingPlayTimer?.cancel();
      _pendingPlayTimer = null;
      _currentPlayingDocID = null;
    }
  }

  void pauseAllExcept(String? allowedDocID) {
    for (final entry in _allVideoControllers.entries) {
      if (entry.key == allowedDocID) continue;

      try {
        final handle = entry.value;
        if (handle.isInitialized) {
          handle.pause();
          handle.setVolume(0.0);
        }
      } catch (_) {}
    }

    _currentPlayingDocID = allowedDocID;
  }

  void playOnlyThis(String docID) {
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

    pauseAllExcept(docID);

    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = Timer(VideoStateManager._playResumeDelay, () {
      if (requestSeq != _playRequestSeq) return;
      if (_currentPlayingDocID != docID) return;
      final handle = _allVideoControllers[docID];
      if (handle != null && handle.isInitialized && !handle.isPlaying) {
        handle.play();
      }
    });
  }

  void reassertOnlyThis(String docID) {
    if (_exclusiveMode && _exclusiveDocID != null && _exclusiveDocID != docID) {
      return;
    }

    final handle = _allVideoControllers[docID];
    if (handle == null || !handle.isInitialized) return;

    _playRequestSeq++;
    final int requestSeq = _playRequestSeq;
    pauseAllExcept(docID);
    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = Timer(VideoStateManager._playResumeDelay, () {
      if (requestSeq != _playRequestSeq) return;
      if (_currentPlayingDocID != docID) return;
      final currentHandle = _allVideoControllers[docID];
      if (currentHandle != null && currentHandle.isInitialized) {
        currentHandle.play();
      }
    });
  }

  void requestPlayVideo(String docID, PlaybackHandle handle) {
    _allVideoControllers[docID] = handle;
    pauseAllExcept(docID);
    _currentPlayingDocID = docID;
  }

  void requestPlayVideoFromController(
    String docID,
    VideoPlayerController controller,
  ) {
    requestPlayVideo(docID, LegacyPlaybackHandle(controller));
  }

  void requestStopVideo(String docID) {
    if (_currentPlayingDocID == docID) {
      _currentPlayingDocID = null;
    }
  }

  void pauseAllVideos({bool force = false}) {
    if (!force && _exclusiveMode) {
      if (_exclusiveDocID != null) {
        pauseAllExcept(_exclusiveDocID);
      }
      return;
    }
    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = null;
    _playRequestSeq++;
    pauseAllExcept(null);
    try {
      AudioFocusCoordinator.instance.pauseAllAudioPlayers();
    } catch (_) {}
  }

  void enterExclusiveMode(String docID) {
    _exclusiveMode = true;
    _exclusiveDocID = docID;
    playOnlyThis(docID);
  }

  void updateExclusiveModeDoc(String docID) {
    if (!_exclusiveMode) return;
    _exclusiveDocID = docID;
    playOnlyThis(docID);
  }

  void exitExclusiveMode() {
    _exclusiveMode = false;
    _exclusiveDocID = null;
  }

  Map<String, dynamic> debugSnapshot() {
    return <String, dynamic>{
      'currentPlayingDocID': _currentPlayingDocID ?? '',
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
