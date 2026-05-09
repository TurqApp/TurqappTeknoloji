part of 'agenda_controller.dart';

extension AgendaControllerPlaybackPart on AgendaController {
  bool _retainVisibleCurrentFeedOwner({
    required double stopThreshold,
  }) {
    if (!PlaybackSurfacePolicy.supportsFeedVisibleOwnerRetention(
      platform: defaultTargetPlatform,
    )) {
      return false;
    }
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
    final retainThreshold =
        stopThreshold < FeedPlaybackSelectionPolicy.switchRetentionThreshold
            ? FeedPlaybackSelectionPolicy.switchRetentionThreshold
            : stopThreshold;
    if (ownerFraction < retainThreshold) return false;
    final centeredChanged = centeredIndex.value != ownerIndex;
    debugPrint(
      '[FeedPlaybackDecision] action=retain_visible_owner '
      'owner=$ownerIndex doc=$feedDocId fraction=${ownerFraction.toStringAsFixed(3)} '
      'threshold=${retainThreshold.toStringAsFixed(3)} centered=${centeredIndex.value}',
    );
    if (centeredChanged) {
      centeredIndex.value = ownerIndex;
      _notifyPlaybackRowUpdates(ownerIndex);
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
    if (!PlaybackSurfacePolicy.supportsFeedStartupTargetRetention(
      platform: defaultTargetPlatform,
    )) {
      return false;
    }
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
      debugPrint(
        '[FeedPlaybackDecision] action=visibility_skip '
        'index=$modelIndex fraction=${visibleFraction.toStringAsFixed(2)} '
        'suspended=${playbackSuspended.value} route=${Get.currentRoute} '
        'primary=$isPrimaryFeedRouteVisible nav=${maybeFindNavBarController()?.selectedIndex.value ?? -1}',
      );
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
      _pruneFeedVisibilityWindow(anchorIndex: modelIndex);
      return;
    }

    if (visibleFraction <= 0.01) {
      _visibleFractions.remove(modelIndex);
      _visibleUpdatedAt.remove(modelIndex);
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
      _visibleUpdatedAt[modelIndex] = DateTime.now();
    }
    _pruneFeedVisibilityWindow(anchorIndex: modelIndex);

    if (_shouldUseTightCellularFeedWarmProfile &&
        visibleFraction >= FeedPlaybackSelectionPolicy.secondaryThreshold) {
      final previewTarget = FeedPlaybackSelectionPolicy.resolveCenteredIndex(
        visibleFractions: _visibleFractions,
        currentIndex: centeredIndex.value,
        lastCenteredIndex: lastCenteredIndex,
        itemCount: agendaList.length,
        canAutoplayIndex: (index) => _canAutoplayVideoPost(agendaList[index]),
        stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
        preferDominantVisibleIndexWhenNonPlayable: true,
      );
      if (previewTarget >= 0 && previewTarget < agendaList.length) {
        _refreshFeedPrefetchForVisibleTarget(previewTarget);
      }
    }

    _scheduleVisibilityEvaluation(
      playThreshold: FeedPlaybackSelectionPolicy.playThreshold,
      stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
    );
  }

