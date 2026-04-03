part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsHealthPart on QALabRecorder {
  List<QALabPinpointFinding> _buildSurfaceRuntimeFindings(
    String surface,
    List<QALabIssue> surfaceIssues,
    List<QALabCheckpoint> surfaceCheckpoints,
  ) {
    final surfaceTimeline = _surfaceTimelineEvents(surface);
    final findings = <QALabPinpointFinding>[];
    final latestCheckpoint =
        surfaceCheckpoints.isEmpty ? null : surfaceCheckpoints.last;
    final latestProbe =
        latestCheckpoint?.probe[surface] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final authProbe =
        latestCheckpoint?.probe['auth'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final referenceTime = latestCheckpoint?.timestamp ?? DateTime.now();
    final route = latestCheckpoint?.route.isNotEmpty == true
        ? latestCheckpoint!.route
        : _latestRouteForSurface(surface);
    findings.addAll(
      _buildSurfaceStateHealthFindings(
        surface: surface,
        latestProbe: latestProbe,
        authProbe: authProbe,
        latestCheckpoint: latestCheckpoint,
        surfaceIssues: surfaceIssues,
        surfaceCheckpoints: surfaceCheckpoints,
        referenceTime: referenceTime,
        route: route,
      ),
    );

    findings.addAll(
      _buildVideoSurfaceFindings(
        surface: surface,
        surfaceIssues: surfaceIssues,
        rootProbe: latestCheckpoint?.probe ?? const <String, dynamic>{},
        referenceTime: referenceTime,
        route: route,
      ),
    );
    findings.addAll(
      _buildAudioSurfaceFindings(
        surface: surface,
        surfaceIssues: surfaceIssues,
        referenceTime: referenceTime,
        route: route,
      ),
    );
    findings.addAll(
      _buildNativePlaybackFindings(
        surface: surface,
        latestProbe: latestProbe,
        rootProbe: latestCheckpoint?.probe ?? const <String, dynamic>{},
        authProbe: authProbe,
        referenceTime: referenceTime,
        route: route,
      ),
    );
    findings.addAll(
      _buildCacheSurfaceFindings(
        surface: surface,
        surfaceIssues: surfaceIssues,
        referenceTime: referenceTime,
        route: route,
      ),
    );
    findings.addAll(
      _buildFetchSurfaceFindings(
        surface: surface,
        surfaceTimeline: surfaceTimeline,
        referenceTime: referenceTime,
        route: route,
      ),
    );
    findings.addAll(
      _buildScrollSurfaceFindings(
        surface: surface,
        surfaceTimeline: surfaceTimeline,
        surfaceIssues: surfaceIssues,
        latestProbe: latestProbe,
        rootProbe: latestCheckpoint?.probe ?? const <String, dynamic>{},
        referenceTime: referenceTime,
        route: route,
      ),
    );
    findings.addAll(
      _buildAdSurfaceFindings(
        surface: surface,
        surfaceTimeline: surfaceTimeline,
        referenceTime: referenceTime,
        route: route,
      ),
    );
    return findings;
  }
}
