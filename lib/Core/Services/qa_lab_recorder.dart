import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'package:turqappv2/hls_player/hls_controller.dart';

import 'qa_lab_catalog.dart';
import 'qa_lab_mode.dart';
import 'qa_lab_remote_uploader.dart';

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

class QALabTimelineEvent {
  const QALabTimelineEvent({
    required this.id,
    required this.category,
    required this.code,
    required this.route,
    required this.surface,
    required this.timestamp,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String category;
  final String code;
  final String route;
  final String surface;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'category': category,
      'code': code,
      'route': route,
      'surface': surface,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'metadata': metadata,
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
  final RxList<QALabTimelineEvent> timelineEvents = <QALabTimelineEvent>[].obs;
  final RxMap<String, dynamic> lastNativePlaybackSnapshot =
      <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> nativePlaybackSamples =
      <Map<String, dynamic>>[].obs;
  Timer? _periodicTimer;
  Timer? _nativePlaybackTimer;
  final Map<String, Timer> _surfaceWatchdogs = <String, Timer>{};
  final Map<String, DateTime> _rateLimitedIssueTimes = <String, DateTime>{};
  final Set<String> _emittedFindingKeys = <String>{};
  DateTime? _lastAutoExportAt;
  DateTime? _lastNativePlaybackSampleAt;
  Map<String, dynamic>? _cachedExtendedDeviceInfo;
  Future<Map<String, dynamic>>? _extendedDeviceInfoFuture;
  bool _autoExportInFlight = false;
  bool _nativePlaybackSampleInFlight = false;

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
    timelineEvents.clear();
    lastNativePlaybackSnapshot.clear();
    nativePlaybackSamples.clear();
    lastExportPath.value = '';
    lastLifecycleState.value = '';
    lastPermissionStatuses.clear();
    _rateLimitedIssueTimes.clear();
    _emittedFindingKeys.clear();
    _lastAutoExportAt = null;
    _lastNativePlaybackSampleAt = null;
    _autoExportInFlight = false;
    _nativePlaybackSampleInFlight = false;
    _periodicTimer?.cancel();
    _nativePlaybackTimer?.cancel();
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
    if (_supportsNativePlaybackSampling) {
      _nativePlaybackTimer = Timer.periodic(
        Duration(seconds: QALabMode.nativePlaybackPollSeconds),
        (_) => unawaited(sampleNativePlayback(trigger: 'poll')),
      );
      unawaited(sampleNativePlayback(trigger: 'session_started'));
    }
    captureCheckpoint(
      label: 'session_started',
      surface: lastSurface.value.isEmpty ? 'app' : lastSurface.value,
      extra: <String, dynamic>{'trigger': trigger},
    );
    unawaited(
      syncRemoteSummary(
        reason: 'session_started:$trigger',
        immediate: false,
      ),
    );
  }

  void resetSession() {
    startSession(trigger: 'reset');
  }

  void disposeSession() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _nativePlaybackTimer?.cancel();
    _nativePlaybackTimer = null;
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
    unawaited(
      syncRemoteSummary(
        reason: 'route_change',
        immediate: false,
      ),
    );
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

  void recordScrollEvent({
    required String surface,
    required String phase,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    _recordTimelineEvent(
      category: 'scroll',
      code: phase,
      surface: surface,
      metadata: metadata,
    );
  }

  void recordFeedFetchEvent({
    required String surface,
    required String stage,
    required String trigger,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    _recordTimelineEvent(
      category: 'feed_fetch',
      code: stage,
      surface: surface,
      metadata: <String, dynamic>{
        'trigger': trigger,
        ...metadata,
      },
    );
  }

  void recordAdEvent({
    String? surface,
    required String stage,
    required String placement,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    _recordTimelineEvent(
      category: 'ad',
      code: stage,
      surface: (surface ?? '').trim(),
      metadata: <String, dynamic>{
        'placement': placement,
        ...metadata,
      },
    );
  }

  void recordPlaybackDispatch({
    required String surface,
    required String stage,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    _recordTimelineEvent(
      category: 'playback_dispatch',
      code: stage,
      surface: surface,
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
    if (_supportsNativePlaybackSampling) {
      unawaited(
        sampleNativePlayback(
          trigger: 'checkpoint:$label',
          surfaceHint: surface,
        ),
      );
    }
    unawaited(
      syncRemoteSummary(
        reason: 'checkpoint:$label',
        immediate: false,
      ),
    );
  }

  Future<void> sampleNativePlayback({
    String trigger = 'manual',
    String? surfaceHint,
  }) async {
    if (!QALabMode.enabled || !_supportsNativePlaybackSampling) {
      return;
    }
    if (_nativePlaybackSampleInFlight) {
      return;
    }
    final now = DateTime.now();
    final previousSampleAt = _lastNativePlaybackSampleAt;
    if (previousSampleAt != null &&
        now.difference(previousSampleAt) < const Duration(milliseconds: 900)) {
      return;
    }

    _nativePlaybackSampleInFlight = true;
    try {
      final snapshot = await HLSController.getActiveSmokeSnapshot();
      if (snapshot.isEmpty) {
        return;
      }
      _lastNativePlaybackSampleAt = now;
      final normalized = _normalizeNativePlaybackSnapshot(
        snapshot,
        trigger: trigger,
        surfaceHint: surfaceHint,
        sampledAt: now,
      );
      lastNativePlaybackSnapshot
        ..clear()
        ..addAll(normalized);
      if (nativePlaybackSamples.isEmpty ||
          !_nativePlaybackSampleEquivalent(
            nativePlaybackSamples.last,
            normalized,
          )) {
        nativePlaybackSamples.add(normalized);
        _trimList(nativePlaybackSamples, 48);
      }
      _maybeEmitAutoSignals();
    } catch (error, stackTrace) {
      if (_isRateLimited(
        'native_playback_sample_failed',
        const Duration(seconds: 12),
      )) {
        return;
      }
      recordIssue(
        source: QALabIssueSource.platform,
        code: 'native_playback_sample_failed',
        severity: QALabIssueSeverity.warning,
        message: 'Native playback snapshot sampling failed.',
        stackTrace: stackTrace.toString(),
        metadata: <String, dynamic>{
          'trigger': trigger,
          'error': error.toString(),
        },
      );
    } finally {
      _nativePlaybackSampleInFlight = false;
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
    if (severity != QALabIssueSeverity.info) {
      unawaited(
        syncRemoteSummary(
          reason: 'issue:$code',
          immediate: severity == QALabIssueSeverity.blocking ||
              severity == QALabIssueSeverity.error,
        ),
      );
    }
  }

  void _recordTimelineEvent({
    required String category,
    required String code,
    required String surface,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    if (!QALabMode.enabled) return;
    if (sessionId.value.isEmpty) {
      startSession(trigger: 'timeline_event');
    }
    final snapshot = IntegrationTestStateProbe.snapshot();
    final route = (snapshot['currentRoute'] ?? '').toString();
    final effectiveSurface = surface.trim().isEmpty
        ? _inferSurfaceFromSnapshot(snapshot)
        : surface.trim();
    timelineEvents.add(
      QALabTimelineEvent(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        category: category,
        code: code,
        route: route,
        surface: effectiveSurface,
        timestamp: DateTime.now(),
        metadata: <String, dynamic>{
          ...metadata,
          'probe': snapshot,
        },
      ),
    );
    _trimList(timelineEvents, QALabMode.maxTimelineEvents);
    lastRoute.value = route;
    lastSurface.value = effectiveSurface;
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
      ..._buildActiveIssueFindings(),
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

  List<QALabTimelineEvent> _surfaceTimelineEvents(String surface) {
    return timelineEvents
        .where((event) => _matchesSurface(event.surface, surface))
        .toList(growable: false);
  }

  List<QALabPinpointFinding> _buildSurfaceRuntimeFindings(
    String surface,
    List<QALabIssue> surfaceIssues,
    List<QALabCheckpoint> surfaceCheckpoints,
  ) {
    final surfaceTimeline = _surfaceTimelineEvents(surface);
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
      _buildNativePlaybackFindings(
        surface: surface,
        latestProbe: latestProbe,
        authProbe: authProbe,
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
    findings.addAll(
      _buildFetchSurfaceFindings(
        surface: surface,
        surfaceTimeline: surfaceTimeline,
        referenceTime: referenceTime,
        route: route,
      ),
    );
    findings.addAll(
      _buildScrollSurfaceFindings(
        surface: surface,
        surfaceTimeline: surfaceTimeline,
        surfaceIssues: surfaceIssues,
        referenceTime: referenceTime,
        route: route,
      ),
    );
    findings.addAll(
      _buildAdSurfaceFindings(
        surface: surface,
        surfaceTimeline: surfaceTimeline,
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
    final surfaceTimeline = _surfaceTimelineEvents(surface);
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
    final duplicateFeedTriggers =
        _countDuplicateFeedTriggerBursts(surfaceTimeline: surfaceTimeline);
    final duplicatePlaybackDispatches = _countDuplicatePlaybackDispatchBursts(
      surfaceTimeline: surfaceTimeline,
    );
    final latestScrollLatency = _latestScrollLatencySummary(
      surfaceTimeline: surfaceTimeline,
      surfaceIssues: surfaceIssues,
      referenceTime: surfaceCheckpoints.isEmpty
          ? DateTime.now()
          : surfaceCheckpoints.last.timestamp,
    );
    final adSummary = _adSummary(surfaceTimeline);

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
      'timelineEventCount': surfaceTimeline.length,
      'duplicateFeedTriggerCount': duplicateFeedTriggers,
      'duplicatePlaybackDispatchCount': duplicatePlaybackDispatches,
      'latestScrollDispatchLatencyMs': latestScrollLatency.$1,
      'latestScrollFirstFrameLatencyMs': latestScrollLatency.$2,
      'adRequestCount': adSummary.$1,
      'adLoadCount': adSummary.$2,
      'adFailureCount': adSummary.$3,
      'worstAdLoadMs': adSummary.$4,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackStatus':
            (lastNativePlaybackSnapshot['status'] ?? '').toString(),
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackErrorCount':
            _nativePlaybackErrors(lastNativePlaybackSnapshot).length,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackActive': lastNativePlaybackSnapshot['active'] == true,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackPlaying':
            lastNativePlaybackSnapshot['isPlaying'] == true,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackBuffering':
            lastNativePlaybackSnapshot['isBuffering'] == true,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackFirstFrame':
            lastNativePlaybackSnapshot['firstFrameRendered'] == true,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackStallCount':
            _asInt(lastNativePlaybackSnapshot['stallCount']),
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
        .where(
          (event) =>
              event.code == 'started' ||
              event.code == 'skipped' ||
              event.code == 'requested',
        )
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

  QALabTimelineEvent? _latestScrollSettleEvent(
    List<QALabTimelineEvent> surfaceTimeline,
  ) {
    return surfaceTimeline
        .where((event) => event.category == 'scroll' && event.code == 'settled')
        .toList(growable: false)
        .lastOrNull;
  }

  QALabTimelineEvent? _firstPlaybackDispatchAfter({
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime after,
    required String docId,
  }) {
    return surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where((event) => (event.metadata['docId'] ?? '').toString() == docId)
        .where((event) => !event.timestamp.isBefore(after))
        .toList(growable: false)
        .firstOrNull;
  }

  List<Map<String, dynamic>> _duplicatePlaybackDispatchBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
    String? docId,
  }) {
    final events = surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where(
          (event) =>
              docId == null ||
              (event.metadata['docId'] ?? '').toString() == docId,
        )
        .toList(growable: false);
    final bursts = <Map<String, dynamic>>[];
    for (int i = 0; i < events.length; i++) {
      final first = events[i];
      final firstDocId = (first.metadata['docId'] ?? '').toString();
      if (firstDocId.isEmpty) continue;
      final stages = <String>[first.code];
      var repeatCount = 1;
      for (int j = i + 1; j < events.length; j++) {
        final next = events[j];
        if ((next.metadata['docId'] ?? '').toString() != firstDocId) {
          continue;
        }
        final deltaMs =
            next.timestamp.difference(first.timestamp).inMilliseconds;
        if (deltaMs > QALabMode.duplicatePlaybackDispatchWindowMs) {
          break;
        }
        repeatCount += 1;
        stages.add(next.code);
      }
      if (repeatCount >= 2) {
        bursts.add(
          <String, dynamic>{
            'timestamp': first.timestamp.toUtc().toIso8601String(),
            'docId': firstDocId,
            'repeatCount': repeatCount,
            'stages': stages,
            'windowMs': QALabMode.duplicatePlaybackDispatchWindowMs,
          },
        );
      }
    }
    bursts.sort((a, b) => _asInt(b['repeatCount']) - _asInt(a['repeatCount']));
    return bursts;
  }

  int _countDuplicatePlaybackDispatchBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
  }) {
    return _duplicatePlaybackDispatchBursts(surfaceTimeline: surfaceTimeline)
        .length;
  }

  (int, int) _latestScrollLatencySummary({
    required List<QALabTimelineEvent> surfaceTimeline,
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
  }) {
    final latestSettle = _latestScrollSettleEvent(surfaceTimeline);
    if (latestSettle == null) {
      return (0, 0);
    }
    final docId = (latestSettle.metadata['docId'] ?? '').toString();
    if (docId.isEmpty) {
      return (0, 0);
    }
    final dispatch = _firstPlaybackDispatchAfter(
      surfaceTimeline: surfaceTimeline,
      after: latestSettle.timestamp,
      docId: docId,
    );
    final firstFrameIssue = surfaceIssues
        .where((issue) => issue.code == 'video_first_frame')
        .where((issue) => _videoIdOf(issue) == docId)
        .where((issue) => issue.timestamp.isAfter(latestSettle.timestamp))
        .toList(growable: false)
        .firstOrNull;
    final dispatchLatencyMs = dispatch == null
        ? 0
        : dispatch.timestamp.difference(latestSettle.timestamp).inMilliseconds;
    final firstFrameLatencyMs = firstFrameIssue == null
        ? 0
        : firstFrameIssue.timestamp
            .difference(latestSettle.timestamp)
            .inMilliseconds;
    return (dispatchLatencyMs, firstFrameLatencyMs);
  }

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

  List<QALabPinpointFinding> _buildNativePlaybackFindings({
    required String surface,
    required Map<String, dynamic> latestProbe,
    required Map<String, dynamic> authProbe,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed' && surface != 'short') {
      return const <QALabPinpointFinding>[];
    }
    if (!_hasAuthenticatedUser(authProbe)) {
      return const <QALabPinpointFinding>[];
    }
    if (lastNativePlaybackSnapshot.isEmpty ||
        lastNativePlaybackSnapshot['supported'] == false) {
      return const <QALabPinpointFinding>[];
    }

    final count = _asInt(latestProbe['count']);
    final errors = _nativePlaybackErrors(lastNativePlaybackSnapshot);
    final isPlaybackExpected =
        lastNativePlaybackSnapshot['isPlaybackExpected'] == true;
    if (count <= 0 && !isPlaybackExpected && errors.isEmpty) {
      return const <QALabPinpointFinding>[];
    }

    final findings = <QALabPinpointFinding>[];
    final hasFirstFrame =
        lastNativePlaybackSnapshot['firstFrameRendered'] == true;
    final isPlaying = lastNativePlaybackSnapshot['isPlaying'] == true;
    final isBuffering = lastNativePlaybackSnapshot['isBuffering'] == true;
    final stallCount = _asInt(lastNativePlaybackSnapshot['stallCount']);
    final sampledAt =
        _parseTimestamp(lastNativePlaybackSnapshot['sampledAt']) ??
            referenceTime;
    final snapshotContext = <String, dynamic>{
      'platform': (lastNativePlaybackSnapshot['platform'] ?? '').toString(),
      'status': (lastNativePlaybackSnapshot['status'] ?? '').toString(),
      'errors': errors,
      'trigger': (lastNativePlaybackSnapshot['trigger'] ?? '').toString(),
      'active': lastNativePlaybackSnapshot['active'] == true,
      'isPlaybackExpected': isPlaybackExpected,
      'isPlaying': isPlaying,
      'isBuffering': isBuffering,
      'firstFrameRendered': hasFirstFrame,
      'stallCount': stallCount,
      'lastKnownPlaybackTime':
          _asDouble(lastNativePlaybackSnapshot['lastKnownPlaybackTime']),
      'layerAttachCount':
          _asInt(lastNativePlaybackSnapshot['layerAttachCount']),
    };

    const firstFrameCodes = <String>{
      'FIRST_FRAME_TIMEOUT',
      'READY_WITHOUT_FRAME',
      'PLAYBACK_NOT_STARTED',
    };
    if (errors.any(firstFrameCodes.contains)) {
      findings.add(
        QALabPinpointFinding(
          severity: errors.contains('FIRST_FRAME_TIMEOUT') ||
                  errors.contains('READY_WITHOUT_FRAME')
              ? QALabIssueSeverity.blocking
              : QALabIssueSeverity.error,
          code: '${surface}_native_first_frame_timeout',
          message:
              'Native playback health on $surface expected a frame but never confirmed one in time.',
          route: route,
          surface: surface,
          timestamp: sampledAt,
          context: snapshotContext,
        ),
      );
    }

    if (errors.contains('DOUBLE_BLACK_SCREEN_RISK')) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.error,
          code: '${surface}_native_black_screen_risk',
          message:
              'Native playback health on $surface detected repeated layer attachment before first frame.',
          route: route,
          surface: surface,
          timestamp: sampledAt,
          context: snapshotContext,
        ),
      );
    }

    if (errors.contains('EXCESSIVE_REBUFFERING') ||
        (isBuffering && stallCount >= 2)) {
      findings.add(
        QALabPinpointFinding(
          severity: stallCount >= 4
              ? QALabIssueSeverity.blocking
              : QALabIssueSeverity.error,
          code: '${surface}_native_buffer_stall',
          message:
              'Native playback health on $surface detected prolonged buffering or excessive rebuffering.',
          route: route,
          surface: surface,
          timestamp: sampledAt,
          context: snapshotContext,
        ),
      );
    }

    if (errors.contains('VIDEO_FREEZE') ||
        errors.contains('FULLSCREEN_INTERRUPTION') ||
        errors.contains('BACKGROUND_RESUME_FAILURE')) {
      findings.add(
        QALabPinpointFinding(
          severity: errors.contains('VIDEO_FREEZE')
              ? QALabIssueSeverity.blocking
              : QALabIssueSeverity.error,
          code: '${surface}_native_playback_interrupted',
          message:
              'Native playback health on $surface reported a freeze or failed recovery after an interruption.',
          route: route,
          surface: surface,
          timestamp: sampledAt,
          context: snapshotContext,
        ),
      );
    }

    if (errors.contains('AUDIO_NOT_STARTED')) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.error,
          code: '${surface}_native_audio_not_started',
          message:
              'Native playback health on $surface reported playback without audio start confirmation.',
          route: route,
          surface: surface,
          timestamp: sampledAt,
          context: snapshotContext,
        ),
      );
    }

    if (surface == 'feed' &&
        isPlaybackExpected &&
        !hasFirstFrame &&
        !isPlaying &&
        _surfaceIssues(surface)
                .where((issue) => issue.code == 'video_first_frame')
                .length >=
            2) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.error,
          code: 'feed_thumbnail_only_runtime_loss',
          message:
              'Feed previously rendered video frames in this session, but the current eligible card stayed on thumbnail state.',
          route: route,
          surface: surface,
          timestamp: sampledAt,
          context: snapshotContext,
        ),
      );
    }

    return findings;
  }

