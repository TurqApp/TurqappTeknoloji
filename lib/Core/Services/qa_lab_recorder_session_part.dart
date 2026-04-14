part of 'qa_lab_recorder.dart';

extension _QALabRecorderSessionPart on QALabRecorder {
  void _startSessionImpl({String trigger = 'manual'}) {
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
    appFramePerformance.clear();
    framePerformanceBySurface.clear();
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

  void _resetSessionImpl() {
    _startSessionImpl(trigger: 'reset');
  }

  void _disposeSessionImpl() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _nativePlaybackTimer?.cancel();
    _nativePlaybackTimer = null;
    _cancelAllSurfaceWatchdogs();
  }

  Future<void> _prepareFreshStartImpl({String trigger = 'launch'}) async {
    if (!QALabMode.enabled) return;
    final clearedTargets = <String>[];
    final cleanupFailures = <Map<String, String>>[];

    Future<void> clearChildren(
      Directory directory, {
      required String label,
      bool suppressEntityFailures = false,
    }) async {
      if (!await directory.exists()) {
        return;
      }
      var cleared = 0;
      await for (final entity in directory.list(followLinks: false)) {
        try {
          await entity.delete(recursive: true);
          cleared += 1;
        } catch (_) {
          if (!suppressEntityFailures) {
            rethrow;
          }
        }
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
      bool recordFailure = true,
    }) async {
      try {
        await action();
      } catch (error) {
        if (!recordFailure) return;
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
        suppressEntityFailures: true,
      ),
      label: 'temp',
      recordFailure: false,
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

    maybeFindQALabRemoteUploader()?.resetLocalState();
    _startSessionImpl(trigger: 'fresh_start:$trigger');
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
}
