part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimePart on QALabRecorder {
  List<QALabPinpointFinding> _buildAdSurfaceFindings({
    required String surface,
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime referenceTime,
    required String route,
  }) {
    final adEvents = surfaceTimeline
        .where((event) => event.category == 'ad')
        .toList(growable: false);
    if (adEvents.isEmpty) {
      return const <QALabPinpointFinding>[];
    }
    final latestRequest = adEvents
        .where((event) => event.code == 'requested')
        .toList(growable: false)
        .lastOrNull;
    final latestLoad = adEvents
        .where((event) => event.code == 'loaded')
        .toList(growable: false)
        .lastOrNull;
    final failureCount =
        adEvents.where((event) => event.code == 'failed').length;
    final retryCount =
        adEvents.where((event) => event.code == 'retry_scheduled').length;
    final findings = <QALabPinpointFinding>[];

    if (latestLoad != null) {
      final latencyMs = _asInt(latestLoad.metadata['latencyMs']);
      if (latencyMs >= QALabMode.adLoadWarningMs) {
        findings.add(
          QALabPinpointFinding(
            severity: latencyMs >= QALabMode.adLoadBlockingMs
                ? QALabIssueSeverity.error
                : QALabIssueSeverity.warning,
            code: '${surface}_ad_load_slow',
            message:
                'An ad on $surface loaded slowly enough to risk visible UI delay.',
            route: route,
            surface: surface,
            timestamp: latestLoad.timestamp,
            context: <String, dynamic>{
              'placement': (latestLoad.metadata['placement'] ?? '').toString(),
              'latencyMs': latencyMs,
            },
          ),
        );
      }
    }

    if (latestRequest != null &&
        latestLoad == null &&
        referenceTime.difference(latestRequest.timestamp).inMilliseconds >=
            QALabMode.adLoadBlockingMs) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.warning,
          code: '${surface}_ad_load_stuck',
          message:
              'An ad request on $surface stayed unresolved long enough to risk delayed layout or chrome.',
          route: route,
          surface: surface,
          timestamp: latestRequest.timestamp,
          context: <String, dynamic>{
            'placement': (latestRequest.metadata['placement'] ?? '').toString(),
            'elapsedMs': referenceTime
                .difference(latestRequest.timestamp)
                .inMilliseconds,
          },
        ),
      );
    }

    if (failureCount >= 2 || retryCount >= 2) {
      findings.add(
        QALabPinpointFinding(
          severity: failureCount >= 3 || retryCount >= 3
              ? QALabIssueSeverity.error
              : QALabIssueSeverity.warning,
          code: '${surface}_ad_retry_burst',
          message:
              'Ad loading on $surface entered repeated failures or retry bursts.',
          route: route,
          surface: surface,
          timestamp: adEvents.last.timestamp,
          context: <String, dynamic>{
            'failureCount': failureCount,
            'retryCount': retryCount,
          },
        ),
      );
    }

    return findings;
  }

  (int, int, int, int) _adSummary(List<QALabTimelineEvent> surfaceTimeline) {
    final adEvents = surfaceTimeline
        .where((event) => event.category == 'ad')
        .toList(growable: false);
    final requestCount =
        adEvents.where((event) => event.code == 'requested').length;
    final loadCount = adEvents.where((event) => event.code == 'loaded').length;
    final failureCount =
        adEvents.where((event) => event.code == 'failed').length;
    final worstLoadMs = adEvents
        .where((event) => event.code == 'loaded')
        .map((event) => _asInt(event.metadata['latencyMs']))
        .fold<int>(0, (left, right) => left > right ? left : right);
    return (requestCount, loadCount, failureCount, worstLoadMs);
  }

  List<QALabPinpointFinding> _buildCacheSurfaceFindings({
    required String surface,
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
    required String route,
  }) {
    final cacheFailures = surfaceIssues
        .where((issue) => issue.code == 'cache_first_failed')
        .toList(growable: false);
    if (cacheFailures.isEmpty) return const <QALabPinpointFinding>[];
    final severity = cacheFailures.length >= 3
        ? QALabIssueSeverity.error
        : QALabIssueSeverity.warning;
    return <QALabPinpointFinding>[
      QALabPinpointFinding(
        severity: severity,
        code: '${surface}_cache_live_failures',
        message:
            'Cache-first live sync failures were detected on $surface during this session.',
        route: route,
        surface: surface,
        timestamp: referenceTime,
        context: <String, dynamic>{
          'failureCount': cacheFailures.length,
        },
      ),
    ];
  }

  List<QALabPinpointFinding> _buildAudioSurfaceFindings({
    required String surface,
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed' && surface != 'short') {
      return const <QALabPinpointFinding>[];
    }
    final endedSessions = surfaceIssues
        .where((issue) => issue.code == 'video_session_ended')
        .toList(growable: false);
    if (endedSessions.length < 2) {
      return const <QALabPinpointFinding>[];
    }

    var audibleCount = 0;
    var mutedCount = 0;
    var unstableFocusCount = 0;
    for (final issue in endedSessions) {
      final isAudible = issue.metadata['isAudible'] == true;
      final hasStableFocus = issue.metadata['hasStableFocus'] == true;
      if (isAudible) {
        audibleCount += 1;
      } else {
        mutedCount += 1;
      }
      if (!hasStableFocus) {
        unstableFocusCount += 1;
      }
    }

    if (audibleCount == 0 || mutedCount == 0) {
      return const <QALabPinpointFinding>[];
    }

    final severity = unstableFocusCount > 0
        ? QALabIssueSeverity.error
        : QALabIssueSeverity.warning;
    return <QALabPinpointFinding>[
      QALabPinpointFinding(
        severity: severity,
        code: '${surface}_audio_state_inconsistent',
        message:
            'Videos on $surface finished with mixed audible and muted states during the same session.',
        route: route,
        surface: surface,
        timestamp: referenceTime,
        context: <String, dynamic>{
          'audibleSessionCount': audibleCount,
          'mutedSessionCount': mutedCount,
          'unstableFocusCount': unstableFocusCount,
        },
      ),
    ];
  }

  List<QALabPinpointFinding> _buildNativePlaybackFindings({
    required String surface,
    required Map<String, dynamic> latestProbe,
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
    if (lastNativePlaybackSnapshot.isEmpty ||
        lastNativePlaybackSnapshot['supported'] == false) {
      return const <QALabPinpointFinding>[];
    }

    final count = _asInt(latestProbe['count']);
    final errors = _nativePlaybackErrors(lastNativePlaybackSnapshot);
    final isPlaybackExpected =
        lastNativePlaybackSnapshot['isPlaybackExpected'] == true;
    if (count <= 0 && !isPlaybackExpected && errors.isEmpty) {
      return const <QALabPinpointFinding>[];
    }

    final findings = <QALabPinpointFinding>[];
    final hasFirstFrame =
        lastNativePlaybackSnapshot['firstFrameRendered'] == true;
    final isPlaying = lastNativePlaybackSnapshot['isPlaying'] == true;
    final isBuffering = lastNativePlaybackSnapshot['isBuffering'] == true;
    final stallCount = _asInt(lastNativePlaybackSnapshot['stallCount']);
    final sampledAt =
        _parseTimestamp(lastNativePlaybackSnapshot['sampledAt']) ??
            referenceTime;
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
      'lastKnownPlaybackTime':
          _asDouble(lastNativePlaybackSnapshot['lastKnownPlaybackTime']),
      'layerAttachCount':
          _asInt(lastNativePlaybackSnapshot['layerAttachCount']),
    };

    const firstFrameCodes = <String>{
      'FIRST_FRAME_TIMEOUT',
      'READY_WITHOUT_FRAME',
      'PLAYBACK_NOT_STARTED',
    };
    final suppressStartupFirstFrameTimeout = _isQALabAutostartWarmup(
      surface: surface,
      route: route,
      referenceTime: referenceTime,
    );
    if (!suppressStartupFirstFrameTimeout &&
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

    if (errors.contains('EXCESSIVE_REBUFFERING') ||
        (isBuffering && stallCount >= 2)) {
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

    if (errors.contains('VIDEO_FREEZE') ||
        errors.contains('FULLSCREEN_INTERRUPTION') ||
        errors.contains('BACKGROUND_RESUME_FAILURE')) {
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
        isPlaybackExpected &&
        !hasFirstFrame &&
        !isPlaying &&
        _surfaceIssues(surface)
                .where((issue) => issue.code == 'video_first_frame')
                .length >=
            2) {
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

  List<QALabPinpointFinding> _buildActiveIssueFindings() {
    final now = DateTime.now();
    return issues
        .where((issue) => issue.severity != QALabIssueSeverity.info)
        .where((issue) => !_isSpecializedIssueCode(issue.code))
        .where((issue) => !_isResolvedPermissionIssue(issue))
        .where(
          (issue) =>
              now.difference(issue.timestamp) <=
              _activeIssueLookback(issue.severity),
        )
        .map(
          (issue) => QALabPinpointFinding(
            severity: issue.severity,
            code: issue.code,
            message: issue.message,
            route: issue.route,
            surface: issue.surface,
            timestamp: issue.timestamp,
            context: <String, dynamic>{
              'source': issue.source.name,
              'lastCheckpoint': _lastCheckpointLabelBefore(issue.timestamp),
            },
          ),
        )
        .toList(growable: false);
  }

  bool _isSpecializedIssueCode(String code) {
    return code.startsWith('video_') ||
        code.startsWith('frame_jank_') ||
        code.startsWith('cache_first_') ||
        code.startsWith('lifecycle_');
  }

  bool _isResolvedPermissionIssue(QALabIssue issue) {
    if (!issue.code.startsWith('permission_') ||
        !issue.code.endsWith('_blocked')) {
      return false;
    }
    final rawKey = issue.code.substring(
      'permission_'.length,
      issue.code.length - '_blocked'.length,
    );
    final status = lastPermissionStatuses[rawKey];
    return status == 'granted' || status == 'limited';
  }

  Duration _activeIssueLookback(QALabIssueSeverity severity) {
    switch (severity) {
      case QALabIssueSeverity.blocking:
        return const Duration(seconds: 75);
      case QALabIssueSeverity.error:
        return const Duration(seconds: 60);
      case QALabIssueSeverity.warning:
        return Duration(seconds: QALabMode.activeIssueLookbackSeconds);
      case QALabIssueSeverity.info:
        return Duration.zero;
    }
  }
}
