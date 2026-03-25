part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsPlaybackPart on QALabRecorder {
  QALabPinpointFinding? _buildAutoplaySurfaceFinding({
    required String surface,
    required List<QALabCheckpoint> surfaceCheckpoints,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed' && surface != 'short') {
      return null;
    }
    if (surfaceCheckpoints.isEmpty) {
      return null;
    }
    final latestCheckpoint = surfaceCheckpoints.last;
    final surfaceProbe =
        latestCheckpoint.probe[surface] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final authProbe = latestCheckpoint.probe['auth'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    if (!_hasAuthenticatedUser(authProbe)) {
      return null;
    }

    final expectedDocId = surface == 'feed'
        ? (surfaceProbe['centeredDocId'] ?? '').toString()
        : (surfaceProbe['activeDocId'] ?? '').toString();
    final count = _asInt(surfaceProbe['count']);
    if (count <= 0 || expectedDocId.isEmpty) {
      return null;
    }
    if (surface == 'feed') {
      final centeredIndex = _asInt(surfaceProbe['centeredIndex']);
      final playbackSuspended = surfaceProbe['playbackSuspended'] == true;
      final pauseAll = surfaceProbe['pauseAll'] == true;
      final canClaimPlaybackNow = surfaceProbe['canClaimPlaybackNow'] == true;
      if (centeredIndex < 0 ||
          centeredIndex >= count ||
          playbackSuspended ||
          pauseAll ||
          !canClaimPlaybackNow) {
        return null;
      }
    } else {
      final activeIndex = _asInt(surfaceProbe['activeIndex']);
      if (activeIndex < 0 || activeIndex >= count) {
        return null;
      }
    }

    final observedSince = _playbackObservationStart(
      surfaceCheckpoints: surfaceCheckpoints,
      route: route,
      surface: surface,
      expectedDocId: expectedDocId,
    );
    final elapsedMs = referenceTime.difference(observedSince).inMilliseconds;
    if (elapsedMs < QALabMode.autoplayDetectionGraceMs) {
      return null;
    }

    final playbackProbe =
        latestCheckpoint.probe['videoPlayback'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final currentPlayingDocId =
        (playbackProbe['currentPlayingDocID'] ?? '').toString();
    if (currentPlayingDocId == expectedDocId) {
      return null;
    }
    final registeredHandleCount =
        _asInt(playbackProbe['registeredHandleCount']);
    final savedStateCount = _asInt(playbackProbe['savedStateCount']);
    final wrongTarget = currentPlayingDocId.isNotEmpty;
    return QALabPinpointFinding(
      severity: registeredHandleCount > 0
          ? QALabIssueSeverity.error
          : QALabIssueSeverity.warning,
      code: wrongTarget
          ? '${surface}_autoplay_wrong_target'
          : '${surface}_autoplay_missing',
      message: wrongTarget
          ? 'Autoplay on $surface claimed the wrong video after the grace window.'
          : 'Autoplay on $surface stayed idle after the grace window.',
      route: route,
      surface: surface,
      timestamp: latestCheckpoint.timestamp,
      context: <String, dynamic>{
        'expectedDocId': expectedDocId,
        'currentPlayingDocID': currentPlayingDocId,
        'registeredHandleCount': registeredHandleCount,
        'savedStateCount': savedStateCount,
        'elapsedMs': elapsedMs,
      },
    );
  }

  List<QALabPinpointFinding> _buildVideoSurfaceFindings({
    required String surface,
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
    required String route,
  }) {
    final findings = <QALabPinpointFinding>[];
    final firstFrameIds = surfaceIssues
        .where((issue) => issue.code == 'video_first_frame')
        .map(_videoIdOf)
        .where((value) => value.isNotEmpty)
        .toSet();
    final endedByVideoId = <String, QALabIssue>{};
    final bufferingEndedByVideoId = <String, QALabIssue>{};

    for (final issue in surfaceIssues) {
      final videoId = _videoIdOf(issue);
      if (videoId.isEmpty) continue;
      if (issue.code == 'video_session_ended') {
        endedByVideoId[videoId] = issue;
      } else if (issue.code == 'video_buffering_ended') {
        bufferingEndedByVideoId[videoId] = issue;
      }
    }

    for (final issue in surfaceIssues) {
      final videoId = _videoIdOf(issue);
      if (videoId.isEmpty) continue;
      if (issue.code == 'video_session_started' &&
          !firstFrameIds.contains(videoId)) {
        final ended = endedByVideoId[videoId];
        final ttffMs = _asInt(ended?.metadata['ttffMs']);
        final elapsedMs =
            referenceTime.difference(issue.timestamp).inMilliseconds;
        if ((ended == null || ttffMs < 0) &&
            elapsedMs >= QALabMode.videoFirstFrameTimeoutMs) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.blocking,
              code: '${surface}_first_frame_timeout',
              message:
                  'Video session started on $surface but no first frame was confirmed before timeout.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'elapsedMs': elapsedMs,
              },
            ),
          );
        }
      }

      if (issue.code == 'video_buffering_started') {
        final ended = bufferingEndedByVideoId[videoId];
        final stillBuffering =
            ended == null || ended.timestamp.isBefore(issue.timestamp);
        final elapsedMs =
            referenceTime.difference(issue.timestamp).inMilliseconds;
        if (stillBuffering && elapsedMs >= QALabMode.videoBufferStallMs) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.error,
              code: '${surface}_buffer_stall',
              message:
                  'Video buffering started on $surface and never recovered before the stall threshold.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'elapsedMs': elapsedMs,
              },
            ),
          );
        }
      }

      if (issue.code == 'video_session_ended') {
        final ttffMs = _asInt(issue.metadata['ttffMs']);
        final rebufferCount = _asInt(issue.metadata['rebufferCount']);
        final totalRebufferMs = _asInt(issue.metadata['totalRebufferMs']);
        if (ttffMs >= QALabMode.videoFirstFrameBlockingMs) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.blocking,
              code: '${surface}_first_frame_too_slow',
              message:
                  'Video first frame latency on $surface exceeded the blocking threshold.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'ttffMs': ttffMs,
              },
            ),
          );
        } else if (ttffMs >= QALabMode.videoFirstFrameWarningMs) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.warning,
              code: '${surface}_first_frame_slow',
              message:
                  'Video first frame latency on $surface is above warning threshold.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'ttffMs': ttffMs,
              },
            ),
          );
        }

        if (rebufferCount >= 6 || totalRebufferMs >= 8000) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.error,
              code: '${surface}_rebuffer_spike',
              message: 'Video playback on $surface spent too long buffering.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'rebufferCount': rebufferCount,
                'totalRebufferMs': totalRebufferMs,
              },
            ),
          );
        } else if (rebufferCount >= 3 || totalRebufferMs >= 4000) {
          findings.add(
            QALabPinpointFinding(
              severity: QALabIssueSeverity.warning,
              code: '${surface}_rebuffer_warning',
              message:
                  'Video playback on $surface showed noticeable rebuffering.',
              route: route,
              surface: surface,
              timestamp: issue.timestamp,
              context: <String, dynamic>{
                'videoId': videoId,
                'rebufferCount': rebufferCount,
                'totalRebufferMs': totalRebufferMs,
              },
            ),
          );
        }
      }
    }

    return findings;
  }
}
