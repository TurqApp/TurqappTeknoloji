part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsScrollPart on QALabRecorder {
  List<QALabPinpointFinding> _buildScrollSurfaceFindings({
    required String surface,
    required List<QALabTimelineEvent> surfaceTimeline,
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed' && surface != 'short') {
      return const <QALabPinpointFinding>[];
    }
    final latestSettle = _latestScrollSettleEvent(surfaceTimeline);
    if (latestSettle == null) {
      return const <QALabPinpointFinding>[];
    }
    final expectedDocId = (latestSettle.metadata['docId'] ?? '').toString();
    if (expectedDocId.isEmpty) {
      return const <QALabPinpointFinding>[];
    }

    final findings = <QALabPinpointFinding>[];
    final dispatch = _firstPlaybackDispatchAfter(
      surfaceTimeline: surfaceTimeline,
      after: latestSettle.timestamp,
      docId: expectedDocId,
    );
    final latestSkip = _latestPlaybackSkipAfter(
      surfaceTimeline: surfaceTimeline,
      after: latestSettle.timestamp,
      docId: expectedDocId,
    );
    final scrollToken = (latestSettle.metadata['scrollToken'] ?? '').toString();
    final dispatchLatencyMs = dispatch == null
        ? referenceTime.difference(latestSettle.timestamp).inMilliseconds
        : dispatch.timestamp.difference(latestSettle.timestamp).inMilliseconds;
    if (dispatch == null &&
        dispatchLatencyMs >= QALabMode.scrollAutoplayDispatchBlockingMs) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.blocking,
          code: '${surface}_scroll_dispatch_timeout',
          message:
              'Playback dispatch did not fire after the latest scroll settled on $surface.',
          route: route,
          surface: surface,
          timestamp: latestSettle.timestamp,
          context: <String, dynamic>{
            'docId': expectedDocId,
            'dispatchLatencyMs': dispatchLatencyMs,
            'scrollToken': scrollToken,
            if (latestSkip != null) 'lastSkipStage': latestSkip.code,
            if (latestSkip != null)
              'lastSkipReason':
                  (latestSkip.metadata['skipReason'] ?? '').toString(),
            if (latestSkip != null)
              'lastSkipSource':
                  (latestSkip.metadata['dispatchSource'] ?? '').toString(),
            if (latestSkip != null)
              'lastCallerSignature':
                  (latestSkip.metadata['callerSignature'] ?? '').toString(),
          },
        ),
      );
    } else if (dispatch != null &&
        dispatchLatencyMs >= QALabMode.scrollAutoplayDispatchWarningMs) {
      findings.add(
        QALabPinpointFinding(
          severity:
              dispatchLatencyMs >= QALabMode.scrollAutoplayDispatchBlockingMs
                  ? QALabIssueSeverity.error
                  : QALabIssueSeverity.warning,
          code: '${surface}_scroll_dispatch_slow',
          message:
              'Playback dispatch arrived late after the latest scroll settled on $surface.',
          route: route,
          surface: surface,
          timestamp: dispatch.timestamp,
          context: <String, dynamic>{
            'docId': expectedDocId,
            'dispatchLatencyMs': dispatchLatencyMs,
            'dispatchStage': dispatch.code,
            'dispatchSource':
                (dispatch.metadata['dispatchSource'] ?? '').toString(),
            'callerSignature':
                (dispatch.metadata['callerSignature'] ?? '').toString(),
            'scrollToken': scrollToken,
          },
        ),
      );
    }

    final firstFrameIssue = surfaceIssues
        .where((issue) => issue.code == 'video_first_frame')
        .where((issue) => _videoIdOf(issue) == expectedDocId)
        .where((issue) => issue.timestamp.isAfter(latestSettle.timestamp))
        .toList(growable: false)
        .firstOrNull;
    final firstFrameLatencyMs = firstFrameIssue == null
        ? referenceTime.difference(latestSettle.timestamp).inMilliseconds
        : firstFrameIssue.timestamp
            .difference(latestSettle.timestamp)
            .inMilliseconds;
    if (dispatch != null &&
        firstFrameIssue == null &&
        firstFrameLatencyMs >= QALabMode.scrollFirstFrameBlockingMs) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.blocking,
          code: '${surface}_scroll_first_frame_missing',
          message:
              'Playback dispatch fired on $surface, but the settled item still never rendered a first frame.',
          route: route,
          surface: surface,
          timestamp: latestSettle.timestamp,
          context: <String, dynamic>{
            'docId': expectedDocId,
            'firstFrameLatencyMs': firstFrameLatencyMs,
          },
        ),
      );
    } else if (firstFrameIssue != null &&
        firstFrameLatencyMs >= QALabMode.scrollFirstFrameWarningMs) {
      findings.add(
        QALabPinpointFinding(
          severity: firstFrameLatencyMs >= QALabMode.scrollFirstFrameBlockingMs
              ? QALabIssueSeverity.error
              : QALabIssueSeverity.warning,
          code: '${surface}_scroll_first_frame_slow',
          message:
              'The settled item on $surface rendered its first frame too late after scroll.',
          route: route,
          surface: surface,
          timestamp: firstFrameIssue.timestamp,
          context: <String, dynamic>{
            'docId': expectedDocId,
            'firstFrameLatencyMs': firstFrameLatencyMs,
          },
        ),
      );
    }

    final duplicateBursts = _duplicatePlaybackDispatchBursts(
      surfaceTimeline: surfaceTimeline,
      docId: expectedDocId,
    );
    if (duplicateBursts.isNotEmpty) {
      findings.add(
        QALabPinpointFinding(
          severity: _asInt(duplicateBursts.first['repeatCount']) >= 3
              ? QALabIssueSeverity.error
              : QALabIssueSeverity.warning,
          code: '${surface}_duplicate_playback_dispatch',
          message:
              'The same $surface item received repeated playback dispatches in a very short window.',
          route: route,
          surface: surface,
          timestamp: _parseTimestamp(duplicateBursts.first['timestamp']) ??
              referenceTime,
          context: duplicateBursts.first,
        ),
      );
    }

    return findings;
  }
}
