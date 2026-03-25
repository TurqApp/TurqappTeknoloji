import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
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
part 'qa_lab_recorder_models_part.dart';
part 'qa_lab_recorder_export_part.dart';
part 'qa_lab_recorder_runtime_part.dart';

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

  Future<void> prepareFreshStart({String trigger = 'launch'}) async {
    if (!QALabMode.enabled) return;
    final clearedTargets = <String>[];
    final cleanupFailures = <Map<String, String>>[];

    Future<void> clearChildren(
      Directory directory, {
      required String label,
    }) async {
      if (!await directory.exists()) {
        return;
      }
      var cleared = 0;
      await for (final entity in directory.list(followLinks: false)) {
        await entity.delete(recursive: true);
        cleared += 1;
      }
      if (cleared > 0) {
        clearedTargets.add('$label:$cleared');
      }
    }

    Future<void> deleteDirectory(
      Directory directory, {
      required String label,
    }) async {
      if (!await directory.exists()) {
        return;
      }
      await directory.delete(recursive: true);
      clearedTargets.add(label);
    }

    Future<void> safeCleanup(
      Future<void> Function() action, {
      required String label,
    }) async {
      try {
        await action();
      } catch (error) {
        cleanupFailures.add(
          <String, String>{
            'target': label,
            'error': error.toString(),
          },
        );
      }
    }

    await safeCleanup(
      () async => clearChildren(
        await getTemporaryDirectory(),
        label: 'temp',
      ),
      label: 'temp',
    );
    await safeCleanup(
      () async {
        final supportDirectory = await getApplicationSupportDirectory();
        await deleteDirectory(
          Directory('${supportDirectory.path}/hls_cache'),
          label: 'hls_cache',
        );
        await deleteDirectory(
          Directory('${supportDirectory.path}/index_pool'),
          label: 'index_pool',
        );
      },
      label: 'app_support',
    );
    await safeCleanup(
      () async {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        await deleteDirectory(
          Directory('${documentsDirectory.path}/qa_lab'),
          label: 'qa_lab_reports',
        );
      },
      label: 'documents',
    );

    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      clearedTargets.add('image_cache');
    } catch (error) {
      cleanupFailures.add(
        <String, String>{
          'target': 'image_cache',
          'error': error.toString(),
        },
      );
    }

    QALabRemoteUploader.maybeFind()?.resetLocalState();
    startSession(trigger: 'fresh_start:$trigger');
    captureCheckpoint(
      label: 'fresh_start_applied',
      surface: lastSurface.value.isEmpty ? 'app' : lastSurface.value,
      extra: <String, dynamic>{
        'trigger': trigger,
        'clearedTargets': clearedTargets,
        'cleanupFailureCount': cleanupFailures.length,
      },
    );
    for (final failure in cleanupFailures) {
      recordIssue(
        source: QALabIssueSource.cache,
        code: 'qa_fresh_start_cleanup_failed',
        severity: QALabIssueSeverity.warning,
        message: 'QA fresh-start cache cleanup failed.',
        metadata: failure,
      );
    }
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

  @override
  void onClose() {
    disposeSession();
    super.onClose();
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
    final snapshot = IntegrationTestStateProbe.snapshot();
    final surface = _inferSurfaceFromSnapshot(snapshot);
    final videoId =
        ((metadata['videoId'] ?? metadata['docId']) ?? '').toString().trim();
    if ((code == 'video_buffering_started' ||
            code == 'video_buffering_ended') &&
        _isRateLimited(
          'video_buffering|$surface|$videoId|$code',
          code == 'video_buffering_started'
              ? const Duration(seconds: 4)
              : const Duration(seconds: 2),
        )) {
      return;
    }
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
    final snapshot = IntegrationTestStateProbe.snapshot();
    final surface = _inferSurfaceFromSnapshot(snapshot);
    if (_isRateLimited(
      'lifecycle|$surface|$state',
      const Duration(seconds: 3),
    )) {
      return;
    }
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
    return _observedSurfaces()
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

  List<QALabTimelineEvent> _routeScopedTimelineEvents(
    List<QALabTimelineEvent> surfaceTimeline,
    String route,
  ) {
    final trimmedRoute = route.trim();
    if (trimmedRoute.isEmpty) {
      return surfaceTimeline;
    }
    final exactMatches = surfaceTimeline
        .where((event) => event.route.trim() == trimmedRoute)
        .toList(growable: false);
    if (exactMatches.isNotEmpty) {
      return exactMatches;
    }
    final unscopedMatches = surfaceTimeline
        .where((event) => event.route.trim().isEmpty)
        .toList(growable: false);
    if (unscopedMatches.isNotEmpty) {
      return unscopedMatches;
    }
    return surfaceTimeline;
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
    final recentHostLookupFailure = _hasRecentHostLookupFailure(
      surfaceIssues: surfaceIssues,
      referenceTime: referenceTime,
    );
    final route = latestCheckpoint?.route.isNotEmpty == true
        ? latestCheckpoint!.route
        : _latestRouteForSurface(surface);

    if ((surface == 'feed' || surface == 'short') &&
        _hasAuthenticatedUser(authProbe)) {
      final count = _asInt(latestProbe['count']);
      if (count == 0 &&
          latestProbe['registered'] == true &&
          !recentHostLookupFailure) {
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
      surfaceIssues: surfaceIssues,
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
      final rootProbe = latestCheckpoint?.probe ?? const <String, dynamic>{};
      final isFeedForeground = _isPrimaryFeedSelected(
        rootProbe,
        route: route,
      );
      final hasInvalidCenteredIndex =
          count > 0 && (centeredIndex < 0 || centeredIndex >= count);
      final invalidCenteredIndexSince = hasInvalidCenteredIndex
          ? _feedCenteredIndexInvalidObservedSince(
              surfaceCheckpoints: surfaceCheckpoints,
              route: route,
            )
          : null;
      final invalidCenteredIndexElapsedMs = invalidCenteredIndexSince == null
          ? 0
          : referenceTime.difference(invalidCenteredIndexSince).inMilliseconds;
      if (hasInvalidCenteredIndex &&
          !recentHostLookupFailure &&
          invalidCenteredIndexElapsedMs >=
              QALabMode.autoplayDetectionGraceMs) {
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
              'elapsedMs': invalidCenteredIndexElapsedMs,
            },
          ),
        );
      }
      final playbackSuspended = latestProbe['playbackSuspended'] == true;
      final pauseAll = latestProbe['pauseAll'] == true;
      final canClaimPlaybackNow = latestProbe['canClaimPlaybackNow'] == true;
      final centeredHasPlayableVideo =
          latestProbe['centeredHasPlayableVideo'] == true;
      if (isFeedForeground &&
          centeredHasPlayableVideo &&
          count > 0 &&
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
              'centeredHasPlayableVideo': centeredHasPlayableVideo,
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
        surfaceCheckpoints: surfaceCheckpoints,
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
    required List<QALabIssue> surfaceIssues,
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
    if (_hasRecentHostLookupFailure(
          surfaceIssues: surfaceIssues,
          referenceTime: referenceTime,
        ) ||
        _hasRecentBackendUnavailableFailure(
          surfaceIssues: surfaceIssues,
          referenceTime: referenceTime,
        )) {
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
      final centeredHasPlayableVideo =
          surfaceProbe['centeredHasPlayableVideo'] == true;
      final playbackSuspended = surfaceProbe['playbackSuspended'] == true;
      final pauseAll = surfaceProbe['pauseAll'] == true;
      final canClaimPlaybackNow = surfaceProbe['canClaimPlaybackNow'] == true;
      if (centeredIndex < 0 ||
          centeredIndex >= count ||
          !centeredHasPlayableVideo ||
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
    if (wrongTarget &&
        !_hasPersistentAutoplayMismatch(
          surface: surface,
          surfaceCheckpoints: surfaceCheckpoints,
          route: route,
          expectedDocId: expectedDocId,
          currentPlayingDocId: currentPlayingDocId,
          referenceTime: referenceTime,
        )) {
      return null;
    }
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

  bool _hasRecentHostLookupFailure({
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
  }) {
    const markers = <String>[
      'Failed host lookup',
      'No address associated with hostname',
    ];
    return surfaceIssues.any((issue) {
      if (issue.source != QALabIssueSource.platform) {
        return false;
      }
      if (referenceTime.difference(issue.timestamp) >
          const Duration(seconds: 20)) {
        return false;
      }
      final message = issue.message;
      return markers.any(message.contains);
    });
  }

  bool _hasRecentBackendUnavailableFailure({
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
  }) {
    return surfaceIssues.any((issue) {
      if (issue.source != QALabIssueSource.platform) {
        return false;
      }
      if (referenceTime.difference(issue.timestamp) >
          const Duration(seconds: 20)) {
        return false;
      }
      final message = issue.message.toLowerCase();
      return message.contains('cloud_firestore/unavailable') ||
          message.contains('service is currently unavailable');
    });
  }

  DateTime? _feedCenteredIndexInvalidObservedSince({
    required List<QALabCheckpoint> surfaceCheckpoints,
    required String route,
  }) {
    DateTime? observedSince;
    for (final checkpoint in surfaceCheckpoints.reversed) {
      if (checkpoint.route != route) {
        break;
      }
      final feedProbe =
          checkpoint.probe['feed'] as Map<String, dynamic>? ??
              const <String, dynamic>{};
      final count = _asInt(feedProbe['count']);
      final centeredIndex = _asInt(feedProbe['centeredIndex']);
      final isInvalid = count > 0 && (centeredIndex < 0 || centeredIndex >= count);
      if (!isInvalid) {
        break;
      }
      observedSince = checkpoint.timestamp;
    }
    return observedSince;
  }

  List<QALabPinpointFinding> _buildVideoSurfaceFindings({
    required String surface,
    required List<QALabIssue> surfaceIssues,
    required List<QALabCheckpoint> surfaceCheckpoints,
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
      if (!_isRelevantSurfaceVideoIssue(
        surface: surface,
        videoId: videoId,
        issueTimestamp: issue.timestamp,
        surfaceCheckpoints: surfaceCheckpoints,
        route: route,
      )) {
        continue;
      }
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
    final findings = <QALabPinpointFinding>[];
    final specializedFailureFinding = _buildSpecializedFeedFetchFailureFinding(
      surfaceTimeline: surfaceTimeline,
      referenceTime: referenceTime,
      route: route,
    );
    if (specializedFailureFinding != null) {
      findings.add(specializedFailureFinding);
    }
    final bursts = _feedTriggerBursts(surfaceTimeline: surfaceTimeline);
    if (bursts.isEmpty) {
      return findings;
    }
    final strongest = bursts.first;
    final repeatCount = _asInt(strongest['repeatCount']);
    findings.add(
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
    );
    return findings;
  }

  QALabPinpointFinding? _buildSpecializedFeedFetchFailureFinding({
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime referenceTime,
    required String route,
  }) {
    final failedEvent = surfaceTimeline
        .where((event) => event.category == 'feed_fetch')
        .where((event) => event.code == 'failed')
        .toList(growable: false)
        .lastOrNull;
    if (failedEvent == null) {
      return null;
    }
    final error = (failedEvent.metadata['error'] ?? '').toString().trim();
    if (error.isEmpty) {
      return null;
    }
    final lowerError = error.toLowerCase();
    final trigger = (failedEvent.metadata['trigger'] ?? '').toString();
    final pageLimit = _asInt(failedEvent.metadata['pageLimit']);
    final currentCount = _asInt(failedEvent.metadata['currentCount']);

    if (error.contains('Failed host lookup') ||
        lowerError.contains('no address associated with hostname')) {
      return QALabPinpointFinding(
        severity: QALabIssueSeverity.error,
        code: 'feed_host_lookup_failed',
        message:
            'feed hit hostname resolution failures while loading remote dependencies.',
        route: route,
        surface: 'feed',
        timestamp: failedEvent.timestamp,
        context: <String, dynamic>{
          'trigger': trigger,
          'pageLimit': pageLimit,
          'currentCount': currentCount,
          'error': error,
        },
      );
    }

    if (lowerError.contains('cloud_firestore/unavailable') ||
        lowerError.contains('service is currently unavailable')) {
      return QALabPinpointFinding(
        severity: QALabIssueSeverity.error,
        code: 'feed_backend_unavailable',
        message:
            'feed hit a transient backend availability failure while loading live data.',
        route: route,
        surface: 'feed',
        timestamp: failedEvent.timestamp,
        context: <String, dynamic>{
          'trigger': trigger,
          'pageLimit': pageLimit,
          'currentCount': currentCount,
          'error': error,
        },
      );
    }

    return null;
  }

  List<Map<String, dynamic>> _feedTriggerBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
  }) {
    final feedEvents = surfaceTimeline
        .where((event) => event.category == 'feed_fetch')
        .where((event) => event.code == 'requested')
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
    final routeTimeline = _routeScopedTimelineEvents(surfaceTimeline, route);
    final latestSettle = _latestScrollSettleEvent(routeTimeline);
    if (latestSettle == null) {
      return const <QALabPinpointFinding>[];
    }
    final expectedDocId = (latestSettle.metadata['docId'] ?? '').toString();
    if (expectedDocId.isEmpty) {
      return const <QALabPinpointFinding>[];
    }

    final findings = <QALabPinpointFinding>[];
    final dispatch = _firstPlaybackDispatchAfter(
      surfaceTimeline: routeTimeline,
      after: latestSettle.timestamp,
      docId: expectedDocId,
    );
    final latestSkip = _latestPlaybackSkipAfter(
      surfaceTimeline: routeTimeline,
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
      surfaceTimeline: routeTimeline,
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
        .where(_isIssuedPlaybackDispatch)
        .where((event) => (event.metadata['docId'] ?? '').toString() == docId)
        .where((event) => !event.timestamp.isBefore(after))
        .toList(growable: false)
        .firstOrNull;
  }

  QALabTimelineEvent? _latestPlaybackSkipAfter({
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime after,
    required String docId,
  }) {
    return surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where((event) => !_isIssuedPlaybackDispatch(event))
        .where((event) => (event.metadata['docId'] ?? '').toString() == docId)
        .where((event) => !event.timestamp.isBefore(after))
        .toList(growable: false)
        .lastOrNull;
  }

  List<Map<String, dynamic>> _duplicatePlaybackDispatchBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
    String? docId,
  }) {
    final events = surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where(_isDuplicatePlaybackDispatchCandidate)
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
            'sources': <String>[
              (first.metadata['dispatchSource'] ?? '').toString(),
              for (int k = i + 1;
                  k < events.length &&
                      (events[k].metadata['docId'] ?? '').toString() ==
                          firstDocId &&
                      events[k]
                              .timestamp
                              .difference(first.timestamp)
                              .inMilliseconds <=
                          QALabMode.duplicatePlaybackDispatchWindowMs;
                  k += 1)
                (events[k].metadata['dispatchSource'] ?? '').toString(),
            ].where((item) => item.isNotEmpty).toSet().toList(growable: false),
            'callerSignatures': <String>[
              (first.metadata['callerSignature'] ?? '').toString(),
              for (int k = i + 1;
                  k < events.length &&
                      (events[k].metadata['docId'] ?? '').toString() ==
                          firstDocId &&
                      events[k]
                              .timestamp
                              .difference(first.timestamp)
                              .inMilliseconds <=
                          QALabMode.duplicatePlaybackDispatchWindowMs;
                  k += 1)
                (events[k].metadata['callerSignature'] ?? '').toString(),
            ].where((item) => item.isNotEmpty).toSet().toList(growable: false),
            'scrollToken': (first.metadata['scrollToken'] ?? '').toString(),
            'windowMs': QALabMode.duplicatePlaybackDispatchWindowMs,
          },
        );
      }
    }
    bursts.sort((a, b) => _asInt(b['repeatCount']) - _asInt(a['repeatCount']));
    return bursts;
  }

  bool _isIssuedPlaybackDispatch(QALabTimelineEvent event) {
    final raw = event.metadata['dispatchIssued'];
    if (raw is bool) return raw;
    if (raw is String) {
      return raw.toLowerCase() != 'false';
    }
    return true;
  }

  bool _isDuplicatePlaybackDispatchCandidate(QALabTimelineEvent event) {
    if (!_isIssuedPlaybackDispatch(event)) {
      return false;
    }
    if (event.surface.trim() != 'feed') {
      return true;
    }
    switch (event.code) {
      case 'feed_play_only_this':
      case 'feed_reassert_only_this':
      case 'feed_card_exclusive_play_only_this':
        return true;
      default:
        return false;
    }
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
}
