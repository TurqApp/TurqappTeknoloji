part of 'qa_lab_recorder.dart';

Future<void> _qaLabSyncRemoteSummary(
  QALabRecorder recorder, {
  required String reason,
  required bool immediate,
  Map<String, dynamic>? extendedDeviceInfoOverride,
}) async {
  if (!QALabMode.enabled || !QALabMode.remoteUploadEnabled) {
    return;
  }
  if (Firebase.apps.isEmpty) {
    return;
  }
  final payload = await _qaLabBuildRemoteSyncPayload(
    recorder,
    reason: reason,
    extendedDeviceInfoOverride: extendedDeviceInfoOverride,
  );
  await ensureQALabRemoteUploader().scheduleUpload(
    sessionDocument: _cloneQaLabExportMap(
      payload['session'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    ),
    occurrences: (payload['occurrences'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_cloneQaLabExportMap)
        .toList(growable: false),
    reason: reason,
    immediate: immediate,
  );
}

Future<Map<String, dynamic>> _qaLabBuildRemoteSyncPayload(
  QALabRecorder recorder, {
  required String reason,
  Map<String, dynamic>? extendedDeviceInfoOverride,
}) async {
  final sessionDocument = await _qaLabBuildRemoteSessionDocument(
    recorder,
    reason: reason,
    extendedDeviceInfoOverride: extendedDeviceInfoOverride,
  );
  return <String, dynamic>{
    'session': sessionDocument,
    'occurrences': _qaLabBuildRemoteIssueOccurrences(
      recorder,
      sessionDocument: sessionDocument,
    ),
  };
}

Future<Map<String, dynamic>> _qaLabBuildRemoteSessionDocument(
  QALabRecorder recorder, {
  required String reason,
  Map<String, dynamic>? extendedDeviceInfoOverride,
}) async {
  if (recorder.sessionId.value.isEmpty) {
    recorder.startSession(trigger: 'remote_sync');
  }
  final now = DateTime.now();
  final currentSnapshot = IntegrationTestStateProbe.snapshot();
  final extendedDeviceInfo = extendedDeviceInfoOverride ??
      await _qaLabGetCachedExtendedDeviceInfo(recorder);
  final packageInfo =
      (extendedDeviceInfo['package'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
  final deviceInfo =
      (extendedDeviceInfo['device'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
  final focusDiagnostics = recorder.buildFocusSurfaceDiagnostics();
  final surfaceAlerts = recorder.buildSurfaceAlertSummaries();
  final alertsBySurface = <String, QALabSurfaceAlertSummary>{
    for (final alert in surfaceAlerts) alert.surface: alert,
  };
  final activeFindings = recorder.buildPinpointFindings();

  return <String, dynamic>{
    'schemaVersion': 1,
    'sessionId': recorder.sessionId.value,
    'generatedAt': now.toUtc().toIso8601String(),
    'startedAt': recorder.startedAt.value?.toUtc().toIso8601String(),
    'platform': defaultTargetPlatform.name,
    'buildMode': _qaLabDeviceInfoSnapshot()['buildMode'],
    'route': <String, dynamic>{
      'lastRoute': recorder.lastRoute.value,
      'lastSurface': recorder.lastSurface.value,
      'lastLifecycleState': recorder.lastLifecycleState.value,
    },
    'app': <String, dynamic>{
      'appName': (packageInfo['appName'] ?? '').toString(),
      'packageName': (packageInfo['packageName'] ?? '').toString(),
      'version': (packageInfo['version'] ?? '').toString(),
      'buildNumber': (packageInfo['buildNumber'] ?? '').toString(),
    },
    'device': <String, dynamic>{
      'platform': defaultTargetPlatform.name,
      'manufacturer': (deviceInfo['manufacturer'] ?? '').toString(),
      'model': (deviceInfo['model'] ?? '').toString(),
      'sdkInt': deviceInfo['sdkInt'],
      'name': (deviceInfo['name'] ?? '').toString(),
      'systemVersion': (deviceInfo['systemVersion'] ?? '').toString(),
    },
    'remote': <String, dynamic>{
      'enabled': QALabMode.remoteUploadEnabled,
      'scope': QALabMode.remoteUploadScope,
      'reason': reason,
    },
    'healthScore': recorder.healthScore,
    'performance': <String, dynamic>{
      'app': _qaLabSanitizeRemoteValue(
        _cloneQaLabExportMap(recorder.appFramePerformance),
      ),
    },
    'permissions': Map<String, String>.from(recorder.lastPermissionStatuses),
    'counts': <String, dynamic>{
      'blocking': recorder.blockingIssueCount,
      'error': recorder.errorIssueCount,
      'warning': recorder.warningIssueCount,
      'info': recorder.issues.length -
          recorder.blockingIssueCount -
          recorder.errorIssueCount -
          recorder.warningIssueCount,
      'issues': recorder.issues.length,
      'activeFindings': activeFindings.length,
      'routes': recorder.routes.length,
      'checkpoints': recorder.checkpoints.length,
      'timeline': recorder.timelineEvents.length,
      'nativePlaybackSamples': recorder.nativePlaybackSamples.length,
    },
    'surfaceSummaries': <String, dynamic>{
      for (final diagnostic in focusDiagnostics)
        diagnostic.surface: <String, dynamic>{
          'latestRoute': diagnostic.latestRoute,
          'healthScore': diagnostic.healthScore,
          'issueCounts': diagnostic.issueCounts,
          'coverageRatio': diagnostic.coverage.coverageRatio,
          'missingTags': diagnostic.coverage.missingTags,
          'runtime': _qaLabRemoteRuntimeSummary(diagnostic.runtime),
          'headlineCode':
              (alertsBySurface[diagnostic.surface]?.headlineCode ?? '')
                  .toString(),
          'headlineMessage':
              (alertsBySurface[diagnostic.surface]?.headlineMessage ?? '')
                  .toString(),
          'primaryRootCauseCategory':
              (alertsBySurface[diagnostic.surface]?.primaryRootCauseCategory ??
                      '')
                  .toString(),
          'primaryRootCauseDetail':
              (alertsBySurface[diagnostic.surface]?.primaryRootCauseDetail ??
                      '')
                  .toString(),
        },
    },
    'topSurfaceAlerts':
        surfaceAlerts.take(8).map((item) => item.toJson()).toList(
              growable: false,
            ),
    'highlightedFindings': activeFindings
        .take(QALabMode.remoteUploadMaxFindings)
        .map(_qaLabRemoteFindingSummary)
        .toList(growable: false),
    'timelineHighlights': _qaLabRemoteTimelineHighlights(
      recorder,
      limit: QALabMode.remoteUploadMaxTimelineEvents,
    ),
    'nativePlayback': _qaLabCompactNativePlaybackSnapshot(
      recorder,
      recorder.lastNativePlaybackSnapshot,
    ),
    'snapshotDigest': _qaLabRemoteSnapshotDigest(currentSnapshot),
  };
}

List<Map<String, dynamic>> _qaLabBuildRemoteIssueOccurrences(
  QALabRecorder recorder, {
  Map<String, dynamic>? sessionDocument,
}) {
  if (recorder.sessionId.value.isEmpty) {
    return const <Map<String, dynamic>>[];
  }
  final session = sessionDocument ?? const <String, dynamic>{};
  final surfaceAlerts = recorder.buildSurfaceAlertSummaries();
  final alertsBySurface = <String, QALabSurfaceAlertSummary>{
    for (final alert in surfaceAlerts) alert.surface: alert,
  };
  final findings = recorder
      .buildPinpointFindings()
      .take(QALabMode.remoteUploadMaxFindings)
      .toList(growable: false);
  final device = (session['device'] as Map?)?.cast<String, dynamic>() ??
      const <String, dynamic>{};
  final app = (session['app'] as Map?)?.cast<String, dynamic>() ??
      const <String, dynamic>{};
  final platform =
      (session['platform'] ?? defaultTargetPlatform.name).toString();
  final buildMode =
      (session['buildMode'] ?? _qaLabDeviceInfoSnapshot()['buildMode'])
          .toString();

  return findings.map((finding) {
    final surfaceAlert = alertsBySurface[finding.surface];
    final signature = _qaLabRemoteIssueSignature(
      surface: finding.surface,
      code: finding.code,
      rootCauseCategory: surfaceAlert?.primaryRootCauseCategory ?? 'unknown',
      platform: platform,
      buildMode: buildMode,
    );
    return <String, dynamic>{
      'occurrenceId': '${recorder.sessionId.value}_$signature',
      'signature': signature,
      'sessionId': recorder.sessionId.value,
      'surface': finding.surface,
      'route': finding.route,
      'code': finding.code,
      'severity': finding.severity.name,
      'message': finding.message,
      'summary': _qaLabRemoteOccurrenceSummary(
        finding: finding,
        surfaceAlert: surfaceAlert,
      ),
      'timestamp': finding.timestamp.toUtc().toIso8601String(),
      'rootCauseCategory':
          (surfaceAlert?.primaryRootCauseCategory ?? '').toString(),
      'rootCauseDetail':
          (surfaceAlert?.primaryRootCauseDetail ?? '').toString(),
      'headlineCode': (surfaceAlert?.headlineCode ?? finding.code).toString(),
      'headlineMessage':
          (surfaceAlert?.headlineMessage ?? finding.message).toString(),
      'eventCount': 1,
      'platform': platform,
      'buildMode': buildMode,
      'deviceModel': (device['model'] ?? '').toString(),
      'appVersion': (app['version'] ?? '').toString(),
      'context': _qaLabSanitizeRemoteValue(finding.context),
      'timeline': _qaLabRemoteTimelineHighlights(
        recorder,
        surface: finding.surface,
        route: finding.route,
        limit: 6,
      ),
      if (finding.surface == 'feed' || finding.surface == 'short')
        'nativePlayback': _qaLabCompactNativePlaybackSnapshot(
          recorder,
          recorder.lastNativePlaybackSnapshot,
        ),
    };
  }).toList(growable: false);
}
