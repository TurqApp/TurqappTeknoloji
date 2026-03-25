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

  String _cacheSurfaceFromPayload(Map<String, dynamic> payload) {
    final surfaceKey = (payload['surfaceKey'] ?? '').toString();
    if (surfaceKey.startsWith('feed_')) return 'feed';
    if (surfaceKey.startsWith('short_')) return 'short';
    if (surfaceKey.startsWith('notifications_')) return 'notifications';
    if (surfaceKey.startsWith('profile_')) return 'profile';
    return 'cache';
  }
}
