import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/runtime_health_exporter.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy_adapter.dart';
import 'package:turqappv2/Core/Services/integration_test_state_probe.dart';

import 'qa_lab_catalog.dart';
import 'qa_lab_mode.dart';

enum QALabIssueSeverity {
  info,
  warning,
  error,
  blocking,
}

enum QALabIssueSource {
  flutter,
  platform,
  handled,
  cache,
  video,
  performance,
  lifecycle,
  permission,
  route,
  manual,
}

class QALabIssue {
  const QALabIssue({
    required this.id,
    required this.source,
    required this.severity,
    required this.code,
    required this.message,
    required this.timestamp,
    required this.route,
    required this.surface,
    this.stackTrace,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final QALabIssueSource source;
  final QALabIssueSeverity severity;
  final String code;
  final String message;
  final DateTime timestamp;
  final String route;
  final String surface;
  final String? stackTrace;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'source': source.name,
      'severity': severity.name,
      'code': code,
      'message': message,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'route': route,
      'surface': surface,
      'stackTrace': stackTrace,
      'metadata': metadata,
    };
  }
}

class QALabRouteEvent {
  const QALabRouteEvent({
    required this.current,
    required this.previous,
    required this.timestamp,
    required this.surface,
  });

  final String current;
  final String previous;
  final DateTime timestamp;
  final String surface;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'current': current,
      'previous': previous,
      'surface': surface,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}

class QALabCheckpoint {
  const QALabCheckpoint({
    required this.id,
    required this.label,
    required this.surface,
    required this.route,
    required this.timestamp,
    required this.probe,
    this.extra = const <String, dynamic>{},
  });

  final String id;
  final String label;
  final String surface;
  final String route;
  final DateTime timestamp;
  final Map<String, dynamic> probe;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'surface': surface,
      'route': route,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'probe': probe,
      'extra': extra,
    };
  }
}

class QALabPinpointFinding {
  const QALabPinpointFinding({
    required this.severity,
    required this.code,
    required this.message,
    required this.route,
    required this.surface,
    required this.timestamp,
    this.context = const <String, dynamic>{},
  });

  final QALabIssueSeverity severity;
  final String code;
  final String message;
  final String route;
  final String surface;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'severity': severity.name,
      'code': code,
      'message': message,
      'route': route,
      'surface': surface,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'context': context,
    };
  }
}

class QALabSurfaceDiagnostic {
  const QALabSurfaceDiagnostic({
    required this.surface,
    required this.latestRoute,
    required this.healthScore,
    required this.issueCounts,
    required this.coverage,
    required this.runtime,
    required this.findings,
  });

  final String surface;
  final String latestRoute;
  final int healthScore;
  final Map<String, int> issueCounts;
  final QALabSurfaceCoverageReport coverage;
  final Map<String, dynamic> runtime;
  final List<QALabPinpointFinding> findings;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface,
      'latestRoute': latestRoute,
      'healthScore': healthScore,
      'issueCounts': issueCounts,
      'coverage': coverage.toJson(),
      'runtime': runtime,
      'findings': findings.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class QALabSurfaceAlertSummary {
  const QALabSurfaceAlertSummary({
    required this.surface,
    required this.latestRoute,
    required this.healthScore,
    required this.blockingCount,
    required this.errorCount,
    required this.warningCount,
    required this.findingCount,
    required this.headlineCode,
    required this.headlineMessage,
    required this.primaryRootCauseCategory,
    required this.primaryRootCauseDetail,
  });

  final String surface;
  final String latestRoute;
  final int healthScore;
  final int blockingCount;
  final int errorCount;
  final int warningCount;
  final int findingCount;
  final String headlineCode;
  final String headlineMessage;
  final String primaryRootCauseCategory;
  final String primaryRootCauseDetail;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface,
      'latestRoute': latestRoute,
      'healthScore': healthScore,
      'blockingCount': blockingCount,
      'errorCount': errorCount,
      'warningCount': warningCount,
      'findingCount': findingCount,
      'headlineCode': headlineCode,
      'headlineMessage': headlineMessage,
      'primaryRootCauseCategory': primaryRootCauseCategory,
      'primaryRootCauseDetail': primaryRootCauseDetail,
    };
  }
}

