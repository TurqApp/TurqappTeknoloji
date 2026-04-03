part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsScrollHelpersPart on QALabRecorder {
  Map<String, dynamic> _timelineProbeSnapshot(QALabTimelineEvent event) {
    final raw = event.metadata['probe'];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return const <String, dynamic>{};
  }

  bool _isPlaybackAlreadyTargetedAtScrollSettle({
    required String surface,
    required String expectedDocId,
    required QALabTimelineEvent settleEvent,
    required Map<String, dynamic> rootProbe,
  }) {
    final settleProbe = _timelineProbeSnapshot(settleEvent);
    final effectiveRootProbe = settleProbe.isNotEmpty ? settleProbe : rootProbe;
    final playbackProbe =
        effectiveRootProbe['videoPlayback'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final currentPlayingDocId =
        (playbackProbe['currentPlayingDocID'] ?? '').toString().trim();
    final targetPlaybackDocId =
        (playbackProbe['targetPlaybackDocID'] ?? '').toString().trim();
    if (_matchesPlaybackDocForSurface(
          surface: surface,
          expectedDocId: expectedDocId,
          currentDocId: currentPlayingDocId,
        ) ||
        _matchesPlaybackDocForSurface(
          surface: surface,
          expectedDocId: expectedDocId,
          currentDocId: targetPlaybackDocId,
        )) {
      return true;
    }
    return false;
  }

  bool _isScrollSettleStillRelevant({
    required String surface,
    required String expectedDocId,
    required Map<String, dynamic> latestProbe,
    required Map<String, dynamic> rootProbe,
    required String route,
  }) {
    final docId = expectedDocId.trim();
    if (docId.isEmpty) return false;
    if (surface == 'feed') {
      if (!_isPrimaryFeedSelected(rootProbe, route: route)) {
        return false;
      }
      final count = _asInt(latestProbe['count']);
      final centeredIndex = _asInt(latestProbe['centeredIndex']);
      final centeredDocId =
          (latestProbe['centeredDocId'] ?? '').toString().trim();
      final centeredHasPlayableVideo = _surfaceProbeAsBool(
        latestProbe['centeredHasPlayableVideo'],
        fallback: centeredDocId.isNotEmpty,
      );
      final centeredHasRenderableVideoCard = _surfaceProbeAsBool(
        latestProbe['centeredHasRenderableVideoCard'],
        fallback: centeredHasPlayableVideo,
      );
      final playbackSuspended = _surfaceProbeAsBool(
        latestProbe['playbackSuspended'],
        fallback: false,
      );
      final pauseAll = _surfaceProbeAsBool(
        latestProbe['pauseAll'],
        fallback: false,
      );
      final canClaimPlaybackNow = _surfaceProbeAsBool(
        latestProbe['canClaimPlaybackNow'],
        fallback: false,
      );
      return count > 0 &&
          centeredIndex >= 0 &&
          centeredIndex < count &&
          centeredDocId == docId &&
          centeredHasPlayableVideo &&
          centeredHasRenderableVideoCard &&
          !playbackSuspended &&
          !pauseAll &&
          canClaimPlaybackNow;
    }
    if (surface == 'short') {
      if (!_isPrimaryShortSelected(rootProbe, route: route)) {
        return false;
      }
      final count = _asInt(latestProbe['count']);
      final activeIndex = _asInt(latestProbe['activeIndex']);
      final activeDocId = (latestProbe['activeDocId'] ?? '').toString().trim();
      return count > 0 &&
          activeIndex >= 0 &&
          activeIndex < count &&
          activeDocId == docId;
    }
    return true;
  }

  QALabTimelineEvent? _latestScrollSettleEvent(
    List<QALabTimelineEvent> surfaceTimeline,
  ) {
    return surfaceTimeline
        .where((event) => event.category == 'scroll' && event.code == 'settled')
        .toList(growable: false)
        .lastOrNull;
  }

  QALabTimelineEvent? _firstScrollStartAfter({
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime after,
  }) {
    return surfaceTimeline
        .where((event) => event.category == 'scroll' && event.code == 'start')
        .where((event) => event.timestamp.isAfter(after))
        .toList(growable: false)
        .firstOrNull;
  }

  QALabTimelineEvent? _firstScrollPhaseAfter({
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime after,
    required String phase,
    required String docId,
    String? scrollToken,
  }) {
    final expectedToken = (scrollToken ?? '').trim();
    return surfaceTimeline
        .where((event) => event.category == 'scroll' && event.code == phase)
        .where((event) => (event.metadata['docId'] ?? '').toString() == docId)
        .where((event) => !event.timestamp.isBefore(after))
        .where(
          (event) =>
              expectedToken.isEmpty ||
              (event.metadata['scrollToken'] ?? '').toString() == expectedToken,
        )
        .toList(growable: false)
        .firstOrNull;
  }

  (int, int, int) _latestScrollLatencySummary({
    required List<QALabTimelineEvent> surfaceTimeline,
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
  }) {
    final latestSettle = _latestScrollSettleEvent(surfaceTimeline);
    if (latestSettle == null) {
      return (0, 0, 0);
    }
    final docId = (latestSettle.metadata['docId'] ?? '').toString();
    if (docId.isEmpty) {
      return (0, 0, 0);
    }
    final scrollToken = (latestSettle.metadata['scrollToken'] ?? '').toString();
    final dispatch = _firstPlaybackDispatchAfter(
      surfaceTimeline: surfaceTimeline,
      after: latestSettle.timestamp,
      docId: docId,
    );
    final stableFrame = _firstScrollPhaseAfter(
      surfaceTimeline: surfaceTimeline,
      after: latestSettle.timestamp,
      phase: 'stable_frame',
      docId: docId,
      scrollToken: scrollToken,
    );
    final firstFrameIssue = surfaceIssues
        .where((issue) => issue.code == 'video_first_frame')
        .where((issue) => _videoIdOf(issue) == docId)
        .where((issue) => issue.timestamp.isAfter(latestSettle.timestamp))
        .toList(growable: false)
        .firstOrNull;
    final dispatchLatencyMs = dispatch == null
        ? 0
        : dispatch.timestamp.difference(latestSettle.timestamp).inMilliseconds;
    final firstFrameLatencyMs = firstFrameIssue == null
        ? 0
        : firstFrameIssue.timestamp
            .difference(latestSettle.timestamp)
            .inMilliseconds;
    final stableFrameLatencyMs = stableFrame == null
        ? 0
        : stableFrame.timestamp
            .difference(latestSettle.timestamp)
            .inMilliseconds;
    return (dispatchLatencyMs, firstFrameLatencyMs, stableFrameLatencyMs);
  }
}
