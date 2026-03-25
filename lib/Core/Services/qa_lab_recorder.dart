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
part 'qa_lab_recorder_remote_sync_part.dart';
part 'qa_lab_recorder_remote_sync_helpers_part.dart';
part 'qa_lab_recorder_remote_sync_device_part.dart';
part 'qa_lab_recorder_remote_sync_sanitize_part.dart';
part 'qa_lab_recorder_runtime_part.dart';
part 'qa_lab_recorder_runtime_surfaces_part.dart';
part 'qa_lab_recorder_runtime_helpers_part.dart';
part 'qa_lab_recorder_runtime_ranking_part.dart';
part 'qa_lab_recorder_runtime_root_cause_part.dart';
part 'qa_lab_recorder_runtime_signals_part.dart';
part 'qa_lab_recorder_runtime_navigation_part.dart';
part 'qa_lab_recorder_capture_part.dart';
part 'qa_lab_recorder_capture_events_part.dart';
part 'qa_lab_recorder_capture_timeline_part.dart';
part 'qa_lab_recorder_capture_issue_part.dart';
part 'qa_lab_recorder_diagnostics_part.dart';
part 'qa_lab_recorder_diagnostics_surfaces_part.dart';
part 'qa_lab_recorder_diagnostics_health_part.dart';
part 'qa_lab_recorder_diagnostics_state_part.dart';
part 'qa_lab_recorder_diagnostics_state_surface_part.dart';
part 'qa_lab_recorder_diagnostics_playback_part.dart';
part 'qa_lab_recorder_diagnostics_timeline_part.dart';
part 'qa_lab_recorder_diagnostics_scroll_part.dart';
part 'qa_lab_recorder_diagnostics_scroll_helpers_part.dart';

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
}