class QALabRecorder extends GetxService {
  static QALabRecorder ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(QALabRecorder(), permanent: true);
  }

  static QALabRecorder? maybeFind() {
    final isRegistered = Get.isRegistered<QALabRecorder>();
    if (!isRegistered) return null;
    return Get.find<QALabRecorder>();
  }

  final RxString sessionId = ''.obs;
  final Rxn<DateTime> startedAt = Rxn<DateTime>();
  final RxString lastRoute = ''.obs;
  final RxString lastSurface = ''.obs;
  final RxString lastExportPath = ''.obs;
  final RxString lastLifecycleState = ''.obs;
  final RxMap<String, String> lastPermissionStatuses = <String, String>{}.obs;
  final RxList<QALabIssue> issues = <QALabIssue>[].obs;
  final RxList<QALabRouteEvent> routes = <QALabRouteEvent>[].obs;
  final RxList<QALabCheckpoint> checkpoints = <QALabCheckpoint>[].obs;
  Timer? _periodicTimer;
  final Map<String, Timer> _surfaceWatchdogs = <String, Timer>{};
  final Map<String, DateTime> _rateLimitedIssueTimes = <String, DateTime>{};
  final Set<String> _emittedFindingKeys = <String>{};
  DateTime? _lastAutoExportAt;
  bool _autoExportInFlight = false;

  @override
  void onInit() {
    super.onInit();
    if (QALabMode.autoStartSession) {
      startSession(trigger: 'auto');
    }
  }

  void startSession({String trigger = 'manual'}) {
    sessionId.value = DateTime.now().millisecondsSinceEpoch.toString();
    startedAt.value = DateTime.now();
    lastRoute.value = Get.currentRoute;
    lastSurface.value =
        _inferSurfaceFromSnapshot(IntegrationTestStateProbe.snapshot());
    issues.clear();
    routes.clear();
    checkpoints.clear();
    lastExportPath.value = '';
    lastLifecycleState.value = '';
    lastPermissionStatuses.clear();
    _rateLimitedIssueTimes.clear();
    _emittedFindingKeys.clear();
    _lastAutoExportAt = null;
    _autoExportInFlight = false;
    _periodicTimer?.cancel();
    _cancelAllSurfaceWatchdogs();
    if (QALabMode.periodicSnapshots) {
      _periodicTimer = Timer.periodic(
        Duration(seconds: QALabMode.periodicSnapshotSeconds),
        (_) => captureCheckpoint(
          label: 'heartbeat',
          surface: lastSurface.value.isEmpty ? 'app' : lastSurface.value,
          extra: <String, dynamic>{'trigger': trigger},
        ),
      );
    }
    captureCheckpoint(
      label: 'session_started',
      surface: lastSurface.value.isEmpty ? 'app' : lastSurface.value,
      extra: <String, dynamic>{'trigger': trigger},
    );
  }

  void resetSession() {
    startSession(trigger: 'reset');
  }

  void disposeSession() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _cancelAllSurfaceWatchdogs();
  }

  void recordRouteChange({
    required String current,
    required String previous,
  }) {
    if (!QALabMode.enabled) return;
    if (sessionId.value.isEmpty) {
      startSession(trigger: 'route');
    }
    final snapshot = IntegrationTestStateProbe.snapshot();
    final surface = _inferSurfaceFromSnapshot(snapshot);
    lastRoute.value = current;
    lastSurface.value = surface;
    routes.add(
      QALabRouteEvent(
        current: current,
        previous: previous,
        timestamp: DateTime.now(),
        surface: surface,
      ),
    );
    _trimList(routes, QALabMode.maxRoutes);
    if (_isPrioritySurface(surface)) {
      captureCheckpoint(
        label: 'route_change',
        surface: surface,
        extra: <String, dynamic>{
          'current': current,
          'previous': previous,
        },
      );
      unawaited(
        refreshPermissionSnapshot(trigger: 'route_change'),
      );
    }
  }

  void recordFlutterError(
    FlutterErrorDetails details, {
    bool suppressed = false,
    String sourceLabel = 'flutter',
  }) {
    final message = details.exceptionAsString();
    recordIssue(
      source: QALabIssueSource.flutter,
      code: suppressed ? 'flutter_suppressed' : 'flutter_error',
      severity: _severityForError(message, suppressed: suppressed),
      message: message,
      stackTrace: details.stack?.toString(),
      metadata: <String, dynamic>{
        'library': details.library ?? '',
        'context': details.context?.toDescription() ?? '',
        'sourceLabel': sourceLabel,
        'suppressed': suppressed,
      },
    );
  }

  void recordPlatformError(
    Object error,
    StackTrace stackTrace, {
    bool suppressed = false,
    String sourceLabel = 'platform',
  }) {
    final message = error.toString();
    recordIssue(
      source: QALabIssueSource.platform,
      code: suppressed ? 'platform_suppressed' : 'platform_error',
      severity: _severityForError(message, suppressed: suppressed),
      message: message,
      stackTrace: stackTrace.toString(),
      metadata: <String, dynamic>{
        'sourceLabel': sourceLabel,
        'errorType': error.runtimeType.toString(),
        'suppressed': suppressed,
      },
    );
  }

  void recordHandledError({
    required String code,
    required String message,
    required String severity,
    required Map<String, dynamic> metadata,
    String? stackTrace,
  }) {
    recordIssue(
      source: QALabIssueSource.handled,
      code: code,
      severity: _severityFromString(severity),
      message: message,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  void recordCacheFirstEvent(Map<String, dynamic> payload) {
    final event = (payload['event'] ?? '').toString();
    final surface = _cacheSurfaceFromPayload(payload);
    if (event.contains('failed')) {
      recordIssue(
        source: QALabIssueSource.cache,
        code: 'cache_first_failed',
        severity: QALabIssueSeverity.warning,
        message: 'Cache-first live sync failed on $surface',
        metadata: payload,
      );
      return;
    }
    if (event == 'liveSyncPreservedPrevious') {
      recordIssue(
        source: QALabIssueSource.cache,
        code: 'cache_first_preserved_previous',
        severity: QALabIssueSeverity.info,
        message: 'Cache-first preserved previous snapshot on $surface',
        metadata: payload,
      );
    }
  }

  void recordVideoEvent({
    required String code,
    required String message,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final severity = code.contains('error') || code.contains('timeout')
        ? QALabIssueSeverity.error
        : QALabIssueSeverity.info;
    recordIssue(
      source: QALabIssueSource.video,
      code: code,
      severity: severity,
      message: message,
      metadata: metadata,
    );
  }

  void recordFrameTimings(List<FrameTiming> timings) {
    if (!QALabMode.enabled || timings.isEmpty) return;
    final totals = timings
        .map((timing) => timing.totalSpan.inMilliseconds)
        .toList(growable: false);
    if (totals.isEmpty) return;
    final slowFrames = totals
        .where((totalMs) => totalMs >= QALabMode.frameJankWarningMs)
        .length;
    if (slowFrames == 0) return;

    final maxTotalMs =
        totals.reduce((left, right) => left > right ? left : right);
    final maxBuildMs = timings
        .map((timing) => timing.buildDuration.inMilliseconds)
        .reduce((left, right) => left > right ? left : right);
    final maxRasterMs = timings
        .map((timing) => timing.rasterDuration.inMilliseconds)
        .reduce((left, right) => left > right ? left : right);
    final averageTotalMs = totals.isEmpty
        ? 0
        : totals.reduce((left, right) => left + right) ~/ totals.length;

    var severity = QALabIssueSeverity.warning;
    var code = 'frame_jank_warning';
    if (maxTotalMs >= QALabMode.frameJankBlockingMs || slowFrames >= 6) {
      severity = QALabIssueSeverity.blocking;
      code = 'frame_jank_blocking';
    } else if (maxTotalMs >= QALabMode.frameJankErrorMs || slowFrames >= 4) {
      severity = QALabIssueSeverity.error;
      code = 'frame_jank_error';
    }

    if (_isRateLimited(
      '${lastSurface.value}|$code',
      const Duration(seconds: 6),
    )) {
      return;
    }

    recordIssue(
      source: QALabIssueSource.performance,
      code: code,
      severity: severity,
      message:
          'Frame pipeline slowed down on ${lastSurface.value.isEmpty ? 'app' : lastSurface.value}.',
      metadata: <String, dynamic>{
        'frameCount': timings.length,
        'slowFrameCount': slowFrames,
        'maxTotalMs': maxTotalMs,
        'maxBuildMs': maxBuildMs,
        'maxRasterMs': maxRasterMs,
        'averageTotalMs': averageTotalMs,
      },
    );
  }

  void recordLifecycleState(String state) {
    if (!QALabMode.enabled) return;
    lastLifecycleState.value = state;
    if (sessionId.value.isEmpty) {
      startSession(trigger: 'lifecycle');
    }
    recordIssue(
      source: QALabIssueSource.lifecycle,
      code: 'lifecycle_$state',
      severity: QALabIssueSeverity.info,
      message: 'Application lifecycle changed to $state.',
      metadata: <String, dynamic>{
        'state': state,
      },
    );
    if (_isPrioritySurface(lastSurface.value)) {
      captureCheckpoint(
        label: 'lifecycle_$state',
        surface: lastSurface.value,
        extra: <String, dynamic>{
          'state': state,
        },
      );
    }
  }

  Future<void> refreshPermissionSnapshot({
    String trigger = 'manual',
  }) async {
    if (!QALabMode.enabled) return;
    final statuses = <String, PermissionStatus>{
      'notifications': await Permission.notification.status,
      'camera': await Permission.camera.status,
      'microphone': await Permission.microphone.status,
      'photos': await Permission.photos.status,
      'location': await Permission.locationWhenInUse.status,
    };
    lastPermissionStatuses.assignAll(
      statuses.map((key, value) => MapEntry(key, value.name)),
    );

    final currentSurface = lastSurface.value;
    final route = lastRoute.value;
    final notificationStatus = statuses['notifications'];
    if (_isPermissionBlocked(notificationStatus)) {
      _recordPermissionIssue(
        code: 'permission_notifications_blocked',
        message: 'Notification permission is not granted.',
        route: route,
        surface: currentSurface.isEmpty ? 'permissions' : currentSurface,
        metadata: <String, dynamic>{
          'trigger': trigger,
          'status': notificationStatus?.name ?? 'unknown',
        },
      );
    }

    if (_surfaceNeedsMediaPermissions(currentSurface)) {
      _recordCriticalPermissionIfBlocked(
        permissionKey: 'camera',
        status: statuses['camera'],
        trigger: trigger,
      );
      _recordCriticalPermissionIfBlocked(
        permissionKey: 'microphone',
        status: statuses['microphone'],
        trigger: trigger,
      );
      _recordCriticalPermissionIfBlocked(
        permissionKey: 'photos',
        status: statuses['photos'],
        trigger: trigger,
      );
    }
  }

  void captureCheckpoint({
    required String label,
    required String surface,
    Map<String, dynamic> extra = const <String, dynamic>{},
    bool refreshWatchdogs = true,
    bool emitSignals = true,
  }) {
    if (!QALabMode.enabled) return;
    if (sessionId.value.isEmpty) {
      startSession(trigger: 'checkpoint');
    }
    final snapshot = IntegrationTestStateProbe.snapshot();
    final route = (snapshot['currentRoute'] ?? '').toString();
    checkpoints.add(
      QALabCheckpoint(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        label: label,
        surface: surface,
        route: route,
        timestamp: DateTime.now(),
        probe: snapshot,
        extra: extra,
      ),
    );
    _trimList(checkpoints, QALabMode.maxCheckpoints);
    lastRoute.value = route;
    lastSurface.value = _inferSurfaceFromSnapshot(snapshot);
    if (refreshWatchdogs) {
      _refreshSurfaceWatchdogs(
        activeSurface: lastSurface.value,
        snapshot: snapshot,
      );
    }
    if (emitSignals) {
      _maybeEmitAutoSignals();
    }
  }

  void recordIssue({
    required QALabIssueSource source,
    required String code,
    required QALabIssueSeverity severity,
    required String message,
    String? stackTrace,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    if (!QALabMode.enabled) return;
    if (sessionId.value.isEmpty) {
      startSession(trigger: 'issue');
    }
    final snapshot = IntegrationTestStateProbe.snapshot();
    final route = (snapshot['currentRoute'] ?? '').toString();
    final surface = _inferSurfaceFromSnapshot(snapshot);
    issues.add(
      QALabIssue(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        source: source,
        severity: severity,
        code: code,
        message: message,
        timestamp: DateTime.now(),
        route: route,
        surface: surface,
        stackTrace: stackTrace,
        metadata: <String, dynamic>{
          ...metadata,
          'probe': snapshot,
        },
      ),
    );
    _trimList(issues, QALabMode.maxIssues);
    lastRoute.value = route;
    lastSurface.value = surface;
    _maybeEmitAutoSignals();
  }

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
      ...issues.where((issue) => issue.severity != QALabIssueSeverity.info).map(
            (issue) => QALabPinpointFinding(
              severity: issue.severity,
              code: issue.code,
              message: issue.message,
              route: issue.route,
              surface: issue.surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'source': issue.source.name,
                'lastCheckpoint': _lastCheckpointLabelBefore(issue.timestamp),
              },
            ),
          ),
      ..._buildPrioritySurfaceFindings(),
      ..._buildTelemetryThresholdFindings(),
    ];
    findings.sort(_compareFindings);
    return _dedupeFindings(findings);
  }

  List<QALabSurfaceDiagnostic> buildFocusSurfaceDiagnostics() {
    return QALabCatalog.focusSurfaces
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
      'currentSnapshot': currentSnapshot,
      'routes': routes.map((event) => event.toJson()).toList(growable: false),
      'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
      'pinpointFindings': buildPinpointFindings()
          .map((item) => item.toJson())
          .toList(growable: false),
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
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo =
        GetPlatform.isAndroid ? await deviceInfo.androidInfo : null;
    final iosInfo = GetPlatform.isIOS ? await deviceInfo.iosInfo : null;
    return <String, dynamic>{
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
  }

  QALabIssueSeverity _severityForError(
    String message, {
    required bool suppressed,
  }) {
    final lower = message.toLowerCase();
    if (suppressed) return QALabIssueSeverity.info;
    if (lower.contains('improper use of a getx') ||
        lower.contains('failed assertion') ||
        lower.contains('unsupported operation') ||
        lower.contains('null check operator used on a null value')) {
      return QALabIssueSeverity.blocking;
    }
    if (lower.contains('permission-denied')) {
      return QALabIssueSeverity.warning;
    }
    return QALabIssueSeverity.error;
  }

  QALabIssueSeverity _severityFromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'critical':
        return QALabIssueSeverity.blocking;
      case 'high':
        return QALabIssueSeverity.error;
      case 'medium':
        return QALabIssueSeverity.warning;
      default:
        return QALabIssueSeverity.info;
    }
  }

  String _lastCheckpointLabelBefore(DateTime timestamp) {
    for (final checkpoint in checkpoints.reversed) {
      if (!checkpoint.timestamp.isAfter(timestamp)) {
        return checkpoint.label;
      }
    }
    return '';
  }

  String _cacheSurfaceFromPayload(Map<String, dynamic> payload) {
    final surfaceKey = (payload['surfaceKey'] ?? '').toString();
    if (surfaceKey.startsWith('feed_')) return 'feed';
    if (surfaceKey.startsWith('short_')) return 'short';
    if (surfaceKey.startsWith('notifications_')) return 'notifications';
    if (surfaceKey.startsWith('profile_')) return 'profile';
    return 'cache';
  }

  List<QALabPinpointFinding> _buildPrioritySurfaceFindings() {
    return QALabCatalog.focusSurfaces
        .expand(
          (surface) => _buildSurfaceRuntimeFindings(
            surface,
            _surfaceIssues(surface),
            _surfaceCheckpoints(surface),
          ),
        )
        .toList(growable: false);
  }

  List<QALabPinpointFinding> _buildTelemetryThresholdFindings() {
    final playbackKpi = PlaybackKpiService.maybeFind();
    if (playbackKpi == null) return const <QALabPinpointFinding>[];
    final report = TelemetryThresholdPolicyAdapter.evaluateKpiService(
      playbackKpi,
    );
    return report.issues
        .map(
          (issue) => QALabPinpointFinding(
            severity: issue.severity.name == 'blocking'
                ? QALabIssueSeverity.blocking
                : QALabIssueSeverity.warning,
            code: 'telemetry_${issue.code}',
            message: issue.message,
            route: _latestRouteForSurface(issue.surface),
            surface: issue.surface,
            timestamp: DateTime.now(),
            context: issue.metrics,
          ),
        )
        .toList(growable: false);
  }

  QALabSurfaceDiagnostic _buildSurfaceDiagnostic(String surface) {
    final surfaceIssues = _surfaceIssues(surface);
    final surfaceCheckpoints = _surfaceCheckpoints(surface);
    final runtimeFindings = _buildSurfaceRuntimeFindings(
      surface,
      surfaceIssues,
      surfaceCheckpoints,
    );
    final warningCount = surfaceIssues
        .where((issue) => issue.severity == QALabIssueSeverity.warning)
        .length;
    final errorCount = surfaceIssues
        .where((issue) => issue.severity == QALabIssueSeverity.error)
        .length;
    final blockingCount = surfaceIssues
        .where((issue) => issue.severity == QALabIssueSeverity.blocking)
        .length;
    final healthScore = (100 -
            (runtimeFindings
                    .where(
                      (item) => item.severity == QALabIssueSeverity.blocking,
                    )
                    .length *
                22) -
            (runtimeFindings
                    .where((item) => item.severity == QALabIssueSeverity.error)
                    .length *
                10) -
            (runtimeFindings
                    .where(
                      (item) => item.severity == QALabIssueSeverity.warning,
                    )
                    .length *
                4))
        .clamp(0, 100)
        .toInt();

    return QALabSurfaceDiagnostic(
      surface: surface,
      latestRoute: _latestRouteForSurface(surface),
      healthScore: healthScore,
      issueCounts: <String, int>{
        'blocking': blockingCount,
        'error': errorCount,
        'warning': warningCount,
        'info':
            surfaceIssues.length - blockingCount - errorCount - warningCount,
      },
      coverage: QALabCatalog.surfaceCoverage(surface),
      runtime:
          _surfaceRuntimeSummary(surface, surfaceIssues, surfaceCheckpoints),
      findings: runtimeFindings,
    );
  }

  List<QALabIssue> _surfaceIssues(String surface) {
    return issues
        .where((issue) => _matchesSurface(issue.surface, surface))
        .toList(growable: false);
  }

  List<QALabCheckpoint> _surfaceCheckpoints(String surface) {
    return checkpoints
        .where((checkpoint) => _matchesSurface(checkpoint.surface, surface))
        .toList(growable: false);
  }

  List<QALabPinpointFinding> _buildSurfaceRuntimeFindings(
    String surface,
    List<QALabIssue> surfaceIssues,
    List<QALabCheckpoint> surfaceCheckpoints,
  ) {
    final findings = <QALabPinpointFinding>[];
    final latestCheckpoint =
        surfaceCheckpoints.isEmpty ? null : surfaceCheckpoints.last;
    final latestProbe =
        latestCheckpoint?.probe[surface] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final authProbe =
        latestCheckpoint?.probe['auth'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final referenceTime = latestCheckpoint?.timestamp ?? DateTime.now();
    final route = latestCheckpoint?.route.isNotEmpty == true
        ? latestCheckpoint!.route
        : _latestRouteForSurface(surface);

    if ((surface == 'feed' || surface == 'short') &&
        _hasAuthenticatedUser(authProbe)) {
      final count = _asInt(latestProbe['count']);
      if (count == 0 && latestProbe['registered'] == true) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.blocking,
            code: '${surface}_blank_surface',
            message:
                '$surface surface is registered but returned zero items while authenticated.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'checkpoint': latestCheckpoint?.label ?? '',
            },
          ),
        );
      }
    }

    final autoplayFinding = _buildAutoplaySurfaceFinding(
      surface: surface,
      surfaceCheckpoints: surfaceCheckpoints,
      referenceTime: referenceTime,
      route: route,
    );
    if (autoplayFinding != null) {
      findings.add(autoplayFinding);
    }

    if (surface == 'feed') {
      final count = _asInt(latestProbe['count']);
      final centeredIndex = _asInt(latestProbe['centeredIndex']);
      if (count > 0 && (centeredIndex < 0 || centeredIndex >= count)) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.error,
            code: 'feed_centered_index_invalid',
            message:
                'Feed has visible items but centered index is outside valid bounds.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'count': count,
              'centeredIndex': centeredIndex,
            },
          ),
        );
      }
      final playbackSuspended = latestProbe['playbackSuspended'] == true;
      final pauseAll = latestProbe['pauseAll'] == true;
      final canClaimPlaybackNow = latestProbe['canClaimPlaybackNow'] == true;
      if (count > 0 &&
          (playbackSuspended || pauseAll || !canClaimPlaybackNow)) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.warning,
            code: 'feed_playback_gate_blocked',
            message:
                'Feed has content but playback gate is not eligible for autoplay.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'playbackSuspended': playbackSuspended,
              'pauseAll': pauseAll,
              'canClaimPlaybackNow': canClaimPlaybackNow,
            },
          ),
        );
      }
    } else if (surface == 'short') {
      final count = _asInt(latestProbe['count']);
      final activeIndex = _asInt(latestProbe['activeIndex']);
      if (count > 0 && (activeIndex < 0 || activeIndex >= count)) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.error,
            code: 'short_active_index_invalid',
            message:
                'Short surface has items but active index is outside valid bounds.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'count': count,
              'activeIndex': activeIndex,
            },
          ),
        );
      }
    } else if (surface == 'chat') {
      final conversationProbe = latestCheckpoint?.probe['chatConversation']
              as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final lastMediaFailureCode =
          (conversationProbe['lastMediaFailureCode'] ?? '').toString();
      if (lastMediaFailureCode.isNotEmpty) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.error,
            code: 'chat_media_failure',
            message: 'Chat media pipeline reported a failure code.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'lastMediaFailureCode': lastMediaFailureCode,
              'lastMediaFailureDetail':
                  (conversationProbe['lastMediaFailureDetail'] ?? '')
                      .toString(),
              'lastMediaAction':
                  (conversationProbe['lastMediaAction'] ?? '').toString(),
            },
          ),
        );
      }
    } else if (surface == 'notifications') {
      final lastOpenedNotificationId =
          (latestProbe['lastOpenedNotificationId'] ?? '').toString();
      final lastOpenedRouteKind =
          (latestProbe['lastOpenedRouteKind'] ?? '').toString();
      if (lastOpenedNotificationId.isNotEmpty && lastOpenedRouteKind.isEmpty) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.warning,
            code: 'notifications_route_resolution_missing',
            message:
                'A notification was opened but route resolution metadata stayed empty.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'notificationId': lastOpenedNotificationId,
            },
          ),
        );
      }
    }

    final suppressedNoiseCount = surfaceIssues
        .where(
          (issue) =>
              issue.code == 'flutter_suppressed' ||
              issue.code == 'platform_suppressed',
        )
        .length;
    if (suppressedNoiseCount >= QALabMode.noiseBurstWarningCount) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.warning,
          code: '${surface}_noise_burst',
          message:
              'Suppressed runtime noise accumulated on $surface and may hide real regressions.',
          route: route,
          surface: surface,
          timestamp: referenceTime,
          context: <String, dynamic>{
            'suppressedNoiseCount': suppressedNoiseCount,
          },
        ),
      );
    }

    final lifecycleInterruptions = surfaceIssues
        .where(
          (issue) =>
              issue.source == QALabIssueSource.lifecycle &&
              issue.code != 'lifecycle_resume',
        )
        .length;
    if (lifecycleInterruptions >= 2) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.warning,
          code: '${surface}_lifecycle_interruptions',
          message:
              'Application lifecycle interrupted $surface multiple times during this session.',
          route: route,
          surface: surface,
          timestamp: referenceTime,
          context: <String, dynamic>{
            'interruptions': lifecycleInterruptions,
          },
        ),
      );
    }

    findings.addAll(
      _buildVideoSurfaceFindings(
        surface: surface,
        surfaceIssues: surfaceIssues,
        referenceTime: referenceTime,
        route: route,
      ),
    );
    findings.addAll(
      _buildAudioSurfaceFindings(
        surface: surface,
        surfaceIssues: surfaceIssues,
        referenceTime: referenceTime,
        route: route,
      ),
    );
    findings.addAll(
      _buildCacheSurfaceFindings(
        surface: surface,
        surfaceIssues: surfaceIssues,
        referenceTime: referenceTime,
        route: route,
      ),
    );
    return findings;
  }

  Map<String, dynamic> _surfaceRuntimeSummary(
    String surface,
    List<QALabIssue> surfaceIssues,
    List<QALabCheckpoint> surfaceCheckpoints,
  ) {
    final videoStarts = surfaceIssues
        .where((issue) => issue.code == 'video_session_started')
        .length;
    final videoFirstFrames = surfaceIssues
        .where((issue) => issue.code == 'video_first_frame')
        .length;
    final videoErrors =
        surfaceIssues.where((issue) => issue.code == 'video_error').length;
    final cacheFailures = surfaceIssues
        .where((issue) => issue.code == 'cache_first_failed')
        .length;
    final jankEvents = surfaceIssues
        .where((issue) => issue.code.startsWith('frame_jank_'))
        .length;
    final worstFrameJankMs = surfaceIssues
        .where((issue) => issue.code.startsWith('frame_jank_'))
        .map((issue) => _asInt(issue.metadata['maxTotalMs']))
        .fold<int>(0, (left, right) => left > right ? left : right);
    final suppressedNoiseCount = surfaceIssues
        .where(
          (issue) =>
              issue.code == 'flutter_suppressed' ||
              issue.code == 'platform_suppressed',
        )
        .length;
    final permissionBlocks = surfaceIssues
        .where((issue) => issue.source == QALabIssueSource.permission)
        .length;
    final lifecycleInterruptions = surfaceIssues
        .where(
          (issue) =>
              issue.source == QALabIssueSource.lifecycle &&
              issue.code != 'lifecycle_resume',
        )
        .length;
    final blankSnapshots = surfaceCheckpoints.where((checkpoint) {
      final probe = checkpoint.probe[surface] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      return probe['registered'] == true && _asInt(probe['count']) == 0;
    }).length;
    final runtimeFindings = _buildSurfaceRuntimeFindings(
      surface,
      surfaceIssues,
      surfaceCheckpoints,
    );
    final autoplayFindings =
        runtimeFindings.where((item) => item.code.contains('autoplay_')).length;

    return <String, dynamic>{
      'checkpointCount': surfaceCheckpoints.length,
      'videoSessionStartCount': videoStarts,
      'videoFirstFrameCount': videoFirstFrames,
      'videoErrorCount': videoErrors,
      'cacheFailureCount': cacheFailures,
      'jankEventCount': jankEvents,
      'worstFrameJankMs': worstFrameJankMs,
      'suppressedNoiseCount': suppressedNoiseCount,
      'permissionBlockCount': permissionBlocks,
      'lifecycleInterruptionCount': lifecycleInterruptions,
      'blankSnapshotCount': blankSnapshots,
      'autoplayFindingCount': autoplayFindings,
      'runtimeFindingCount': runtimeFindings.length,
    };
  }

  QALabPinpointFinding? _buildAutoplaySurfaceFinding({
    required String surface,
    required List<QALabCheckpoint> surfaceCheckpoints,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed' && surface != 'short') {
      return null;
    }
    if (surfaceCheckpoints.isEmpty) {
      return null;
    }
    final latestCheckpoint = surfaceCheckpoints.last;
    final surfaceProbe =
        latestCheckpoint.probe[surface] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final authProbe = latestCheckpoint.probe['auth'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    if (!_hasAuthenticatedUser(authProbe)) {
      return null;
    }

    final expectedDocId = surface == 'feed'
        ? (surfaceProbe['centeredDocId'] ?? '').toString()
        : (surfaceProbe['activeDocId'] ?? '').toString();
    final count = _asInt(surfaceProbe['count']);
    if (count <= 0 || expectedDocId.isEmpty) {
      return null;
    }
    if (surface == 'feed') {
      final centeredIndex = _asInt(surfaceProbe['centeredIndex']);
      final playbackSuspended = surfaceProbe['playbackSuspended'] == true;
      final pauseAll = surfaceProbe['pauseAll'] == true;
      final canClaimPlaybackNow = surfaceProbe['canClaimPlaybackNow'] == true;
      if (centeredIndex < 0 ||
          centeredIndex >= count ||
          playbackSuspended ||
          pauseAll ||
          !canClaimPlaybackNow) {
        return null;
      }
    } else {
      final activeIndex = _asInt(surfaceProbe['activeIndex']);
      if (activeIndex < 0 || activeIndex >= count) {
        return null;
      }
    }

    final observedSince = _playbackObservationStart(
      surfaceCheckpoints: surfaceCheckpoints,
      route: route,
      surface: surface,
      expectedDocId: expectedDocId,
    );
    final elapsedMs = referenceTime.difference(observedSince).inMilliseconds;
    if (elapsedMs < QALabMode.autoplayDetectionGraceMs) {
      return null;
    }

    final playbackProbe =
        latestCheckpoint.probe['videoPlayback'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final currentPlayingDocId =
        (playbackProbe['currentPlayingDocID'] ?? '').toString();
    if (currentPlayingDocId == expectedDocId) {
      return null;
    }
    final registeredHandleCount =
        _asInt(playbackProbe['registeredHandleCount']);
    final savedStateCount = _asInt(playbackProbe['savedStateCount']);
    final wrongTarget = currentPlayingDocId.isNotEmpty;
    return QALabPinpointFinding(
      severity: registeredHandleCount > 0
          ? QALabIssueSeverity.error
          : QALabIssueSeverity.warning,
      code: wrongTarget
          ? '${surface}_autoplay_wrong_target'
          : '${surface}_autoplay_missing',
      message: wrongTarget
          ? 'Autoplay on $surface claimed the wrong video after the grace window.'
          : 'Autoplay on $surface stayed idle after the grace window.',
      route: route,
      surface: surface,
      timestamp: latestCheckpoint.timestamp,
      context: <String, dynamic>{
        'expectedDocId': expectedDocId,
        'currentPlayingDocID': currentPlayingDocId,
        'registeredHandleCount': registeredHandleCount,
        'savedStateCount': savedStateCount,
        'elapsedMs': elapsedMs,
      },
    );
  }

  List<QALabPinpointFinding> _buildVideoSurfaceFindings({
    required String surface,
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
    required String route,
  }) {
    final findings = <QALabPinpointFinding>[];
    final firstFrameIds = surfaceIssues
        .where((issue) => issue.code == 'video_first_frame')
        .map(_videoIdOf)
        .where((value) => value.isNotEmpty)
        .toSet();
    final endedByVideoId = <String, QALabIssue>{};
    final bufferingEndedByVideoId = <String, QALabIssue>{};

    for (final issue in surfaceIssues) {
      final videoId = _videoIdOf(issue);
      if (videoId.isEmpty) continue;
      if (issue.code == 'video_session_ended') {
        endedByVideoId[videoId] = issue;
      } else if (issue.code == 'video_buffering_ended') {
        bufferingEndedByVideoId[videoId] = issue;
      }
    }

    for (final issue in surfaceIssues) {
      final videoId = _videoIdOf(issue);
      if (videoId.isEmpty) continue;
      if (issue.code == 'video_session_started' &&
          !firstFrameIds.contains(videoId)) {
        final ended = endedByVideoId[videoId];
        final ttffMs = _asInt(ended?.metadata['ttffMs']);
        final elapsedMs =
            referenceTime.difference(issue.timestamp).inMilliseconds;
        if ((ended == null || ttffMs < 0) &&
            elapsedMs >= QALabMode.videoFirstFrameTimeoutMs) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.blocking,
              code: '${surface}_first_frame_timeout',
              message:
                  'Video session started on $surface but no first frame was confirmed before timeout.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'elapsedMs': elapsedMs,
              },
            ),
          );
        }
      }

      if (issue.code == 'video_buffering_started') {
        final ended = bufferingEndedByVideoId[videoId];
        final stillBuffering =
            ended == null || ended.timestamp.isBefore(issue.timestamp);
        final elapsedMs =
            referenceTime.difference(issue.timestamp).inMilliseconds;
        if (stillBuffering && elapsedMs >= QALabMode.videoBufferStallMs) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.error,
              code: '${surface}_buffer_stall',
              message:
                  'Video buffering started on $surface and never recovered before the stall threshold.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'elapsedMs': elapsedMs,
              },
            ),
          );
        }
      }

      if (issue.code == 'video_session_ended') {
        final ttffMs = _asInt(issue.metadata['ttffMs']);
        final rebufferCount = _asInt(issue.metadata['rebufferCount']);
        final totalRebufferMs = _asInt(issue.metadata['totalRebufferMs']);
        if (ttffMs >= QALabMode.videoFirstFrameBlockingMs) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.blocking,
              code: '${surface}_first_frame_too_slow',
              message:
                  'Video first frame latency on $surface exceeded the blocking threshold.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'ttffMs': ttffMs,
              },
            ),
          );
        } else if (ttffMs >= QALabMode.videoFirstFrameWarningMs) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.warning,
              code: '${surface}_first_frame_slow',
              message:
                  'Video first frame latency on $surface is above warning threshold.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'ttffMs': ttffMs,
              },
            ),
          );
        }

        if (rebufferCount >= 6 || totalRebufferMs >= 8000) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.error,
              code: '${surface}_rebuffer_spike',
              message: 'Video playback on $surface spent too long buffering.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'rebufferCount': rebufferCount,
                'totalRebufferMs': totalRebufferMs,
              },
            ),
          );
        } else if (rebufferCount >= 3 || totalRebufferMs >= 4000) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.warning,
              code: '${surface}_rebuffer_warning',
              message:
                  'Video playback on $surface showed noticeable rebuffering.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'rebufferCount': rebufferCount,
                'totalRebufferMs': totalRebufferMs,
              },
            ),
          );
        }
      }
    }

    return findings;
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
    final endedSessions = surfaceIssues
        .where((issue) => issue.code == 'video_session_ended')
        .toList(growable: false);
    if (endedSessions.length < 2) {
      return const <QALabPinpointFinding>[];
    }

    var audibleCount = 0;
    var mutedCount = 0;
    var unstableFocusCount = 0;
    for (final issue in endedSessions) {
      final isAudible = issue.metadata['isAudible'] == true;
      final hasStableFocus = issue.metadata['hasStableFocus'] == true;
      if (isAudible) {
        audibleCount += 1;
      } else {
        mutedCount += 1;
      }
      if (!hasStableFocus) {
        unstableFocusCount += 1;
      }
    }

    if (audibleCount == 0 || mutedCount == 0) {
      return const <QALabPinpointFinding>[];
    }

    final severity = unstableFocusCount > 0
        ? QALabIssueSeverity.error
        : QALabIssueSeverity.warning;
    return <QALabPinpointFinding>[
      QALabPinpointFinding(
        severity: severity,
        code: '${surface}_audio_state_inconsistent',
        message:
            'Videos on $surface finished with mixed audible and muted states during the same session.',
        route: route,
        surface: surface,
        timestamp: referenceTime,
        context: <String, dynamic>{
          'audibleSessionCount': audibleCount,
          'mutedSessionCount': mutedCount,
          'unstableFocusCount': unstableFocusCount,
        },
      ),
    ];
  }

  void _recordCriticalPermissionIfBlocked({
    required String permissionKey,
    required PermissionStatus? status,
    required String trigger,
  }) {
    if (!_isPermissionBlocked(status)) return;
    final surface =
        lastSurface.value.isEmpty ? 'permissions' : lastSurface.value;
    _recordPermissionIssue(
      code: 'permission_${permissionKey}_blocked',
      message: '$permissionKey permission is not granted.',
      route: lastRoute.value,
      surface: surface,
      metadata: <String, dynamic>{
        'trigger': trigger,
        'status': status?.name ?? 'unknown',
      },
    );
  }

  void _recordPermissionIssue({
    required String code,
    required String message,
    required String route,
    required String surface,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final rateKey = '$surface|$code|${metadata['status'] ?? ''}';
    if (_isRateLimited(rateKey, const Duration(seconds: 10))) {
      return;
    }
    issues.add(
      QALabIssue(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        source: QALabIssueSource.permission,
        severity: QALabIssueSeverity.warning,
        code: code,
        message: message,
        timestamp: DateTime.now(),
        route: route,
        surface: surface,
        metadata: <String, dynamic>{
          ...metadata,
          'probe': IntegrationTestStateProbe.snapshot(),
        },
      ),
    );
    _trimList(issues, QALabMode.maxIssues);
    _maybeEmitAutoSignals();
  }

  bool _surfaceNeedsMediaPermissions(String surface) {
    return surface == 'chat' ||
        surface == 'story' ||
        surface == 'story_comments' ||
        surface == 'short' ||
        surface == 'feed' ||
        surface == 'upload';
  }

  bool _isPermissionBlocked(PermissionStatus? status) {
    return status == PermissionStatus.denied ||
        status == PermissionStatus.permanentlyDenied ||
        status == PermissionStatus.restricted;
  }

  bool _isRateLimited(String key, Duration interval) {
    final now = DateTime.now();
    final previous = _rateLimitedIssueTimes[key];
    if (previous != null && now.difference(previous) < interval) {
      return true;
    }
    _rateLimitedIssueTimes[key] = now;
    return false;
  }

  bool _matchesSurface(String actualSurface, String targetSurface) {
    if (actualSurface == targetSurface) return true;
    if (targetSurface == 'chat' && actualSurface == 'chat_conversation') {
      return true;
    }
    if (targetSurface == 'story' && actualSurface == 'story_comments') {
      return true;
    }
    if (targetSurface == 'profile' && actualSurface == 'social_profile') {
      return true;
    }
    return false;
  }

  String _latestRouteForSurface(String surface) {
    for (final event in routes.reversed) {
      if (_matchesSurface(event.surface, surface)) {
        return event.current;
      }
    }
    return surface == lastSurface.value ? lastRoute.value : '';
  }

  bool _hasAuthenticatedUser(Map<String, dynamic> authProbe) {
    final currentUid = (authProbe['currentUid'] ?? '').toString();
    final firebaseSignedIn = authProbe['isFirebaseSignedIn'] == true;
    final currentUserLoaded = authProbe['currentUserLoaded'] == true;
    return currentUid.isNotEmpty || firebaseSignedIn || currentUserLoaded;
  }

  bool _isPrioritySurface(String surface) {
    return QALabCatalog.focusSurfaces.contains(surface);
  }

  void _refreshSurfaceWatchdogs({
    required String activeSurface,
    required Map<String, dynamic> snapshot,
  }) {
    if (!_isSurfaceAutoplayWatchdog(activeSurface) ||
        !_shouldTrackSurfaceWatchdog(activeSurface, snapshot)) {
      _cancelSurfaceWatchdog('feed');
      _cancelSurfaceWatchdog('short');
      return;
    }
    if (activeSurface == 'feed') {
      _cancelSurfaceWatchdog('short');
    } else {
      _cancelSurfaceWatchdog('feed');
    }
    _cancelSurfaceWatchdog(activeSurface);
    _surfaceWatchdogs[activeSurface] = Timer(
      Duration(seconds: QALabMode.surfaceWatchdogSeconds),
      () => _runSurfaceWatchdog(activeSurface),
    );
  }

  void _runSurfaceWatchdog(String surface) {
    _surfaceWatchdogs.remove(surface)?.cancel();
    if (!QALabMode.enabled) {
      return;
    }
    final snapshot = IntegrationTestStateProbe.snapshot();
    final currentSurface = _inferSurfaceFromSnapshot(snapshot);
    if (currentSurface != surface ||
        !_shouldTrackSurfaceWatchdog(surface, snapshot)) {
      return;
    }
    captureCheckpoint(
      label: '${surface}_watchdog',
      surface: surface,
      extra: <String, dynamic>{
        'watchdog': true,
        'watchdogSeconds': QALabMode.surfaceWatchdogSeconds,
      },
      refreshWatchdogs: false,
      emitSignals: true,
    );
  }

  bool _isSurfaceAutoplayWatchdog(String surface) {
    return surface == 'feed' || surface == 'short';
  }

  bool _shouldTrackSurfaceWatchdog(
    String surface,
    Map<String, dynamic> snapshot,
  ) {
    final authProbe =
        snapshot['auth'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    if (!_hasAuthenticatedUser(authProbe)) {
      return false;
    }
    final surfaceProbe =
        snapshot[surface] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final count = _asInt(surfaceProbe['count']);
    if (surfaceProbe['registered'] != true || count <= 0) {
      return false;
    }
    if (surface == 'feed') {
      final centeredIndex = _asInt(surfaceProbe['centeredIndex']);
      return centeredIndex >= 0 &&
          centeredIndex < count &&
          surfaceProbe['playbackSuspended'] != true &&
          surfaceProbe['pauseAll'] != true &&
          surfaceProbe['canClaimPlaybackNow'] == true &&
          (surfaceProbe['centeredDocId'] ?? '').toString().isNotEmpty;
    }
    final activeIndex = _asInt(surfaceProbe['activeIndex']);
    return activeIndex >= 0 &&
        activeIndex < count &&
        (surfaceProbe['activeDocId'] ?? '').toString().isNotEmpty;
  }

  DateTime _playbackObservationStart({
    required List<QALabCheckpoint> surfaceCheckpoints,
    required String route,
    required String surface,
    required String expectedDocId,
  }) {
    var observedSince = surfaceCheckpoints.last.timestamp;
    for (final checkpoint in surfaceCheckpoints.reversed) {
      if (checkpoint.route != route) {
        break;
      }
      final surfaceProbe = checkpoint.probe[surface] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final docId = surface == 'feed'
          ? (surfaceProbe['centeredDocId'] ?? '').toString()
          : (surfaceProbe['activeDocId'] ?? '').toString();
      if (docId != expectedDocId) {
        break;
      }
      observedSince = checkpoint.timestamp;
    }
    return observedSince;
  }

  String _videoIdOf(QALabIssue issue) {
    return (issue.metadata['videoId'] ?? '').toString();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  int _compareFindings(QALabPinpointFinding a, QALabPinpointFinding b) {
    final severityCompare =
        _severityRank(b.severity) - _severityRank(a.severity);
    if (severityCompare != 0) return severityCompare;
    return b.timestamp.compareTo(a.timestamp);
  }

  int _severityRank(QALabIssueSeverity severity) {
    switch (severity) {
      case QALabIssueSeverity.blocking:
        return 4;
      case QALabIssueSeverity.error:
        return 3;
      case QALabIssueSeverity.warning:
        return 2;
      case QALabIssueSeverity.info:
        return 1;
    }
  }

  int _compareSurfaceAlertSummaries(
    QALabSurfaceAlertSummary a,
    QALabSurfaceAlertSummary b,
  ) {
    final severityCompare = ((b.blockingCount * 1000) +
            (b.errorCount * 100) +
            (b.warningCount * 10) +
            (100 - b.healthScore)) -
        ((a.blockingCount * 1000) +
            (a.errorCount * 100) +
            (a.warningCount * 10) +
            (100 - a.healthScore));
    if (severityCompare != 0) {
      return severityCompare;
    }
    return a.surface.compareTo(b.surface);
  }

  (String, String) _inferPrimaryRootCause(
    QALabSurfaceDiagnostic diagnostic,
    List<QALabPinpointFinding> findings,
    String headlineCode,
  ) {
    final runtime = diagnostic.runtime;
    final code = headlineCode.trim().toLowerCase();

    if (code.contains('blank_surface')) {
      return (
        'data_absent',
        '${diagnostic.surface} loaded as an empty authenticated surface.',
      );
    }
    if (code.contains('autoplay') || code.contains('playback_gate')) {
      return (
        'autoplay_dispatch',
        '${diagnostic.surface} had eligible content but autoplay did not lock onto the expected video.',
      );
    }
    if (code.contains('first_frame')) {
      return (
        'first_frame_latency',
        '${diagnostic.surface} started playback but first frame confirmation lagged or never arrived.',
      );
    }
    if (code.contains('buffer_stall') || code.contains('rebuffer')) {
      return (
        'buffering_instability',
        '${diagnostic.surface} playback spent too long buffering or repeatedly rebuffered.',
      );
    }
    if (code.contains('audio_state') || code.contains('mute')) {
      return (
        'audio_state_drift',
        '${diagnostic.surface} produced inconsistent audible state across video sessions.',
      );
    }
    if (code.contains('cache_live_failures') ||
        (runtime['cacheFailureCount'] as int? ?? 0) > 0) {
      return (
        'cache_live_sync',
        '${diagnostic.surface} cache-first flow preserved stale state or failed to refresh live data.',
      );
    }
    if (code.contains('permission')) {
      return (
        'permission_block',
        '${diagnostic.surface} is blocked by OS-level permission state.',
      );
    }
    if (code.contains('jank') || code.contains('noise_burst')) {
      return (
        'runtime_noise',
        '${diagnostic.surface} accumulated frame jank or suppressed runtime noise.',
      );
    }
    if (code.contains('lifecycle')) {
      return (
        'lifecycle_interruption',
        '${diagnostic.surface} was interrupted by app lifecycle transitions.',
      );
    }
    if (code.contains('route_resolution')) {
      return (
        'route_resolution',
        '${diagnostic.surface} opened without completing target route resolution.',
      );
    }
    if (code.contains('media_failure')) {
      return (
        'media_pipeline',
        '${diagnostic.surface} reported a media pipeline failure.',
      );
    }
    if (code == 'coverage_gap') {
      return (
        'coverage_gap',
        '${diagnostic.surface} still has missing QA coverage tags.',
      );
    }

    final blockingCount = findings
        .where((item) => item.severity == QALabIssueSeverity.blocking)
        .length;
    final errorCount = findings
        .where((item) => item.severity == QALabIssueSeverity.error)
        .length;
    if (blockingCount > 0 || errorCount > 0) {
      return (
        'runtime_regression',
        '${diagnostic.surface} has high-severity findings without a specialized root-cause mapping yet.',
      );
    }
    return (
      'observation_only',
      '${diagnostic.surface} is degraded, but only low-severity observations are present so far.',
    );
  }

  List<QALabPinpointFinding> _dedupeFindings(
    List<QALabPinpointFinding> findings,
  ) {
    final seen = <String>{};
    final deduped = <QALabPinpointFinding>[];
    for (final finding in findings) {
      final key = [
        finding.surface,
        finding.route,
        finding.code,
        finding.message,
      ].join('|');
      if (!seen.add(key)) continue;
      deduped.add(finding);
    }
    return deduped;
  }

  String _inferSurfaceFromSnapshot(Map<String, dynamic> snapshot) {
    bool registered(String key) =>
        (snapshot[key] as Map<String, dynamic>? ??
            const <String, dynamic>{})['registered'] ==
        true;

    if (registered('storyComments')) return 'story_comments';
    if (registered('comments')) return 'comments';
    if (registered('chatConversation')) return 'chat_conversation';
    if (registered('chat')) return 'chat';
    if (registered('notifications')) return 'notifications';
    if (registered('socialProfile')) return 'social_profile';
    if (registered('profile')) {
      final route = (snapshot['currentRoute'] ?? '').toString();
      if (route.contains('FollowingFollowers')) return 'following_followers';
      if (route.contains('Permissions')) return 'permissions';
      if (route.contains('Settings')) return 'settings';
      return 'profile';
    }
    if (registered('short')) return 'short';
    if (registered('education')) return 'pasaj';
    if (registered('explore')) return 'explore';
    if (registered('feed')) return 'feed';
    final route = (snapshot['currentRoute'] ?? '').toString();
    if (route.isNotEmpty) return route;
    return 'app';
  }

  void _trimList<T>(RxList<T> list, int maxCount) {
    if (list.length <= maxCount) return;
    list.removeRange(0, list.length - maxCount);
  }

  void _cancelSurfaceWatchdog(String surface) {
    _surfaceWatchdogs.remove(surface)?.cancel();
  }

  void _cancelAllSurfaceWatchdogs() {
    for (final timer in _surfaceWatchdogs.values) {
      timer.cancel();
    }
    _surfaceWatchdogs.clear();
  }

  void _maybeEmitAutoSignals() {
    if (!QALabMode.enabled) {
      return;
    }
    var shouldAutoExport = false;
    for (final finding in buildPinpointFindings()) {
      final key = [
        finding.surface,
        finding.route,
        finding.code,
        finding.message,
      ].join('|');
      if (!_emittedFindingKeys.add(key)) {
        continue;
      }
      if (QALabMode.autoMarkerLogs) {
        debugPrint(_formatFindingMarker(finding));
      }
      if (_severityRank(finding.severity) >=
          _severityRank(QALabIssueSeverity.error)) {
        shouldAutoExport = true;
      }
    }
    if (shouldAutoExport && QALabMode.autoExportFindings) {
      _scheduleAutoExport();
    }
  }

  String _formatFindingMarker(QALabPinpointFinding finding) {
    return '[QA_LAB][${finding.severity.name.toUpperCase()}]'
        '[${finding.surface}] ${finding.code} route=${finding.route} '
        'message=${finding.message}';
  }

  void _scheduleAutoExport() {
    if (_autoExportInFlight) {
      return;
    }
    final now = DateTime.now();
    final previous = _lastAutoExportAt;
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 2)) {
      return;
    }
    _lastAutoExportAt = now;
    _autoExportInFlight = true;
    unawaited(
      exportSessionJson().then((file) {
        if (QALabMode.autoMarkerLogs) {
          debugPrint('[QA_LAB][EXPORT] ${file.path}');
        }
      }).catchError((Object error, StackTrace stackTrace) {
        debugPrint(
          '[QA_LAB][EXPORT_ERROR] ${error.runtimeType}: $error\n$stackTrace',
        );
      }).whenComplete(() {
        _autoExportInFlight = false;
      }),
    );
  }

  @override
  void onClose() {
    _periodicTimer?.cancel();
    _cancelAllSurfaceWatchdogs();
    super.onClose();
  }
}
