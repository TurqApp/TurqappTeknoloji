part of 'flood_listing_controller.dart';

extension FloodListingControllerRuntimePart on FloodListingController {
  static const int _floodPriorityBatchSize = 5;
  static const int _floodNextBatchPromotionTriggerOffset = 2;
  static const Duration _floodPriorityPlanTick = Duration(milliseconds: 900);
  static const int _floodPlayableLeadQueueCount = 3;
  static const int _floodPlayableTailQueueCount = 3;

  void _rebuildPlayableFloodQueueMetadata() {
    _playableRawIndices.clear();
    _playableQueueIndexByRawIndex.clear();
    var playableQueueIndex = 0;
    for (var rawIndex = 0; rawIndex < floods.length; rawIndex++) {
      final post = floods[rawIndex];
      if (!post.hasPlayableVideo) continue;
      _playableRawIndices.add(rawIndex);
      _playableQueueIndexByRawIndex[rawIndex] = playableQueueIndex;
      playableQueueIndex++;
    }
  }

  List<PostsModel> _playableFloodPosts() {
    if (_playableRawIndices.isEmpty) return const <PostsModel>[];
    return _playableRawIndices
        .where((rawIndex) => rawIndex >= 0 && rawIndex < floods.length)
        .map((rawIndex) => floods[rawIndex])
        .toList(growable: false);
  }

  int _playableFloodQueueIndexForRawIndex(int rawIndex) {
    if (_playableRawIndices.isEmpty) return -1;
    final exact = _playableQueueIndexByRawIndex[rawIndex];
    if (exact != null) return exact;
    if (rawIndex <= 0) return 0;
    for (var i = rawIndex - 1; i >= 0; i--) {
      final mapped = _playableQueueIndexByRawIndex[i];
      if (mapped != null) return mapped;
    }
    return 0;
  }

  List<int> _collectPlayableFloodIndicesByQueue({
    required int playableQueueStart,
    required int playableCount,
  }) {
    if (playableCount <= 0 || _playableRawIndices.isEmpty) return const <int>[];
    final safeStart = playableQueueStart.clamp(0, _playableRawIndices.length);
    if (safeStart >= _playableRawIndices.length) return const <int>[];
    final endExclusive =
        (safeStart + playableCount).clamp(0, _playableRawIndices.length);
    return _playableRawIndices.sublist(safeStart, endExclusive);
  }

  void _updateFloodPlaybackQueue(int focusedIndex) {
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;
    final playablePosts = _playableFloodPosts();
    if (playablePosts.isEmpty) return;
    final playableQueueIndex = _playableFloodQueueIndexForRawIndex(focusedIndex);
    if (playableQueueIndex < 0) return;
    final maxDocs =
        (playableQueueIndex +
                _floodPlayableLeadQueueCount +
                _floodPlayableTailQueueCount)
            .clamp(1, playablePosts.length);
    try {
      unawaited(
        prefetch.updateFeedQueueForPosts(
          playablePosts,
          playableQueueIndex,
          maxDocs: maxDocs,
        ),
      );
    } catch (_) {}
  }

  void _scheduleFloodSegmentWarmupForIndices(
    Iterable<int> indices, {
    required int readySegments,
  }) {
    if (floods.isEmpty) return;
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;
    for (final i in indices) {
      if (i < 0 || i >= floods.length) continue;
      final model = floods[i];
      if (!model.hasPlayableVideo) continue;
      try {
        prefetch.boostDoc(
          model.docID,
          readySegments: readySegments,
        );
      } catch (_) {}
    }
  }

  int _playableFloodCachedSegmentCount(int index) {
    if (index < 0 || index >= floods.length) return 0;
    final model = floods[index];
    if (!model.hasPlayableVideo) return 0;
    final entry = SegmentCacheManager.maybeFind()?.getEntry(model.docID);
    return entry?.cachedSegmentCount ?? 0;
  }

  bool _allPlayableFloodsReadyForSegments(int segmentCount) {
    if (segmentCount <= 0) return true;
    for (var i = 0; i < floods.length; i++) {
      final model = floods[i];
      if (!model.hasPlayableVideo) continue;
      if (_playableFloodCachedSegmentCount(i) < segmentCount) {
        return false;
      }
    }
    return true;
  }

  void _promoteNextFloodBatchForSecondSegmentSweepIfNeeded() {
    if (!_allPlayableFloodsReadyForSegments(1)) return;
    final playableCount = _playableRawIndices.length;
    if (playableCount == 0) return;

    for (var batchStart = 0;
        batchStart < playableCount;
        batchStart += _floodPriorityBatchSize) {
      final batchIndices = _collectPlayableFloodIndicesByQueue(
        playableQueueStart: batchStart,
        playableCount: _floodPriorityBatchSize,
      );
      final batchCount = batchIndices.length;
      if (batchCount <= 0) return;

      var batchNeedsSecondSegment = false;
      for (final rawIndex in batchIndices) {
        if (_playableFloodCachedSegmentCount(rawIndex) < 2) {
          batchNeedsSecondSegment = true;
          break;
        }
      }

      if (!batchNeedsSecondSegment) {
        continue;
      }

      if (_promotedSecondSegmentBatchStarts.add(batchStart)) {
        _scheduleFloodSegmentWarmupForIndices(
          batchIndices,
          readySegments: 2,
        );
      }
      return;
    }
  }

