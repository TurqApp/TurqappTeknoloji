part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimeSurfacesPart on QALabRecorder {
  bool _surfaceProbeAsBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return fallback;
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return fallback;
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
    final firebaseSignedIn = _surfaceProbeAsBool(
      authProbe['isFirebaseSignedIn'],
      fallback: false,
    );
    final currentUserLoaded = _surfaceProbeAsBool(
      authProbe['currentUserLoaded'],
      fallback: false,
    );
    return currentUid.isNotEmpty || firebaseSignedIn || currentUserLoaded;
  }

  bool _isPrioritySurface(String surface) {
    final normalized = surface.trim();
    return normalized.isNotEmpty && normalized != 'app';
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
    if (!_surfaceProbeAsBool(surfaceProbe['registered'], fallback: false) ||
        count <= 0) {
      return false;
    }
    if (surface == 'feed') {
      final centeredIndex = _asInt(surfaceProbe['centeredIndex']);
      return centeredIndex >= 0 &&
          centeredIndex < count &&
          !_surfaceProbeAsBool(
            surfaceProbe['playbackSuspended'],
            fallback: false,
          ) &&
          !_surfaceProbeAsBool(surfaceProbe['pauseAll'], fallback: false) &&
          _surfaceProbeAsBool(
            surfaceProbe['canClaimPlaybackNow'],
            fallback: false,
          ) &&
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
}
