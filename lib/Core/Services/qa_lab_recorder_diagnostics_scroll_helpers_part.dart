part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsScrollHelpersPart on QALabRecorder {
  QALabTimelineEvent? _latestScrollSettleEvent(
    List<QALabTimelineEvent> surfaceTimeline,
  ) {
    return surfaceTimeline
        .where((event) => event.category == 'scroll' && event.code == 'settled')
        .toList(growable: false)
        .lastOrNull;
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
