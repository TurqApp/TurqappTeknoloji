part of 'qa_lab_recorder.dart';

extension QALabRecorderCaptureEventsPart on QALabRecorder {
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
