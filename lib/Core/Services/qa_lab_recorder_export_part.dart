part of 'qa_lab_recorder.dart';

extension QALabRecorderExportPart on QALabRecorder {
  int get blockingIssueCount => issues
      .where((issue) => issue.severity == QALabIssueSeverity.blocking)
      .length;

  int get errorIssueCount => issues
      .where((issue) => issue.severity == QALabIssueSeverity.error)
      .length;

  int get warningIssueCount => issues
      .where((issue) => issue.severity == QALabIssueSeverity.warning)
      .length;

  int get healthScore {
    final raw = 100 -
        (blockingIssueCount * 25) -
        (errorIssueCount * 10) -
        (warningIssueCount * 4);
    if (raw < 0) return 0;
    if (raw > 100) return 100;
    return raw;
  }

  List<QALabPinpointFinding> buildPinpointFindings() {
    final findings = <QALabPinpointFinding>[
      ..._buildActiveIssueFindings(),
      ..._buildPrioritySurfaceFindings(),
      ..._buildTelemetryThresholdFindings(),
    ];
    findings.sort(_compareFindings);
    return _dedupeFindings(findings);
  }

  List<QALabSurfaceDiagnostic> buildFocusSurfaceDiagnostics() {
    return _observedSurfaces()
        .map(_buildSurfaceDiagnostic)
        .toList(growable: false);
  }

  List<QALabSurfaceAlertSummary> buildSurfaceAlertSummaries() {
    final diagnostics = buildFocusSurfaceDiagnostics();
    final findings = buildPinpointFindings();
    final findingsBySurface = <String, List<QALabPinpointFinding>>{};
    for (final finding in findings) {
      findingsBySurface
          .putIfAbsent(finding.surface, () => <QALabPinpointFinding>[])
          .add(finding);
    }

    final summaries = diagnostics
        .map((diagnostic) {
          final surfaceFindings =
              findingsBySurface[diagnostic.surface] ?? const [];
          if (surfaceFindings.isEmpty &&
              diagnostic.healthScore == 100 &&
              diagnostic.coverage.complete) {
            return null;
          }
          final blockingCount = surfaceFindings
              .where((item) => item.severity == QALabIssueSeverity.blocking)
              .length;
          final errorCount = surfaceFindings
              .where((item) => item.severity == QALabIssueSeverity.error)
              .length;
          final warningCount = surfaceFindings
              .where((item) => item.severity == QALabIssueSeverity.warning)
              .length;
          final headline =
              surfaceFindings.isEmpty ? null : surfaceFindings.first;
          final headlineCode = headline?.code ??
              (diagnostic.coverage.complete
                  ? 'surface_attention'
                  : 'coverage_gap');
          final headlineMessage = headline?.message ??
              (diagnostic.coverage.complete
                  ? '${diagnostic.surface} surface has low health without a pinpoint finding.'
                  : '${diagnostic.surface} surface still has QA coverage gaps.');
          final rootCause =
              _inferPrimaryRootCause(diagnostic, surfaceFindings, headlineCode);
          return QALabSurfaceAlertSummary(
            surface: diagnostic.surface,
            latestRoute: diagnostic.latestRoute,
            healthScore: diagnostic.healthScore,
            blockingCount: blockingCount,
            errorCount: errorCount,
            warningCount: warningCount,
            findingCount: surfaceFindings.length,
            headlineCode: headlineCode,
            headlineMessage: headlineMessage,
            primaryRootCauseCategory: rootCause.$1,
            primaryRootCauseDetail: rootCause.$2,
          );
        })
        .whereType<QALabSurfaceAlertSummary>()
        .toList(growable: false);
    summaries.sort(_compareSurfaceAlertSummaries);
    return summaries;
  }

