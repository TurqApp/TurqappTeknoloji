part of 'flood_listing_controller.dart';

extension FloodListingControllerRuntimePart on FloodListingController {
  void _scheduleFloodSegmentWarmup({int? preferredIndex}) {
    if (floods.isEmpty) return;
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;

    final focusIndex = (preferredIndex ?? resolveResumeCenteredIndex())
        .clamp(0, floods.length - 1);
    final windowCount =
        ReadBudgetRegistry.exploreFloodInitialBatch.clamp(1, floods.length);
    final endExclusive = (focusIndex + windowCount).clamp(0, floods.length);
    for (var i = focusIndex; i < endExclusive; i++) {
      final model = floods[i];
      if (!model.hasPlayableVideo) continue;
      try {
        prefetch.boostDoc(
          model.docID,
          readySegments: SegmentCacheRuntimeService.globalReadySegmentCount,
        );
      } catch (_) {}
    }
  }

  void _handleOnInit() {
    scrollController.addListener(_onScroll);
  }

  void _handleOnClose() {
    _visibilityDebounce?.cancel();
    _visibleFractions.clear();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
  }

  String floodInstanceTag(String docId) => 'flood_$docId';

  GlobalKey getFloodKey({required String docId}) {
    return _floodKeys.putIfAbsent(
      docId,
      () => GlobalObjectKey(floodInstanceTag(docId)),
    );
  }

  void _onScroll() {
    if (!scrollController.hasClients || floods.isEmpty) return;
    final position = scrollController.position;
    if (position.pixels <= 0 && _visibleFractions.isEmpty) {
      currentVisibleIndex.value = 0;
      capturePendingCenteredEntry(preferredIndex: 0);
      _scheduleFloodSegmentWarmup(preferredIndex: 0);
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
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
      currentVisibleIndex.value = modelIndex;
      capturePendingCenteredEntry(preferredIndex: modelIndex);
      _scheduleFloodSegmentWarmup(preferredIndex: modelIndex);
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
    _scheduleFloodSegmentWarmup(preferredIndex: nextIndex);
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
    _scheduleFloodSegmentWarmup(preferredIndex: target);
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
