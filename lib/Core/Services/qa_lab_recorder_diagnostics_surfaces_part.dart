part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsSurfacesPart on QALabRecorder {
  String _lastCheckpointLabelBefore(DateTime timestamp) {
    for (final checkpoint in checkpoints.reversed) {
      if (!checkpoint.timestamp.isAfter(timestamp)) {
        return checkpoint.label;
      }
    }
    return '';
  }

  QALabSurfaceDiagnostic _buildSurfaceDiagnostic(String surface) {
    final surfaceIssues = _surfaceIssues(surface);
    final surfaceCheckpoints = _surfaceCheckpoints(surface);
    final runtimeFindings = _buildSurfaceRuntimeFindings(
      surface,
      surfaceIssues,
      surfaceCheckpoints,
    );
    final warningCount = surfaceIssues
        .where((issue) => issue.severity == QALabIssueSeverity.warning)
        .length;
    final errorCount = surfaceIssues
        .where((issue) => issue.severity == QALabIssueSeverity.error)
        .length;
    final blockingCount = surfaceIssues
        .where((issue) => issue.severity == QALabIssueSeverity.blocking)
        .length;
    final healthScore = (100 -
            (runtimeFindings
                    .where(
                      (item) => item.severity == QALabIssueSeverity.blocking,
                    )
                    .length *
                22) -
            (runtimeFindings
                    .where((item) => item.severity == QALabIssueSeverity.error)
                    .length *
                10) -
            (runtimeFindings
                    .where(
                      (item) => item.severity == QALabIssueSeverity.warning,
                    )
                    .length *
                4))
        .clamp(0, 100)
        .toInt();

    return QALabSurfaceDiagnostic(
      surface: surface,
      latestRoute: _latestRouteForSurface(surface),
      healthScore: healthScore,
      issueCounts: <String, int>{
        'blocking': blockingCount,
        'error': errorCount,
        'warning': warningCount,
        'info':
            surfaceIssues.length - blockingCount - errorCount - warningCount,
      },
      coverage: QALabCatalog.surfaceCoverage(surface),
      runtime:
          _surfaceRuntimeSummary(surface, surfaceIssues, surfaceCheckpoints),
      findings: runtimeFindings,
    );
  }

  List<QALabIssue> _surfaceIssues(String surface) {
    return issues
        .where((issue) => _matchesSurface(issue.surface, surface))
        .toList(growable: false);
  }

  List<QALabCheckpoint> _surfaceCheckpoints(String surface) {
    return checkpoints
        .where((checkpoint) => _matchesSurface(checkpoint.surface, surface))
        .toList(growable: false);
  }

  List<QALabTimelineEvent> _surfaceTimelineEvents(String surface) {
    return timelineEvents
        .where((event) => _matchesSurface(event.surface, surface))
        .toList(growable: false);
  }

  Map<String, dynamic> _surfaceRuntimeSummary(
    String surface,
    List<QALabIssue> surfaceIssues,
    List<QALabCheckpoint> surfaceCheckpoints,
  ) {
    final framePerformance = _cloneQaLabExportMap(
      framePerformanceBySurface[surface] ?? const <String, dynamic>{},
    );
    final surfaceTimeline = _surfaceTimelineEvents(surface);
    final videoStarts = surfaceIssues
        .where((issue) => issue.code == 'video_session_started')
        .length;
    final videoFirstFrames = surfaceIssues
        .where((issue) => issue.code == 'video_first_frame')
        .length;
    final videoErrors =
        surfaceIssues.where((issue) => issue.code == 'video_error').length;
    final cacheFailures = surfaceIssues
        .where((issue) => issue.code == 'cache_first_failed')
        .length;
    final jankEvents = surfaceIssues
        .where((issue) => issue.code.startsWith('frame_jank_'))
        .length;
    final worstFrameJankMs = surfaceIssues
        .where((issue) => issue.code.startsWith('frame_jank_'))
        .map((issue) => _asInt(issue.metadata['maxTotalMs']))
        .fold<int>(0, (left, right) => left > right ? left : right);
    final suppressedNoiseCount = surfaceIssues
        .where(
          (issue) =>
              issue.code == 'flutter_suppressed' ||
              issue.code == 'platform_suppressed',
        )
        .length;
    final topSuppressedNoiseFamilies =
        _topSuppressedNoiseFamilies(surfaceIssues);
    final permissionBlocks = surfaceIssues
        .where((issue) => issue.source == QALabIssueSource.permission)
        .length;
    final lifecycleInterruptions = surfaceIssues
        .where(
          (issue) =>
              issue.source == QALabIssueSource.lifecycle &&
              issue.code != 'lifecycle_resume',
        )
        .length;
    final blankSnapshots = surfaceCheckpoints.where((checkpoint) {
      final probe = checkpoint.probe[surface] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      return probe['registered'] == true && _asInt(probe['count']) == 0;
    }).length;
    final runtimeFindings = _buildSurfaceRuntimeFindings(
      surface,
      surfaceIssues,
      surfaceCheckpoints,
    );
    final autoplayFindings =
        runtimeFindings.where((item) => item.code.contains('autoplay_')).length;
    final duplicateFeedTriggers =
        _countDuplicateFeedTriggerBursts(surfaceTimeline: surfaceTimeline);
    final duplicatePlaybackDispatches = _countDuplicatePlaybackDispatchBursts(
      surfaceTimeline: surfaceTimeline,
    );
    final latestScrollLatency = _latestScrollLatencySummary(
      surfaceTimeline: surfaceTimeline,
      surfaceIssues: surfaceIssues,
      referenceTime: surfaceCheckpoints.isEmpty
          ? DateTime.now()
          : surfaceCheckpoints.last.timestamp,
    );
    final adSummary = _adSummary(surfaceTimeline);

    return <String, dynamic>{
      'checkpointCount': surfaceCheckpoints.length,
      'videoSessionStartCount': videoStarts,
      'videoFirstFrameCount': videoFirstFrames,
      'videoErrorCount': videoErrors,
      'cacheFailureCount': cacheFailures,
      'jankEventCount': jankEvents,
      'worstFrameJankMs': worstFrameJankMs,
      'frameSampleCount': _asInt(framePerformance['sampleCount']),
      'frameCount': _asInt(framePerformance['frameCount']),
      'slowFrameCount': _asInt(framePerformance['slowFrameCount']),
      'slowFrameRatio': _asDouble(framePerformance['slowFrameRatio']),
      'averageFrameTotalMs': _asInt(framePerformance['averageTotalMs']),
      'maxFrameTotalMs': _asInt(framePerformance['maxTotalMs']),
      'maxFrameBuildMs': _asInt(framePerformance['maxBuildMs']),
      'maxFrameRasterMs': _asInt(framePerformance['maxRasterMs']),
      'lastFrameObservedAt':
          (framePerformance['lastObservedAt'] ?? '').toString(),
      'suppressedNoiseCount': suppressedNoiseCount,
      if (topSuppressedNoiseFamilies.isNotEmpty)
        'topSuppressedNoiseFamilies': topSuppressedNoiseFamilies,
      'permissionBlockCount': permissionBlocks,
      'lifecycleInterruptionCount': lifecycleInterruptions,
      'blankSnapshotCount': blankSnapshots,
      'autoplayFindingCount': autoplayFindings,
      'runtimeFindingCount': runtimeFindings.length,
      'timelineEventCount': surfaceTimeline.length,
      'duplicateFeedTriggerCount': duplicateFeedTriggers,
      'duplicatePlaybackDispatchCount': duplicatePlaybackDispatches,
      'latestScrollDispatchLatencyMs': latestScrollLatency.$1,
      'latestScrollFirstFrameLatencyMs': latestScrollLatency.$2,
      'latestScrollStableFrameLatencyMs': latestScrollLatency.$3,
      'adRequestCount': adSummary.$1,
      'adLoadCount': adSummary.$2,
      'adFailureCount': adSummary.$3,
      'worstAdLoadMs': adSummary.$4,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackStatus':
            (lastNativePlaybackSnapshot['status'] ?? '').toString(),
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackErrorCount':
            _nativePlaybackErrors(lastNativePlaybackSnapshot).length,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackActive': lastNativePlaybackSnapshot['active'] == true,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackPlaying':
            lastNativePlaybackSnapshot['isPlaying'] == true,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackBuffering':
            lastNativePlaybackSnapshot['isBuffering'] == true,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackFirstFrame':
            lastNativePlaybackSnapshot['firstFrameRendered'] == true,
      if (surface == 'feed' || surface == 'short')
        'nativePlaybackStallCount':
            _asInt(lastNativePlaybackSnapshot['stallCount']),
    };
  }
}
