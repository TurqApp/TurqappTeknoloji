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

    final safeCurrent = _lastFeedCurrentIndex.clamp(0, _lastFeedDocIDs.length - 1);
    final previousIndex = _lastFeedPreviousIndex.clamp(0, _lastFeedDocIDs.length - 1);
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
    if (enabled) {
      _processQueue();
    }
  }
}
