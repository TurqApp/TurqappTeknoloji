part of 'video_state_manager.dart';

void _handleVideoStateManagerClose(VideoStateManager manager) {
  manager._pendingPlayTimer?.cancel();
  manager._pendingPlayTimer = null;
  manager._externalOnDemandFetchClaims.clear();
}

extension VideoStateManagerRuntimePart on VideoStateManager {
  String? get currentPlayingDocID => _currentPlayingDocID;
  String? get targetPlaybackDocID => _targetPlaybackDocID;

  void claimExternalOnDemandFetch(String docID) {
    final normalizedDocID = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalizedDocID == null || normalizedDocID.isEmpty) return;
    final currentCount = _externalOnDemandFetchClaims[normalizedDocID] ?? 0;
    _externalOnDemandFetchClaims[normalizedDocID] = currentCount + 1;
  }

  void releaseExternalOnDemandFetch(String docID) {
    final normalizedDocID = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalizedDocID == null || normalizedDocID.isEmpty) return;
    final currentCount = _externalOnDemandFetchClaims[normalizedDocID];
    if (currentCount == null) return;
    if (currentCount <= 1) {
      _externalOnDemandFetchClaims.remove(normalizedDocID);
      return;
    }
    _externalOnDemandFetchClaims[normalizedDocID] = currentCount - 1;
  }

  bool allowsOnDemandSegmentFetchFor(String? docID) {
    final requestedDocID = HlsSegmentPolicy.normalizeDocId(docID);
    if (requestedDocID == null || requestedDocID.isEmpty) {
      return false;
    }
    final activeOwnerDocID =
        HlsSegmentPolicy.normalizeDocId(_currentPlayingDocID);
    if (requestedDocID == activeOwnerDocID) return true;
    if (CacheNetworkPolicy.isOnCellular) {
      return _externalOnDemandFetchClaims.containsKey(requestedDocID) &&
          requestedDocID == activeOwnerDocID;
    }
    final targetOwnerDocID =
        HlsSegmentPolicy.normalizeDocId(_targetPlaybackDocID);
    if (requestedDocID == targetOwnerDocID) return true;
    return _externalOnDemandFetchClaims.containsKey(requestedDocID);
  }

  bool shouldKeepAudiblePlayback(
    String docID, {
    Duration grace = const Duration(milliseconds: 650),
  }) {
    if (_currentPlayingDocID == docID) return true;
    if (hasPendingPlayFor(docID)) return true;
    if (_targetPlaybackDocID != docID) return false;
    final updatedAt = _targetPlaybackUpdatedAt;
    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt) <= grace;
  }

  bool isPlaybackTargetActive(String docID) {
    if (_currentPlayingDocID != docID) return false;
    final handle = _allVideoControllers[docID];
    return handle != null && handle.isInitialized && handle.isPlaying;
  }

  bool canResumePlaybackFor(String docID) {
    if (_exclusiveMode && _exclusiveDocID != null && _exclusiveDocID != docID) {
      return false;
    }
    final handle = _allVideoControllers[docID];
    return handle != null && handle.isInitialized;
  }

  DateTime? activatePlaybackTargetIfReady(
    String docID, {
    required String? lastCommandDocId,
    required DateTime? lastCommandAt,
    Duration minInterval = const Duration(milliseconds: 180),
  }) {
    final pendingTimer = _pendingPlayTimer;
    if (_targetPlaybackDocID == docID &&
        pendingTimer != null &&
        pendingTimer.isActive) {
      return null;
    }
    final now = DateTime.now();
    final shouldIssueCommand = lastCommandDocId != docID ||
        lastCommandAt == null ||
        now.difference(lastCommandAt) > minInterval;
    if (!shouldIssueCommand) return null;
    if (_currentPlayingDocID == docID) {
      if (isPlaybackTargetActive(docID)) return null;
      playOnlyThis(docID);
      return now;
    }
    playOnlyThis(docID);
    return now;
  }

  DateTime? claimPlaybackTargetIfReady(
    String docID, {
    required String? lastCommandDocId,
    required DateTime? lastCommandAt,
    Duration minInterval = const Duration(milliseconds: 180),
  }) {
    if (_currentPlayingDocID == docID) return null;
    final now = DateTime.now();
    final shouldIssueCommand = lastCommandDocId != docID ||
        lastCommandAt == null ||
        now.difference(lastCommandAt) > minInterval;
    if (!shouldIssueCommand) return null;
    playOnlyThis(docID);
    return now;
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
    _targetPlaybackDocID = docID;
    _targetPlaybackUpdatedAt = DateTime.now();
    final handle = _allVideoControllers[docID];
    if (handle == null) return false;
    if (!handle.isInitialized) return false;
    _pendingPlayTimer?.cancel();
    _pendingPlayTimer = null;
    if (!handle.isPlaying) {
      if ((GetPlatform.isAndroid || GetPlatform.isIOS) &&
          docID.startsWith('feed:') &&
          handle is HLSAdapterPlaybackHandle) {
        final resumePosition = handle.position;
        if (resumePosition >= const Duration(milliseconds: 180)) {
          unawaited(handle.seekTo(resumePosition));
        }
      }
      _playbackExecutionService.resumeHandle(handle);
    }
    return true;
  }
}
