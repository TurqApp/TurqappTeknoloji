part of 'qa_lab_recorder.dart';

extension QALabRecorderCapturePerformancePart on QALabRecorder {
  Map<String, dynamic> _mergeFramePerformanceSummary({
    required Map<String, dynamic> previous,
    required List<FrameTiming> timings,
    required String surface,
    required DateTime observedAt,
  }) {
    final totals = timings
        .map((timing) => timing.totalSpan.inMilliseconds)
        .toList(growable: false);
    final builds = timings
        .map((timing) => timing.buildDuration.inMilliseconds)
        .toList(growable: false);
    final rasters = timings
        .map((timing) => timing.rasterDuration.inMilliseconds)
        .toList(growable: false);
    final batchFrameCount = totals.length;
    final batchSlowFrameCount = totals
        .where((totalMs) => totalMs >= QALabMode.frameJankWarningMs)
        .length;
    final batchTotalMs =
        totals.fold<int>(0, (sum, totalMs) => sum + totalMs);
    final nextFrameCount = _asInt(previous['frameCount']) + batchFrameCount;
    final nextSlowFrameCount =
        _asInt(previous['slowFrameCount']) + batchSlowFrameCount;
    final nextTotalFrameTimeMs =
        _asInt(previous['totalFrameTimeMs']) + batchTotalMs;
    final batchMaxTotalMs =
        totals.reduce((left, right) => left > right ? left : right);
    final batchMaxBuildMs =
        builds.reduce((left, right) => left > right ? left : right);
    final batchMaxRasterMs =
        rasters.reduce((left, right) => left > right ? left : right);

    return <String, dynamic>{
      'surface': surface,
      'sampleCount': _asInt(previous['sampleCount']) + 1,
      'frameCount': nextFrameCount,
      'slowFrameCount': nextSlowFrameCount,
      'slowFrameRatio':
          nextFrameCount == 0 ? 0.0 : nextSlowFrameCount / nextFrameCount,
      'averageTotalMs':
          nextFrameCount == 0 ? 0 : nextTotalFrameTimeMs ~/ nextFrameCount,
      'maxTotalMs': [
        _asInt(previous['maxTotalMs']),
        batchMaxTotalMs,
      ].reduce((left, right) => left > right ? left : right),
      'maxBuildMs': [
        _asInt(previous['maxBuildMs']),
        batchMaxBuildMs,
      ].reduce((left, right) => left > right ? left : right),
      'maxRasterMs': [
        _asInt(previous['maxRasterMs']),
        batchMaxRasterMs,
      ].reduce((left, right) => left > right ? left : right),
      'totalFrameTimeMs': nextTotalFrameTimeMs,
      'lastObservedAt': observedAt.toUtc().toIso8601String(),
    };
  }

  void _recordFramePerformanceSample({
    required String surface,
    required List<FrameTiming> timings,
  }) {
    if (timings.isEmpty) return;
    final observedAt = DateTime.now();
    final appSummary = _mergeFramePerformanceSummary(
      previous: Map<String, dynamic>.from(appFramePerformance),
      timings: timings,
      surface: 'app',
      observedAt: observedAt,
    );
    appFramePerformance.assignAll(appSummary);

    final previousSurfaceSummary = Map<String, dynamic>.from(
      framePerformanceBySurface[surface] ?? const <String, dynamic>{},
    );
    framePerformanceBySurface[surface] = _mergeFramePerformanceSummary(
      previous: previousSurfaceSummary,
      timings: timings,
      surface: surface,
      observedAt: observedAt,
    );
  }

  void recordFrameTimings(List<FrameTiming> timings) {
    if (!QALabMode.enabled || timings.isEmpty) return;
    final snapshot = IntegrationTestStateProbe.snapshot();
    final route = (snapshot['currentRoute'] ?? '').toString();
    final surface = _inferSurfaceFromSnapshot(snapshot);
    final effectiveSurface = surface.trim().isEmpty ? 'app' : surface.trim();
    if (route.trim().isNotEmpty) {
      lastRoute.value = route;
    }
    lastSurface.value = effectiveSurface;

    final totals = timings
        .map((timing) => timing.totalSpan.inMilliseconds)
        .toList(growable: false);
    if (totals.isEmpty) return;
    _recordFramePerformanceSample(
      surface: effectiveSurface,
      timings: timings,
    );

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
      '$effectiveSurface|$code',
      const Duration(seconds: 6),
    )) {
      return;
    }

    recordIssue(
      source: QALabIssueSource.performance,
      code: code,
      severity: severity,
      message:
          'Frame pipeline slowed down on $effectiveSurface.',
      metadata: <String, dynamic>{
        'surface': effectiveSurface,
        'frameCount': timings.length,
        'slowFrameCount': slowFrames,
        'maxTotalMs': maxTotalMs,
        'maxBuildMs': maxBuildMs,
        'maxRasterMs': maxRasterMs,
        'averageTotalMs': averageTotalMs,
      },
    );
  }
}
