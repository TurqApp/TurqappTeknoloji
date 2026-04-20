part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsScrollPart on QALabRecorder {
  List<QALabPinpointFinding> _buildScrollSurfaceFindings({
    required String surface,
    required List<QALabTimelineEvent> surfaceTimeline,
    required List<QALabIssue> surfaceIssues,
    required Map<String, dynamic> latestProbe,
    required Map<String, dynamic> rootProbe,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed' && surface != 'short') {
      return const <QALabPinpointFinding>[];
    }
    final latestSettle = _latestScrollSettleEvent(surfaceTimeline);
    if (latestSettle == null) {
      return const <QALabPinpointFinding>[];
    }
    final surfaceCheckpoints = _surfaceCheckpoints(surface);
    final settledEvents = surfaceTimeline
        .where((event) => event.category == 'scroll' && event.code == 'settled')
        .toList(growable: false);
    final expectedDocId = (latestSettle.metadata['docId'] ?? '').toString();
    if (expectedDocId.isEmpty) {
      return const <QALabPinpointFinding>[];
    }
    final sameDocAsScrollStart = _didFeedScrollStayOnSameDoc(
      surfaceTimeline: surfaceTimeline,
      settleEvent: latestSettle,
    );
    if (!_isScrollSettleStillRelevant(
      surface: surface,
      expectedDocId: expectedDocId,
      latestProbe: latestProbe,
      rootProbe: rootProbe,
      route: route,
    )) {
      return const <QALabPinpointFinding>[];
    }

    final findings = <QALabPinpointFinding>[];
    final dispatch = _firstPlaybackDispatchAfter(
      surfaceTimeline: surfaceTimeline,
      after: latestSettle.timestamp,
      docId: expectedDocId,
    );
    final latestSkip = _latestPlaybackSkipAfter(
      surfaceTimeline: surfaceTimeline,
      after: latestSettle.timestamp,
      docId: expectedDocId,
    );
    final playbackAlreadyTargetedAtSettle =
        _isPlaybackAlreadyTargetedAtScrollSettle(
      surface: surface,
      expectedDocId: expectedDocId,
      settleEvent: latestSettle,
      rootProbe: rootProbe,
    );
    final nextScrollStart = _firstScrollStartAfter(
      surfaceTimeline: surfaceTimeline,
      after: latestSettle.timestamp,
    );
    final scrollToken = (latestSettle.metadata['scrollToken'] ?? '').toString();
    final suppressShortWarmupScrollWarnings = surface == 'short' &&
        _isTransientBlankSurfaceWarmup(
          surface: surface,
          surfaceCheckpoints: surfaceCheckpoints,
          referenceTime: referenceTime,
          route: route,
        );
    // First short swipe after initial settle still shares startup warmup noise on
    // iOS; keep it out of blocking/slow transition diagnostics.
    final suppressFirstShortTransitionWarnings =
        surface == 'short' && settledEvents.length <= 2;
    final suppressShortTransitionWarnings = suppressShortWarmupScrollWarnings ||
        suppressFirstShortTransitionWarnings;
    final stableFrameEvent = surface != 'short'
        ? null
        : _firstScrollPhaseAfter(
            surfaceTimeline: surfaceTimeline,
            after: latestSettle.timestamp,
            phase: 'stable_frame',
            docId: expectedDocId,
            scrollToken: scrollToken,
          );
    final playbackProbe = rootProbe['videoPlayback'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final currentPlayingDocId =
        (playbackProbe['currentPlayingDocID'] ?? '').toString().trim();
    final targetPlaybackDocId =
        (playbackProbe['targetPlaybackDocID'] ?? '').toString().trim();
    final nativeSurfaceHint =
        (lastNativePlaybackSnapshot['surfaceHint'] ?? '').toString().trim();
    final nativeSampledAt =
        _parseTimestamp(lastNativePlaybackSnapshot['sampledAt']) ??
            referenceTime;
    final shortRuntimePlaybackRecovered = surface == 'short' &&
        dispatch != null &&
        (_matchesPlaybackDocForSurface(
              surface: surface,
              expectedDocId: expectedDocId,
              currentDocId: currentPlayingDocId,
            ) ||
            _matchesPlaybackDocForSurface(
              surface: surface,
              expectedDocId: expectedDocId,
              currentDocId: targetPlaybackDocId,
            )) &&
        (nativeSurfaceHint.isEmpty || nativeSurfaceHint == surface) &&
        lastNativePlaybackSnapshot['firstFrameRendered'] == true &&
        lastNativePlaybackSnapshot['isPlaying'] == true &&
        lastNativePlaybackSnapshot['isBuffering'] != true &&
        !nativeSampledAt.isBefore(latestSettle.timestamp);
    final dispatchLatencyMs = dispatch == null
        ? referenceTime.difference(latestSettle.timestamp).inMilliseconds
        : dispatch.timestamp.difference(latestSettle.timestamp).inMilliseconds;
    final supersededByNextScroll = nextScrollStart != null &&
        nextScrollStart.timestamp
                .difference(latestSettle.timestamp)
                .inMilliseconds <
            QALabMode.scrollAutoplayDispatchBlockingMs;
    if (!sameDocAsScrollStart &&
        !supersededByNextScroll &&
        !playbackAlreadyTargetedAtSettle &&
        dispatch == null &&
        dispatchLatencyMs >= QALabMode.scrollAutoplayDispatchBlockingMs) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.blocking,
          code: '${surface}_scroll_dispatch_timeout',
          message:
              'Playback dispatch did not fire after the latest scroll settled on $surface.',
          route: route,
          surface: surface,
          timestamp: latestSettle.timestamp,
          context: <String, dynamic>{
            'docId': expectedDocId,
            'dispatchLatencyMs': dispatchLatencyMs,
            'scrollToken': scrollToken,
            'playbackAlreadyTargetedAtSettle': playbackAlreadyTargetedAtSettle,
            if (latestSkip != null) 'lastSkipStage': latestSkip.code,
            if (latestSkip != null)
              'lastSkipReason':
                  (latestSkip.metadata['skipReason'] ?? '').toString(),
            if (latestSkip != null)
              'lastSkipSource':
                  (latestSkip.metadata['dispatchSource'] ?? '').toString(),
            if (latestSkip != null)
              'lastCallerSignature':
                  (latestSkip.metadata['callerSignature'] ?? '').toString(),
          },
        ),
      );
    } else if (!sameDocAsScrollStart &&
        !(surface == 'short' && suppressShortTransitionWarnings) &&
        dispatch != null &&
        dispatchLatencyMs >= QALabMode.scrollAutoplayDispatchWarningMs) {
      findings.add(
        QALabPinpointFinding(
          severity:
              dispatchLatencyMs >= QALabMode.scrollAutoplayDispatchBlockingMs
                  ? QALabIssueSeverity.error
                  : QALabIssueSeverity.warning,
          code: '${surface}_scroll_dispatch_slow',
          message:
              'Playback dispatch arrived late after the latest scroll settled on $surface.',
          route: route,
          surface: surface,
          timestamp: dispatch.timestamp,
          context: <String, dynamic>{
            'docId': expectedDocId,
            'dispatchLatencyMs': dispatchLatencyMs,
            'dispatchStage': dispatch.code,
            'dispatchSource':
                (dispatch.metadata['dispatchSource'] ?? '').toString(),
            'callerSignature':
                (dispatch.metadata['callerSignature'] ?? '').toString(),
            'scrollToken': scrollToken,
          },
        ),
      );
    }

    final firstFrameIssue = surfaceIssues
        .where((issue) => issue.code == 'video_first_frame')
        .where((issue) => _videoIdOf(issue) == expectedDocId)
        .where((issue) => issue.timestamp.isAfter(latestSettle.timestamp))
        .toList(growable: false)
        .firstOrNull;
    final firstFrameLatencyMs = firstFrameIssue == null
        ? referenceTime.difference(latestSettle.timestamp).inMilliseconds
        : firstFrameIssue.timestamp
            .difference(latestSettle.timestamp)
            .inMilliseconds;
    if (dispatch != null &&
        (nextScrollStart == null ||
            !nextScrollStart.timestamp.isBefore(
              latestSettle.timestamp.add(
                Duration(
                  milliseconds: QALabMode.scrollFirstFrameBlockingMs,
                ),
              ),
            )) &&
        firstFrameIssue == null &&
        firstFrameLatencyMs >= QALabMode.scrollFirstFrameBlockingMs) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.blocking,
          code: '${surface}_scroll_first_frame_missing',
          message:
              'Playback dispatch fired on $surface, but the settled item still never rendered a first frame.',
          route: route,
          surface: surface,
          timestamp: latestSettle.timestamp,
          context: <String, dynamic>{
            'docId': expectedDocId,
            'firstFrameLatencyMs': firstFrameLatencyMs,
          },
        ),
      );
    } else if (!(surface == 'short' && suppressShortTransitionWarnings) &&
        firstFrameIssue != null &&
        firstFrameLatencyMs >= QALabMode.scrollFirstFrameWarningMs) {
      findings.add(
        QALabPinpointFinding(
          severity: firstFrameLatencyMs >= QALabMode.scrollFirstFrameBlockingMs
              ? QALabIssueSeverity.error
              : QALabIssueSeverity.warning,
          code: '${surface}_scroll_first_frame_slow',
          message:
              'The settled item on $surface rendered its first frame too late after scroll.',
          route: route,
          surface: surface,
          timestamp: firstFrameIssue.timestamp,
          context: <String, dynamic>{
            'docId': expectedDocId,
            'firstFrameLatencyMs': firstFrameLatencyMs,
          },
        ),
      );
    }

    if (surface == 'short') {
      final hasSlowShortFirstFrameFinding = firstFrameIssue != null &&
          firstFrameLatencyMs >= QALabMode.scrollFirstFrameWarningMs;
      final stableFrameSource = stableFrameEvent == null
          ? (firstFrameIssue == null ? 'runtime_playing' : 'video_first_frame')
          : 'stable_frame';
      final effectiveStableFrameTimestamp = stableFrameEvent?.timestamp ??
          firstFrameIssue?.timestamp ??
          (shortRuntimePlaybackRecovered ? nativeSampledAt : null);
      final stableFrameLatencyMs = effectiveStableFrameTimestamp == null
          ? referenceTime.difference(latestSettle.timestamp).inMilliseconds
          : effectiveStableFrameTimestamp
              .difference(latestSettle.timestamp)
              .inMilliseconds;
      final missingStableFrameBlockingMs = dispatch != null ||
              firstFrameIssue != null ||
              playbackAlreadyTargetedAtSettle
          ? QALabMode.scrollFirstFrameBlockingMs
          : QALabMode.shortVisualStableFrameBlockingMs;
      if (effectiveStableFrameTimestamp == null &&
          stableFrameLatencyMs >= missingStableFrameBlockingMs) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.blocking,
            code: 'short_transition_visual_missing',
            message:
                'Short page settled, but QA never confirmed a visually stable frame before the transition threshold.',
            route: route,
            surface: surface,
            timestamp: latestSettle.timestamp,
            context: <String, dynamic>{
              'docId': expectedDocId,
              'scrollToken': scrollToken,
              'stableFrameLatencyMs': stableFrameLatencyMs,
            },
          ),
        );
      } else if (!suppressShortTransitionWarnings &&
          !(stableFrameSource == 'video_first_frame' &&
              hasSlowShortFirstFrameFinding) &&
          effectiveStableFrameTimestamp != null &&
          stableFrameLatencyMs >= QALabMode.shortVisualStableFrameWarningMs) {
        final stableFrameSeverity =
            stableFrameSource == 'stable_frame' && firstFrameIssue != null
                ? (stableFrameLatencyMs >= QALabMode.scrollFirstFrameBlockingMs
                    ? QALabIssueSeverity.error
                    : QALabIssueSeverity.warning)
                : QALabIssueSeverity.warning;
        findings.add(
          QALabPinpointFinding(
            severity: stableFrameSeverity,
            code: 'short_transition_visual_slow',
            message:
                'Short transition reached a visually stable frame too late after scroll settle.',
            route: route,
            surface: surface,
            timestamp: effectiveStableFrameTimestamp,
            context: <String, dynamic>{
              'docId': expectedDocId,
              'scrollToken': scrollToken,
              'stableFrameLatencyMs': stableFrameLatencyMs,
              'source': stableFrameSource,
              'positionMs': stableFrameEvent == null
                  ? null
                  : _asInt(stableFrameEvent.metadata['positionMs']),
              'isPlaying': stableFrameEvent == null
                  ? null
                  : stableFrameEvent.metadata['isPlaying'] == true,
              'isBuffering': stableFrameEvent == null
                  ? null
                  : stableFrameEvent.metadata['isBuffering'] == true,
            },
          ),
        );
      }
    }

    final hasShortVisualConfirmation = surface == 'short' &&
        (stableFrameEvent != null ||
            firstFrameIssue != null ||
            shortRuntimePlaybackRecovered);

    final duplicateBursts = _duplicatePlaybackDispatchBursts(
      surfaceTimeline: surfaceTimeline,
      docId: expectedDocId,
      after: latestSettle.timestamp,
    ).where((burst) {
      if (surface != 'short') {
        return true;
      }
      return !_isBenignShortDuplicatePlaybackBurst(
        burst,
        hasVisualConfirmation: hasShortVisualConfirmation,
      );
    }).toList(growable: false);
    if (duplicateBursts.isNotEmpty) {
      findings.add(
        QALabPinpointFinding(
          severity: _asInt(duplicateBursts.first['repeatCount']) >= 3
              ? QALabIssueSeverity.error
              : QALabIssueSeverity.warning,
          code: '${surface}_duplicate_playback_dispatch',
          message:
              'The same $surface item received repeated playback dispatches in a very short window.',
          route: route,
          surface: surface,
          timestamp: _parseTimestamp(duplicateBursts.first['timestamp']) ??
              referenceTime,
          context: duplicateBursts.first,
        ),
      );
    }

    if (surface == 'short') {
      final retryEvents = surfaceTimeline
          .where((event) => event.category == 'playback_dispatch')
          .where((event) => !event.timestamp.isBefore(latestSettle.timestamp))
          .where(
            (event) =>
                (event.metadata['docId'] ?? '').toString() == expectedDocId,
          )
          .where(
            (event) =>
                event.code == 'short_watchdog_play_retry' ||
                event.code == 'short_stall_recovery_play',
          )
          .toList(growable: false);
      final onlyWatchdogRetries = retryEvents.every(
        (event) => event.code == 'short_watchdog_play_retry',
      );
      final benignWatchdogReplay = hasShortVisualConfirmation &&
          onlyWatchdogRetries &&
          retryEvents.length == 2;
      if (!suppressShortTransitionWarnings &&
          retryEvents.length >= 2 &&
          !benignWatchdogReplay) {
        findings.add(
          QALabPinpointFinding(
            severity: retryEvents.length >= 3 ||
                    retryEvents.any(
                      (event) => event.code == 'short_stall_recovery_play',
                    )
                ? QALabIssueSeverity.error
                : QALabIssueSeverity.warning,
            code: 'short_playback_retry_burst',
            message:
                'Short playback needed repeated recovery play commands after page settle.',
            route: route,
            surface: surface,
            timestamp: retryEvents.last.timestamp,
            context: <String, dynamic>{
              'docId': expectedDocId,
              'retryCount': retryEvents.length,
              'stages': retryEvents
                  .map((event) => event.code)
                  .toList(growable: false),
              'maxRetry': retryEvents
                  .map((event) => _asInt(event.metadata['retry']))
                  .fold<int>(0, (left, right) => left > right ? left : right),
              'elapsedMs': retryEvents.last.timestamp
                  .difference(latestSettle.timestamp)
                  .inMilliseconds,
            },
          ),
        );
      }
    }

    return findings;
  }
}
