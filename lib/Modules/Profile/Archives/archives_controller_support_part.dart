part of 'archives_controller.dart';

extension ArchiveControllerSupportPart on ArchiveController {
  String agendaInstanceTag(String docId) => 'archives_$docId';

  GlobalKey getAgendaKey({required String docId}) {
    return _agendaKeys.putIfAbsent(
      docId,
      () => GlobalObjectKey(agendaInstanceTag(docId)),
    );
  }

  void disposeAgendaContentController(String docID) {
    final tag = agendaInstanceTag(docID);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
    }
  }

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (modelIndex < 0 || modelIndex >= list.length) return;
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
        disposeAgendaContentController(list[modelIndex].docID);
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
    if (list.isEmpty || _visibleFractions.isEmpty) return;
    final current = centeredIndex.value;
    final directionalDecision =
        FeedPlaybackSelectionPolicy.resolveDirectionalScrollDecision(
      isScrollActive: true,
      visibleFractions: _visibleFractions,
      currentIndex: current,
      scrollDirection: _scrollDirection,
      itemCount: list.length,
      canAutoplayIndex: (index) =>
          index >= 0 && index < list.length && list[index].hasPlayableVideo,
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
            itemCount: list.length,
            canAutoplayIndex: (index) =>
                index >= 0 &&
                index < list.length &&
                list[index].hasPlayableVideo,
            isPlaybackTargetCurrent: (_) => false,
            playbackKeyForIndex: (index) => agendaInstanceTag(
              list[index].docID,
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
    if (targetIndex < 0 || targetIndex >= list.length) return;
    if (lastCenteredIndex != null &&
        lastCenteredIndex != targetIndex &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < list.length) {
      disposeAgendaContentController(list[lastCenteredIndex!].docID);
    }
    centeredIndex.value = targetIndex;
    currentVisibleIndex.value = targetIndex;
    lastCenteredIndex = targetIndex;
    capturePendingCenteredEntry(preferredIndex: targetIndex);
  }

  void removeArchivedPost(String docId) {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) return;
    final removedIndex = list.indexWhere(
      (post) => post.docID.trim() == normalizedDocId,
    );
    if (removedIndex < 0) return;

    disposeAgendaContentController(normalizedDocId);
    list.removeAt(removedIndex);

    if (list.isEmpty) {
      centeredIndex.value = -1;
      currentVisibleIndex.value = -1;
      lastCenteredIndex = null;
      _pendingCenteredDocId = null;
      return;
    }

    final nextIndex = removedIndex.clamp(0, list.length - 1);
    centeredIndex.value = nextIndex;
    currentVisibleIndex.value = nextIndex;
    lastCenteredIndex = nextIndex;
    capturePendingCenteredEntry(preferredIndex: nextIndex);
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
        candidateIndex >= list.length) {
      _pendingCenteredDocId = null;
      return;
    }
    final docId = list[candidateIndex].docID.trim();
    _pendingCenteredDocId = docId.isEmpty ? null : docId;
  }
}
