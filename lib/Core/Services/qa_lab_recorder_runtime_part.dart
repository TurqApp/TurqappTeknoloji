part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimePart on QALabRecorder {
  bool _hasSurfacePlaybackRecoverySignalNear({
    required List<QALabIssue> surfaceIssues,
    required DateTime anchorTime,
    Duration lookback = const Duration(milliseconds: 6000),
    Duration lookahead = const Duration(milliseconds: 3500),
  }) {
    if (surfaceIssues.isEmpty) return false;
    for (final issue in surfaceIssues) {
      if (issue.source != QALabIssueSource.video) continue;
      if (issue.code == 'video_first_frame' ||
          issue.code == 'playback_visual_video_play') {
        final deltaMs = issue.timestamp.difference(anchorTime).inMilliseconds;
        if (deltaMs >= -lookback.inMilliseconds &&
            deltaMs <= lookahead.inMilliseconds) {
          return true;
        }
      }
    }
    return false;
  }

  bool _hasRecentFeedSurfaceLossVisualTransition({
    required List<QALabIssue> surfaceIssues,
    required DateTime anchorTime,
  }) {
    if (surfaceIssues.isEmpty) return false;
    for (final issue in surfaceIssues) {
      if (issue.source != QALabIssueSource.video) continue;
      if (!issue.code.startsWith('playback_visual_')) continue;
      if (issue.metadata['surfaceAllowed'] == false) {
        final deltaMs = issue.timestamp.difference(anchorTime).inMilliseconds;
        if (deltaMs >= -2200 && deltaMs <= 1200) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isSurfaceNativeWarmupGrace({
    required String surface,
    required String route,
    required DateTime referenceTime,
  }) {
    if (surface != 'feed' && surface != 'short') {
      return false;
    }
    if (_isTransientBlankSurfaceWarmup(
      surface: surface,
      surfaceCheckpoints: _surfaceCheckpoints(surface),
      referenceTime: referenceTime,
      route: route,
    )) {
      return true;
    }
    if (surface == 'feed' &&
        _isQALabAutostartWarmup(
          surface: surface,
          route: route,
          referenceTime: referenceTime,
        )) {
      return true;
    }
    return false;
  }

  bool _hasObservedSurfaceVideoSession(
    List<QALabIssue> surfaceIssues,
  ) {
    for (final issue in surfaceIssues) {
      if (issue.source != QALabIssueSource.video) continue;
      if (issue.code == 'video_session_started' ||
          issue.code == 'video_first_frame') {
        return true;
      }
    }
    return false;
  }

  List<QALabPinpointFinding> _buildNativePlaybackFindings({
    required String surface,
    required Map<String, dynamic> latestProbe,
    required Map<String, dynamic> rootProbe,
    required Map<String, dynamic> authProbe,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed' && surface != 'short') {
      return const <QALabPinpointFinding>[];
    }
    if (!_hasAuthenticatedUser(authProbe)) {
      return const <QALabPinpointFinding>[];
    }
    final visibilitySnapshot = _resolveVisibilitySnapshot(
      rootProbe,
      surface: surface,
    );
    final effectiveRoute =
        (visibilitySnapshot['currentRoute'] ?? '').toString().trim().isNotEmpty
            ? (visibilitySnapshot['currentRoute'] ?? '').toString().trim()
            : route;
    final surfaceIssues = _surfaceIssues(surface);
    final hasObservedSurfaceVideoSession =
        _hasObservedSurfaceVideoSession(surfaceIssues);
    final isForegroundSurface = surface == 'feed'
        ? _isPrimaryFeedSelected(visibilitySnapshot, route: effectiveRoute)
        : _isPrimaryShortSelected(visibilitySnapshot, route: effectiveRoute);
    if (!isForegroundSurface) {
      return const <QALabPinpointFinding>[];
    }
    if (lastNativePlaybackSnapshot.isEmpty ||
        lastNativePlaybackSnapshot['supported'] == false) {
      return const <QALabPinpointFinding>[];
    }
    final nativeSurfaceHint =
        (lastNativePlaybackSnapshot['surfaceHint'] ?? '').toString().trim();
    if (nativeSurfaceHint.isNotEmpty && nativeSurfaceHint != surface) {
      return const <QALabPinpointFinding>[];
    }

    final count = _asInt(latestProbe['count']);
    final errors = _nativePlaybackErrors(lastNativePlaybackSnapshot);
    final isPlaybackExpected =
        lastNativePlaybackSnapshot['isPlaybackExpected'] == true;
    if (count <= 0 && !isPlaybackExpected && errors.isEmpty) {
      return const <QALabPinpointFinding>[];
    }
    if (surface == 'short' && !hasObservedSurfaceVideoSession) {
      return const <QALabPinpointFinding>[];
    }

    final findings = <QALabPinpointFinding>[];
    final hasFirstFrame =
        lastNativePlaybackSnapshot['firstFrameRendered'] == true;
    final isPlaying = lastNativePlaybackSnapshot['isPlaying'] == true;
    final isBuffering = lastNativePlaybackSnapshot['isBuffering'] == true;
    final stallCount = _asInt(lastNativePlaybackSnapshot['stallCount']);
    final lastKnownPlaybackTime =
        _asDouble(lastNativePlaybackSnapshot['lastKnownPlaybackTime']);
    final sampledAt =
        _parseTimestamp(lastNativePlaybackSnapshot['sampledAt']) ??
            referenceTime;
    final hasRecentFeedSurfaceLossVisualTransition = surface == 'feed' &&
        _hasRecentFeedSurfaceLossVisualTransition(
          surfaceIssues: surfaceIssues,
          anchorTime: sampledAt,
        );
    final hasNearbySurfacePlaybackRecoverySignal =
        _hasSurfacePlaybackRecoverySignalNear(
          surfaceIssues: surfaceIssues,
          anchorTime: sampledAt,
        );
    final suppressNativeWarmupSignals = _isSurfaceNativeWarmupGrace(
      surface: surface,
      route: effectiveRoute,
      referenceTime: referenceTime,
    );
    final snapshotContext = <String, dynamic>{
      'platform': (lastNativePlaybackSnapshot['platform'] ?? '').toString(),
      'status': (lastNativePlaybackSnapshot['status'] ?? '').toString(),
      'errors': errors,
      'trigger': (lastNativePlaybackSnapshot['trigger'] ?? '').toString(),
      'active': lastNativePlaybackSnapshot['active'] == true,
      'isPlaybackExpected': isPlaybackExpected,
      'isPlaying': isPlaying,
      'isBuffering': isBuffering,
      'firstFrameRendered': hasFirstFrame,
      'stallCount': stallCount,
      'lastKnownPlaybackTime': lastKnownPlaybackTime,
      'layerAttachCount':
          _asInt(lastNativePlaybackSnapshot['layerAttachCount']),
    };
    final hasRecoveredPlaybackAtSample = hasFirstFrame &&
        isPlaying &&
        !isBuffering &&
        lastKnownPlaybackTime >= 0.25;

    const firstFrameCodes = <String>{
      'FIRST_FRAME_TIMEOUT',
      'READY_WITHOUT_FRAME',
      'PLAYBACK_NOT_STARTED',
    };
    final hasRecentUnresolvedLifecycleInterruption =
        _hasRecentUnresolvedLifecycleInterruption(
      surfaceIssues: surfaceIssues,
      referenceTime: referenceTime,
    );
    final backgroundRecoveryPending =
        _nativePlaybackAwaitingBackgroundRecovery(lastNativePlaybackSnapshot);
    final suppressStartupFirstFrameTimeout = _isQALabAutostartWarmup(
      surface: surface,
      route: effectiveRoute,
      referenceTime: referenceTime,
    );
    if (!suppressStartupFirstFrameTimeout &&
        !suppressNativeWarmupSignals &&
        !backgroundRecoveryPending &&
        !hasRecentUnresolvedLifecycleInterruption &&
        errors.any(firstFrameCodes.contains)) {
      findings.add(
        QALabPinpointFinding(
          severity: errors.contains('FIRST_FRAME_TIMEOUT') ||
                  errors.contains('READY_WITHOUT_FRAME')
              ? QALabIssueSeverity.blocking
              : QALabIssueSeverity.error,
          code: '${surface}_native_first_frame_timeout',
          message:
              'Native playback health on $surface expected a frame but never confirmed one in time.',
          route: route,
          surface: surface,
          timestamp: sampledAt,
          context: snapshotContext,
        ),
      );
    }

    if (errors.contains('DOUBLE_BLACK_SCREEN_RISK')) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.error,
          code: '${surface}_native_black_screen_risk',
          message:
              'Native playback health on $surface detected repeated layer attachment before first frame.',
          route: route,
          surface: surface,
          timestamp: sampledAt,
          context: snapshotContext,
        ),
      );
    }

    final hasMeaningfulPlaybackExpectation =
        isPlaybackExpected || isPlaying || hasFirstFrame;
    if ((errors.contains('EXCESSIVE_REBUFFERING') ||
            (isBuffering && stallCount >= 2)) &&
        hasMeaningfulPlaybackExpectation) {
      if (!suppressNativeWarmupSignals &&
          !hasRecentUnresolvedLifecycleInterruption &&
          !hasRecentFeedSurfaceLossVisualTransition) {
        findings.add(
          QALabPinpointFinding(
            severity: stallCount >= 4
                ? QALabIssueSeverity.blocking
                : QALabIssueSeverity.error,
            code: '${surface}_native_buffer_stall',
            message:
                'Native playback health on $surface detected prolonged buffering or excessive rebuffering.',
            route: route,
            surface: surface,
            timestamp: sampledAt,
            context: snapshotContext,
          ),
        );
      }
    }

    if (errors.contains('VIDEO_FREEZE') ||
        errors.contains('FULLSCREEN_INTERRUPTION') ||
        errors.contains('BACKGROUND_RESUME_FAILURE')) {
      if (!suppressNativeWarmupSignals &&
          !hasRecentFeedSurfaceLossVisualTransition &&
          !hasNearbySurfacePlaybackRecoverySignal &&
          !hasRecoveredPlaybackAtSample) {
        findings.add(
          QALabPinpointFinding(
            severity: errors.contains('VIDEO_FREEZE')
                ? QALabIssueSeverity.blocking
                : QALabIssueSeverity.error,
            code: '${surface}_native_playback_interrupted',
            message:
                'Native playback health on $surface reported a freeze or failed recovery after an interruption.',
            route: route,
            surface: surface,
            timestamp: sampledAt,
            context: snapshotContext,
          ),
        );
      }
    }

    if (errors.contains('AUDIO_NOT_STARTED')) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.error,
          code: '${surface}_native_audio_not_started',
          message:
              'Native playback health on $surface reported playback without audio start confirmation.',
          route: route,
          surface: surface,
          timestamp: sampledAt,
          context: snapshotContext,
        ),
      );
    }

    if (surface == 'feed' &&
        _isPrimaryFeedSelected(rootProbe, route: effectiveRoute) &&
        isPlaybackExpected &&
        !hasFirstFrame &&
        !isPlaying &&
        _surfaceIssues(surface)
                .where((issue) => issue.code == 'video_first_frame')
                .length >=
            2) {
      final feedProbe = rootProbe['feed'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final feedCount = _asInt(feedProbe['count']);
      final centeredIndex = _asInt(feedProbe['centeredIndex']);
      final centeredDocId =
          (feedProbe['centeredDocId'] ?? '').toString().trim();
      final playbackSuspended = feedProbe['playbackSuspended'] == true;
      final pauseAll = feedProbe['pauseAll'] == true;
      final canClaimPlaybackNow = feedProbe['canClaimPlaybackNow'] == true;
      if (feedCount <= 0 ||
          centeredDocId.isEmpty ||
          centeredIndex < 0 ||
          centeredIndex >= feedCount ||
          playbackSuspended ||
          pauseAll ||
          !canClaimPlaybackNow) {
        return findings;
      }
      if (_isQALabAutostartWarmup(
        surface: surface,
        route: effectiveRoute,
        referenceTime: referenceTime,
      )) {
        return findings;
      }
      final playbackProbe =
          rootProbe['videoPlayback'] as Map<String, dynamic>? ??
              const <String, dynamic>{};
      final expectedDocId = centeredDocId;
      final targetPlaybackDocId =
          (playbackProbe['targetPlaybackDocID'] ?? '').toString();
      final targetPlaybackUpdatedAt =
          _parseTimestamp(playbackProbe['targetPlaybackUpdatedAt']);
      final targetGracePending = _matchesPlaybackDocForSurface(
            surface: surface,
            expectedDocId: expectedDocId,
            currentDocId: targetPlaybackDocId,
          ) &&
          targetPlaybackUpdatedAt != null &&
          referenceTime.difference(targetPlaybackUpdatedAt).inMilliseconds <
              QALabMode.autoplayDetectionGraceMs;
      final hasNativeTroubleSignal = errors.isNotEmpty ||
          stallCount > 0 ||
          lastNativePlaybackSnapshot['active'] != true;
      if (targetGracePending ||
          !hasNativeTroubleSignal ||
          hasRecentUnresolvedLifecycleInterruption) {
        return findings;
      }
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.error,
          code: 'feed_thumbnail_only_runtime_loss',
          message:
              'Feed previously rendered video frames in this session, but the current eligible card stayed on thumbnail state.',
          route: route,
          surface: surface,
          timestamp: sampledAt,
          context: snapshotContext,
        ),
      );
    }

    return findings;
  }
}