  void _pruneFeedVisibilityWindow({required int anchorIndex}) {
    final now = DateTime.now();
    final centered = centeredIndex.value;
    final keysToRemove = <int>[];
    _visibleFractions.forEach((index, fraction) {
      if (index < 0 || index >= agendaList.length) {
        keysToRemove.add(index);
        return;
      }
      final updatedAt = _visibleUpdatedAt[index];
      final age = updatedAt == null
          ? const Duration(days: 1)
          : now.difference(updatedAt);
      final distanceFromAnchor = (index - anchorIndex).abs();
      final distanceFromCentered =
          centered >= 0 ? (index - centered).abs() : distanceFromAnchor;
      final keepCenteredAsAnchor = index == centered &&
          age <= const Duration(milliseconds: 700) &&
          distanceFromAnchor <= 4;
      final closestDistance = keepCenteredAsAnchor
          ? min(distanceFromAnchor, distanceFromCentered)
          : distanceFromAnchor;
      final staleAndFar =
          age > const Duration(milliseconds: 900) && closestDistance > 8;
      final tinyAndFar = fraction < 0.12 && closestDistance > 6;
      final staleCenteredAndFar = index == centered &&
          age > const Duration(milliseconds: 700) &&
          distanceFromAnchor > 4;
      if (staleAndFar || tinyAndFar || staleCenteredAndFar) {
        keysToRemove.add(index);
      }
    });
    if (keysToRemove.isEmpty) return;
    for (final index in keysToRemove) {
      _visibleFractions.remove(index);
      _visibleUpdatedAt.remove(index);
    }
    debugPrint(
      '[FeedVisibilityPrune] removed=${keysToRemove.length} '
      'remaining=${_visibleFractions.length} anchor=$anchorIndex '
      'centered=$centered removedKeys=$keysToRemove',
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
        debugPrint(
          '[FeedPlaybackDecision] action=retain_startup_lock '
          'locked=$lockedIndex doc=$lockedDocId centered=${centeredIndex.value}',
        );
        final centeredChanged = centeredIndex.value != lockedIndex;
        if (centeredChanged) {
          centeredIndex.value = lockedIndex;
          _notifyPlaybackRowUpdates(lockedIndex);
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
      final currentFraction = _visibleFractions[current] ?? 0.0;
      debugPrint(
        '[FeedPlaybackDecision] action=retain_startup_target '
        'current=$current doc=${agendaList[current].docID} '
        'fraction=${currentFraction.toStringAsFixed(3)} '
        'stop=${stopThreshold.toStringAsFixed(3)}',
      );
      lastCenteredIndex = current;
      _trackPlaybackWindow();
      return;
    }
    final decision = FeedPlaybackSelectionPolicy.resolvePlaybackDecision(
      visibleFractions: _visibleFractions,
      visibleUpdatedAt: _visibleUpdatedAt,
      currentIndex: current,
      lastCenteredIndex: lastCenteredIndex,
      itemCount: agendaList.length,
      canAutoplayIndex: (index) => _canAutoplayVideoPost(agendaList[index]),
      isPlaybackTargetCurrent: _isPlaybackTargetCurrent,
      playbackKeyForIndex: (index) =>
          _feedPlaybackHandleKeyForDoc(agendaList[index].docID),
      lastCommandAt: _lastPlaybackCommandAt,
      lastCommandDocId: _lastPlaybackCommandDocId,
      stopThreshold: stopThreshold,
      supportsSwitchRetention:
          PlaybackSurfacePolicy.supportsFeedSwitchRetention(
        platform: defaultTargetPlatform,
      ),
      preferDominantVisibleIndexWhenNonPlayable: true,
    );

    if (decision.hasTarget) {
      final targetIndex = decision.targetIndex;
      debugPrint(
        '[FeedPlaybackDecision] action=${decision.action} '
        'current=$current target=$targetIndex changed=${centeredIndex.value != targetIndex} '
        'visible=${_visibleFractions.entries.map((e) => '${e.key}:${e.value.toStringAsFixed(2)}').join(',')}',
      );
      final centeredChanged = centeredIndex.value != targetIndex;
      if (centeredChanged) {
        centeredIndex.value = targetIndex;
        _notifyPlaybackRowUpdates(targetIndex);
        if (decision.shouldEnsurePlayback) {
          _ensureFeedPlaybackForIndex(targetIndex);
        }
      } else if (decision.shouldEnsurePlayback) {
        _ensureFeedPlaybackForIndex(targetIndex);
      }
      lastCenteredIndex = targetIndex;
    } else {
      debugPrint(
        '[FeedPlaybackDecision] action=no_target '
        'current=$current visible=${_visibleFractions.entries.map((e) => '${e.key}:${e.value.toStringAsFixed(2)}').join(',')} '
        'canClaim=$canClaimPlaybackNow route=${Get.currentRoute} '
        'nav=${maybeFindNavBarController()?.selectedIndex.value ?? -1} '
        'pauseAll=${pauseAll.value} suspended=${playbackSuspended.value}',
      );
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
