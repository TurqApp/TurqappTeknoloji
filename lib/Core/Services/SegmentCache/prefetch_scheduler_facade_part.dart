part of 'prefetch_scheduler.dart';

PrefetchScheduler? maybeFindPrefetchScheduler() =>
    Get.isRegistered<PrefetchScheduler>()
        ? Get.find<PrefetchScheduler>()
        : null;

PrefetchScheduler ensurePrefetchScheduler({bool permanent = false}) =>
    maybeFindPrefetchScheduler() ??
    Get.put(PrefetchScheduler(), permanent: permanent);

extension PrefetchSchedulerReadFacadePart on PrefetchScheduler {
  List<String> currentFeedDocIds() =>
      List<String>.from(_lastFeedDocIDs, growable: false);

  List<String> currentFeedSurfaceVideoDocIds() =>
      List<String>.from(_lastFeedSurfaceVideoDocIDs, growable: false);

  List<String> currentFeedBankDocIds() =>
      List<String>.from(_lastFeedBankDocIDs, growable: false);

  int queuePositionForDoc(String docID) {
    final normalized = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalized == null || normalized.isEmpty) return -1;
    return _queue.indexWhere((job) => job.docID == normalized);
  }

  bool isActivelyDownloadingDoc(String docID) {
    final normalized = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalized == null || normalized.isEmpty) return false;
    return (_activeDocRefCounts[normalized] ?? 0) > 0;
  }

  bool hasPendingPrefetchForDoc(String docID) {
    final normalized = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalized == null || normalized.isEmpty) return false;
    if (_pendingFollowUpJobs.containsKey(normalized)) return true;
    return _queue.any((job) => job.docID == normalized);
  }

  Map<String, dynamic>? describeTransferOwner(String docID) {
    final normalized = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalized == null || normalized.isEmpty) return null;

    final shortTier = classifyShortTransferDoc(normalized);
    final feedTier = classifyFeedTransferDoc(normalized);
    final inShortWindow = shortTier?['allowedSegmentWarm'] == true ||
        shortTier?['allowedCacheOnly'] == true;
    final inFeedWindow = feedTier?['allowedSegmentWarm'] == true ||
        feedTier?['allowedCacheOnly'] == true;
    final inFeedBank = _lastFeedBankDocIDs.contains(normalized);
    final pendingPrefetch = hasPendingPrefetchForDoc(normalized);
    final activeDownload = isActivelyDownloadingDoc(normalized);
    final sourceHint = _prefetchSourceForDoc(normalized) ?? 'unknown';

    String owner;
    if (inShortWindow) {
      owner = 'short';
    } else if (inFeedWindow || inFeedBank) {
      owner = 'feed';
    } else if (sourceHint == 'quota' &&
        _shouldAllowBackgroundQuotaFill &&
        (pendingPrefetch || activeDownload)) {
      owner = 'quota';
    } else {
      owner = 'unknown';
    }

    return <String, dynamic>{
      'owner': owner,
      'inShortWindow': inShortWindow,
      'inFeedWindow': inFeedWindow,
      'inFeedBank': inFeedBank,
      'pendingPrefetch': pendingPrefetch,
      'activeDownload': activeDownload,
      'hasActiveFeedPlaybackWindow': _hasActiveFeedPlaybackWindow,
      'hasActiveShortPlaybackWindow': _hasActiveShortPlaybackWindow,
      'sourceHint': sourceHint,
    };
  }

  Map<String, dynamic>? classifyTransferDoc(String docID) {
    final ownerInfo = describeTransferOwner(docID);
    final owner = (ownerInfo?['owner'] ?? 'unknown').toString();
    if (owner == 'short') {
      return classifyShortTransferDoc(docID);
    }
    if (owner == 'feed') {
      return classifyFeedTransferDoc(docID);
    }
    final shortTier = classifyShortTransferDoc(docID);
    if (shortTier != null &&
        shortTier['targetIndex'] != null &&
        shortTier['targetIndex'] != -1) {
      return shortTier;
    }
    return classifyFeedTransferDoc(docID) ?? shortTier;
  }

  Map<String, dynamic>? classifyFeedTransferDoc(String docID) {
    final normalized = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalized == null || normalized.isEmpty) return null;
    if (_lastFeedDocIDs.isEmpty) return null;
    final targetIndex = _lastFeedDocIDs.indexOf(normalized);
    if (targetIndex < 0) {
      return <String, dynamic>{
        'targetIndex': -1,
        'currentIndex': _lastFeedCurrentIndex,
        'distance': null,
        'tier': 'not_in_feed_window',
        'allowedSegmentWarm': false,
        'allowedCacheOnly': false,
      };
    }

    final safeCurrent =
        _lastFeedCurrentIndex.clamp(0, _lastFeedDocIDs.length - 1);
    final previousIndex =
        _lastFeedPreviousIndex.clamp(0, _lastFeedDocIDs.length - 1);
    final distance = targetIndex - safeCurrent;
    if (distance == 0) {
      return <String, dynamic>{
        'targetIndex': targetIndex,
        'currentIndex': safeCurrent,
        'distance': distance,
        'tier': 'visible',
        'allowedSegmentWarm': true,
        'allowedCacheOnly': true,
      };
    }

    final scrollingBackward = safeCurrent < previousIndex;
    final isMotionSide = scrollingBackward ? distance < 0 : distance > 0;
    final absDistance = distance.abs();
    final strongMotionLimit = _prefetchSchedulerFeedAheadCount;
    final strongOppositeLimit = _prefetchSchedulerFeedBehindCount;
    const int cacheOnlyOppositeLimit = 2;

    if (isMotionSide && absDistance <= strongMotionLimit) {
      return <String, dynamic>{
        'targetIndex': targetIndex,
        'currentIndex': safeCurrent,
        'distance': distance,
        'tier': 'motion_strong',
        'allowedSegmentWarm': true,
        'allowedCacheOnly': true,
      };
    }

    if (!isMotionSide && absDistance <= strongOppositeLimit) {
      return <String, dynamic>{
        'targetIndex': targetIndex,
        'currentIndex': safeCurrent,
        'distance': distance,
        'tier': 'opposite_strong',
        'allowedSegmentWarm': true,
        'allowedCacheOnly': true,
      };
    }

    if (!isMotionSide &&
        absDistance <= strongOppositeLimit + cacheOnlyOppositeLimit) {
      return <String, dynamic>{
        'targetIndex': targetIndex,
        'currentIndex': safeCurrent,
        'distance': distance,
        'tier': 'opposite_cache_only',
        'allowedSegmentWarm': false,
        'allowedCacheOnly': true,
      };
    }

    return <String, dynamic>{
      'targetIndex': targetIndex,
      'currentIndex': safeCurrent,
      'distance': distance,
      'tier': 'outside_window',
      'allowedSegmentWarm': false,
      'allowedCacheOnly': false,
    };
  }

  Map<String, dynamic>? classifyShortTransferDoc(String docID) {
    final normalized = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalized == null || normalized.isEmpty) return null;
    if (_lastShortDocIDs.isEmpty) return null;
    final targetIndex = _lastShortDocIDs.indexOf(normalized);
    if (targetIndex < 0) {
      return <String, dynamic>{
        'targetIndex': -1,
        'currentIndex': _lastShortCurrentIndex,
        'distance': null,
        'tier': 'not_in_short_window',
        'allowedSegmentWarm': false,
        'allowedCacheOnly': false,
      };
    }

    final safeCurrent =
        _lastShortCurrentIndex.clamp(0, _lastShortDocIDs.length - 1);
    final distance = targetIndex - safeCurrent;
    if (distance == 0) {
      return <String, dynamic>{
        'targetIndex': targetIndex,
        'currentIndex': safeCurrent,
        'distance': distance,
        'tier': 'visible',
        'allowedSegmentWarm': true,
        'allowedCacheOnly': true,
      };
    }

    final maxAhead = math.max(_breadthCount, _depthCount - 1);
    if (distance > 0 && distance <= maxAhead) {
      return <String, dynamic>{
        'targetIndex': targetIndex,
        'currentIndex': safeCurrent,
        'distance': distance,
        'tier': 'ahead_prefetch',
        'allowedSegmentWarm': true,
        'allowedCacheOnly': true,
      };
    }

    return <String, dynamic>{
      'targetIndex': targetIndex,
      'currentIndex': safeCurrent,
      'distance': distance,
      'tier': 'outside_window',
      'allowedSegmentWarm': false,
      'allowedCacheOnly': false,
    };
  }

  Future<void> ensureWifiQuotaFillPlan() => _ensureWifiQuotaFillPlan();

  void resetWifiQuotaFillPlan() => _resetWifiQuotaFillPlanState();

  bool get automaticQuotaFillEnabled => _automaticQuotaFillEnabled;

  void setAutomaticQuotaFillEnabled(
    bool enabled, {
    String reason = 'manual',
  }) {
    if (_automaticQuotaFillEnabled == enabled) return;
    _state.automaticQuotaFillEnabled = enabled;
    if (!enabled) {
      _resetWifiQuotaFillPlanState();
    }
    debugPrint(
      '[Prefetch] automaticQuotaFillEnabled=$enabled reason=$reason',
    );
    _publishPrefetchHealthIfNeeded(force: true);
  }
}
