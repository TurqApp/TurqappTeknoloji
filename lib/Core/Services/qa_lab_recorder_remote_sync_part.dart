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
  await QALabRemoteUploader.ensure().scheduleUpload(
    sessionDocument: Map<String, dynamic>.from(
      payload['session'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    ),
    occurrences: (payload['occurrences'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
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

Map<String, dynamic> _qaLabDeviceInfoSnapshot() {
  return <String, dynamic>{
    'platform': defaultTargetPlatform.name,
    'buildMode': kReleaseMode
        ? 'release'
        : kProfileMode
            ? 'profile'
            : 'debug',
  };
}

Future<Map<String, dynamic>> _qaLabBuildExtendedDeviceInfo(
  QALabRecorder recorder,
) async {
  if (recorder._cachedExtendedDeviceInfo != null) {
    return Map<String, dynamic>.from(recorder._cachedExtendedDeviceInfo!);
  }
  final packageInfo = await PackageInfo.fromPlatform();
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo =
      GetPlatform.isAndroid ? await deviceInfo.androidInfo : null;
  final iosInfo = GetPlatform.isIOS ? await deviceInfo.iosInfo : null;
  final snapshot = <String, dynamic>{
    'package': <String, dynamic>{
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    },
    'device': <String, dynamic>{
      if (androidInfo != null) 'manufacturer': androidInfo.manufacturer,
      if (androidInfo != null) 'model': androidInfo.model,
      if (androidInfo != null) 'sdkInt': androidInfo.version.sdkInt,
      if (iosInfo != null) 'name': iosInfo.name,
      if (iosInfo != null) 'model': iosInfo.model,
      if (iosInfo != null) 'systemVersion': iosInfo.systemVersion,
    },
  };
  recorder._cachedExtendedDeviceInfo = snapshot;
  return Map<String, dynamic>.from(snapshot);
}

Future<Map<String, dynamic>> _qaLabGetCachedExtendedDeviceInfo(
  QALabRecorder recorder,
) {
  final cached = recorder._cachedExtendedDeviceInfo;
  if (cached != null) {
    return Future<Map<String, dynamic>>.value(
      Map<String, dynamic>.from(cached),
    );
  }
  final inFlight = recorder._extendedDeviceInfoFuture;
  if (inFlight != null) {
    return inFlight;
  }
  final future = _qaLabBuildExtendedDeviceInfo(recorder);
  recorder._extendedDeviceInfoFuture = future.whenComplete(() {
    recorder._extendedDeviceInfoFuture = null;
  });
  return recorder._extendedDeviceInfoFuture!;
}

Map<String, dynamic> _qaLabRemoteSyncSnapshot(QALabRecorder recorder) {
  final uploader = QALabRemoteUploader.maybeFind();
  return <String, dynamic>{
    'enabled': QALabMode.remoteUploadEnabled,
    'scope': QALabMode.remoteUploadScope,
    if (uploader != null) 'state': uploader.lastSyncState.value,
    if (uploader != null) 'reason': uploader.lastSyncReason.value,
    if (uploader != null)
      'lastSyncedAt': uploader.lastSyncedAt.value?.toUtc().toIso8601String(),
    if (uploader != null) 'uploadCount': uploader.uploadCount.value,
    if (uploader != null)
      'uploadedOccurrenceCount': uploader.uploadedOccurrenceCount.value,
    if (uploader != null) 'lastError': uploader.lastSyncError.value,
  };
}

Map<String, dynamic> _qaLabRemoteRuntimeSummary(Map<String, dynamic> runtime) {
  const keys = <String>[
    'checkpointCount',
    'runtimeFindingCount',
    'blankSnapshotCount',
    'videoSessionStartCount',
    'videoFirstFrameCount',
    'cacheFailureCount',
    'jankEventCount',
    'worstFrameJankMs',
    'duplicateFeedTriggerCount',
    'duplicatePlaybackDispatchCount',
    'latestScrollDispatchLatencyMs',
    'latestScrollFirstFrameLatencyMs',
    'adRequestCount',
    'adLoadCount',
    'adFailureCount',
    'worstAdLoadMs',
    'nativePlaybackStatus',
    'nativePlaybackErrorCount',
    'nativePlaybackPlaying',
    'nativePlaybackBuffering',
    'nativePlaybackFirstFrame',
    'nativePlaybackStallCount',
  ];
  return <String, dynamic>{
    for (final key in keys)
      if (runtime.containsKey(key))
        key: _qaLabSanitizeRemoteValue(runtime[key]),
  };
}

Map<String, dynamic> _qaLabRemoteFindingSummary(
  QALabPinpointFinding finding,
) {
  return <String, dynamic>{
    'code': finding.code,
    'severity': finding.severity.name,
    'surface': finding.surface,
    'route': finding.route,
    'message': finding.message,
    'timestamp': finding.timestamp.toUtc().toIso8601String(),
    'context': _qaLabSanitizeRemoteValue(finding.context),
  };
}

String _qaLabRemoteOccurrenceSummary({
  required QALabPinpointFinding finding,
  QALabSurfaceAlertSummary? surfaceAlert,
}) {
  final rootCause = (surfaceAlert?.primaryRootCauseCategory ?? '').trim();
  final route = finding.route.trim().isEmpty ? '-' : finding.route.trim();
  final rootLabel = rootCause.isEmpty ? '' : ' [$rootCause]';
  return '${finding.surface} $route :: ${finding.code}$rootLabel :: ${finding.message}';
}

List<Map<String, dynamic>> _qaLabRemoteTimelineHighlights(
  QALabRecorder recorder, {
  String? surface,
  String? route,
  int limit = 8,
}) {
  final filtered = recorder.timelineEvents.where((event) {
    if (surface != null && surface.trim().isNotEmpty) {
      if (event.surface.trim() != surface.trim()) {
        return false;
      }
    }
    if (route != null && route.trim().isNotEmpty) {
      if (event.route.trim() != route.trim()) {
        return false;
      }
    }
    return true;
  }).toList(growable: false);
  final slice = filtered.length <= limit
      ? filtered
      : filtered.sublist(filtered.length - limit);
  return slice
      .map(
        (event) => <String, dynamic>{
          'category': event.category,
          'code': event.code,
          'surface': event.surface,
          'route': event.route,
          'timestamp': event.timestamp.toUtc().toIso8601String(),
          'metadata': _qaLabSanitizeRemoteValue(event.metadata),
        },
      )
      .toList(growable: false);
}

Map<String, dynamic> _qaLabCompactNativePlaybackSnapshot(
  QALabRecorder recorder,
  Map<String, dynamic> snapshot,
) {
  if (snapshot.isEmpty) {
    return const <String, dynamic>{};
  }
  return <String, dynamic>{
    'platform': (snapshot['platform'] ?? '').toString(),
    'status': (snapshot['status'] ?? '').toString(),
    'errors': recorder._nativePlaybackErrors(snapshot),
    'active': snapshot['active'] == true,
    'firstFrameRendered': snapshot['firstFrameRendered'] == true,
    'isPlaybackExpected': snapshot['isPlaybackExpected'] == true,
    'isPlaying': snapshot['isPlaying'] == true,
    'isBuffering': snapshot['isBuffering'] == true,
    'stallCount': recorder._asInt(snapshot['stallCount']),
    'lastKnownPlaybackTime':
        recorder._asDouble(snapshot['lastKnownPlaybackTime']),
    'sampledAt': (snapshot['sampledAt'] ?? '').toString(),
    'trigger': (snapshot['trigger'] ?? '').toString(),
  };
}

Map<String, dynamic> _qaLabRemoteSnapshotDigest(Map<String, dynamic> snapshot) {
  final digest = <String, dynamic>{
    'currentRoute': (snapshot['currentRoute'] ?? '').toString(),
    'keys': snapshot.keys.take(24).map((item) => item.toString()).toList(),
  };
  for (final key in <String>[
    'auth',
    'feed',
    'short',
    'videoPlayback',
    'notifications',
    'chatConversation',
    'story',
    'pasaj',
    'profile',
    'settings',
    'upload',
    'explore',
  ]) {
    final value = snapshot[key];
    if (value is Map) {
      digest[key] = _qaLabSanitizeRemoteValue(value);
    }
  }
  return digest;
}

Object? _qaLabSanitizeRemoteValue(
  Object? value, {
  int depth = 0,
}) {
  if (value == null || value is num || value is bool) {
    return value;
  }
  if (value is String) {
    return value.length <= 260 ? value : '${value.substring(0, 257)}...';
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is Map) {
    if (depth >= 2) {
      return <String, dynamic>{
        'keys': value.keys.take(12).map((item) => item.toString()).toList(),
      };
    }
    final result = <String, dynamic>{};
    for (final entry in value.entries.take(12)) {
      final key = entry.key.toString();
      if (key == 'probe' || key.toLowerCase().contains('stack')) {
        continue;
      }
      result[key] = _qaLabSanitizeRemoteValue(entry.value, depth: depth + 1);
    }
    return result;
  }
  if (value is Iterable) {
    final items = value.take(7).map((item) {
      return _qaLabSanitizeRemoteValue(item, depth: depth + 1);
    }).toList(growable: true);
    if (value.length > 7) {
      items.add('...');
    }
    return items;
  }
  return value.toString();
}

String _qaLabRemoteIssueSignature({
  required String surface,
  required String code,
  required String rootCauseCategory,
  required String platform,
  required String buildMode,
}) {
  final base = <String>[
    surface.trim().toLowerCase(),
    code.trim().toLowerCase(),
    rootCauseCategory.trim().toLowerCase(),
    platform.trim().toLowerCase(),
    buildMode.trim().toLowerCase(),
  ].join('|');
  return _qaLabStableHash(base);
}

String _qaLabStableHash(String input) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(input)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
