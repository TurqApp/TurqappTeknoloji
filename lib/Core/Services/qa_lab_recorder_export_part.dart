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
  }) {
    return _qaLabSyncRemoteSummary(
      this,
      reason: reason,
      immediate: immediate,
      extendedDeviceInfoOverride: extendedDeviceInfoOverride,
    );
  }

  Future<Map<String, dynamic>> buildRemoteSyncPayload({
    required String reason,
    Map<String, dynamic>? extendedDeviceInfoOverride,
  }) {
    return _qaLabBuildRemoteSyncPayload(
      this,
      reason: reason,
      extendedDeviceInfoOverride: extendedDeviceInfoOverride,
    );
  }

  Future<Map<String, dynamic>> buildRemoteSessionDocument({
    required String reason,
    Map<String, dynamic>? extendedDeviceInfoOverride,
  }) {
    return _qaLabBuildRemoteSessionDocument(
      this,
      reason: reason,
      extendedDeviceInfoOverride: extendedDeviceInfoOverride,
    );
  }

  List<Map<String, dynamic>> buildRemoteIssueOccurrences({
    Map<String, dynamic>? sessionDocument,
  }) {
    return _qaLabBuildRemoteIssueOccurrences(
      this,
      sessionDocument: sessionDocument,
    );
  }

  Map<String, dynamic> _deviceInfoSnapshot() => _qaLabDeviceInfoSnapshot();

  Future<Map<String, dynamic>> buildExtendedDeviceInfo() =>
      _qaLabBuildExtendedDeviceInfo(this);

  Map<String, dynamic> _remoteSyncSnapshot() => _qaLabRemoteSyncSnapshot(this);
}
