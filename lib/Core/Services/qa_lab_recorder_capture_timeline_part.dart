part of 'qa_lab_recorder.dart';

extension QALabRecorderCaptureTimelinePart on QALabRecorder {
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
}
