part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimeIssuePart on QALabRecorder {
  List<QALabPinpointFinding> _buildAdSurfaceFindings({
    required String surface,
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime referenceTime,
    required String route,
  }) {
    final adEvents = surfaceTimeline
        .where((event) => event.category == 'ad')
        .toList(growable: false);
    if (adEvents.isEmpty) {
      return const <QALabPinpointFinding>[];
    }
    final latestRequest = adEvents
        .where((event) => event.code == 'requested')
        .toList(growable: false)
        .lastOrNull;
    final latestLoad = adEvents
        .where((event) => event.code == 'loaded')
        .toList(growable: false)
        .lastOrNull;
    final failureCount =
        adEvents.where((event) => event.code == 'failed').length;
    final retryCount =
        adEvents.where((event) => event.code == 'retry_scheduled').length;
    final findings = <QALabPinpointFinding>[];

    if (latestLoad != null) {
      final latencyMs = _asInt(latestLoad.metadata['latencyMs']);
      if (latencyMs >= QALabMode.adLoadWarningMs) {
        findings.add(
          QALabPinpointFinding(
            severity: latencyMs >= QALabMode.adLoadBlockingMs
                ? QALabIssueSeverity.error
                : QALabIssueSeverity.warning,
            code: '${surface}_ad_load_slow',
            message:
                'An ad on $surface loaded slowly enough to risk visible UI delay.',
            route: route,
            surface: surface,
            timestamp: latestLoad.timestamp,
            context: <String, dynamic>{
              'placement': (latestLoad.metadata['placement'] ?? '').toString(),
              'latencyMs': latencyMs,
            },
          ),
        );
      }
    }

    if (latestRequest != null &&
        latestLoad == null &&
        referenceTime.difference(latestRequest.timestamp).inMilliseconds >=
            QALabMode.adLoadBlockingMs) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.warning,
          code: '${surface}_ad_load_stuck',
          message:
              'An ad request on $surface stayed unresolved long enough to risk delayed layout or chrome.',
          route: route,
          surface: surface,
          timestamp: latestRequest.timestamp,
          context: <String, dynamic>{
            'placement': (latestRequest.metadata['placement'] ?? '').toString(),
            'elapsedMs': referenceTime
                .difference(latestRequest.timestamp)
                .inMilliseconds,
          },
        ),
      );
    }

    if (failureCount >= 2 || retryCount >= 2) {
      findings.add(
        QALabPinpointFinding(
          severity: failureCount >= 3 || retryCount >= 3
              ? QALabIssueSeverity.error
              : QALabIssueSeverity.warning,
          code: '${surface}_ad_retry_burst',
          message:
              'Ad loading on $surface entered repeated failures or retry bursts.',
          route: route,
          surface: surface,
          timestamp: adEvents.last.timestamp,
          context: <String, dynamic>{
            'failureCount': failureCount,
            'retryCount': retryCount,
          },
        ),
      );
    }

    return findings;
  }

  (int, int, int, int) _adSummary(List<QALabTimelineEvent> surfaceTimeline) {
    final adEvents = surfaceTimeline
        .where((event) => event.category == 'ad')
        .toList(growable: false);
    final requestCount =
        adEvents.where((event) => event.code == 'requested').length;
    final loadCount = adEvents.where((event) => event.code == 'loaded').length;
    final failureCount =
        adEvents.where((event) => event.code == 'failed').length;
    final worstLoadMs = adEvents
        .where((event) => event.code == 'loaded')
        .map((event) => _asInt(event.metadata['latencyMs']))
        .fold<int>(0, (left, right) => left > right ? left : right);
    return (requestCount, loadCount, failureCount, worstLoadMs);
  }

  List<QALabPinpointFinding> _buildCacheSurfaceFindings({
    required String surface,
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
    required String route,
  }) {
    final cacheFailures = surfaceIssues
        .where((issue) => issue.code == 'cache_first_failed')
        .toList(growable: false);
    if (cacheFailures.isEmpty) return const <QALabPinpointFinding>[];
    final severity = cacheFailures.length >= 3
        ? QALabIssueSeverity.error
        : QALabIssueSeverity.warning;
    return <QALabPinpointFinding>[
      QALabPinpointFinding(
        severity: severity,
        code: '${surface}_cache_live_failures',
        message:
            'Cache-first live sync failures were detected on $surface during this session.',
        route: route,
        surface: surface,
        timestamp: referenceTime,
        context: <String, dynamic>{
          'failureCount': cacheFailures.length,
        },
      ),
    ];
  }

  List<QALabPinpointFinding> _buildAudioSurfaceFindings({
    required String surface,
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed' && surface != 'short') {
      return const <QALabPinpointFinding>[];
    }
    const runIntegrationSmoke = bool.fromEnvironment(
      'RUN_INTEGRATION_SMOKE',
      defaultValue: false,
    );
    if (surface == 'short' && runIntegrationSmoke) {
      return const <QALabPinpointFinding>[];
    }
    final endedSessions = surfaceIssues
        .where((issue) => issue.code == 'video_session_ended')
        .toList(growable: false);
    final stableEndedSessions = endedSessions
        .where((issue) => issue.metadata['hasStableFocus'] == true)
        .toList(growable: false);
    if (stableEndedSessions.length < 2) {
      return const <QALabPinpointFinding>[];
    }

    var audibleCount = 0;
    var mutedCount = 0;
    for (final issue in stableEndedSessions) {
      final isAudible = issue.metadata['isAudible'] == true;
      if (isAudible) {
        audibleCount += 1;
      } else {
        mutedCount += 1;
      }
    }

    if (audibleCount == 0 ||
        mutedCount == 0 ||
        audibleCount < 2 ||
        mutedCount < 2) {
      return const <QALabPinpointFinding>[];
    }

    return <QALabPinpointFinding>[
      QALabPinpointFinding(
        severity: QALabIssueSeverity.error,
        code: '${surface}_audio_state_inconsistent',
        message:
            'Videos on $surface finished with mixed audible and muted states during the same session.',
        route: route,
        surface: surface,
        timestamp: referenceTime,
        context: <String, dynamic>{
          'audibleSessionCount': audibleCount,
          'mutedSessionCount': mutedCount,
          'stableSessionCount': stableEndedSessions.length,
        },
      ),
    ];
  }
}
