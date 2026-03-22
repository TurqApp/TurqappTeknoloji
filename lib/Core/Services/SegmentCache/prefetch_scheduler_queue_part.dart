part of 'prefetch_scheduler.dart';

extension PrefetchSchedulerQueuePart on PrefetchScheduler {
  Future<void> updateQueue(List<String> docIDs, int currentIndex) async {
    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;
    if (docIDs.isEmpty) return;
    final safeCurrent = currentIndex.clamp(0, docIDs.length - 1);
    final currentDocId = docIDs[safeCurrent];

    _mobileSeedMode =
        _shouldEnableMobileSeedMode(docIDs: docIDs, cacheManager: cacheManager);

    if (!CacheNetworkPolicy.canPrefetch && !_mobileSeedMode) {
      pause();
      return;
    }

    _queue.clear();
    _jobEnqueuedAt.clear();

    for (var i = 1; i <= _breadthCount; i++) {
      final idx = safeCurrent + i;
      if (idx >= docIDs.length) break;
      final docID = docIDs[idx];

      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) continue;

      _queue.add(_PrefetchJob(
        docID: docID,
        maxSegments: PrefetchScheduler._targetReadySegments,
        priority: 0,
        sortScore: _buildJobScore(
          currentIndex: safeCurrent,
          currentDocId: currentDocId,
          targetIndex: idx,
          priority: 0,
          watchProgress: entry?.watchProgress ?? 0.0,
          cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
          totalSegmentCount: entry?.totalSegmentCount ?? 0,
        ),
      ));
      _jobEnqueuedAt[docID] = DateTime.now();
    }

    if (safeCurrent >= 0 && safeCurrent < docIDs.length) {
      final docID = docIDs[safeCurrent];
      final entry = cacheManager.getEntry(docID);
      if (entry == null || !entry.isFullyCached) {
        _queue.add(_PrefetchJob(
          docID: docID,
          maxSegments: PrefetchScheduler._targetReadySegments,
          priority: 1,
          sortScore: _buildJobScore(
            currentIndex: safeCurrent,
            currentDocId: currentDocId,
            targetIndex: safeCurrent,
            priority: 1,
            watchProgress: entry?.watchProgress ?? 0.0,
            cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
            totalSegmentCount: entry?.totalSegmentCount ?? 0,
          ),
        ));
        _jobEnqueuedAt[docID] = DateTime.now();
      }
    }

    for (var i = 1; i <= _depthCount - 1; i++) {
      final idx = safeCurrent + i;
      if (idx >= docIDs.length) break;
      final docID = docIDs[idx];
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) continue;