  void _startFloodPriorityPlanTicker() {
    _priorityPlanTimer?.cancel();
    _priorityPlanTimer = Timer.periodic(_floodPriorityPlanTick, (_) {
      _promoteNextFloodBatchForSecondSegmentSweepIfNeeded();
    });
  }

  void _updateFloodPrefetchPriorityContext(int focusedIndex) {
    if (floods.isEmpty) return;
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;
    final docIds = floods.map((post) => post.docID.trim()).toList(growable: false);
    if (docIds.isEmpty) return;
    final safeFocusedIndex = focusedIndex.clamp(0, docIds.length - 1);
    prefetch.updatePriorityWindowContext(docIds, safeFocusedIndex);
  }

  void _scheduleFloodSegmentWarmup({
    int? preferredIndex,
    int readySegments = 2,
    int? windowCount,
  }) {
    if (floods.isEmpty) return;
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;

    final focusIndex = (preferredIndex ?? resolveResumeCenteredIndex())
        .clamp(0, floods.length - 1);
    final resolvedWindowCount = (windowCount ?? floods.length).clamp(
      1,
      floods.length,
    );
    final endExclusive =
        (focusIndex + resolvedWindowCount).clamp(0, floods.length);
    for (var i = focusIndex; i < endExclusive; i++) {
      final model = floods[i];
      if (!model.hasPlayableVideo) continue;
      try {
        prefetch.boostDoc(
          model.docID,
          readySegments: readySegments,
        );
      } catch (_) {}
    }
  }

  void _resetFloodSegmentPriorityPlan() {
    _promotedSecondSegmentBatchStarts.clear();
  }

  void _scheduleInitialFloodSegmentPriorityPlan() {
    if (floods.isEmpty) return;
    _rebuildPlayableFloodQueueMetadata();
    _resetFloodSegmentPriorityPlan();
    _updateFloodPrefetchPriorityContext(0);
    _updateFloodPlaybackQueue(0);

    final initialPlayableIndices = _collectPlayableFloodIndicesByQueue(
      playableQueueStart: 0,
      playableCount: _floodPriorityBatchSize,
    );
    _scheduleFloodSegmentWarmupForIndices(
      initialPlayableIndices,
      readySegments: 2,
    );
    _promotedSecondSegmentBatchStarts.add(0);

    if (initialPlayableIndices.isEmpty) return;
    final remainingStart = initialPlayableIndices.length;
    if (remainingStart >= _playableRawIndices.length) return;
    _scheduleFloodSegmentWarmupForIndices(
      _collectPlayableFloodIndicesByQueue(
        playableQueueStart: remainingStart,
        playableCount: _playableRawIndices.length - remainingStart,
      ),
      readySegments: 1,
    );
  }

  void _promoteNextFloodSegmentBatchIfNeeded(int focusedIndex) {
    if (focusedIndex < 0 || focusedIndex >= floods.length) return;
    final focusedPlayableIndex = _playableFloodQueueIndexForRawIndex(focusedIndex);
    if (focusedPlayableIndex < 0) return;
    final currentBatchStart =
        (focusedPlayableIndex ~/ _floodPriorityBatchSize) *
            _floodPriorityBatchSize;
    final promotionThreshold =
        currentBatchStart + _floodNextBatchPromotionTriggerOffset;
    if (focusedPlayableIndex < promotionThreshold) return;

    final nextBatchStart = currentBatchStart + _floodPriorityBatchSize;
    if (nextBatchStart >= _playableRawIndices.length) return;
    if (!_promotedSecondSegmentBatchStarts.add(nextBatchStart)) return;

    final nextBatchIndices = _collectPlayableFloodIndicesByQueue(
      playableQueueStart: nextBatchStart,
      playableCount: _floodPriorityBatchSize,
    );
    if (nextBatchIndices.isEmpty) return;
    _scheduleFloodSegmentWarmupForIndices(
      nextBatchIndices,
      readySegments: 2,
    );
  }

  void _handleOnInit() {
    _startFloodPriorityPlanTicker();
    scrollController.addListener(_onScroll);
  }

  void _handleOnClose() {
    _priorityPlanTimer?.cancel();
    _visibilityDebounce?.cancel();
    _visibleFractions.clear();
    _playableRawIndices.clear();
    _playableQueueIndexByRawIndex.clear();
    _promotedSecondSegmentBatchStarts.clear();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
  }

