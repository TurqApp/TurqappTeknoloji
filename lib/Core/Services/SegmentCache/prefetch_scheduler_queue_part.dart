part of 'prefetch_scheduler.dart';

extension PrefetchSchedulerQueuePart on PrefetchScheduler {
  bool _shouldEnqueuePrefetchJob(int readySegments) => readySegments > 0;

  void _resetWifiQuotaFillPlanState() {
    _quotaFillRemoteInFlight = false;
    _quotaFillRemoteHasMore = true;
    _quotaFillRemoteCursor = null;
    _quotaFillRemoteExhaustedUsageBytes = 0;
    _quotaFillRemoteExhaustedTargetBytes = 0;
  }

  void _resetWifiQuotaFillPlanIfNeeded(SegmentCacheManager cacheManager) {
    if (_quotaFillRemoteHasMore) return;
    final targetBytes = _wifiQuotaFillTargetBytes;
    if (targetBytes <= 0) {
      _resetWifiQuotaFillPlanState();
      return;
    }
    if (_quotaFillRemoteExhaustedTargetBytes != targetBytes) {
      _resetWifiQuotaFillPlanState();
      return;
    }
    final usageDropThreshold = ((targetBytes * 0.15).round())
        .clamp(32 * 1024 * 1024, 256 * 1024 * 1024);
    final currentUsageBytes = cacheManager.totalTrackedUsageBytes;
    if (currentUsageBytes + usageDropThreshold <
        _quotaFillRemoteExhaustedUsageBytes) {
      _resetWifiQuotaFillPlanState();
    }
  }

  void _appendQuotaFillJobs(
    _ResolvedPrefetchQueue resolved,
    SegmentCacheManager cacheManager,
  ) {
    if (resolved.docIDs.isEmpty) return;
    final safeCurrent =
        resolved.currentIndex.clamp(0, resolved.docIDs.length - 1);
    final currentDocId = resolved.docIDs[safeCurrent];
    final queuedDocIds = _queue.map((job) => job.docID).toSet()
      ..addAll(_pendingFollowUpJobs.keys)
      ..addAll(_activeDocRefCounts.keys);

    var addedJobs = 0;
    for (var index = 0; index < resolved.docIDs.length; index++) {
      final docID = resolved.docIDs[index];
      if (!queuedDocIds.add(docID)) continue;
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) continue;
      final readySegments = _resolvedReadySegmentTarget(
        docID: docID,
        cacheManager: cacheManager,
      );
      if (!_shouldEnqueuePrefetchJob(readySegments)) continue;
      _queue.add(
        _PrefetchJob(
          docID,
          readySegments,
          2,
          _buildJobScore(
            currentIndex: safeCurrent,
            currentDocId: currentDocId,
            targetIndex: index,
            priority: 2,
            watchProgress: entry?.watchProgress ?? 0.0,
            cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
            totalSegmentCount: entry?.totalSegmentCount ?? 0,
          ),
          source: 'quota',
        ),
      );
      _jobEnqueuedAt[docID] = DateTime.now();
      addedJobs++;
    }

