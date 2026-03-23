part of 'agenda_controller.dart';

extension AgendaControllerPlaybackPart on AgendaController {
  void _performOnPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (modelIndex < 0 || modelIndex >= agendaList.length) return;
    final prev = _visibleFractions[modelIndex];

    if (GetPlatform.isAndroid &&
        prev != null &&
        (prev - visibleFraction).abs() < 0.08) {
      return;
    }

    if (visibleFraction <= 0.01) {
      _visibleFractions.remove(modelIndex);
      _visibleUpdatedAt.remove(modelIndex);
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
      _visibleUpdatedAt[modelIndex] = DateTime.now();
    }

    const double playThreshold = 0.80;
    final double stopThreshold = GetPlatform.isAndroid ? 0.25 : 0.40;

    _scheduleVisibilityEvaluation(
      playThreshold: playThreshold,
      stopThreshold: stopThreshold,
    );
  }

  void _performScheduleVisibilityEvaluation({
    required double playThreshold,
    required double stopThreshold,
  }) {
    _visibilityDebounce?.cancel();
    _visibilityDebounce = Timer(
      GetPlatform.isAndroid
          ? const Duration(milliseconds: 48)
          : const Duration(milliseconds: 40),
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
    var bestIndex = -1;
    var bestFraction = 0.0;
    var fallbackIndex = -1;
    var fallbackFraction = 0.0;

    _visibleFractions.forEach((index, fraction) {
      if (index < 0 || index >= agendaList.length) return;
      final post = agendaList[index];
      if (!_canAutoplayVideoPost(post)) return;
      if (fraction > fallbackFraction) {
        fallbackFraction = fraction;
        fallbackIndex = index;
      }
      if (fraction < playThreshold) return;
      if (fraction > bestFraction) {
        bestFraction = fraction;
        bestIndex = index;
      }
    });

    if (bestIndex >= 0) {
      final currentFraction =
          current >= 0 ? (_visibleFractions[current] ?? 0.0) : 0.0;
      final hysteresis = GetPlatform.isAndroid ? 0.10 : 0.06;
      final shouldSwitch = current == -1 ||
          current == bestIndex ||
          currentFraction < playThreshold ||
          bestFraction >= currentFraction + hysteresis;

      if (shouldSwitch && centeredIndex.value != bestIndex) {
        centeredIndex.value = bestIndex;
        lastCenteredIndex = bestIndex;
      }
      if (centeredIndex.value != bestIndex ||
          !_isPlaybackTargetCurrent(bestIndex)) {
        _ensureFeedPlaybackForIndex(bestIndex);
      }
      _trackPlaybackWindow();
      return;
    }

    final secondaryThreshold = GetPlatform.isAndroid ? 0.55 : 0.62;
    if (fallbackIndex >= 0 && fallbackFraction >= secondaryThreshold) {
      if (centeredIndex.value != fallbackIndex) {
        centeredIndex.value = fallbackIndex;
        lastCenteredIndex = fallbackIndex;
      }
      if (centeredIndex.value != fallbackIndex ||
          !_isPlaybackTargetCurrent(fallbackIndex)) {
        _ensureFeedPlaybackForIndex(fallbackIndex);
      }
      _trackPlaybackWindow();
      return;
    }

    if (current >= 0) {
      final currentFraction = _visibleFractions[current] ?? 0.0;
      final lingerThreshold = GetPlatform.isAndroid ? 0.14 : stopThreshold;
      if (currentFraction < lingerThreshold) {
        final preservedIndex = () {
          if (lastCenteredIndex != null &&
              lastCenteredIndex! >= 0 &&
              lastCenteredIndex! < agendaList.length &&
              _canAutoplayVideoPost(agendaList[lastCenteredIndex!])) {
            return lastCenteredIndex!;
          }
          if (current >= 0 &&
              current < agendaList.length &&
              _canAutoplayVideoPost(agendaList[current])) {
            return current;
          }
          final anyVisiblePlayable = _visibleFractions.entries
              .where((entry) =>
                  entry.key >= 0 &&
                  entry.key < agendaList.length &&
                  _canAutoplayVideoPost(agendaList[entry.key]))
              .map((entry) => entry.key)
              .cast<int?>()
              .firstWhere((entry) => entry != null, orElse: () => null);
          if (anyVisiblePlayable != null) return anyVisiblePlayable;
          final firstPlayable =
              agendaList.indexWhere((post) => _canAutoplayVideoPost(post));
          return firstPlayable >= 0 ? firstPlayable : -1;
        }();

        if (preservedIndex >= 0 && preservedIndex < agendaList.length) {
          if (centeredIndex.value != preservedIndex) {
            centeredIndex.value = preservedIndex;
          }
          lastCenteredIndex = preservedIndex;
          if (centeredIndex.value != preservedIndex ||
              !_isPlaybackTargetCurrent(preservedIndex)) {
            _ensureFeedPlaybackForIndex(preservedIndex);
          }
        } else {
          centeredIndex.value = -1;
        }
      }
    } else if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < agendaList.length &&
        _canAutoplayVideoPost(agendaList[lastCenteredIndex!])) {
      centeredIndex.value = lastCenteredIndex!;
      if (!_isPlaybackTargetCurrent(lastCenteredIndex!)) {
        _ensureFeedPlaybackForIndex(lastCenteredIndex!);
      }
    }

    _trackPlaybackWindow();
  }

  void _performTrackPlaybackWindow() {
    final playbackKpi = PlaybackKpiService.maybeFind();
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
