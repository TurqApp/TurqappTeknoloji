part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsAutoplayPart on QALabRecorder {
  bool _matchesPlaybackTargetForSurface({
    required String surface,
    required String expectedDocId,
    required String currentPlayingDocId,
  }) {
    final expected = expectedDocId.trim();
    final current = currentPlayingDocId.trim();
    if (expected.isEmpty || current.isEmpty) return false;
    if (current == expected) return true;
    if (surface == 'feed') {
      return current == 'feed:$expected';
    }
    if (surface == 'short') {
      return current == 'short:$expected';
    }
    return false;
  }

  QALabPinpointFinding? _buildAutoplaySurfaceFinding({
    required String surface,
    required List<QALabCheckpoint> surfaceCheckpoints,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed' && surface != 'short') {
      return null;
    }
    final surfaceIssues = _surfaceIssues(surface);
    if (surfaceCheckpoints.isEmpty) {
      return null;
    }
    final latestCheckpoint = surfaceCheckpoints.last;
    final surfaceProbe =
        latestCheckpoint.probe[surface] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final authProbe = latestCheckpoint.probe['auth'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    if (!_hasAuthenticatedUser(authProbe)) {
      return null;
    }

    final expectedDocId = surface == 'feed'
        ? (surfaceProbe['centeredDocId'] ?? '').toString()
        : (surfaceProbe['activeDocId'] ?? '').toString();
    final count = _asInt(surfaceProbe['count']);
    if (count <= 0 || expectedDocId.isEmpty) {
      return null;
    }
    if (surface == 'feed') {
      if (_isQALabAutostartWarmup(
        surface: surface,
        route: route,
        referenceTime: referenceTime,
      )) {
        return null;
      }
      if (!_isPrimaryFeedSelected(latestCheckpoint.probe, route: route)) {
        return null;
      }
      final centeredIndex = _asInt(surfaceProbe['centeredIndex']);
      final playbackSuspended = surfaceProbe['playbackSuspended'] == true;
      final pauseAll = surfaceProbe['pauseAll'] == true;
      final canClaimPlaybackNow = surfaceProbe['canClaimPlaybackNow'] == true;
      final centeredHasPlayableVideo =
          surfaceProbe['centeredHasPlayableVideo'] == true;
      final centeredHasRenderableVideoCard =
          surfaceProbe['centeredHasRenderableVideoCard'] == true;
      if (centeredIndex < 0 ||
          centeredIndex >= count ||
          playbackSuspended ||
          pauseAll ||
          !canClaimPlaybackNow) {
        return null;
      }
      if (expectedDocId.isNotEmpty &&
          centeredHasRenderableVideoCard &&
          !centeredHasPlayableVideo) {
        return null;
      }
      if (!centeredHasRenderableVideoCard) {
        return null;
      }
    } else {
      final activeIndex = _asInt(surfaceProbe['activeIndex']);
      if (activeIndex < 0 || activeIndex >= count) {
        return null;
      }
    }

    var observedSince = _playbackObservationStart(
      surfaceCheckpoints: surfaceCheckpoints,
      route: route,
      surface: surface,
      expectedDocId: expectedDocId,
    );
    final elapsedMs = referenceTime.difference(observedSince).inMilliseconds;
    if (elapsedMs < QALabMode.autoplayDetectionGraceMs) {
      return null;
    }
    if (_hasRecentUnresolvedLifecycleInterruption(
          surfaceIssues: surfaceIssues,
          referenceTime: referenceTime,
        ) ||
        _hasUnresolvedLifecycleInterruptionAfter(
          surfaceIssues: surfaceIssues,
          timestamp: observedSince,
        )) {
      return null;
    }

    final playbackProbe =
        latestCheckpoint.probe['videoPlayback'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final targetPlaybackDocId =
        (playbackProbe['targetPlaybackDocID'] ?? '').toString();
    final targetPlaybackUpdatedAt =
        _parseTimestamp(playbackProbe['targetPlaybackUpdatedAt']);
    if (_matchesPlaybackTargetForSurface(
          surface: surface,
          expectedDocId: expectedDocId,
          currentPlayingDocId: targetPlaybackDocId,
        ) &&
        targetPlaybackUpdatedAt != null &&
        targetPlaybackUpdatedAt.isAfter(observedSince)) {
      observedSince = targetPlaybackUpdatedAt;
    }
    final currentPlayingDocId =
        (playbackProbe['currentPlayingDocID'] ?? '').toString();
    if (_matchesPlaybackTargetForSurface(
      surface: surface,
      expectedDocId: expectedDocId,
      currentPlayingDocId: currentPlayingDocId,
    )) {
      return null;
    }
    final registeredHandleCount =
        _asInt(playbackProbe['registeredHandleCount']);
    final savedStateCount = _asInt(playbackProbe['savedStateCount']);
    final wrongTarget = currentPlayingDocId.isNotEmpty;
    return QALabPinpointFinding(
      severity: registeredHandleCount > 0
          ? QALabIssueSeverity.error
          : QALabIssueSeverity.warning,
      code: wrongTarget
          ? '${surface}_autoplay_wrong_target'
          : '${surface}_autoplay_missing',
      message: wrongTarget
          ? 'Autoplay on $surface claimed the wrong video after the grace window.'
          : 'Autoplay on $surface stayed idle after the grace window.',
      route: route,
      surface: surface,
      timestamp: latestCheckpoint.timestamp,
      context: <String, dynamic>{
        'expectedDocId': expectedDocId,
        'currentPlayingDocID': currentPlayingDocId,
        'registeredHandleCount': registeredHandleCount,
        'savedStateCount': savedStateCount,
        'elapsedMs': elapsedMs,
      },
    );
  }
}
