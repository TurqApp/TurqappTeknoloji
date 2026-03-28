part of 'video_state_manager.dart';

void _handleVideoStateManagerClose(VideoStateManager manager) {
  manager._pendingPlayTimer?.cancel();
  manager._pendingPlayTimer = null;
}

extension VideoStateManagerRuntimePart on VideoStateManager {
  String? get currentPlayingDocID => _currentPlayingDocID;

  bool canResumePlaybackFor(String docID) {
    if (_exclusiveMode && _exclusiveDocID != null && _exclusiveDocID != docID) {
      return false;
    }
    final handle = _allVideoControllers[docID];
    return handle != null && handle.isInitialized;
  }

  bool hasPendingPlayFor(String docID) {
    final timer = _pendingPlayTimer;
    return timer != null && timer.isActive && _currentPlayingDocID == docID;
  }

  bool resumeCurrentPlaybackIfReady(String docID) {
    if (_exclusiveMode && _exclusiveDocID != null && _exclusiveDocID != docID) {
      return false;
    }
    if (_currentPlayingDocID != docID) return false;
    final handle = _allVideoControllers[docID];
    if (handle == null || !handle.isInitialized) return false;
    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = null;
    if (!handle.isPlaying) {
      handle.play();
    }
    return true;
  }
}