  String floodInstanceTag(String docId) => 'flood_$docId';

  void _onScroll() {
    if (!scrollController.hasClients || floods.isEmpty) return;
    final position = scrollController.position;
    if (position.pixels <= 0 && _visibleFractions.isEmpty) {
      currentVisibleIndex.value = 0;
      capturePendingCenteredEntry(preferredIndex: 0);
      _scheduleInitialFloodSegmentPriorityPlan();
    }
  }

  bool _canAutoplayFloodPost(PostsModel post) => post.hasPlayableVideo;

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (modelIndex < 0 || modelIndex >= floods.length) return;
    final previousFraction = _visibleFractions[modelIndex];
    if (FeedPlaybackSelectionPolicy.shouldIgnoreVisibilityUpdate(
      previousFraction: previousFraction,
      visibleFraction: visibleFraction,
    )) {
      return;
    }

    if (visibleFraction <= 0.01) {
      _visibleFractions.remove(modelIndex);
      if (modelIndex != centeredIndex.value) {
        disposeAgendaContentController(floods[modelIndex].docID);
      }
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
      currentVisibleIndex.value = modelIndex;
      capturePendingCenteredEntry(preferredIndex: modelIndex);
      _updateFloodPrefetchPriorityContext(modelIndex);
      _updateFloodPlaybackQueue(modelIndex);
      _scheduleFloodSegmentWarmup(
        preferredIndex: modelIndex,
        readySegments: 2,
        windowCount: 1,
      );
      _promoteNextFloodSegmentBatchIfNeeded(modelIndex);
    }

    _visibilityDebounce?.cancel();
    _visibilityDebounce = Timer(
      FeedPlaybackSelectionPolicy.evaluationDebounceDuration,
      _evaluateCenteredPlayback,
    );
  }

  void _evaluateCenteredPlayback() {
    if (floods.isEmpty) {
      centeredIndex.value = -1;
      return;
    }

    final nextIndex = FeedPlaybackSelectionPolicy.resolveCenteredIndex(
      visibleFractions: _visibleFractions,
      currentIndex: centeredIndex.value,
      lastCenteredIndex: lastCenteredIndex,
      itemCount: floods.length,
      canAutoplayIndex: (index) => _canAutoplayFloodPost(floods[index]),
      stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
    );

    if (nextIndex < 0 || nextIndex >= floods.length) {
      centeredIndex.value = -1;
      return;
    }

    if (lastCenteredIndex != null &&
        lastCenteredIndex != nextIndex &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < floods.length) {
      final prevModel = floods[lastCenteredIndex!];
      disposeAgendaContentController(prevModel.docID);
    }

    centeredIndex.value = nextIndex;
    currentVisibleIndex.value = nextIndex;
    lastCenteredIndex = nextIndex;
    capturePendingCenteredEntry(preferredIndex: nextIndex);
    _updateFloodPrefetchPriorityContext(nextIndex);
    _updateFloodPlaybackQueue(nextIndex);
    _scheduleFloodSegmentWarmup(
      preferredIndex: nextIndex,
      readySegments: 2,
      windowCount: 1,
    );
    _promoteNextFloodSegmentBatchIfNeeded(nextIndex);
  }

  void disposeAgendaContentController(String docID) {
    final tag = floodInstanceTag(docID);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
      print("🎯 Disposed AgendaContentController");
    }
  }

  int resolveResumeCenteredIndex() {
    if (floods.isEmpty) return -1;
    final pendingDocId = _pendingCenteredDocId;
    if (pendingDocId != null && pendingDocId.isNotEmpty) {
      final mapped = floods.indexWhere((post) => post.docID == pendingDocId);
      if (mapped >= 0) return mapped;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < floods.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < floods.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void resumeCenteredPost() {
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= floods.length) return;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    lastCenteredIndex = target;
    capturePendingCenteredEntry(preferredIndex: target);
    _updateFloodPrefetchPriorityContext(target);
    _updateFloodPlaybackQueue(target);
    _scheduleFloodSegmentWarmup(
      preferredIndex: target,
      readySegments: 2,
      windowCount: 1,
    );
    _promoteNextFloodSegmentBatchIfNeeded(target);
  }

  void capturePendingCenteredEntry({int? preferredIndex, PostsModel? model}) {
    if (model != null) {
      final docId = model.docID.trim();
      _pendingCenteredDocId = docId.isEmpty ? null : docId;
      return;
    }
    final candidateIndex = preferredIndex ??
        (currentVisibleIndex.value >= 0
            ? currentVisibleIndex.value
            : lastCenteredIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= floods.length) {
      _pendingCenteredDocId = null;
      return;
    }
    final docId = floods[candidateIndex].docID.trim();
    _pendingCenteredDocId = docId.isEmpty ? null : docId;
  }
}
