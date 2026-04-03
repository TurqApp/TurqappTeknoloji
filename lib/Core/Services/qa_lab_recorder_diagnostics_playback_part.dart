part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsPlaybackPart on QALabRecorder {
  bool _hasUnresolvedLifecycleInterruptionAfter({
    required List<QALabIssue> surfaceIssues,
    required DateTime timestamp,
  }) {
    DateTime? latestInterruptionAt;
    DateTime? latestResumeAt;

    for (final issue in surfaceIssues) {
      if (issue.source != QALabIssueSource.lifecycle) {
        continue;
      }
      if (issue.timestamp.isBefore(timestamp)) {
        continue;
      }
      if (issue.code == 'lifecycle_resume') {
        if (latestResumeAt == null || issue.timestamp.isAfter(latestResumeAt)) {
          latestResumeAt = issue.timestamp;
        }
        continue;
      }
      if (latestInterruptionAt == null ||
          issue.timestamp.isAfter(latestInterruptionAt)) {
        latestInterruptionAt = issue.timestamp;
      }
    }

    if (latestInterruptionAt == null) {
      return false;
    }
    return latestResumeAt == null ||
        latestResumeAt.isBefore(latestInterruptionAt);
  }

  bool _isVideoIssueStillRelevantForSurface({
    required String surface,
    required String videoId,
    required Map<String, dynamic> snapshot,
  }) {
    final normalizedVideoId = videoId.trim();
    if (normalizedVideoId.isEmpty) return false;
    final playbackProbe = snapshot['videoPlayback'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final currentPlayingDocId =
        (playbackProbe['currentPlayingDocID'] ?? '').toString().trim();
    final targetPlaybackDocId =
        (playbackProbe['targetPlaybackDocID'] ?? '').toString().trim();

    bool matchesTrackedDoc(String currentDocId) {
      return _matchesPlaybackDocForSurface(
        surface: surface,
        expectedDocId: normalizedVideoId,
        currentDocId: currentDocId,
      );
    }

    if (surface == 'feed') {
      final surfaceProbe = snapshot[surface] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final count = _asInt(surfaceProbe['count']);
      final centeredIndex = _asInt(surfaceProbe['centeredIndex']);
      final centeredDocId =
          (surfaceProbe['centeredDocId'] ?? '').toString().trim();
      final centeredHasPlayableVideo = _surfaceProbeAsBool(
        surfaceProbe['centeredHasPlayableVideo'],
        fallback: centeredDocId.isNotEmpty,
      );
      final centeredHasRenderableVideoCard = _surfaceProbeAsBool(
        surfaceProbe['centeredHasRenderableVideoCard'],
        fallback: centeredHasPlayableVideo,
      );
      final playbackSuspended = _surfaceProbeAsBool(
        surfaceProbe['playbackSuspended'],
        fallback: false,
      );
      final pauseAll = _surfaceProbeAsBool(
        surfaceProbe['pauseAll'],
        fallback: false,
      );
      final canClaimPlaybackNow = _surfaceProbeAsBool(
        surfaceProbe['canClaimPlaybackNow'],
        fallback: false,
      );
      if (count <= 0 ||
          centeredIndex < 0 ||
          centeredIndex >= count ||
          !centeredHasPlayableVideo ||
          !centeredHasRenderableVideoCard ||
          playbackSuspended ||
          pauseAll ||
          !canClaimPlaybackNow) {
        return false;
      }
      return centeredDocId == normalizedVideoId ||
          matchesTrackedDoc(currentPlayingDocId) ||
          matchesTrackedDoc(targetPlaybackDocId);
    }

    if (surface == 'short') {
      final surfaceProbe = snapshot[surface] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final count = _asInt(surfaceProbe['count']);
      final activeIndex = _asInt(surfaceProbe['activeIndex']);
      final activeDocId = (surfaceProbe['activeDocId'] ?? '').toString().trim();
      if (count <= 0 ||
          activeIndex < 0 ||
          activeIndex >= count ||
          activeDocId.isEmpty) {
        return false;
      }
      return activeDocId == normalizedVideoId ||
          matchesTrackedDoc(currentPlayingDocId) ||
          matchesTrackedDoc(targetPlaybackDocId);
    }

    if (surface == 'explore') {
      return matchesTrackedDoc(currentPlayingDocId) ||
          matchesTrackedDoc(targetPlaybackDocId);
    }

    return true;
  }

  List<QALabPinpointFinding> _buildVideoSurfaceFindings({
    required String surface,
    required List<QALabIssue> surfaceIssues,
    required Map<String, dynamic> rootProbe,
    required DateTime referenceTime,
    required String route,
  }) {
    final currentSnapshot = _resolveVisibilitySnapshot(
      rootProbe,
      surface: surface,
    );
    final issueSnapshot = rootProbe.isEmpty ? currentSnapshot : rootProbe;
    if (surface == 'feed' &&
        !_isPrimaryFeedSelected(currentSnapshot, route: route)) {
      return const <QALabPinpointFinding>[];
    }
    if (surface == 'explore' &&
        !_isPrimaryExploreSelected(currentSnapshot, route: route)) {
      return const <QALabPinpointFinding>[];
    }
    if (surface == 'short' &&
        !_isPrimaryShortSelected(currentSnapshot, route: route)) {
      return const <QALabPinpointFinding>[];
    }

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
      final isStillRelevant = _isVideoIssueStillRelevantForSurface(
        surface: surface,
        videoId: videoId,
        snapshot: issueSnapshot,
      );
      final interruptedBeforeRecovery =
          _hasUnresolvedLifecycleInterruptionAfter(
        surfaceIssues: surfaceIssues,
        timestamp: issue.timestamp,
      );
      if (issue.code == 'video_session_started' &&
          !firstFrameIds.contains(videoId)) {
        if (!isStillRelevant || interruptedBeforeRecovery) continue;
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
        if (!isStillRelevant || interruptedBeforeRecovery) continue;
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
