part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsPart on QALabRecorder {
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

  bool _isQALabAutostartWarmup({
    required String surface,
    required String route,
    required DateTime referenceTime,
  }) {
    if (surface != 'feed') return false;
    final started = startedAt.value;
    if (started == null) return false;
    final ageMs = referenceTime.difference(started).inMilliseconds;
    if (ageMs < 0 || ageMs > 9000) return false;

    final normalizedRoute = route.trim().toLowerCase();
    if (normalizedRoute.contains('qa_lab') ||
        normalizedRoute.contains('qalab')) {
      return false;
    }
    return normalizedRoute.isEmpty ||
        normalizedRoute == '/' ||
        normalizedRoute.contains('navbar') ||
        normalizedRoute.contains('feed');
  }
}
