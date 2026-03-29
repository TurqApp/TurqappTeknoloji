part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsPart on QALabRecorder {
  bool _diagnosticsProbeAsBool(Object? value, {required bool fallback}) {
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
    final playbackKpi = maybeFindPlaybackKpiService();
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

  bool _isTransientBlankSurfaceWarmup({
    required String surface,
    required List<QALabCheckpoint> surfaceCheckpoints,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed' && surface != 'short') {
      return false;
    }
    if (_isQALabAutostartWarmup(
      surface: surface,
      route: route,
      referenceTime: referenceTime,
    )) {
      return true;
    }
    if (surfaceCheckpoints.isEmpty) {
      return false;
    }

    var observedSince = surfaceCheckpoints.last.timestamp;
    for (final checkpoint in surfaceCheckpoints.reversed) {
      if (checkpoint.route != route) {
        break;
      }
      final probe = checkpoint.probe[surface] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      if (!_diagnosticsProbeAsBool(probe['registered'], fallback: false)) {
        break;
      }
      observedSince = checkpoint.timestamp;
    }

    final ageMs = referenceTime.difference(observedSince).inMilliseconds;
    return ageMs >= 0 && ageMs < QALabMode.autoplayDetectionGraceMs;
  }
}
