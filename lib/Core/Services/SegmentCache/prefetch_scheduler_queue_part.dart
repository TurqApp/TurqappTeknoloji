part of 'prefetch_scheduler.dart';

extension PrefetchSchedulerQueuePart on PrefetchScheduler {
  void _resetWifiQuotaFillPlanState() {
    _quotaFillRemoteInFlight = false;
    _quotaFillRemoteHasMore = true;
    _quotaFillRemoteCursor = null;
    _quotaFillRemoteExhaustedUsageBytes = 0;
    _quotaFillRemoteExhaustedTargetBytes = 0;
  }

  void _markWifiQuotaFillExhausted(SegmentCacheManager cacheManager) {
    _quotaFillRemoteHasMore = false;
    _quotaFillRemoteExhaustedUsageBytes = cacheManager.totalTrackedUsageBytes;
    _quotaFillRemoteExhaustedTargetBytes = _wifiQuotaFillTargetBytes;
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
    final usageDropThreshold =
        ((targetBytes * 0.15).round()).clamp(32 * 1024 * 1024, 256 * 1024 * 1024);
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
    final safeCurrent = resolved.currentIndex.clamp(0, resolved.docIDs.length - 1);
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
    if (_hasReachedWifiQuotaFillTarget(cacheManager)) return;
    _resetWifiQuotaFillPlanIfNeeded(cacheManager);

    Future<void> seedFromLocalCandidates() async {
      final localCandidates = cacheManager.getQuotaFillCandidatePosts(
        limit: _prefetchSchedulerQuotaFillPlanningDocLimit,
      );
      if (localCandidates.isEmpty) return;
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
        _lastFeedBankDocIDs.length +
        _activeDocRefCounts.length;
    if (backlogCount >= _prefetchSchedulerQuotaFillLowWatermark) {
      return;
    }

    await seedFromLocalCandidates();

    final refreshedBacklogCount = _queue.length +
        _pendingFollowUpJobs.length +
        _lastFeedBankDocIDs.length +
        _activeDocRefCounts.length;
    if (refreshedBacklogCount >= _prefetchSchedulerQuotaFillLowWatermark) {
      return;
    }

    if (_quotaFillRemoteInFlight || !_quotaFillRemoteHasMore) return;
    _quotaFillRemoteInFlight = true;
    try {
      final page = await ExploreRepository.ensure().fetchVideoReadyPage(
        startAfter: _quotaFillRemoteCursor,
        pageLimit: _prefetchSchedulerQuotaFillRemotePageLimit,
      );
      _quotaFillRemoteCursor = page.lastDoc;
      _quotaFillRemoteHasMore = page.hasMore && page.lastDoc != null;
      if (!_quotaFillRemoteHasMore) {
        _markWifiQuotaFillExhausted(cacheManager);
      }
      if (page.items.isEmpty) return;

      cacheManager.cachePostCards(page.items);
      final remoteCandidates = cacheManager.getQuotaFillCandidatePosts(
        limit: _prefetchSchedulerQuotaFillPlanningDocLimit,
      );
      if (remoteCandidates.isEmpty) return;

      await _appendQuotaFillQueueForPosts(
        remoteCandidates,
        0,
        maxDocs: remoteCandidates.length,
      );
      for (final post in remoteCandidates.take(2)) {
        boostDoc(
          post.docID,
          readySegments: _prefetchSchedulerQuotaFillBoostReadySegments,
        );
      }
    } catch (e) {
      debugPrint('[Prefetch] Remote quota fill plan failed: $e');
    } finally {
      _quotaFillRemoteInFlight = false;
    }
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
      _queue.add(
        _PrefetchJob(
          focusedDocID,
          readySegments,
          -1,
          (1000000 + readySegments - (entry?.cachedSegmentCount ?? 0))
              .toDouble(),
        ),
      );
      _jobEnqueuedAt[focusedDocID] = DateTime.now();
      cacheManager.touchEntry(focusedDocID);
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
    seedFeedBankCandidates(posts, currentIndex: currentIndex);
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
    final prunedExisting = pruneSeenFeedBankDocIds(
      bankDocIds: _lastFeedBankDocIDs,
      posts: posts,
      currentIndex: currentIndex,
    );
    final incomingDocIds = buildFeedBankDocIds(
      posts: posts,
      currentIndex: currentIndex,
      maxDocs: maxDocs,
    );
    if (incomingDocIds.isNotEmpty) {
      final incomingDocIdSet = incomingDocIds.toSet();
      _getCacheManager()?.cachePostCards(
        posts.where((post) => incomingDocIdSet.contains(post.docID.trim())),
      );
    }
    _lastFeedBankDocIDs = mergeFeedBankDocIds(
      existingDocIds: prunedExisting,
      incomingDocIds: incomingDocIds,
      maxDocs: maxDocs,
    );
  }

  Future<void> updateQueue(List<String> docIDs, int currentIndex) async {
    final cacheManager = _getCacheManager();
    if (cacheManager == null) return;
    if (docIDs.isEmpty) return;
    final safeCurrent = currentIndex.clamp(0, docIDs.length - 1);
    final currentDocId = docIDs[safeCurrent];
    _lastFeedDocIDs = const <String>[];
    _lastFeedCurrentIndex = 0;
    _lastFeedReadyCount = 0;
    _lastFeedWindowCount = 0;
    _lastFeedReadyRatio = 0.0;
    updatePriorityWindowContext(docIDs, safeCurrent);

    _mobileSeedMode =
        _shouldEnableMobileSeedMode(docIDs: docIDs, cacheManager: cacheManager);

    if (!CacheNetworkPolicy.canPrefetch && !_mobileSeedMode) {
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
      final readySegments = _resolvedReadySegmentTarget(
        docID: docID,
        cacheManager: cacheManager,
      );

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

    if (_queueFocusedDocIfNeeded(cacheManager: cacheManager)) {
      return;
    }

    _queue.clear();
    _pendingFollowUpJobs.clear();
    _jobEnqueuedAt.clear();

    final safeCurrent = currentIndex.clamp(0, docIDs.length - 1);
    updatePriorityWindowContext(docIDs, safeCurrent);
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
      final readySegments = _resolvedReadySegmentTarget(
        docID: docID,
        cacheManager: cacheManager,
      );
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

    _appendFeedBankBatchJobs(
      cacheManager: cacheManager,
      currentDocId: docIDs[safeCurrent],
      currentIndex: safeCurrent,
      queued: queued,
      addBankJob: (docID, readySegments, priority, bankOffset) {
        final entry = cacheManager.getEntry(docID);
        final targetIndex = docIDs.length + bankOffset;
        _queue.add(_PrefetchJob(
          docID,
          readySegments,
          priority,
          _buildJobScore(
            currentIndex: safeCurrent,
            currentDocId: docIDs[safeCurrent],
            targetIndex: targetIndex,
            priority: priority,
            watchProgress: entry?.watchProgress ?? 0.0,
            cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
            totalSegmentCount: entry?.totalSegmentCount ?? 0,
          ),
        ));
        _jobEnqueuedAt[docID] = DateTime.now();
      },
    );

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

  void _appendFeedBankBatchJobs({
    required SegmentCacheManager cacheManager,
    required String currentDocId,
    required int currentIndex,
    required Set<String> queued,
    required void Function(
      String docID,
      int readySegments,
      int priority,
      int bankOffset,
    ) addBankJob,
  }) {
    if (_lastFeedBankDocIDs.isEmpty) return;

    final pendingBankDocIds = <String>[];
    for (final docID in _lastFeedBankDocIDs) {
      final trimmed = docID.trim();
      if (trimmed.isEmpty) continue;
      final entry = cacheManager.getEntry(trimmed);
      final cachedPost = entry?.cachedPostModel;
      if (!_isEligibleBankQueuePost(cachedPost)) {
        continue;
      }
      final targetSegments = _resolvedFeedBankReadySegments(
        docID: trimmed,
        cacheManager: cacheManager,
      );
      if ((entry?.cachedSegmentCount ?? 0) >= targetSegments) {
        continue;
      }
      pendingBankDocIds.add(trimmed);
    }
    if (pendingBankDocIds.isEmpty) return;

    final batchDocIds = pendingBankDocIds
        .take(_prefetchSchedulerFeedBankBatchSize)
        .toList(growable: false);
    final firstSegmentStage = <String>[];
    final secondSegmentStage = <String>[];
    for (final docID in batchDocIds) {
      final entry = cacheManager.getEntry(docID);
      final cachedSegments = entry?.cachedSegmentCount ?? 0;
      final targetSegments = _resolvedFeedBankReadySegments(
        docID: docID,
        cacheManager: cacheManager,
      );
      if (cachedSegments < 1) {
        firstSegmentStage.add(docID);
        continue;
      }
      if (targetSegments > 1 && cachedSegments < targetSegments) {
        secondSegmentStage.add(docID);
      }
    }

    final stageDocIds =
        firstSegmentStage.isNotEmpty ? firstSegmentStage : secondSegmentStage;
    if (stageDocIds.isEmpty) return;

    final stageReadySegments = firstSegmentStage.isNotEmpty ? 1 : 2;
    final stagePriority = firstSegmentStage.isNotEmpty ? 3 : 4;
    var bankOffset = 0;
    for (final docID in stageDocIds) {
      if (!queued.add(docID)) continue;
      addBankJob(docID, stageReadySegments, stagePriority, bankOffset);
      bankOffset++;
    }
  }

  bool _ensureFeedBankBatchQueuedIfNeeded(SegmentCacheManager cacheManager) {
    if (_lastFeedDocIDs.isEmpty || _lastFeedBankDocIDs.isEmpty) {
      return false;
    }
    if (_activeBankDownloads > 0) return false;
    if (_queue.any((job) => _isBankDocId(job.docID))) return false;

    final safeCurrent =
        _lastFeedCurrentIndex.clamp(0, _lastFeedDocIDs.length - 1);
    final queued = _queue.map((job) => job.docID).toSet()
      ..addAll(_activeBankDocIDs);
    final beforeCount = _queue.length;

    _appendFeedBankBatchJobs(
      cacheManager: cacheManager,
      currentDocId: _lastFeedDocIDs[safeCurrent],
      currentIndex: safeCurrent,
      queued: queued,
      addBankJob: (docID, readySegments, priority, bankOffset) {
        final entry = cacheManager.getEntry(docID);
        final targetIndex = _lastFeedDocIDs.length + bankOffset;
        _queue.add(_PrefetchJob(
          docID,
          readySegments,
          priority,
          _buildJobScore(
            currentIndex: safeCurrent,
            currentDocId: _lastFeedDocIDs[safeCurrent],
            targetIndex: targetIndex,
            priority: priority,
            watchProgress: entry?.watchProgress ?? 0.0,
            cachedSegmentCount: entry?.cachedSegmentCount ?? 0,
            totalSegmentCount: entry?.totalSegmentCount ?? 0,
          ),
        ));
        _jobEnqueuedAt[docID] = DateTime.now();
      },
    );

    if (_queue.length == beforeCount) return false;
    _queue.sort(_compareJobs);
    return true;
  }

  int _resolvedFeedBankReadySegments({
    required String docID,
    required SegmentCacheManager cacheManager,
  }) {
    final target = _resolvedReadySegmentTarget(
      docID: docID,
      cacheManager: cacheManager,
    );
    if (target <= 1) return 1;
    return 2;
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

    if (!CacheNetworkPolicy.canPrefetch && !_mobileSeedMode) {
      return;
    }

    _paused = false;

    final entry = cacheManager.getEntry(normalizedDocId);
    final resolvedReadySegments = _resolvedReadySegmentTarget(
      docID: normalizedDocId,
      cacheManager: cacheManager,
      fallback: readySegments,
    );
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

  bool _isEligibleBankQueuePost(PostsModel? post) {
    if (post == null) return false;
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