  List<QALabPinpointFinding> _buildActiveIssueFindings() {
    final now = DateTime.now();
    return issues
        .where((issue) => issue.severity != QALabIssueSeverity.info)
        .where((issue) => !_isSpecializedIssueCode(issue.code))
        .where((issue) => !_isResolvedPermissionIssue(issue))
        .where(
          (issue) =>
              now.difference(issue.timestamp) <=
              _activeIssueLookback(issue.severity),
        )
        .map(
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
        )
        .toList(growable: false);
  }

  bool _isSpecializedIssueCode(String code) {
    return code.startsWith('video_') ||
        code.startsWith('frame_jank_') ||
        code.startsWith('cache_first_') ||
        code.startsWith('lifecycle_');
  }

  bool _isResolvedPermissionIssue(QALabIssue issue) {
    if (!issue.code.startsWith('permission_') ||
        !issue.code.endsWith('_blocked')) {
      return false;
    }
    final rawKey = issue.code.substring(
      'permission_'.length,
      issue.code.length - '_blocked'.length,
    );
    final status = lastPermissionStatuses[rawKey];
    return status == 'granted' || status == 'limited';
  }

  Duration _activeIssueLookback(QALabIssueSeverity severity) {
    switch (severity) {
      case QALabIssueSeverity.blocking:
        return const Duration(seconds: 75);
      case QALabIssueSeverity.error:
        return const Duration(seconds: 60);
      case QALabIssueSeverity.warning:
        return Duration(seconds: QALabMode.activeIssueLookbackSeconds);
      case QALabIssueSeverity.info:
        return Duration.zero;
    }
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

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
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
    if (code.contains('duplicate_fetch')) {
      return (
        'feed_trigger_duplication',
        '${diagnostic.surface} triggered repeated feed loads before a prior fetch settled.',
      );
    }
    if (code.contains('duplicate_playback_dispatch')) {
      return (
        'playback_dispatch_duplication',
        '${diagnostic.surface} issued repeated playback commands against the same item in a tight burst.',
      );
    }
    if (code.contains('scroll_dispatch') ||
        code.contains('scroll_first_frame')) {
      return (
        'scroll_autoplay_latency',
        '${diagnostic.surface} lost time between scroll settle, playback dispatch, and the first rendered frame.',
      );
    }
    if (code.contains('first_frame')) {
      return (
        'first_frame_latency',
        '${diagnostic.surface} started playback but first frame confirmation lagged or never arrived.',
      );
    }
    if (code.contains('black_screen')) {
      return (
        'first_frame_latency',
        '${diagnostic.surface} reattached video layers before a stable first frame and risks blank flashes.',
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
    if (code.contains('thumbnail_only')) {
      return (
        'playback_session_loss',
        '${diagnostic.surface} had prior video success in the session but later regressed to thumbnail-only playback.',
      );
    }
    if (code.contains('ad_load') || code.contains('ad_retry')) {
      return (
        'ad_loading_latency',
        '${diagnostic.surface} ad lifecycle added delay, failure, or retry pressure during rendering.',
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
    if (code.contains('interrupted')) {
      return (
        'lifecycle_interruption',
        '${diagnostic.surface} failed to recover cleanly after a fullscreen or background interruption.',
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

  bool get _supportsNativePlaybackSampling =>
      GetPlatform.isIOS || GetPlatform.isAndroid;

  Map<String, dynamic> _normalizeNativePlaybackSnapshot(
    Map<String, dynamic> snapshot, {
    required String trigger,
    required String? surfaceHint,
    required DateTime sampledAt,
  }) {
    final nestedSnapshot = snapshot['snapshot'] is Map
        ? Map<String, dynamic>.from(snapshot['snapshot'] as Map)
        : Map<String, dynamic>.from(snapshot);
    final errors = _nativePlaybackErrors(snapshot);
    return <String, dynamic>{
      'platform': defaultTargetPlatform.name,
      'trigger': trigger,
      'surfaceHint': surfaceHint ?? '',
      'sampledAt': sampledAt.toUtc().toIso8601String(),
      'supported': snapshot['supported'] != false,
      'active': snapshot['active'] == true,
      'status': (snapshot['status'] ?? '').toString(),
      'errors': errors,
      'firstFrameRendered': snapshot['firstFrameRendered'] == true ||
          nestedSnapshot['hasRenderedFirstFrame'] == true,
      'isPlaybackExpected': nestedSnapshot['isPlaybackExpected'] == true,
      'isPlaying': nestedSnapshot['isPlaying'] == true,
      'isBuffering': nestedSnapshot['isBuffering'] == true,
      'stallCount': _asInt(nestedSnapshot['stallCount']),
      'layerAttachCount': _asInt(nestedSnapshot['layerAttachCount']),
      'lastKnownPlaybackTime':
          _asDouble(nestedSnapshot['lastKnownPlaybackTime']),
      'awaitingFullscreenRecovery':
          nestedSnapshot['awaitingFullscreenRecovery'] == true,
      'awaitingBackgroundRecovery':
          nestedSnapshot['awaitingBackgroundRecovery'] == true,
      'raw': (snapshot['raw'] ?? '').toString(),
      'snapshot': nestedSnapshot,
    };
  }

  List<String> _nativePlaybackErrors(Map<String, dynamic> snapshot) {
    final rawErrors = snapshot['errors'];
    if (rawErrors is! List) {
      return const <String>[];
    }
    return rawErrors
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  bool _nativePlaybackSampleEquivalent(
    Map<String, dynamic> previous,
    Map<String, dynamic> current,
  ) {
    final previousErrors = _nativePlaybackErrors(previous);
    final currentErrors = _nativePlaybackErrors(current);
    return previous['platform'] == current['platform'] &&
        previous['status'] == current['status'] &&
        previous['active'] == current['active'] &&
        previous['firstFrameRendered'] == current['firstFrameRendered'] &&
        previous['isPlaybackExpected'] == current['isPlaybackExpected'] &&
        previous['isPlaying'] == current['isPlaying'] &&
        previous['isBuffering'] == current['isBuffering'] &&
        _asInt(previous['stallCount']) == _asInt(current['stallCount']) &&
        _asInt(previous['layerAttachCount']) ==
            _asInt(current['layerAttachCount']) &&
        _asDouble(previous['lastKnownPlaybackTime']) ==
            _asDouble(current['lastKnownPlaybackTime']) &&
        listEquals(previousErrors, currentErrors);
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
    if (shouldAutoExport && QALabMode.remoteUploadEnabled) {
      unawaited(
        syncRemoteSummary(
          reason: 'auto_finding',
          immediate: true,
        ),
      );
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
    _nativePlaybackTimer?.cancel();
    _cancelAllSurfaceWatchdogs();
    super.onClose();
  }
}
