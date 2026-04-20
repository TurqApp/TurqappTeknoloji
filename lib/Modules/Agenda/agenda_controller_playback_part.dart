part of 'agenda_controller.dart';

extension AgendaControllerPlaybackPart on AgendaController {
  bool _retainVisibleCurrentFeedOwner({
    required double stopThreshold,
  }) {
    if (!GetPlatform.isIOS) return false;
    if (_qaScrollStartedAt != null) {
      return false;
    }
    final currentPlayingDocId =
        VideoStateManager.instance.currentPlayingDocID?.trim() ?? '';
    if (!currentPlayingDocId.startsWith('feed:')) return false;
    final feedDocId = currentPlayingDocId.substring('feed:'.length);
    if (feedDocId.isEmpty) return false;
    final ownerIndex = agendaList.indexWhere((post) => post.docID == feedDocId);
    if (ownerIndex < 0 || ownerIndex >= agendaList.length) return false;
    if (!_canAutoplayVideoPost(agendaList[ownerIndex])) return false;
    final ownerFraction = _visibleFractions[ownerIndex] ?? 0.0;
    if (ownerFraction < stopThreshold) return false;
    final centeredChanged = centeredIndex.value != ownerIndex;
    if (centeredChanged) {
      centeredIndex.value = ownerIndex;
    }
    lastCenteredIndex = ownerIndex;
    if (!centeredChanged && !_isPlaybackTargetCurrent(ownerIndex)) {
      _ensureFeedPlaybackForIndex(ownerIndex);
    }
    _trackPlaybackWindow();
    return true;
  }

  bool _shouldRetainStartupPlaybackTarget({
    required int current,
    required double stopThreshold,
  }) {
    if (!GetPlatform.isIOS) return false;
    if (_qaScrollStartedAt != null) {
      return false;
    }
    if (current < 0 || current >= agendaList.length) return false;
    if (!_canAutoplayVideoPost(agendaList[current])) return false;
    if (_lastPlaybackCommandAt == null) return false;
    // iOS cold-start layout can rebalance visible fractions for a few frames
    // before the user actually scrolls. Releasing the startup target early
    // causes 0->2->3 handoffs and sequential player spin-up across cards.
    final currentFraction = _visibleFractions[current] ?? 0.0;
    final startupRetentionThreshold =
        stopThreshold < 0.55 ? 0.55 : stopThreshold;
    return currentFraction >= startupRetentionThreshold;
  }

  void _performOnPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (modelIndex < 0 || modelIndex >= agendaList.length) return;
    if (playbackSuspended.value || !isPrimaryFeedRouteVisible) {
      _visibleFractions.remove(modelIndex);
      _visibleUpdatedAt.remove(modelIndex);
      if (centeredIndex.value == modelIndex) {
        centeredIndex.value = -1;
      }
      _lastPlaybackWindowSignature = null;
      _trackPlaybackWindow();
      return;
    }
    final prev = _visibleFractions[modelIndex];

    if (FeedPlaybackSelectionPolicy.shouldIgnoreVisibilityUpdate(
      previousFraction: prev,
      visibleFraction: visibleFraction,
    )) {
      return;
    }

    if (visibleFraction <= 0.01) {
      _visibleFractions.remove(modelIndex);
      _visibleUpdatedAt.remove(modelIndex);
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
      _visibleUpdatedAt[modelIndex] = DateTime.now();
    }

