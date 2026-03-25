part of 'qa_lab_recorder.dart';

extension QALabRecorderCapturePart on QALabRecorder {
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
}
