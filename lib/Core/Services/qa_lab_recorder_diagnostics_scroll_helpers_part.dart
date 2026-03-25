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

  QALabTimelineEvent? _firstPlaybackDispatchAfter({
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime after,
    required String docId,
  }) {
    return surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where(_isIssuedPlaybackDispatch)
        .where((event) => (event.metadata['docId'] ?? '').toString() == docId)
        .where((event) => !event.timestamp.isBefore(after))
        .toList(growable: false)
        .firstOrNull;
  }

  QALabTimelineEvent? _latestPlaybackSkipAfter({
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime after,
    required String docId,
  }) {
    return surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where((event) => !_isIssuedPlaybackDispatch(event))
        .where((event) => (event.metadata['docId'] ?? '').toString() == docId)
        .where((event) => !event.timestamp.isBefore(after))
        .toList(growable: false)
        .lastOrNull;
  }

  List<Map<String, dynamic>> _duplicatePlaybackDispatchBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
    String? docId,
  }) {
    final events = surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where(_isIssuedPlaybackDispatch)
        .where(
          (event) =>
              docId == null ||
              (event.metadata['docId'] ?? '').toString() == docId,
        )
        .toList(growable: false);
    final bursts = <Map<String, dynamic>>[];
    for (int i = 0; i < events.length; i++) {
      final first = events[i];
      final firstDocId = (first.metadata['docId'] ?? '').toString();
      if (firstDocId.isEmpty) continue;
      final stages = <String>[first.code];
      var repeatCount = 1;
      for (int j = i + 1; j < events.length; j++) {
        final next = events[j];
        if ((next.metadata['docId'] ?? '').toString() != firstDocId) {
          continue;
        }
        final deltaMs =
            next.timestamp.difference(first.timestamp).inMilliseconds;
        if (deltaMs > QALabMode.duplicatePlaybackDispatchWindowMs) {
          break;
        }
        repeatCount += 1;
        stages.add(next.code);
      }
      if (repeatCount >= 2) {
        bursts.add(
          <String, dynamic>{
            'timestamp': first.timestamp.toUtc().toIso8601String(),
            'docId': firstDocId,
            'repeatCount': repeatCount,
            'stages': stages,
            'sources': <String>[
              (first.metadata['dispatchSource'] ?? '').toString(),
              for (int k = i + 1;
                  k < events.length &&
                      (events[k].metadata['docId'] ?? '').toString() ==
                          firstDocId &&
                      events[k]
                              .timestamp
                              .difference(first.timestamp)
                              .inMilliseconds <=
                          QALabMode.duplicatePlaybackDispatchWindowMs;
                  k += 1)
                (events[k].metadata['dispatchSource'] ?? '').toString(),
            ].where((item) => item.isNotEmpty).toSet().toList(growable: false),
            'callerSignatures': <String>[
              (first.metadata['callerSignature'] ?? '').toString(),
              for (int k = i + 1;
                  k < events.length &&
                      (events[k].metadata['docId'] ?? '').toString() ==
                          firstDocId &&
                      events[k]
                              .timestamp
                              .difference(first.timestamp)
                              .inMilliseconds <=
                          QALabMode.duplicatePlaybackDispatchWindowMs;
                  k += 1)
                (events[k].metadata['callerSignature'] ?? '').toString(),
            ].where((item) => item.isNotEmpty).toSet().toList(growable: false),
            'scrollToken': (first.metadata['scrollToken'] ?? '').toString(),
            'windowMs': QALabMode.duplicatePlaybackDispatchWindowMs,
          },
        );
      }
    }
    bursts.sort((a, b) => _asInt(b['repeatCount']) - _asInt(a['repeatCount']));
    return bursts;
  }

  bool _isIssuedPlaybackDispatch(QALabTimelineEvent event) {
    final raw = event.metadata['dispatchIssued'];
    if (raw is bool) return raw;
    if (raw is String) {
      return raw.toLowerCase() != 'false';
    }
    return true;
  }

  int _countDuplicatePlaybackDispatchBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
  }) {
    return _duplicatePlaybackDispatchBursts(surfaceTimeline: surfaceTimeline)
        .length;
  }

  (int, int) _latestScrollLatencySummary({
    required List<QALabTimelineEvent> surfaceTimeline,
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
  }) {
    final latestSettle = _latestScrollSettleEvent(surfaceTimeline);
    if (latestSettle == null) {
      return (0, 0);
    }
    final docId = (latestSettle.metadata['docId'] ?? '').toString();
    if (docId.isEmpty) {
      return (0, 0);
    }
    final dispatch = _firstPlaybackDispatchAfter(
      surfaceTimeline: surfaceTimeline,
      after: latestSettle.timestamp,
      docId: docId,
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
    return (dispatchLatencyMs, firstFrameLatencyMs);
  }
}
