part of 'qa_lab_recorder.dart';

extension QALabRecorderRuntimePart on QALabRecorder {
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
        _isPrimaryFeedSelected(rootProbe, route: route) &&
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
}