      _queue.add(_PrefetchJob(
        docID: docID,
        maxSegments: PrefetchScheduler._targetReadySegments,
        priority: 2,
        sortScore: _buildJobScore(
          currentIndex: safeCurrent,
          currentDocId: currentDocId,
          targetIndex: idx,
          priority: 2,
          watchProgress: entry?.watchProgress ?? 0.0,
          cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
          totalSegmentCount: entry?.totalSegmentCount ?? 0,
        ),
      ));
      _jobEnqueuedAt[docID] = DateTime.now();
    }

    for (var i = 1; i <= 5; i++) {
      final idx = safeCurrent - i;
      if (idx < 0) break;
      if (idx < docIDs.length) {
        cacheManager.touchEntry(docIDs[idx]);
      }
    }

    _queue.sort(_compareJobs);
    _publishPrefetchHealthIfNeeded();
    _processQueue();
  }

  Future<void> updateFeedQueue(List<String> docIDs, int currentIndex) async {
    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;

    _mobileSeedMode =
        _shouldEnableMobileSeedMode(docIDs: docIDs, cacheManager: cacheManager);

    if (!CacheNetworkPolicy.canPrefetch && !_mobileSeedMode) {
      pause();
      return;
    }
    if (docIDs.isEmpty) return;

    _queue.clear();
    _jobEnqueuedAt.clear();

    final safeCurrent = currentIndex.clamp(0, docIDs.length - 1);
    _lastFeedDocIDs = List<String>.from(docIDs);
    _lastFeedCurrentIndex = safeCurrent;
    final aroundStart = (safeCurrent - 5).clamp(0, docIDs.length - 1);
    final aroundEnd = (safeCurrent + 5).clamp(0, docIDs.length - 1);
    final initialEnd = (safeCurrent + _feedFullWindow - 1).clamp(
      0,
      docIDs.length - 1,
    );
    final prepEnd = (initialEnd + _feedPrepWindow).clamp(0, docIDs.length - 1);

    final queued = <String>{};
    void addJob(int index, int priority) {
      if (index < 0 || index >= docIDs.length) return;
      final docID = docIDs[index];
      if (!queued.add(docID)) return;
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) return;
      _queue.add(_PrefetchJob(
        docID: docID,
        maxSegments: PrefetchScheduler._targetReadySegments,
        priority: priority,
        sortScore: _buildJobScore(
          currentIndex: safeCurrent,
          currentDocId: docIDs[safeCurrent],
          targetIndex: index,
          priority: priority,
          watchProgress: entry?.watchProgress ?? 0.0,
          cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
          totalSegmentCount: entry?.totalSegmentCount ?? 0,
        ),
      ));
      _jobEnqueuedAt[docID] = DateTime.now();
    }

    for (int i = safeCurrent; i <= initialEnd; i++) {
      addJob(i, 0);
    }

    for (int i = aroundStart; i <= aroundEnd; i++) {
      addJob(i, 0);
    }

    for (int i = initialEnd + 1; i <= prepEnd; i++) {
      addJob(i, 1);
    }

    for (var i = 1; i <= 5; i++) {
      final idx = safeCurrent - i;
      if (idx < 0) break;
      if (idx < docIDs.length) {
        cacheManager.touchEntry(docIDs[idx]);
      }
    }

    _queue.sort(_compareJobs);
    _updateFeedReadyRatio();
    _publishPrefetchHealthIfNeeded();
    _processQueue();
  }

  int _compareJobs(_PrefetchJob a, _PrefetchJob b) {
    final scoreCompare = b.sortScore.compareTo(a.sortScore);
    if (scoreCompare != 0) return scoreCompare;
    return a.priority.compareTo(b.priority);
  }

  double _buildJobScore({
    required int currentIndex,
    required String currentDocId,
    required int targetIndex,
    required int priority,
    required double watchProgress,
    required int cachedSegmentCount,
    required int totalSegmentCount,
  }) {
    final session = VideoTelemetryService.instance.activeSessionSnapshot(
      currentDocId,
    );
    return PrefetchScoringEngine.score(
      PrefetchScoreContext(
        basePriority: priority,
        currentIndex: currentIndex,
        targetIndex: targetIndex,
        isOnWiFi: _isOnWiFi,
        mobileSeedMode: _mobileSeedMode,
        feedReadyRatio: _lastFeedReadyRatio,
        watchProgress: watchProgress,
        cachedSegmentCount: cachedSegmentCount,
        totalSegmentCount: totalSegmentCount,
        sessionWatchTimeSeconds: session?.watchTimeSeconds ?? 0.0,
        sessionCompletionRate: session?.completionRate ?? 0.0,
        sessionRebufferRatio: session?.rebufferRatio ?? 0.0,
        sessionHasFirstFrame: session?.hasFirstFrame ?? false,
        sessionIsAudible: session?.isAudible ?? false,
        sessionHasStableFocus: session?.hasStableFocus ?? false,
      ),
    );
  }

  bool _shouldEnableMobileSeedMode({
    required List<String> docIDs,
    required SegmentCacheManager cacheManager,
  }) {
    final policy = PlaybackPolicyEngine.maybeFind();
    if (policy == null) return false;
    return policy
        .snapshot(
          visibleReadyCount: _lastFeedReadyCount,
          visibleWindowCount: _lastFeedWindowCount,
        )
        .enableMobileSeedMode;
  }

  Iterable<String> _pickMobileSeedSegments({
    required String docID,
    required List<String> segmentUris,
    required String variantDir,
    required SegmentCacheManager cacheManager,
  }) {
    if (segmentUris.isEmpty) return const <String>[];

    final ordered = <String>[];
    final seen = <int>{};
    final total = segmentUris.length;

    for (int n = 1; n <= total; n++) {
      for (final seg in <int>[n, n + 3]) {
        if (seg > total) continue;
        final idx = seg - 1;
        if (!seen.add(idx)) continue;
        final uri = segmentUris[idx];
        final key = '$variantDir$uri'.replaceFirst('Posts/$docID/hls/', '');
        if (cacheManager.getSegmentFile(docID, key) == null) {
          ordered.add(uri);
        }
      }
    }
    return ordered;
  }

  Iterable<String> _pickWatchedPrioritySegments({
    required String docID,
    required List<String> segmentUris,
    required String variantDir,
    required SegmentCacheManager cacheManager,
    required double watchProgress,
  }) {
    if (segmentUris.isEmpty) return const <String>[];

    final total = segmentUris.length;
    final watchedSeg = _estimateWatchedSegment(
      watchProgress: watchProgress,
      totalSegments: total,
    );

    final baseTarget = watchedSeg <= 2 ? 3 : watchedSeg + 1;

    final ordered = <String>[];
    final seen = <int>{};
    for (int seg = baseTarget; seg <= total; seg++) {
      final idx = seg - 1;
      if (!seen.add(idx)) continue;
      final uri = segmentUris[idx];
      final key = '$variantDir$uri'.replaceFirst('Posts/$docID/hls/', '');
      if (cacheManager.getSegmentFile(docID, key) == null) {
        ordered.add(uri);
      }
    }

    if (ordered.isNotEmpty) return ordered;

    for (int idx = 0; idx < total; idx++) {
      final uri = segmentUris[idx];
      final key = '$variantDir$uri'.replaceFirst('Posts/$docID/hls/', '');
      if (cacheManager.getSegmentFile(docID, key) == null) {
        ordered.add(uri);
      }
    }
    return ordered;
  }

  int _estimateWatchedSegment({
    required double watchProgress,
    required int totalSegments,
  }) {
    final p = watchProgress.clamp(0.0, 1.0);
    final raw = (p * totalSegments).floor();
    return raw.clamp(1, totalSegments);
  }
}
