part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsTimelinePart on QALabRecorder {
  List<QALabPinpointFinding> _buildFetchSurfaceFindings({
    required String surface,
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed') {
      return const <QALabPinpointFinding>[];
    }
    final bursts = _feedTriggerBursts(surfaceTimeline: surfaceTimeline);
    if (bursts.isEmpty) {
      return const <QALabPinpointFinding>[];
    }
    final strongest = bursts.first;
    final repeatCount = _asInt(strongest['repeatCount']);
    return <QALabPinpointFinding>[
      QALabPinpointFinding(
        severity: repeatCount >= 3
            ? QALabIssueSeverity.error
            : QALabIssueSeverity.warning,
        code: 'feed_duplicate_fetch_trigger',
        message:
            'Feed fetch was triggered repeatedly before the previous request fully settled.',
        route: route,
        surface: surface,
        timestamp: _parseTimestamp(strongest['timestamp']) ?? referenceTime,
        context: strongest,
      ),
    ];
  }

  List<Map<String, dynamic>> _feedTriggerBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
  }) {
    final feedEvents = surfaceTimeline
        .where((event) => event.category == 'feed_fetch')
        .where((event) => event.code == 'requested')
        .toList(growable: false);
    final bursts = <Map<String, dynamic>>[];
    for (int i = 0; i < feedEvents.length; i++) {
      final first = feedEvents[i];
      final trigger = (first.metadata['trigger'] ?? '').toString();
      if (trigger.isEmpty) continue;
      var repeatCount = 1;
      for (int j = i + 1; j < feedEvents.length; j++) {
        final next = feedEvents[j];
        if ((next.metadata['trigger'] ?? '').toString() != trigger) {
          continue;
        }
        final deltaMs =
            next.timestamp.difference(first.timestamp).inMilliseconds;
        if (deltaMs > QALabMode.duplicateFeedTriggerWindowMs) {
          break;
        }
        repeatCount += 1;
      }
      if (repeatCount >= 2) {
        bursts.add(
          <String, dynamic>{
            'timestamp': first.timestamp.toUtc().toIso8601String(),
            'trigger': trigger,
            'stage': first.code,
            'repeatCount': repeatCount,
            'windowMs': QALabMode.duplicateFeedTriggerWindowMs,
          },
        );
      }
    }
    bursts.sort((a, b) => _asInt(b['repeatCount']) - _asInt(a['repeatCount']));
    return bursts;
  }

  int _countDuplicateFeedTriggerBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
  }) {
    return _feedTriggerBursts(surfaceTimeline: surfaceTimeline).length;
  }
}
