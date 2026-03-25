part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsPart on QALabRecorder {
  String _lastCheckpointLabelBefore(DateTime timestamp) {
    for (final checkpoint in checkpoints.reversed) {
      if (!checkpoint.timestamp.isAfter(timestamp)) {
        return checkpoint.label;
      }
    }
    return '';
  }

  List<QALabPinpointFinding> _buildPrioritySurfaceFindings() {
    return _observedSurfaces()
        .expand(
          (surface) => _buildSurfaceRuntimeFindings(
            surface,
            _surfaceIssues(surface),
            _surfaceCheckpoints(surface),
          ),
        )
        .toList(growable: false);
  }

  List<QALabPinpointFinding> _buildTelemetryThresholdFindings() {
    final playbackKpi = PlaybackKpiService.maybeFind();
    if (playbackKpi == null) return const <QALabPinpointFinding>[];
    final report = TelemetryThresholdPolicyAdapter.evaluateKpiService(
      playbackKpi,
    );
    return report.issues
        .map(
          (issue) => QALabPinpointFinding(
            severity: issue.severity.name == 'blocking'
                ? QALabIssueSeverity.blocking
                : QALabIssueSeverity.warning,
            code: 'telemetry_${issue.code}',
            message: issue.message,
            route: _latestRouteForSurface(issue.surface),
            surface: issue.surface,
            timestamp: DateTime.now(),
            context: issue.metrics,
          ),
        )
        .toList(growable: false);
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

  bool _isQALabAutostartWarmup({
    required String surface,
    required String route,
    required DateTime referenceTime,
  }) {
    if (surface != 'feed') return false;
    final started = startedAt.value;
    if (started == null) return false;
    final ageMs = referenceTime.difference(started).inMilliseconds;
    if (ageMs < 0 || ageMs > 9000) return false;

    final normalizedRoute = route.trim().toLowerCase();
    if (normalizedRoute.contains('qa_lab') ||
        normalizedRoute.contains('qalab')) {
      return false;
    }
    return normalizedRoute.isEmpty ||
        normalizedRoute == '/' ||
        normalizedRoute.contains('navbar') ||
        normalizedRoute.contains('feed');
  }

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

    if ((surface == 'feed' || surface == 'short') &&
        _hasAuthenticatedUser(authProbe)) {
      final count = _asInt(latestProbe['count']);
      if (count == 0 && latestProbe['registered'] == true) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.blocking,
            code: '${surface}_blank_surface',
            message:
                '$surface surface is registered but returned zero items while authenticated.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'checkpoint': latestCheckpoint?.label ?? '',
            },
          ),
        );
      }
    }

    final autoplayFinding = _buildAutoplaySurfaceFinding(
      surface: surface,
      surfaceCheckpoints: surfaceCheckpoints,
      referenceTime: referenceTime,
      route: route,
    );
    if (autoplayFinding != null) {
      findings.add(autoplayFinding);
    }

    if (surface == 'feed') {
      final count = _asInt(latestProbe['count']);
      final centeredIndex = _asInt(latestProbe['centeredIndex']);
      final rootProbe = latestCheckpoint?.probe ?? const <String, dynamic>{};
      final isFeedForeground = _isPrimaryFeedSelected(
        rootProbe,
        route: route,
      );
      if (count > 0 && (centeredIndex < 0 || centeredIndex >= count)) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.error,
            code: 'feed_centered_index_invalid',
            message:
                'Feed has visible items but centered index is outside valid bounds.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'count': count,
              'centeredIndex': centeredIndex,
            },
          ),
        );
      }
      final playbackSuspended = latestProbe['playbackSuspended'] == true;
      final pauseAll = latestProbe['pauseAll'] == true;
      final canClaimPlaybackNow = latestProbe['canClaimPlaybackNow'] == true;
      if (isFeedForeground &&
          count > 0 &&
          !_isQALabAutostartWarmup(
            surface: surface,
            route: route,
            referenceTime: referenceTime,
          ) &&
          (playbackSuspended || pauseAll || !canClaimPlaybackNow)) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.warning,
            code: 'feed_playback_gate_blocked',
            message:
                'Feed has content but playback gate is not eligible for autoplay.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'playbackSuspended': playbackSuspended,
              'pauseAll': pauseAll,
              'canClaimPlaybackNow': canClaimPlaybackNow,
            },
          ),
        );
      }
    } else if (surface == 'short') {
      final count = _asInt(latestProbe['count']);
      final activeIndex = _asInt(latestProbe['activeIndex']);
      if (count > 0 && (activeIndex < 0 || activeIndex >= count)) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.error,
            code: 'short_active_index_invalid',
            message:
                'Short surface has items but active index is outside valid bounds.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'count': count,
              'activeIndex': activeIndex,
            },
          ),
        );
      }
    } else if (surface == 'chat') {
      final conversationProbe = latestCheckpoint?.probe['chatConversation']
              as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final lastMediaFailureCode =
          (conversationProbe['lastMediaFailureCode'] ?? '').toString();
      if (lastMediaFailureCode.isNotEmpty) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.error,
            code: 'chat_media_failure',
            message: 'Chat media pipeline reported a failure code.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'lastMediaFailureCode': lastMediaFailureCode,
              'lastMediaFailureDetail':
                  (conversationProbe['lastMediaFailureDetail'] ?? '')
                      .toString(),
              'lastMediaAction':
                  (conversationProbe['lastMediaAction'] ?? '').toString(),
            },
          ),
        );
      }
    } else if (surface == 'notifications') {
      final lastOpenedNotificationId =
          (latestProbe['lastOpenedNotificationId'] ?? '').toString();
      final lastOpenedRouteKind =
          (latestProbe['lastOpenedRouteKind'] ?? '').toString();
      if (lastOpenedNotificationId.isNotEmpty && lastOpenedRouteKind.isEmpty) {
        findings.add(
          QALabPinpointFinding(
            severity: QALabIssueSeverity.warning,
            code: 'notifications_route_resolution_missing',
            message:
                'A notification was opened but route resolution metadata stayed empty.',
            route: route,
            surface: surface,
            timestamp: referenceTime,
            context: <String, dynamic>{
              'notificationId': lastOpenedNotificationId,
            },
          ),
        );
      }
    }

    final suppressedNoiseCount = surfaceIssues
        .where(
          (issue) =>
              issue.code == 'flutter_suppressed' ||
              issue.code == 'platform_suppressed',
        )
        .length;
    if (suppressedNoiseCount >= QALabMode.noiseBurstWarningCount) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.warning,
          code: '${surface}_noise_burst',
          message:
              'Suppressed runtime noise accumulated on $surface and may hide real regressions.',
          route: route,
          surface: surface,
          timestamp: referenceTime,
          context: <String, dynamic>{
            'suppressedNoiseCount': suppressedNoiseCount,
          },
        ),
      );
    }

    final lifecycleInterruptions = surfaceIssues
        .where(
          (issue) =>
              issue.source == QALabIssueSource.lifecycle &&
              issue.code != 'lifecycle_resume',
        )
        .length;
    if (lifecycleInterruptions >= 2) {
      findings.add(
        QALabPinpointFinding(
          severity: QALabIssueSeverity.warning,
          code: '${surface}_lifecycle_interruptions',
          message:
              'Application lifecycle interrupted $surface multiple times during this session.',
          route: route,
          surface: surface,
          timestamp: referenceTime,
          context: <String, dynamic>{
            'interruptions': lifecycleInterruptions,
          },
        ),
      );
    }

    findings.addAll(
      _buildVideoSurfaceFindings(
        surface: surface,
        surfaceIssues: surfaceIssues,
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

  Map<String, dynamic> _surfaceRuntimeSummary(
    String surface,
    List<QALabIssue> surfaceIssues,
    List<QALabCheckpoint> surfaceCheckpoints,
  ) {
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
      'suppressedNoiseCount': suppressedNoiseCount,
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

  List<QALabPinpointFinding> _buildFetchSurfaceFindings({
    required String surface,
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime referenceTime,
    required String route,
  }) {
    if (surface != 'feed') {
      return const <QALabPinpointFinding>[];
    }
    final bursts = _feedTriggerBursts(surfaceTimeline: surfaceTimeline);
    if (bursts.isEmpty) {
      return const <QALabPinpointFinding>[];
    }
    final strongest = bursts.first;
    final repeatCount = _asInt(strongest['repeatCount']);
    return <QALabPinpointFinding>[
      QALabPinpointFinding(
        severity: repeatCount >= 3
            ? QALabIssueSeverity.error
            : QALabIssueSeverity.warning,
        code: 'feed_duplicate_fetch_trigger',
        message:
            'Feed fetch was triggered repeatedly before the previous request fully settled.',
        route: route,
        surface: surface,
        timestamp: _parseTimestamp(strongest['timestamp']) ?? referenceTime,
        context: strongest,
      ),
    ];
  }

  List<Map<String, dynamic>> _feedTriggerBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
  }) {
    final feedEvents = surfaceTimeline
        .where((event) => event.category == 'feed_fetch')
        .where((event) => event.code == 'requested')
        .toList(growable: false);
    final bursts = <Map<String, dynamic>>[];
    for (int i = 0; i < feedEvents.length; i++) {
      final first = feedEvents[i];
      final trigger = (first.metadata['trigger'] ?? '').toString();
      if (trigger.isEmpty) continue;
      var repeatCount = 1;
      for (int j = i + 1; j < feedEvents.length; j++) {
        final next = feedEvents[j];
        if ((next.metadata['trigger'] ?? '').toString() != trigger) {
          continue;
        }
        final deltaMs =
            next.timestamp.difference(first.timestamp).inMilliseconds;
        if (deltaMs > QALabMode.duplicateFeedTriggerWindowMs) {
          break;
        }
        repeatCount += 1;
      }
      if (repeatCount >= 2) {
        bursts.add(
          <String, dynamic>{
            'timestamp': first.timestamp.toUtc().toIso8601String(),
            'trigger': trigger,
            'stage': first.code,
            'repeatCount': repeatCount,
            'windowMs': QALabMode.duplicateFeedTriggerWindowMs,
          },
        );
      }
    }
    bursts.sort((a, b) => _asInt(b['repeatCount']) - _asInt(a['repeatCount']));
    return bursts;
  }

  int _countDuplicateFeedTriggerBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
  }) {
    return _feedTriggerBursts(surfaceTimeline: surfaceTimeline).length;
  }

  List<QALabPinpointFinding> _buildScrollSurfaceFindings({
    required String surface,
    required List<QALabTimelineEvent> surfaceTimeline,
    required List<QALabIssue> surfaceIssues,
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
    final expectedDocId = (latestSettle.metadata['docId'] ?? '').toString();
    if (expectedDocId.isEmpty) {
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
    final scrollToken = (latestSettle.metadata['scrollToken'] ?? '').toString();
    final dispatchLatencyMs = dispatch == null
        ? referenceTime.difference(latestSettle.timestamp).inMilliseconds
        : dispatch.timestamp.difference(latestSettle.timestamp).inMilliseconds;
    if (dispatch == null &&
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
    } else if (dispatch != null &&
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
    } else if (firstFrameIssue != null &&
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

    final duplicateBursts = _duplicatePlaybackDispatchBursts(
      surfaceTimeline: surfaceTimeline,
      docId: expectedDocId,
    );
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

    return findings;
  }

  QALabTimelineEvent? _latestScrollSettleEvent(
    List<QALabTimelineEvent> surfaceTimeline,
  ) {
    return surfaceTimeline
        .where((event) => event.category == 'scroll' && event.code == 'settled')
        .toList(growable: false)
        .lastOrNull;
  }

  QALabTimelineEvent? _firstPlaybackDispatchAfter({
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime after,
    required String docId,
  }) {
    return surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where(_isIssuedPlaybackDispatch)
        .where((event) => (event.metadata['docId'] ?? '').toString() == docId)
        .where((event) => !event.timestamp.isBefore(after))
        .toList(growable: false)
        .firstOrNull;
  }

  QALabTimelineEvent? _latestPlaybackSkipAfter({
    required List<QALabTimelineEvent> surfaceTimeline,
    required DateTime after,
    required String docId,
  }) {
    return surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where((event) => !_isIssuedPlaybackDispatch(event))
        .where((event) => (event.metadata['docId'] ?? '').toString() == docId)
        .where((event) => !event.timestamp.isBefore(after))
        .toList(growable: false)
        .lastOrNull;
  }

  List<Map<String, dynamic>> _duplicatePlaybackDispatchBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
    String? docId,
  }) {
    final events = surfaceTimeline
        .where((event) => event.category == 'playback_dispatch')
        .where(_isIssuedPlaybackDispatch)
        .where(
          (event) =>
              docId == null ||
              (event.metadata['docId'] ?? '').toString() == docId,
        )
        .toList(growable: false);
    final bursts = <Map<String, dynamic>>[];
    for (int i = 0; i < events.length; i++) {
      final first = events[i];
      final firstDocId = (first.metadata['docId'] ?? '').toString();
      if (firstDocId.isEmpty) continue;
      final stages = <String>[first.code];
      var repeatCount = 1;
      for (int j = i + 1; j < events.length; j++) {
        final next = events[j];
        if ((next.metadata['docId'] ?? '').toString() != firstDocId) {
          continue;
        }
        final deltaMs =
            next.timestamp.difference(first.timestamp).inMilliseconds;
        if (deltaMs > QALabMode.duplicatePlaybackDispatchWindowMs) {
          break;
        }
        repeatCount += 1;
        stages.add(next.code);
      }
      if (repeatCount >= 2) {
        bursts.add(
          <String, dynamic>{
            'timestamp': first.timestamp.toUtc().toIso8601String(),
            'docId': firstDocId,
            'repeatCount': repeatCount,
            'stages': stages,
            'sources': <String>[
              (first.metadata['dispatchSource'] ?? '').toString(),
              for (int k = i + 1;
                  k < events.length &&
                      (events[k].metadata['docId'] ?? '').toString() ==
                          firstDocId &&
                      events[k]
                              .timestamp
                              .difference(first.timestamp)
                              .inMilliseconds <=
                          QALabMode.duplicatePlaybackDispatchWindowMs;
                  k += 1)
                (events[k].metadata['dispatchSource'] ?? '').toString(),
            ].where((item) => item.isNotEmpty).toSet().toList(growable: false),
            'callerSignatures': <String>[
              (first.metadata['callerSignature'] ?? '').toString(),
              for (int k = i + 1;
                  k < events.length &&
                      (events[k].metadata['docId'] ?? '').toString() ==
                          firstDocId &&
                      events[k]
                              .timestamp
                              .difference(first.timestamp)
                              .inMilliseconds <=
                          QALabMode.duplicatePlaybackDispatchWindowMs;
                  k += 1)
                (events[k].metadata['callerSignature'] ?? '').toString(),
            ].where((item) => item.isNotEmpty).toSet().toList(growable: false),
            'scrollToken': (first.metadata['scrollToken'] ?? '').toString(),
            'windowMs': QALabMode.duplicatePlaybackDispatchWindowMs,
          },
        );
      }
    }
    bursts.sort((a, b) => _asInt(b['repeatCount']) - _asInt(a['repeatCount']));
    return bursts;
  }

  bool _isIssuedPlaybackDispatch(QALabTimelineEvent event) {
    final raw = event.metadata['dispatchIssued'];
    if (raw is bool) return raw;
    if (raw is String) {
      return raw.toLowerCase() != 'false';
    }
    return true;
  }

  int _countDuplicatePlaybackDispatchBursts({
    required List<QALabTimelineEvent> surfaceTimeline,
  }) {
    return _duplicatePlaybackDispatchBursts(surfaceTimeline: surfaceTimeline)
        .length;
  }

  (int, int) _latestScrollLatencySummary({
    required List<QALabTimelineEvent> surfaceTimeline,
    required List<QALabIssue> surfaceIssues,
    required DateTime referenceTime,
  }) {
    final latestSettle = _latestScrollSettleEvent(surfaceTimeline);
    if (latestSettle == null) {
      return (0, 0);
    }
    final docId = (latestSettle.metadata['docId'] ?? '').toString();
    if (docId.isEmpty) {
      return (0, 0);
    }
    final dispatch = _firstPlaybackDispatchAfter(
      surfaceTimeline: surfaceTimeline,
      after: latestSettle.timestamp,
      docId: docId,
    );
    final firstFrameIssue = surfaceIssues
        .where((issue) => issue.code == 'video_first_frame')
        .where((issue) => _videoIdOf(issue) == docId)
        .where((issue) => issue.timestamp.isAfter(latestSettle.timestamp))
        .toList(growable: false)
        .firstOrNull;
    final dispatchLatencyMs = dispatch == null
        ? 0
        : dispatch.timestamp.difference(latestSettle.timestamp).inMilliseconds;
    final firstFrameLatencyMs = firstFrameIssue == null
        ? 0
        : firstFrameIssue.timestamp
            .difference(latestSettle.timestamp)
            .inMilliseconds;
    return (dispatchLatencyMs, firstFrameLatencyMs);
  }
}
