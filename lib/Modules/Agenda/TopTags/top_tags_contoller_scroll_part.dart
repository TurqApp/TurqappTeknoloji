part of 'top_tags_contoller_library.dart';

extension TopTagsControllerScrollPart on _TopTagsControllerBase {
  int _resolveRestoreIndex() {
    if (agendaList.isEmpty) return -1;
    final pendingDocId = _pendingCenteredDocId;
    if (pendingDocId != null && pendingDocId.isNotEmpty) {
      final mapped =
          agendaList.indexWhere((post) => post.docID == pendingDocId);
      if (mapped >= 0) return mapped;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < agendaList.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < agendaList.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void _restoreCenteredPost() {
    final target = _resolveRestoreIndex();
    if (target < 0 || target >= agendaList.length) return;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    lastCenteredIndex = target;
    _pendingCenteredDocId = null;
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
        candidateIndex >= agendaList.length) {
      _pendingCenteredDocId = null;
      return;
    }
    final docId = agendaList[candidateIndex].docID.trim();
    _pendingCenteredDocId = docId.isEmpty ? null : docId;
  }

  void resumeCenteredPost() {
    _restoreCenteredPost();
  }

  void _onScroll() {
    final currentOffset = scrollController.offset;
    final signedScrollDelta = currentOffset - _lastObservedOffset;
    final scrollDelta = signedScrollDelta.abs();
    if (scrollDelta > 1.0) {
      if (_scrollStartedAt == null) {
        _scrollStartedAt = DateTime.now();
        _scrollStartOffset = currentOffset;
        _scrollDirection = 0;
      }
      _scrollDirection =
          FeedPlaybackSelectionPolicy.resolveStableScrollDirection(
        currentDirection: _scrollDirection,
        scrollStartOffset: _scrollStartOffset,
        currentOffset: currentOffset,
        signedScrollDelta: signedScrollDelta,
      );
      _scrollSettleDebounce?.cancel();
      _scrollSettleDebounce = Timer(
        FeedPlaybackSelectionPolicy.scrollSettleReassertDuration,
        () {
          _scrollStartedAt = null;
          _scrollStartOffset = 0.0;
          _scrollDirection = 0;
        },
      );
    }

    navbar.updateVisibilityFromPrimaryScroll(
      source: 'top_tags',
      offset: currentOffset,
    );
    _lastObservedOffset = currentOffset;

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      fetchAgendaBigData();
    }
    if (_visibleFractions.isNotEmpty) return;

    const itemHeight = 500.0;
    final newIndex =
        ((scrollController.offset + Get.height / 2) ~/ itemHeight) - 1;

    if (newIndex != currentVisibleIndex.value &&
        newIndex >= 0 &&
        newIndex < agendaList.length) {
      if (lastCenteredIndex != null && lastCenteredIndex != newIndex) {
        final prevModel = agendaList[lastCenteredIndex!];
        disposeAgendaContentController(prevModel.docID);
      }
      currentVisibleIndex.value = newIndex;
      centeredIndex.value = newIndex;
      lastCenteredIndex = newIndex;
      capturePendingCenteredEntry(preferredIndex: newIndex);
    }
  }

  void updateVisibleIndexByPosition(
    ScrollMetrics metrics,
    BuildContext context,
  ) {
    if (agendaList.isEmpty) return;
    if (_visibleFractions.isNotEmpty) return;
    if (metrics.pixels <= 0) {
      centeredIndex.value = 0;
      currentVisibleIndex.value = 0;
      lastCenteredIndex = 0;
      capturePendingCenteredEntry(preferredIndex: 0);
      return;
    }
    final estimatedItemExtent = (metrics.viewportDimension * 0.74).clamp(
      320.0,
      680.0,
    );
    final nextIndex = (((metrics.pixels + metrics.viewportDimension * 0.25) /
                estimatedItemExtent)
            .floor())
        .clamp(0, agendaList.length - 1);
    centeredIndex.value = nextIndex;
    currentVisibleIndex.value = nextIndex;
    lastCenteredIndex = nextIndex;
    capturePendingCenteredEntry(preferredIndex: nextIndex);
  }

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (modelIndex < 0 || modelIndex >= agendaList.length) return;
    final previousFraction = _visibleFractions[modelIndex];
    if (FeedPlaybackSelectionPolicy.shouldIgnoreVisibilityUpdate(
      previousFraction: previousFraction,
      visibleFraction: visibleFraction,
    )) {
      return;
    }

    if (visibleFraction <= 0.01) {
      _visibleFractions.remove(modelIndex);
      _visibleUpdatedAt.remove(modelIndex);
      if (modelIndex != centeredIndex.value) {
        disposeAgendaContentController(agendaList[modelIndex].docID);
      }
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
      _visibleUpdatedAt[modelIndex] = DateTime.now();
      currentVisibleIndex.value = modelIndex;
      capturePendingCenteredEntry(preferredIndex: modelIndex);
    }

    _visibilityDebounce?.cancel();
    _visibilityDebounce = Timer(
      FeedPlaybackSelectionPolicy.evaluationDebounceDuration,
      _evaluateCenteredPlayback,
    );
  }

  void _evaluateCenteredPlayback() {
    if (agendaList.isEmpty || _visibleFractions.isEmpty) return;
    final current = centeredIndex.value;
    final directionalDecision =
        FeedPlaybackSelectionPolicy.resolveDirectionalScrollDecision(
      isScrollActive: true,
      visibleFractions: _visibleFractions,
      currentIndex: current,
      scrollDirection: _scrollDirection,
      itemCount: agendaList.length,
      canAutoplayIndex: (index) =>
          index >= 0 &&
          index < agendaList.length &&
          agendaList[index].hasPlayableVideo,
      isPlaybackTargetCurrent: (_) => false,
    );
    final decision = directionalDecision.hasTarget
        ? FeedPlaybackDecision(
            action: directionalDecision.action,
            targetIndex: directionalDecision.targetIndex,
            shouldEnsurePlayback: directionalDecision.shouldEnsurePlayback,
            shouldPauseAll: false,
          )
        : FeedPlaybackSelectionPolicy.resolvePlaybackDecision(
            visibleFractions: _visibleFractions,
            visibleUpdatedAt: _visibleUpdatedAt,
            currentIndex: current,
            lastCenteredIndex: lastCenteredIndex,
            itemCount: agendaList.length,
            canAutoplayIndex: (index) =>
                index >= 0 &&
                index < agendaList.length &&
                agendaList[index].hasPlayableVideo,
            isPlaybackTargetCurrent: (_) => false,
            playbackKeyForIndex: (index) => agendaInstanceTag(
              agendaList[index].docID,
            ),
            lastCommandAt: null,
            lastCommandDocId: null,
            stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
            supportsSwitchRetention: false,
            preferDominantVisibleIndexWhenNonPlayable: true,
          );
    if (!decision.hasTarget) {
      centeredIndex.value = -1;
      currentVisibleIndex.value = -1;
      return;
    }
    final targetIndex = decision.targetIndex;
    if (targetIndex < 0 || targetIndex >= agendaList.length) return;
    if (lastCenteredIndex != null &&
        lastCenteredIndex != targetIndex &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < agendaList.length) {
      disposeAgendaContentController(agendaList[lastCenteredIndex!].docID);
    }
    centeredIndex.value = targetIndex;
    currentVisibleIndex.value = targetIndex;
    lastCenteredIndex = targetIndex;
    capturePendingCenteredEntry(preferredIndex: targetIndex);
  }

  void disposeAgendaContentController(String docID) {
    final tag = agendaInstanceTag(docID);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
      print('Disposed AgendaContentController');
    }
  }
}