    _scheduleVisibilityEvaluation(
      playThreshold: FeedPlaybackSelectionPolicy.playThreshold,
      stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
    );
  }

  void _performScheduleVisibilityEvaluation({
    required double playThreshold,
    required double stopThreshold,
  }) {
    _visibilityDebounce?.cancel();
    _visibilityDebounce = Timer(
      FeedPlaybackSelectionPolicy.evaluationDebounceDuration,
      () => _evaluateCenteredPlayback(
        playThreshold: playThreshold,
        stopThreshold: stopThreshold,
      ),
    );
  }

  void _performEvaluateCenteredPlayback({
    required double playThreshold,
    required double stopThreshold,
  }) {
    if (_retainVisibleCurrentFeedOwner(stopThreshold: stopThreshold)) {
      return;
    }
    if (_canRetainStartupPlaybackLock) {
      final lockedDocId = _startupLockedFeedDocId?.trim() ?? '';
      final lockedIndex =
          agendaList.indexWhere((post) => post.docID == lockedDocId);
      if (lockedIndex >= 0 &&
          lockedIndex < agendaList.length &&
          _canAutoplayVideoPost(agendaList[lockedIndex])) {
        final centeredChanged = centeredIndex.value != lockedIndex;
        if (centeredChanged) {
          centeredIndex.value = lockedIndex;
        }
        lastCenteredIndex = lockedIndex;
        if (!centeredChanged && !_isPlaybackTargetCurrent(lockedIndex)) {
          _ensureFeedPlaybackForIndex(lockedIndex);
        }
        _trackPlaybackWindow();
        return;
      }
    }
    final current = centeredIndex.value;
    if (_shouldRetainStartupPlaybackTarget(
      current: current,
      stopThreshold: stopThreshold,
    )) {
      lastCenteredIndex = current;
      _trackPlaybackWindow();
      return;
    }
    if (current >= 0 && current < agendaList.length) {
      final currentDocId = agendaList[current].docID;
      final currentPlaybackKey = _feedPlaybackHandleKeyForDoc(currentDocId);
      final currentFraction = _visibleFractions[current] ?? 0.0;
      if (FeedPlaybackSelectionPolicy.shouldRetainRecentlyActivatedTarget(
        lastCommandAt: _lastPlaybackCommandAt,
        lastCommandDocId: _lastPlaybackCommandDocId,
        currentDocId: currentPlaybackKey,
        isCurrentTargetActive: _isPlaybackTargetCurrent(current),
        currentFraction: currentFraction,
        stopThreshold: stopThreshold,
      )) {
        lastCenteredIndex = current;
        _trackPlaybackWindow();
        return;
      }
    }
    final targetIndex = FeedPlaybackSelectionPolicy.resolveCenteredIndex(
      visibleFractions: _visibleFractions,
      currentIndex: current,
      lastCenteredIndex: lastCenteredIndex,
      itemCount: agendaList.length,
      canAutoplayIndex: (index) => _canAutoplayVideoPost(agendaList[index]),
      stopThreshold: stopThreshold,
      preferDominantVisibleIndexWhenNonPlayable: true,
    );

    if (targetIndex >= 0 && targetIndex < agendaList.length) {
      final now = DateTime.now();
      if (GetPlatform.isIOS &&
          current >= 0 &&
          current < agendaList.length &&
          current != targetIndex &&
          _isPlaybackTargetCurrent(current)) {
        final currentFraction = _visibleFractions[current] ?? 0.0;
        final targetUpdatedAt = _visibleUpdatedAt[targetIndex];
        final targetIsFresh = targetUpdatedAt != null &&
            now.difference(targetUpdatedAt) <
                FeedPlaybackSelectionPolicy.scrollSettleReassertDuration;
        if (currentFraction >=
                FeedPlaybackSelectionPolicy.switchRetentionThreshold &&
            targetIsFresh) {
          lastCenteredIndex = current;
          _trackPlaybackWindow();
          return;
        }
      }
      final centeredChanged = centeredIndex.value != targetIndex;
      if (centeredChanged) {
        centeredIndex.value = targetIndex;
        if (GetPlatform.isIOS) {
          _ensureFeedPlaybackForIndex(targetIndex);
        }
      }
      lastCenteredIndex = targetIndex;
    } else {
      centeredIndex.value = -1;
    }

    _trackPlaybackWindow();
  }

  void _performTrackPlaybackWindow() {
    final playbackKpi = maybeFindPlaybackKpiService();
    maybeFindHlsDataUsageProbe()?.setVisibleDoc(
        centeredIndex.value >= 0 && centeredIndex.value < agendaList.length
            ? agendaList[centeredIndex.value].docID
            : null);
    if (playbackKpi == null) return;
    final centered = centeredIndex.value;
    final activeDocId = centered >= 0 && centered < agendaList.length
        ? agendaList[centered].docID
        : '';
    final currentPlayingDocId = VideoStateManager.instance.currentPlayingDocID;
    final externalOwnerActive = _hasExternalPlaybackOwner(currentPlayingDocId);
    final ownershipExpected = isPrimaryFeedRouteVisible &&
        canClaimPlaybackNow &&
        !playbackSuspended.value &&
        !pauseAll.value &&
        !externalOwnerActive;
    if (GetPlatform.isAndroid &&
        ownershipExpected &&
        centered == 0 &&
        currentPlayingDocId == null &&
        centered < agendaList.length &&
        _canAutoplayVideoPost(agendaList[centered])) {
      _ensureFeedPlaybackForIndex(centered);
    }
    final visibleCount = _visibleFractions.length;
    var strongestIndex = -1;
    var strongestFraction = 0.0;
    _visibleFractions.forEach((index, fraction) {
      if (fraction > strongestFraction) {
        strongestFraction = fraction;
        strongestIndex = index;
      }
    });
    final signature = <String>[
      '$centered',
      activeDocId,
      '$visibleCount',
      '$strongestIndex',
      strongestFraction.toStringAsFixed(2),
    ].join('|');
    if (signature == _lastPlaybackWindowSignature) return;
    _lastPlaybackWindowSignature = signature;
    playbackKpi.track(
      PlaybackKpiEventType.playbackWindow,
      <String, dynamic>{
        'surface': 'feed',
        'activeIndex': centered,
        'activeDocId': activeDocId,
        'visibleCount': visibleCount,
        'ownershipExpected': ownershipExpected,
        'externalOwnerActive': externalOwnerActive,
        'currentPlayingDocId': currentPlayingDocId ?? '',
        'strongestIndex': strongestIndex,
        'strongestFraction': strongestFraction,
      },
    );
  }
}