  Map<String, dynamic> buildExportJson() {
    final currentSnapshot = IntegrationTestStateProbe.snapshot();
    final playbackKpi = PlaybackKpiService.maybeFind();
    final runtimeHealthExport = playbackKpi == null
        ? const <String, dynamic>{}
        : RuntimeHealthExporter.exportFromKpiService(playbackKpi);
    final thresholdReport = runtimeHealthExport['thresholdReport']
            as Map<String, dynamic>? ??
        (playbackKpi == null
            ? const <String, dynamic>{}
            : TelemetryThresholdPolicyAdapter.evaluateKpiService(playbackKpi)
                .toJson());
    final surfaceDiagnostics = buildFocusSurfaceDiagnostics();
    final surfaceAlerts = buildSurfaceAlertSummaries();
    final activeFindings = buildPinpointFindings();

    return <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'session': <String, dynamic>{
        'sessionId': sessionId.value,
        'startedAt': startedAt.value?.toUtc().toIso8601String(),
        'lastRoute': lastRoute.value,
        'lastSurface': lastSurface.value,
        'lastLifecycleState': lastLifecycleState.value,
        'healthScore': healthScore,
        'issueCounts': <String, dynamic>{
          'blocking': blockingIssueCount,
          'error': errorIssueCount,
          'warning': warningIssueCount,
          'info': issues.length -
              blockingIssueCount -
              errorIssueCount -
              warningIssueCount,
        },
      },
      'catalog': <String, dynamic>{
        'summary': QALabCatalog.summaryJson(),
        'entries': QALabCatalog.entries
            .map((entry) => entry.toJson())
            .toList(growable: false),
      },
      'executiveSummary': <String, dynamic>{
        'activeFindingCount': activeFindings.length,
        'blockingSurfaceCount':
            surfaceAlerts.where((item) => item.blockingCount > 0).length,
        'errorSurfaceCount':
            surfaceAlerts.where((item) => item.errorCount > 0).length,
        'warningSurfaceCount':
            surfaceAlerts.where((item) => item.warningCount > 0).length,
        'topSurfaceAlerts':
            surfaceAlerts.take(8).map((item) => item.toJson()).toList(),
      },
      'device': _deviceInfoSnapshot(),
      'permissions': Map<String, String>.from(lastPermissionStatuses),
      'nativePlayback': <String, dynamic>{
        'latestSnapshot': Map<String, dynamic>.from(lastNativePlaybackSnapshot),
        'sampleCount': nativePlaybackSamples.length,
        'samples': nativePlaybackSamples.toList(growable: false),
      },
      'remoteSync': _remoteSyncSnapshot(),
      'currentSnapshot': currentSnapshot,
      'routes': routes.map((event) => event.toJson()).toList(growable: false),
      'timeline':
          timelineEvents.map((event) => event.toJson()).toList(growable: false),
      'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
      'pinpointFindings':
          activeFindings.map((item) => item.toJson()).toList(growable: false),
      'surfaceDiagnostics': surfaceDiagnostics
          .map((item) => item.toJson())
          .toList(growable: false),
      'checkpoints': checkpoints
          .map((checkpoint) => checkpoint.toJson())
          .toList(growable: false),
      'telemetryThresholdReport': thresholdReport,
      'runtimeHealthExport': runtimeHealthExport,
    };
  }

  Future<File> exportSessionJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final qaDir = Directory('${directory.path}/qa_lab');
    if (!qaDir.existsSync()) {
      qaDir.createSync(recursive: true);
    }
    final file = File('${qaDir.path}/qa_report_${sessionId.value}.json');
    final exportJson = buildExportJson();
    exportJson['extendedDeviceInfo'] = await buildExtendedDeviceInfo();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(exportJson),
    );
    lastExportPath.value = file.path;
    return file;
  }

  Future<void> shareLatestExport() async {
    final file = lastExportPath.value.trim().isNotEmpty
        ? File(lastExportPath.value.trim())
        : await exportSessionJson();
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path)],
        subject: 'TurqApp QA Lab Report',
        text: 'TurqApp QA Lab diagnostic export',
      ),
    );
  }

  Future<void> syncRemoteSummary({
    String reason = 'manual',
    bool immediate = true,
    Map<String, dynamic>? extendedDeviceInfoOverride,
  }) async {
    if (!QALabMode.enabled || !QALabMode.remoteUploadEnabled) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      return;
    }
    final payload = await buildRemoteSyncPayload(
      reason: reason,
      extendedDeviceInfoOverride: extendedDeviceInfoOverride,
    );
    await QALabRemoteUploader.ensure().scheduleUpload(
      sessionDocument: Map<String, dynamic>.from(
        payload['session'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      occurrences:
          (payload['occurrences'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false),
      reason: reason,
      immediate: immediate,
    );
  }

  Future<Map<String, dynamic>> buildRemoteSyncPayload({
    required String reason,
    Map<String, dynamic>? extendedDeviceInfoOverride,
  }) async {
    final sessionDocument = await buildRemoteSessionDocument(
      reason: reason,
      extendedDeviceInfoOverride: extendedDeviceInfoOverride,
    );
    return <String, dynamic>{
      'session': sessionDocument,
      'occurrences': buildRemoteIssueOccurrences(
        sessionDocument: sessionDocument,
      ),
    };
  }

  Future<Map<String, dynamic>> buildRemoteSessionDocument({
    required String reason,
    Map<String, dynamic>? extendedDeviceInfoOverride,
  }) async {
    if (sessionId.value.isEmpty) {
      startSession(trigger: 'remote_sync');
    }
    final now = DateTime.now();
    final currentSnapshot = IntegrationTestStateProbe.snapshot();
    final extendedDeviceInfo =
        extendedDeviceInfoOverride ?? await _getCachedExtendedDeviceInfo();
    final packageInfo =
        (extendedDeviceInfo['package'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final deviceInfo =
        (extendedDeviceInfo['device'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final focusDiagnostics = buildFocusSurfaceDiagnostics();
    final surfaceAlerts = buildSurfaceAlertSummaries();
    final alertsBySurface = <String, QALabSurfaceAlertSummary>{
      for (final alert in surfaceAlerts) alert.surface: alert,
    };
    final activeFindings = buildPinpointFindings();

    return <String, dynamic>{
      'schemaVersion': 1,
      'sessionId': sessionId.value,
      'generatedAt': now.toUtc().toIso8601String(),
      'startedAt': startedAt.value?.toUtc().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      'buildMode': _deviceInfoSnapshot()['buildMode'],
      'route': <String, dynamic>{
        'lastRoute': lastRoute.value,
        'lastSurface': lastSurface.value,
        'lastLifecycleState': lastLifecycleState.value,
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
      'healthScore': healthScore,
      'permissions': Map<String, String>.from(lastPermissionStatuses),
      'counts': <String, dynamic>{
        'blocking': blockingIssueCount,
        'error': errorIssueCount,
        'warning': warningIssueCount,
        'info': issues.length -
            blockingIssueCount -
            errorIssueCount -
            warningIssueCount,
        'issues': issues.length,
        'activeFindings': activeFindings.length,
        'routes': routes.length,
        'checkpoints': checkpoints.length,
        'timeline': timelineEvents.length,
        'nativePlaybackSamples': nativePlaybackSamples.length,
      },
      'surfaceSummaries': <String, dynamic>{
        for (final diagnostic in focusDiagnostics)
          diagnostic.surface: <String, dynamic>{
            'latestRoute': diagnostic.latestRoute,
            'healthScore': diagnostic.healthScore,
            'issueCounts': diagnostic.issueCounts,
            'coverageRatio': diagnostic.coverage.coverageRatio,
            'missingTags': diagnostic.coverage.missingTags,
            'runtime': _remoteRuntimeSummary(diagnostic.runtime),
            'headlineCode':
                (alertsBySurface[diagnostic.surface]?.headlineCode ?? '')
                    .toString(),
            'headlineMessage':
                (alertsBySurface[diagnostic.surface]?.headlineMessage ?? '')
                    .toString(),
            'primaryRootCauseCategory': (alertsBySurface[diagnostic.surface]
                        ?.primaryRootCauseCategory ??
                    '')
                .toString(),
            'primaryRootCauseDetail':
                (alertsBySurface[diagnostic.surface]?.primaryRootCauseDetail ??
                        '')
                    .toString(),
          },
      },
      'topSurfaceAlerts': surfaceAlerts
          .take(8)
          .map((item) => item.toJson())
          .toList(growable: false),
      'highlightedFindings': activeFindings
          .take(QALabMode.remoteUploadMaxFindings)
          .map(_remoteFindingSummary)
          .toList(growable: false),
      'timelineHighlights': _remoteTimelineHighlights(
        limit: QALabMode.remoteUploadMaxTimelineEvents,
      ),
      'nativePlayback':
          _compactNativePlaybackSnapshot(lastNativePlaybackSnapshot),
      'snapshotDigest': _remoteSnapshotDigest(currentSnapshot),
    };
  }

  List<Map<String, dynamic>> buildRemoteIssueOccurrences({
    Map<String, dynamic>? sessionDocument,
  }) {
    if (sessionId.value.isEmpty) {
      return const <Map<String, dynamic>>[];
    }
    final session = sessionDocument ?? const <String, dynamic>{};
    final surfaceAlerts = buildSurfaceAlertSummaries();
    final alertsBySurface = <String, QALabSurfaceAlertSummary>{
      for (final alert in surfaceAlerts) alert.surface: alert,
    };
    final findings = buildPinpointFindings()
        .take(QALabMode.remoteUploadMaxFindings)
        .toList(growable: false);
    final device = (session['device'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final app = (session['app'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final platform =
        (session['platform'] ?? defaultTargetPlatform.name).toString();
    final buildMode =
        (session['buildMode'] ?? _deviceInfoSnapshot()['buildMode']).toString();

    return findings.map((finding) {
      final surfaceAlert = alertsBySurface[finding.surface];
      final signature = _remoteIssueSignature(
        surface: finding.surface,
        code: finding.code,
        rootCauseCategory: surfaceAlert?.primaryRootCauseCategory ?? 'unknown',
        platform: platform,
        buildMode: buildMode,
      );
      return <String, dynamic>{
        'occurrenceId': '${sessionId.value}_$signature',
        'signature': signature,
        'sessionId': sessionId.value,
        'surface': finding.surface,
        'route': finding.route,
        'code': finding.code,
        'severity': finding.severity.name,
        'message': finding.message,
        'summary': _remoteOccurrenceSummary(
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
        'context': _sanitizeRemoteValue(finding.context),
        'timeline': _remoteTimelineHighlights(
          surface: finding.surface,
          route: finding.route,
          limit: 6,
        ),
        if (finding.surface == 'feed' || finding.surface == 'short')
          'nativePlayback':
              _compactNativePlaybackSnapshot(lastNativePlaybackSnapshot),
      };
    }).toList(growable: false);
  }

  Map<String, dynamic> _deviceInfoSnapshot() {
    return <String, dynamic>{
      'platform': defaultTargetPlatform.name,
      'buildMode': kReleaseMode
          ? 'release'
          : kProfileMode
              ? 'profile'
              : 'debug',
    };
  }

  Future<Map<String, dynamic>> buildExtendedDeviceInfo() async {
    if (_cachedExtendedDeviceInfo != null) {
      return Map<String, dynamic>.from(_cachedExtendedDeviceInfo!);
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
    _cachedExtendedDeviceInfo = snapshot;
    return Map<String, dynamic>.from(snapshot);
  }

  Future<Map<String, dynamic>> _getCachedExtendedDeviceInfo() {
    final cached = _cachedExtendedDeviceInfo;
    if (cached != null) {
      return Future<Map<String, dynamic>>.value(
        Map<String, dynamic>.from(cached),
      );
    }
    final inFlight = _extendedDeviceInfoFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = buildExtendedDeviceInfo();
    _extendedDeviceInfoFuture = future.whenComplete(() {
      _extendedDeviceInfoFuture = null;
    });
    return _extendedDeviceInfoFuture!;
  }

  Map<String, dynamic> _remoteSyncSnapshot() {
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

  Map<String, dynamic> _remoteRuntimeSummary(Map<String, dynamic> runtime) {
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
        if (runtime.containsKey(key)) key: _sanitizeRemoteValue(runtime[key]),
    };
  }

  Map<String, dynamic> _remoteFindingSummary(QALabPinpointFinding finding) {
    return <String, dynamic>{
      'code': finding.code,
      'severity': finding.severity.name,
      'surface': finding.surface,
      'route': finding.route,
      'message': finding.message,
      'timestamp': finding.timestamp.toUtc().toIso8601String(),
      'context': _sanitizeRemoteValue(finding.context),
    };
  }

  String _remoteOccurrenceSummary({
    required QALabPinpointFinding finding,
    QALabSurfaceAlertSummary? surfaceAlert,
  }) {
    final rootCause = (surfaceAlert?.primaryRootCauseCategory ?? '').trim();
    final route = finding.route.trim().isEmpty ? '-' : finding.route.trim();
    final rootLabel = rootCause.isEmpty ? '' : ' [$rootCause]';
    return '${finding.surface} $route :: ${finding.code}$rootLabel :: ${finding.message}';
  }

  List<Map<String, dynamic>> _remoteTimelineHighlights({
    String? surface,
    String? route,
    int limit = 8,
  }) {
    final filtered = timelineEvents.where((event) {
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
            'metadata': _sanitizeRemoteValue(event.metadata),
          },
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _compactNativePlaybackSnapshot(
    Map<String, dynamic> snapshot,
  ) {
    if (snapshot.isEmpty) {
      return const <String, dynamic>{};
    }
    return <String, dynamic>{
      'platform': (snapshot['platform'] ?? '').toString(),
      'status': (snapshot['status'] ?? '').toString(),
      'errors': _nativePlaybackErrors(snapshot),
      'active': snapshot['active'] == true,
      'firstFrameRendered': snapshot['firstFrameRendered'] == true,
      'isPlaybackExpected': snapshot['isPlaybackExpected'] == true,
      'isPlaying': snapshot['isPlaying'] == true,
      'isBuffering': snapshot['isBuffering'] == true,
      'stallCount': _asInt(snapshot['stallCount']),
      'lastKnownPlaybackTime': _asDouble(snapshot['lastKnownPlaybackTime']),
      'sampledAt': (snapshot['sampledAt'] ?? '').toString(),
      'trigger': (snapshot['trigger'] ?? '').toString(),
    };
  }

  Map<String, dynamic> _remoteSnapshotDigest(Map<String, dynamic> snapshot) {
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
        digest[key] = _sanitizeRemoteValue(value);
      }
    }
    return digest;
  }

  Object? _sanitizeRemoteValue(
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
        result[key] = _sanitizeRemoteValue(entry.value, depth: depth + 1);
      }
      return result;
    }
    if (value is Iterable) {
      final items = value.take(7).map((item) {
        return _sanitizeRemoteValue(item, depth: depth + 1);
      }).toList(growable: true);
      if (value.length > 7) {
        items.add('...');
      }
      return items;
    }
    return value.toString();
  }

  String _remoteIssueSignature({
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
    return _stableHash(base);
  }

  String _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