    if (addedJobs <= 0) return;
    _paused = false;
    _queue.sort(_compareJobs);
    _publishPrefetchHealthIfNeeded();
  }

  Future<void> _appendQuotaFillQueueForPosts(
    List<PostsModel> posts,
    int currentIndex, {
    int? maxDocs,
  }) async {
    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;
    final resolved = _resolveOfflineCandidateQueue(
      posts,
      currentIndex: currentIndex,
      maxDocs: maxDocs,
    );
    if (resolved == null) return;
    cacheManager.cachePostCards(resolved.posts);
    _appendQuotaFillJobs(resolved, cacheManager);
  }

  Future<void> _ensureWifiQuotaFillPlan() async {
    final cacheManager = _getCacheManager();
    if (cacheManager == null || _paused) return;
    if (!_isOnWiFi || _mobileSeedMode) return;
    if (!_shouldAllowBackgroundQuotaFill) {
      _abortStalePrefetchActivity(reason: 'quota_plan_background_gate');
      return;
    }
    if (_hasReachedWifiQuotaFillTarget(cacheManager)) return;
    if (_quotaFillRemoteInFlight) {
      debugPrint('[ShortQuotaFill] status=skip reason=plan_inflight');
      return;
    }
    _resetWifiQuotaFillPlanIfNeeded(cacheManager);
    _quotaFillRemoteInFlight = true;

    try {
      bool stopIfBackgroundGateClosed(String reason) {
        if (_shouldAllowBackgroundQuotaFill) return false;
        _abortStalePrefetchActivity(reason: reason);
        debugPrint('[ShortQuotaFill] status=skip reason=$reason');
        return true;
      }

      debugPrint(
        '[ShortQuotaFill] status=plan_start enabled=$_automaticQuotaFillEnabled '
        'wifi=$_isOnWiFi backlog=${_queue.length + _pendingFollowUpJobs.length + _activeDocRefCounts.length} '
        'targetBytes=$_wifiQuotaFillTargetBytes usageBytes=${cacheManager.totalTrackedUsageBytes}',
      );

      Future<void> seedFromLocalCandidates() async {
        final localCandidates = _selectShortQuotaFillCandidates(
          cacheManager.getQuotaFillCandidatePosts(
            limit: _prefetchSchedulerQuotaFillPlanningBatchSize,
          ),
          limit: _prefetchSchedulerQuotaFillPlanningBatchSize,
        );
        debugPrint(
          '[ShortQuotaFill] status=local_seed count=${localCandidates.length}',
        );
        if (localCandidates.isEmpty) return;
        for (final post in localCandidates) {
          cacheManager.markReservedForShort(post.docID);
        }
        await _appendQuotaFillQueueForPosts(
          localCandidates,
          0,
          maxDocs: localCandidates.length,
        );
        for (final post in localCandidates.take(2)) {
          boostDoc(
            post.docID,
            readySegments: _prefetchSchedulerQuotaFillBoostReadySegments,
          );
        }
      }

      final backlogCount = _queue.length +
          _pendingFollowUpJobs.length +
          _activeDocRefCounts.length;
      if (backlogCount >= _prefetchSchedulerQuotaFillLowWatermark) {
        return;
      }

      await seedFromLocalCandidates();
      if (stopIfBackgroundGateClosed('plan_interrupted_by_playback')) return;

      final refreshedBacklogCount = _queue.length +
          _pendingFollowUpJobs.length +
          _activeDocRefCounts.length;
      if (refreshedBacklogCount >= _prefetchSchedulerQuotaFillLowWatermark) {
        return;
      }
      debugPrint('[ShortQuotaFill] status=manifest_only_no_remote_seed');
    } catch (e) {
      debugPrint('[Prefetch] Quota fill plan failed: $e');
    } finally {
      _quotaFillRemoteInFlight = false;
    }
  }

  List<PostsModel> _selectShortQuotaFillCandidates(
    List<PostsModel> posts, {
    required int limit,
  }) {
    if (posts.isEmpty || limit <= 0) {
      return const <PostsModel>[];
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final excludedFeedDocIds = _lastFeedSurfaceVideoDocIDs
        .map((docId) => docId.trim())
        .toSet()
      ..removeWhere((docId) => docId.isEmpty);

    final seen = <String>{};
    final filtered = posts.where((post) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seen.add(docId)) return false;
      if (excludedFeedDocIds.contains(docId)) return false;
      if (!post.hasPlayableVideo) return false;
      if (post.isFloodSeriesContent) return false;
      if (post.arsiv || post.deletedPost == true || post.gizlendi == true) {
        return false;
      }
      if (post.timeStamp <= 0 || post.timeStamp > nowMs) return false;
      if (post.aspectRatio.toDouble() >
          _prefetchSchedulerShortLandscapeAspectThreshold) {
        return false;
      }
      return true;
    }).toList(growable: false)
      ..sort((left, right) {
        final timeCompare = right.timeStamp.compareTo(left.timeStamp);
        if (timeCompare != 0) return timeCompare;
        return right.docID.trim().compareTo(left.docID.trim());
      });

    if (filtered.isEmpty) {
      return const <PostsModel>[];
    }

    debugPrint(
      '[ShortQuotaFill] status=filtered_candidates count=${filtered.length}',
    );
    return filtered.take(limit).toList(growable: false);
  }

  void updatePriorityWindowContext(List<String> docIDs, int currentIndex) {
    if (docIDs.isEmpty) {
      _lastPriorityDocIDs = const <String>[];
      _lastPriorityCurrentIndex = 0;
      return;
    }
    final safeCurrent = currentIndex.clamp(0, docIDs.length - 1);
    _lastPriorityDocIDs = List<String>.from(docIDs);
    _lastPriorityCurrentIndex = safeCurrent;
  }

  void focusDoc(String? docID) {
    final normalized = HlsSegmentPolicy.normalizeDocId(docID);
    _restrictToFocusedDoc = true;
    _focusedDocID =
        normalized == null || normalized.isEmpty ? null : normalized;
    pause();
  }

  void unfocusDoc() {
    if (!_restrictToFocusedDoc && _focusedDocID == null) return;
    _restrictToFocusedDoc = false;
    _focusedDocID = null;
    _publishPrefetchHealthIfNeeded(force: true);
  }

  bool _queueFocusedDocIfNeeded({
    required SegmentCacheManager cacheManager,
  }) {
    if (!_restrictToFocusedDoc) return false;

    final focusedDocID = _focusedDocID;

    _queue.clear();
    _pendingFollowUpJobs.clear();
    _jobEnqueuedAt.clear();

    if (focusedDocID == null || focusedDocID.isEmpty) {
      _publishPrefetchHealthIfNeeded();
      return true;
    }

    final entry = cacheManager.getEntry(focusedDocID);
    if (entry == null || !entry.isFullyCached) {
      final readySegments = _resolvedReadySegmentTarget(
        docID: focusedDocID,
        cacheManager: cacheManager,
      );
      if (_shouldEnqueuePrefetchJob(readySegments)) {
        _queue.add(
          _PrefetchJob(
            focusedDocID,
            readySegments,
            -1,
            (1000000 + readySegments - (entry?.cachedSegmentCount ?? 0))
                .toDouble(),
            source: 'short',
          ),
        );
        _jobEnqueuedAt[focusedDocID] = DateTime.now();
        cacheManager.touchEntry(focusedDocID);
      }
    }

    _paused = false;
    _queue.sort(_compareJobs);
    _publishPrefetchHealthIfNeeded();
    _processQueue();
    return true;
  }

  Future<void> updateQueueForPosts(
    List<PostsModel> posts,
    int currentIndex, {
    int? maxDocs,
  }) async {
    final resolved = _resolveOfflineCandidateQueue(
      posts,
      currentIndex: currentIndex,
      maxDocs: maxDocs,
    );
    if (resolved == null) return;
    _getCacheManager()?.cachePostCards(resolved.posts);
    await updateQueue(resolved.docIDs, resolved.currentIndex);
  }

  Future<void> updateFeedQueueForPosts(
    List<PostsModel> posts,
    int currentIndex, {
    int? maxDocs,
  }) async {
    final seenSurfaceDocIds = <String>{};
    _lastFeedSurfaceVideoDocIDs = posts
        .map((post) => post.docID.trim())
        .where((docId) => docId.isNotEmpty && seenSurfaceDocIds.add(docId))
        .toList(growable: false);
    _lastFeedBankDocIDs = const <String>[];
    final resolved = _resolveOfflineCandidateQueue(
      posts,
      currentIndex: currentIndex,
      maxDocs: maxDocs,
    );
    if (resolved == null) return;
    _getCacheManager()?.cachePostCards(resolved.posts);
    await updateFeedQueue(resolved.docIDs, resolved.currentIndex);
  }

  void seedFeedBankCandidates(
    List<PostsModel> posts, {
    required int currentIndex,
    int? maxDocs,
  }) {
    _lastFeedBankDocIDs = const <String>[];
    return;
  }

  Future<void> updateQueue(List<String> docIDs, int currentIndex) async {
    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;
    if (docIDs.isEmpty) return;
    final safeCurrent = currentIndex.clamp(0, docIDs.length - 1);
    final currentDocId = docIDs[safeCurrent];
    updatePriorityWindowContext(docIDs, safeCurrent);
    _lastShortDocIDs = List<String>.from(docIDs);
    _lastShortCurrentIndex = safeCurrent;
    _abortStalePrefetchActivity(reason: 'short_window_update');

    _mobileSeedMode =
        _shouldEnableMobileSeedMode(docIDs: docIDs, cacheManager: cacheManager);

    if (!_isOnWiFi || !CacheNetworkPolicy.canPrefetch) {
      pause();
      return;
    }

    if (_queueFocusedDocIfNeeded(cacheManager: cacheManager)) {
      return;
    }

    _queue.clear();
    _pendingFollowUpJobs.clear();
    _jobEnqueuedAt.clear();

    for (var i = 1; i <= _breadthCount; i++) {
      final idx = safeCurrent + i;
      if (idx >= docIDs.length) break;
      final docID = docIDs[idx];

      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) continue;
      final readySegments = _resolvedReadySegmentTarget(
        docID: docID,
        cacheManager: cacheManager,
      );
      if (!_shouldEnqueuePrefetchJob(readySegments)) continue;

      _queue.add(_PrefetchJob(
        docID,
        readySegments,
        0,
        _buildJobScore(
          currentIndex: safeCurrent,
          currentDocId: currentDocId,
          targetIndex: idx,
          priority: 0,
          watchProgress: entry?.watchProgress ?? 0.0,
          cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
          totalSegmentCount: entry?.totalSegmentCount ?? 0,
        ),
        source: 'short',
      ));
      _jobEnqueuedAt[docID] = DateTime.now();
    }

    if (safeCurrent >= 0 && safeCurrent < docIDs.length) {
      final docID = docIDs[safeCurrent];
      final entry = cacheManager.getEntry(docID);
      if (entry == null || !entry.isFullyCached) {
        final readySegments = _resolvedReadySegmentTarget(
          docID: docID,
          cacheManager: cacheManager,
        );
        if (_shouldEnqueuePrefetchJob(readySegments)) {
          _queue.add(_PrefetchJob(
            docID,
            readySegments,
            1,
            _buildJobScore(
              currentIndex: safeCurrent,
              currentDocId: currentDocId,
              targetIndex: safeCurrent,
              priority: 1,
              watchProgress: entry?.watchProgress ?? 0.0,
              cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
              totalSegmentCount: entry?.totalSegmentCount ?? 0,
            ),
            source: 'short',
          ));
          _jobEnqueuedAt[docID] = DateTime.now();
        }
      }
    }

    for (var i = 1; i <= _depthCount - 1; i++) {
      final idx = safeCurrent + i;
      if (idx >= docIDs.length) break;
      final docID = docIDs[idx];
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) continue;
      final readySegments = _resolvedReadySegmentTarget(
        docID: docID,
        cacheManager: cacheManager,
      );
      if (!_shouldEnqueuePrefetchJob(readySegments)) continue;

      _queue.add(_PrefetchJob(
        docID,
        readySegments,
        2,
        _buildJobScore(
          currentIndex: safeCurrent,
          currentDocId: currentDocId,
          targetIndex: idx,
          priority: 2,
          watchProgress: entry?.watchProgress ?? 0.0,
          cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
          totalSegmentCount: entry?.totalSegmentCount ?? 0,
        ),
        source: 'short',
      ));
      _jobEnqueuedAt[docID] = DateTime.now();
    }

    for (var i = 1; i <= _prefetchSchedulerFeedRetainBehindCount; i++) {
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

    if (!_isOnWiFi || !CacheNetworkPolicy.canPrefetch) {
      pause();
      return;
    }
    if (docIDs.isEmpty) return;

    if (_queueFocusedDocIfNeeded(cacheManager: cacheManager)) {
      return;
    }

    _queue.clear();
    _pendingFollowUpJobs.clear();
    _jobEnqueuedAt.clear();

    final safeCurrent = currentIndex.clamp(0, docIDs.length - 1);
    final previousIndex = _lastFeedCurrentIndex.clamp(0, docIDs.length - 1);
    final directionalWindow = resolveDirectionalFeedWindowCounts(
      previousIndex: previousIndex,
      currentIndex: safeCurrent,
    );
    final priorityWindow = resolveFeedPriorityWindowContext(
      docIDs: docIDs,
      currentIndex: safeCurrent,
    );
    updatePriorityWindowContext(
      priorityWindow.docIDs,
      priorityWindow.currentIndex,
    );
    _lastFeedDocIDs = List<String>.from(docIDs);
    _lastFeedPreviousIndex = previousIndex;
    _lastFeedCurrentIndex = safeCurrent;
    _abortStalePrefetchActivity(reason: 'feed_window_update');
    final behindStart = (safeCurrent - directionalWindow.behindCount)
        .clamp(0, docIDs.length - 1);
    final aheadEnd = (safeCurrent + directionalWindow.aheadCount)
        .clamp(0, docIDs.length - 1);

    final queued = <String>{};
    void addJob(int index, int priority) {
      if (index < 0 || index >= docIDs.length) return;
      final docID = docIDs[index];
      if (!queued.add(docID)) return;
      final entry = cacheManager.getEntry(docID);
      if (entry != null && entry.isFullyCached) return;
      final readySegmentFallback = resolveFeedWindowReadySegments(
        currentIndex: safeCurrent,
        targetIndex: index,
      );
      final readySegments = _resolvedReadySegmentTarget(
        docID: docID,
        cacheManager: cacheManager,
        fallback: readySegmentFallback,
      );
      if (!_shouldEnqueuePrefetchJob(readySegments)) return;
      _queue.add(_PrefetchJob(
        docID,
        readySegments,
        priority,
        _buildJobScore(
          currentIndex: safeCurrent,
          currentDocId: docIDs[safeCurrent],
          targetIndex: index,
          priority: priority,
          watchProgress: entry?.watchProgress ?? 0.0,
          cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
          totalSegmentCount: entry?.totalSegmentCount ?? 0,
        ),
        source: 'feed',
      ));
      _jobEnqueuedAt[docID] = DateTime.now();
    }

    for (int i = safeCurrent; i <= aheadEnd; i++) {
      final distanceAhead = i - safeCurrent;
      final priority =
          distanceAhead < _prefetchSchedulerFeedHardBoostCount ? 0 : 1;
      addJob(i, priority);
    }

    for (int i = safeCurrent - 1; i >= behindStart; i--) {
      addJob(i, 1);
    }

    _queue.sort(_compareJobs);
    _updateFeedReadyRatio();
    _publishPrefetchHealthIfNeeded();
    _processQueue();
  }

  void boostDoc(
    String docID, {
    int readySegments = _prefetchSchedulerTargetReadySegments,
  }) {
    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;
    final normalizedDocId = HlsSegmentPolicy.normalizeDocId(docID);
    if (normalizedDocId == null || normalizedDocId.isEmpty) return;
    if (_restrictToFocusedDoc &&
        _focusedDocID != null &&
        _focusedDocID != normalizedDocId) {
      return;
    }

    _mobileSeedMode = _shouldEnableMobileSeedMode(
      docIDs:
          _lastFeedDocIDs.isEmpty ? <String>[normalizedDocId] : _lastFeedDocIDs,
      cacheManager: cacheManager,
    );

    if (!_isOnWiFi || !CacheNetworkPolicy.canPrefetch) {
      return;
    }

    _paused = false;

    final entry = cacheManager.getEntry(normalizedDocId);
    final resolvedReadySegments = _resolvedReadySegmentTarget(
      docID: normalizedDocId,
      cacheManager: cacheManager,
      fallback: readySegments,
    );
    if (!_shouldEnqueuePrefetchJob(resolvedReadySegments)) {
      _queue.removeWhere((job) => job.docID == normalizedDocId);
      _pendingFollowUpJobs.remove(normalizedDocId);
      _jobEnqueuedAt.remove(normalizedDocId);
      _publishPrefetchHealthIfNeeded();
      return;
    }
    if (entry != null && entry.cachedSegmentCount >= resolvedReadySegments) {
      return;
    }

    _queue.removeWhere((job) => job.docID == normalizedDocId);
    _pendingFollowUpJobs.remove(normalizedDocId);
    _queue.add(
      _PrefetchJob(
        normalizedDocId,
        resolvedReadySegments,
        -1,
        (1000000 + resolvedReadySegments - (entry?.cachedSegmentCount ?? 0))
            .toDouble(),
        source: 'feed',
      ),
    );
    _jobEnqueuedAt[normalizedDocId] = DateTime.now();
    cacheManager.touchEntry(normalizedDocId);
    _queue.sort(_compareJobs);
    _publishPrefetchHealthIfNeeded();
    _processQueue();
  }

  int _compareJobs(_PrefetchJob a, _PrefetchJob b) {
    final scoreCompare = b.sortScore.compareTo(a.sortScore);
    if (scoreCompare != 0) return scoreCompare;
    return a.priority.compareTo(b.priority);
  }

  _ResolvedPrefetchQueue? _resolveOfflineCandidateQueue(
    List<PostsModel> posts, {
    required int currentIndex,
    int? maxDocs,
  }) {
    if (posts.isEmpty) return null;
    final safeCurrent = currentIndex.clamp(0, posts.length - 1);
    final currentDocId = posts[safeCurrent].docID.trim();
    final seenDocIds = <String>{};
    final eligible = posts.where((post) {
      final docId = post.docID.trim();
      if (docId.isEmpty || !seenDocIds.add(docId)) return false;
      return _isEligibleOfflineCandidatePost(post);
    }).toList(growable: false);
    if (eligible.isEmpty) return null;

    final limited =
        maxDocs == null || maxDocs <= 0 || eligible.length <= maxDocs
            ? eligible
            : eligible.take(maxDocs).toList(growable: false);
    if (limited.isEmpty) return null;

    final remapped = limited.indexWhere((post) => post.docID == currentDocId);
    return _ResolvedPrefetchQueue(
      docIDs: limited.map((post) => post.docID).toList(growable: false),
      posts: limited,
      currentIndex: remapped < 0 ? 0 : remapped,
    );
  }

  bool _isEligibleOfflineCandidatePost(PostsModel post) {
    if (!post.hasPlayableVideo) return false;
    return normalizeRozetValue(post.rozet).isNotEmpty;
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
    if (!_isOnWiFi) return false;
    if (!_restrictToFocusedDoc) return false;
    final focusedDocId = _focusedDocID?.trim() ?? '';
    if (focusedDocId.isEmpty) return false;
    final policy = maybeFindPlaybackPolicyEngine();
    if (policy == null) return false;
    return policy
        .snapshot(
          visibleReadyCount: _lastFeedReadyCount,
          visibleWindowCount: _lastFeedWindowCount,
        )
        .enableMobileSeedMode;
  }

  int _resolvedReadySegmentTarget({
    required String docID,
    required SegmentCacheManager cacheManager,
    int fallback = _prefetchSchedulerTargetReadySegments,
  }) {
    final post = cacheManager.getEntry(docID)?.cachedPostModel;
    return resolvePrefetchReadySegmentsForPost(
      post,
      fallbackReadySegments: fallback,
    );
  }

  Iterable<String> _pickMobileSeedSegments({
    required String docID,
    required List<String> segmentUris,
    required String variantDir,
    required SegmentCacheManager cacheManager,
  }) {
    if (segmentUris.isEmpty) return const <String>[];

    final ordered = <String>[];
    for (final uri in segmentUris) {
      final key = '$variantDir$uri'.replaceFirst('Posts/$docID/hls/', '');
      if (cacheManager.getSegmentFile(docID, key) != null) {
        continue;
      }
      ordered.add(uri);
    }
    return ordered;
  }

  Iterable<String> _pickWatchedPrioritySegments({
    required String docID,
    required List<String> segmentUris,
    required String variantDir,
    required SegmentCacheManager cacheManager,
    required double watchProgress,
    int? desiredReadySegments,
  }) {
    if (segmentUris.isEmpty) return const <String>[];

    final total = segmentUris.length;
    final watchedSeg = _estimateWatchedSegment(
      watchProgress: watchProgress,
      totalSegments: total,
    );
    final targetReadySegments =
        (desiredReadySegments ?? (watchedSeg + 1)).clamp(1, total);

    final ordered = <String>[];
    final seen = <int>{};
    for (int seg = 1; seg <= targetReadySegments; seg++) {
      final idx = seg - 1;
      if (!seen.add(idx)) continue;
      final uri = segmentUris[idx];
      final key = '$variantDir$uri'.replaceFirst('Posts/$docID/hls/', '');
      if (cacheManager.getSegmentFile(docID, key) == null) {
        ordered.add(uri);
      }
    }

    if (ordered.isNotEmpty) return ordered;

    for (int idx = targetReadySegments; idx < total; idx++) {
      final uri = segmentUris[idx];
      final key = '$variantDir$uri'.replaceFirst('Posts/$docID/hls/', '');
      if (cacheManager.getSegmentFile(docID, key) == null) {
        ordered.add(uri);
      }
    }
    return ordered;
  }

  Iterable<String> _pickQuotaFillPrioritySegments({
    required String docID,
    required List<String> segmentUris,
    required String variantDir,
    required SegmentCacheManager cacheManager,
    required int desiredReadySegments,
  }) {
    if (segmentUris.isEmpty) return const <String>[];

    final cachedIndices = <int>{};
    for (var index = 0; index < segmentUris.length; index++) {
      final uri = segmentUris[index];
      final key = '$variantDir$uri'.replaceFirst('Posts/$docID/hls/', '');
      if (cacheManager.getSegmentFile(docID, key) != null) {
        cachedIndices.add(index);
      }
    }

    final orderedIndices = buildQuotaFillSegmentOrder(
      totalSegments: segmentUris.length,
      desiredReadySegments: desiredReadySegments,
      cachedSegmentIndices: cachedIndices,
    );
    return orderedIndices.map((index) => segmentUris[index]);
  }

  int _estimateWatchedSegment({
    required double watchProgress,
    required int totalSegments,
  }) {
    return HlsSegmentPolicy.estimateCurrentSegmentFromProgress(
      progress: watchProgress,
      totalSegments: totalSegments,
    );
  }
}
