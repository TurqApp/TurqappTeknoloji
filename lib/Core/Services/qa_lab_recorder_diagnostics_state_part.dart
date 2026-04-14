part of 'qa_lab_recorder.dart';

extension QALabRecorderDiagnosticsStatePart on QALabRecorder {
  List<Map<String, dynamic>> _topSuppressedNoiseFamilies(
    List<QALabIssue> surfaceIssues,
  ) {
    final counts = <String, int>{};
    for (final issue in surfaceIssues) {
      if (issue.code != 'flutter_suppressed' &&
          issue.code != 'platform_suppressed') {
        continue;
      }
      final family = _suppressedNoiseFamily(issue);
      counts.update(family, (value) => value + 1, ifAbsent: () => 1);
    }
    final entries = counts.entries.toList(growable: false)
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.compareTo(b.key);
      });
    return entries
        .take(3)
        .map(
          (entry) => <String, dynamic>{
            'family': entry.key,
            'count': entry.value,
          },
        )
        .toList(growable: false);
  }

  String _suppressedNoiseFamily(QALabIssue issue) {
    final metadata = issue.metadata;
    final errorType = (metadata['errorType'] ?? '').toString().trim();
    if (errorType.isNotEmpty) return errorType;
    final library = (metadata['library'] ?? '').toString().trim();
    if (library.isNotEmpty) return library;
    final sourceLabel = (metadata['sourceLabel'] ?? '').toString().trim();
    if (sourceLabel.isNotEmpty) return sourceLabel;
    if (issue.code.trim().isNotEmpty) return issue.code.trim();
    if (issue.message.trim().isNotEmpty) return issue.message.trim();
    return 'unknown';
  }

  List<QALabPinpointFinding> _buildSurfaceStateHealthFindings({
    required String surface,
    required Map<String, dynamic> latestProbe,
    required Map<String, dynamic> authProbe,
    required QALabCheckpoint? latestCheckpoint,
    required List<QALabIssue> surfaceIssues,
    required List<QALabCheckpoint> surfaceCheckpoints,
    required DateTime referenceTime,
    required String route,
  }) {
    final findings = <QALabPinpointFinding>[];

    if ((surface == 'feed' || surface == 'short') &&
        _hasAuthenticatedUser(authProbe)) {
      final count = _asInt(latestProbe['count']);
      final rootProbe = latestCheckpoint?.probe ?? const <String, dynamic>{};
      final isForegroundSurface = surface == 'feed'
          ? _isPrimaryFeedSelected(rootProbe, route: route)
          : _isPrimaryShortSelected(rootProbe, route: route);
      final feedBootstrapInFlight = surface == 'feed' &&
          (_diagnosticsProbeAsBool(
                latestProbe['isLoading'],
                fallback: false,
              ) ||
              _diagnosticsProbeAsBool(
                latestProbe['ensureInitialLoadInFlight'],
                fallback: false,
              ) ||
              _diagnosticsProbeAsBool(
                latestProbe['surfaceBootstrapInFlight'],
                fallback: false,
              ));
      if (count == 0 &&
          latestProbe['registered'] == true &&
          isForegroundSurface &&
          !feedBootstrapInFlight &&
          !_isTransientBlankSurfaceWarmup(
            surface: surface,
            surfaceCheckpoints: surfaceCheckpoints,
            referenceTime: referenceTime,
            route: route,
          ) &&
          !_isTransientShortBlankSurfaceBootstrap(
            surface: surface,
            surfaceIssues: surfaceIssues,
            surfaceCheckpoints: surfaceCheckpoints,
            referenceTime: referenceTime,
            route: route,
          )) {
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
    findings.addAll(
      _buildSurfaceStateSpecificFindings(
        surface: surface,
        latestProbe: latestProbe,
        latestCheckpoint: latestCheckpoint,
        surfaceIssues: surfaceIssues,
        surfaceCheckpoints: surfaceCheckpoints,
        referenceTime: referenceTime,
        route: route,
      ),
    );

    final suppressedNoiseCount = surfaceIssues
        .where(
          (issue) =>
              issue.code == 'flutter_suppressed' ||
              issue.code == 'platform_suppressed',
        )
        .length;
    final topSuppressedNoiseFamilies =
        _topSuppressedNoiseFamilies(surfaceIssues);
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
            if (topSuppressedNoiseFamilies.isNotEmpty)
              'topSuppressedNoiseFamilies': topSuppressedNoiseFamilies,
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

    return findings;
  }
}
