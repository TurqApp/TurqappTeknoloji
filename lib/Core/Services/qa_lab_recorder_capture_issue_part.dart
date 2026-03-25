part of 'qa_lab_recorder.dart';

extension QALabRecorderCaptureIssuePart on QALabRecorder {
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
