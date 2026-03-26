part of 'agenda_controller.dart';

extension AgendaControllerPlaybackPart on AgendaController {
  void _performOnPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (modelIndex < 0 || modelIndex >= agendaList.length) return;
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
    final current = centeredIndex.value;
    final targetIndex = FeedPlaybackSelectionPolicy.resolveCenteredIndex(
      visibleFractions: _visibleFractions,
      currentIndex: current,
      lastCenteredIndex: lastCenteredIndex,
      itemCount: agendaList.length,
      canAutoplayIndex: (index) => _canAutoplayVideoPost(agendaList[index]),
      stopThreshold: stopThreshold,
    );

    if (targetIndex >= 0 && targetIndex < agendaList.length) {
      if (centeredIndex.value != targetIndex) {
        centeredIndex.value = targetIndex;
      }
      lastCenteredIndex = targetIndex;
      if (centeredIndex.value != targetIndex ||
          !_isPlaybackTargetCurrent(targetIndex)) {
        _ensureFeedPlaybackForIndex(targetIndex);
      }
    } else {
      centeredIndex.value = -1;
    }

    _trackPlaybackWindow();
  }

  void _performTrackPlaybackWindow() {
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi == null) return;
    final centered = centeredIndex.value;
    final activeDocId = centered >= 0 && centered < agendaList.length
        ? agendaList[centered].docID
        : '';
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
        'strongestIndex': strongestIndex,
        'strongestFraction': strongestFraction,
      },
    );
  }
}
