part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsPart on QALabRecorder {
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
}
