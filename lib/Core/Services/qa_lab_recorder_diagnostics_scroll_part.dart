part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsScrollPart on QALabRecorder {
  List<QALabPinpointFinding> _buildScrollSurfaceFindings({
    required String surface,
    required List<QALabTimelineEvent> surfaceTimeline,
    required List<QALabIssue> surfaceIssues,
    required Map<String, dynamic> latestProbe,
    required Map<String, dynamic> rootProbe,
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
    if (!_isScrollSettleStillRelevant(
      surface: surface,
      expectedDocId: expectedDocId,
      latestProbe: latestProbe,
      rootProbe: rootProbe,
      route: route,
    )) {
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
    final playbackAlreadyTargetedAtSettle =
        _isPlaybackAlreadyTargetedAtScrollSettle(
      surface: surface,
      expectedDocId: expectedDocId,
      settleEvent: latestSettle,
      rootProbe: rootProbe,
    );
    final nextScrollStart = _firstScrollStartAfter(
      surfaceTimeline: surfaceTimeline,
      after: latestSettle.timestamp,
    );
    final scrollToken = (latestSettle.metadata['scrollToken'] ?? '').toString();
    final stableFrameEvent = surface != 'short'
        ? null
        : _firstScrollPhaseAfter(
            surfaceTimeline: surfaceTimeline,
            after: latestSettle.timestamp,
            phase: 'stable_frame',
            docId: expectedDocId,
            scrollToken: scrollToken,
          );
    final dispatchLatencyMs = dispatch == null
        ? referenceTime.difference(latestSettle.timestamp).inMilliseconds
        : dispatch.timestamp.difference(latestSettle.timestamp).inMilliseconds;
    final supersededByNextScroll = nextScrollStart != null &&
        nextScrollStart.timestamp
                .difference(latestSettle.timestamp)
                .inMilliseconds <
            QALabMode.scrollAutoplayDispatchBlockingMs;
    if (!supersededByNextScroll &&
        !playbackAlreadyTargetedAtSettle &&
        dispatch == null &&
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
            'playbackAlreadyTargetedAtSettle': playbackAlreadyTargetedAtSettle,
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
        (nextScrollStart == null ||
            !nextScrollStart.timestamp.isBefore(
              latestSettle.timestamp.add(
                Duration(
                  milliseconds: QALabMode.scrollFirstFrameBlockingMs,
                ),
              ),
            )) &&
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

    if (surface == 'short') {
      final stableFrameLatencyMs = stableFrameEvent == null
          ? referenceTime.difference(latestSettle.timestamp).inMilliseconds
          : stableFrameEvent.timestamp
              .difference(latestSettle.timestamp)
              .inMilliseconds;
      if (stableFrameEvent == null &&
          stableFrameLatencyMs >= QALabMode.shortVisualStableFrameBlockingMs) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.blocking,
            code: 'short_transition_visual_missing',
            message:
                'Short page settled, but QA never confirmed a visually stable frame before the transition threshold.',
            route: route,
            surface: surface,
            timestamp: latestSettle.timestamp,
            context: <String, dynamic>{
              'docId': expectedDocId,
              'scrollToken': scrollToken,
              'stableFrameLatencyMs': stableFrameLatencyMs,
            },
          ),
        );
      } else if (stableFrameEvent != null &&
          stableFrameLatencyMs >= QALabMode.shortVisualStableFrameWarningMs) {
        findings.add(
          QALabPinpointFinding(
            severity: stableFrameLatencyMs >=
                    QALabMode.shortVisualStableFrameBlockingMs
                ? QALabIssueSeverity.error
                : QALabIssueSeverity.warning,
            code: 'short_transition_visual_slow',
            message:
                'Short transition reached a visually stable frame too late after scroll settle.',
            route: route,
            surface: surface,
            timestamp: stableFrameEvent.timestamp,
            context: <String, dynamic>{
              'docId': expectedDocId,
              'scrollToken': scrollToken,
              'stableFrameLatencyMs': stableFrameLatencyMs,
              'positionMs': _asInt(stableFrameEvent.metadata['positionMs']),
              'isPlaying': stableFrameEvent.metadata['isPlaying'] == true,
              'isBuffering': stableFrameEvent.metadata['isBuffering'] == true,
            },
          ),
        );
      }
    }

    final duplicateBursts = _duplicatePlaybackDispatchBursts(
      surfaceTimeline: surfaceTimeline,
      docId: expectedDocId,
      after: latestSettle.timestamp,
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

    if (surface == 'short') {
      final retryEvents = surfaceTimeline
          .where((event) => event.category == 'playback_dispatch')
          .where((event) => !event.timestamp.isBefore(latestSettle.timestamp))
          .where(
            (event) =>
                (event.metadata['docId'] ?? '').toString() == expectedDocId,
          )
          .where(
            (event) =>
                event.code == 'short_watchdog_play_retry' ||
                event.code == 'short_stall_recovery_play',
          )
          .toList(growable: false);
      if (retryEvents.length >= 2) {
        findings.add(
          QALabPinpointFinding(
            severity: retryEvents.length >= 3 ||
                    retryEvents.any(
                      (event) => event.code == 'short_stall_recovery_play',
                    )
                ? QALabIssueSeverity.error
                : QALabIssueSeverity.warning,
            code: 'short_playback_retry_burst',
            message:
                'Short playback needed repeated recovery play commands after page settle.',
            route: route,
            surface: surface,
            timestamp: retryEvents.last.timestamp,
            context: <String, dynamic>{
              'docId': expectedDocId,
              'retryCount': retryEvents.length,
              'stages': retryEvents
                  .map((event) => event.code)
                  .toList(growable: false),
              'maxRetry': retryEvents
                  .map((event) => _asInt(event.metadata['retry']))
                  .fold<int>(0, (left, right) => left > right ? left : right),
              'elapsedMs': retryEvents.last.timestamp
                  .difference(latestSettle.timestamp)
                  .inMilliseconds,
            },
          ),
        );
      }
    }

    return findings;
  }
}
