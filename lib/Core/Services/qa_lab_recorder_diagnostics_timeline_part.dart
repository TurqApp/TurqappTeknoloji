part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsTimelinePart on QALabRecorder {
  static const Set<String> _feedFetchSettledStages = <String>{
    'completed',
    'failed',
    'skipped',
    'buffered_page',
  };

  List<QALabPinpointFinding> _buildFetchSurfaceFindings({
    required String surface,
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime referenceTime,
    required String route,
  }) {
    final findings = <QALabPinpointFinding>[];
    final bursts = _feedTriggerBursts(surfaceTimeline: surfaceTimeline);
    if (bursts.isNotEmpty) {
      final strongest = bursts.first;
      final repeatCount = _asInt(strongest['repeatCount']);
      findings.add(
        QALabPinpointFinding(
          severity: repeatCount >= 3
              ? QALabIssueSeverity.error
              : QALabIssueSeverity.warning,
          code: '${surface}_duplicate_fetch_trigger',
          message:
              '$surface fetch was triggered repeatedly before the previous request fully settled.',
          route: route,
          surface: surface,
          timestamp: _parseTimestamp(strongest['timestamp']) ?? referenceTime,
          context: strongest,
        ),
      );
    }
    if (surface == 'short') {
      final sourceNotReady = _latestSourceNotReadyFetchEvent(
        surfaceTimeline: surfaceTimeline,
      );
      if (sourceNotReady != null) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.warning,
            code: 'short_video_source_not_ready',
            message:
                'Short fetch received video cards whose playback source was not ready yet.',
            route: route,
            surface: surface,
            timestamp:
                _parseTimestamp(sourceNotReady['timestamp']) ?? referenceTime,
            context: sourceNotReady,
          ),
        );
      }
    }
    return findings;
  }

  List<Map<String, dynamic>> _feedTriggerBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
  }) {
    final feedEvents = surfaceTimeline
        .where((event) => event.category == 'feed_fetch')
        .toList(growable: false);
    final bursts = <Map<String, dynamic>>[];
    for (int i = 0; i < feedEvents.length; i++) {
      final first = feedEvents[i];
      if (first.code != 'requested') {
        continue;
      }
      final trigger = (first.metadata['trigger'] ?? '').toString();
      if (trigger.isEmpty) continue;
      var repeatCount = 1;
      final stages = <String>[first.code];
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
        stages.add(next.code);
        if (_feedFetchSettledStages.contains(next.code)) {
          break;
        }
        if (next.code != 'requested') {
          continue;
        }
        repeatCount += 1;
      }
      if (repeatCount >= 2) {
        bursts.add(
          <String, dynamic>{
            'timestamp': first.timestamp.toUtc().toIso8601String(),
            'trigger': trigger,
            'stage': first.code,
            'stages': stages,
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

  Map<String, dynamic>? _latestSourceNotReadyFetchEvent({
    required List<QALabTimelineEvent> surfaceTimeline,
  }) {
    for (final event in surfaceTimeline.reversed) {
      if (event.category != 'feed_fetch' || event.code != 'source_not_ready') {
        continue;
      }
      return <String, dynamic>{
        'timestamp': event.timestamp.toUtc().toIso8601String(),
        ...event.metadata,
      };
    }
    return null;
  }
}
