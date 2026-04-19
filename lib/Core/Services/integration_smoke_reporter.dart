class IntegrationSmokeScenarioReport {
  const IntegrationSmokeScenarioReport({
    required this.scenario,
    required this.currentRoute,
    required this.previousRoute,
    required this.hasFailure,
    required this.hasScreenshot,
    required this.artifactExported,
    required this.artifactReason,
    required this.invariantCount,
    required this.telemetryIssueCount,
    required this.telemetryBlockingCount,
    required this.deviceLogIssueCount,
    required this.deviceLogBlockingCount,
  });

  final String scenario;
  final String currentRoute;
  final String previousRoute;
  final bool hasFailure;
  final bool hasScreenshot;
  final bool artifactExported;
  final String artifactReason;
  final int invariantCount;
  final int telemetryIssueCount;
  final int telemetryBlockingCount;
  final int deviceLogIssueCount;
  final int deviceLogBlockingCount;

  bool get hasBlockingSignal =>
      hasFailure ||
      invariantCount > 0 ||
      telemetryBlockingCount > 0 ||
      deviceLogBlockingCount > 0;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'scenario': scenario,
      'currentRoute': currentRoute,
      'previousRoute': previousRoute,
      'hasFailure': hasFailure,
      'hasScreenshot': hasScreenshot,
      'artifactExported': artifactExported,
      'artifactReason': artifactReason,
      'invariantCount': invariantCount,
      'telemetryIssueCount': telemetryIssueCount,
      'telemetryBlockingCount': telemetryBlockingCount,
      'deviceLogIssueCount': deviceLogIssueCount,
      'deviceLogBlockingCount': deviceLogBlockingCount,
      'hasBlockingSignal': hasBlockingSignal,
    };
  }
}

class IntegrationSmokeReport {
  IntegrationSmokeReport({
    required this.scenarioCount,
    required this.failureCount,
    required this.screenshotCount,
    required this.invariantViolationCount,
    required this.telemetryIssueCount,
    required this.telemetryBlockingCount,
    required this.deviceLogIssueCount,
    required this.deviceLogBlockingCount,
    required this.blockingScenarioCount,
    required List<IntegrationSmokeScenarioReport> scenarios,
  }) : scenarios = List<IntegrationSmokeScenarioReport>.from(
          scenarios,
          growable: false,
        );

  final int scenarioCount;
  final int failureCount;
  final int screenshotCount;
  final int invariantViolationCount;
  final int telemetryIssueCount;
  final int telemetryBlockingCount;
  final int deviceLogIssueCount;
  final int deviceLogBlockingCount;
  final int blockingScenarioCount;
  final List<IntegrationSmokeScenarioReport> scenarios;

  bool get hasBlockingSignals => blockingScenarioCount > 0;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'summary': <String, dynamic>{
        'scenarioCount': scenarioCount,
        'failureCount': failureCount,
        'screenshotCount': screenshotCount,
        'invariantViolationCount': invariantViolationCount,
        'telemetryIssueCount': telemetryIssueCount,
        'telemetryBlockingCount': telemetryBlockingCount,
        'deviceLogIssueCount': deviceLogIssueCount,
        'deviceLogBlockingCount': deviceLogBlockingCount,
        'blockingScenarioCount': blockingScenarioCount,
        'hasBlockingSignals': hasBlockingSignals,
      },
      'scenarios': scenarios.map((scenario) => scenario.toJson()).toList(
            growable: false,
          ),
    };
  }
}

class IntegrationSmokeReporter {
  const IntegrationSmokeReporter._();

  static IntegrationSmokeReport buildReport(
    List<Map<String, dynamic>> artifacts,
  ) {
    final rawScenarios = artifacts
        .map(_toScenarioReport)
        .where((scenario) => scenario.scenario.isNotEmpty)
        .toList(growable: false);
    final mergedByScenario = <String, IntegrationSmokeScenarioReport>{};
    for (final scenario in rawScenarios) {
      final existing = mergedByScenario[scenario.scenario];
      if (existing == null) {
        mergedByScenario[scenario.scenario] = scenario;
        continue;
      }
      mergedByScenario[scenario.scenario] = _mergeScenarioReports(
        existing,
        scenario,
      );
    }
    final scenarios = mergedByScenario.values.toList(growable: false);
    final failureCount =
        scenarios.where((scenario) => scenario.hasFailure).length;
    final screenshotCount =
        scenarios.where((scenario) => scenario.hasScreenshot).length;
    final invariantViolationCount = scenarios.fold<int>(
      0,
      (sum, scenario) => sum + scenario.invariantCount,
    );
    final telemetryIssueCount = scenarios.fold<int>(
      0,
      (sum, scenario) => sum + scenario.telemetryIssueCount,
    );
    final telemetryBlockingCount = scenarios.fold<int>(
      0,
      (sum, scenario) => sum + scenario.telemetryBlockingCount,
    );
    final deviceLogIssueCount = scenarios.fold<int>(
      0,
      (sum, scenario) => sum + scenario.deviceLogIssueCount,
    );
    final deviceLogBlockingCount = scenarios.fold<int>(
      0,
      (sum, scenario) => sum + scenario.deviceLogBlockingCount,
    );
    final blockingScenarioCount =
        scenarios.where((scenario) => scenario.hasBlockingSignal).length;

    return IntegrationSmokeReport(
      scenarioCount: scenarios.length,
      failureCount: failureCount,
      screenshotCount: screenshotCount,
      invariantViolationCount: invariantViolationCount,
      telemetryIssueCount: telemetryIssueCount,
      telemetryBlockingCount: telemetryBlockingCount,
      deviceLogIssueCount: deviceLogIssueCount,
      deviceLogBlockingCount: deviceLogBlockingCount,
      blockingScenarioCount: blockingScenarioCount,
      scenarios: scenarios,
    );
  }

  static IntegrationSmokeScenarioReport _mergeScenarioReports(
    IntegrationSmokeScenarioReport first,
    IntegrationSmokeScenarioReport second,
  ) {
    String pickRoute(String primary, String fallback) {
      return primary.isNotEmpty ? primary : fallback;
    }

    String pickReason(String primary, String fallback) {
      return primary.isNotEmpty ? primary : fallback;
    }

    return IntegrationSmokeScenarioReport(
      scenario: first.scenario,
      currentRoute: pickRoute(first.currentRoute, second.currentRoute),
      previousRoute: pickRoute(first.previousRoute, second.previousRoute),
      hasFailure: first.hasFailure || second.hasFailure,
      hasScreenshot: first.hasScreenshot || second.hasScreenshot,
      artifactExported: first.artifactExported || second.artifactExported,
      artifactReason: pickReason(first.artifactReason, second.artifactReason),
      invariantCount: first.invariantCount > second.invariantCount
          ? first.invariantCount
          : second.invariantCount,
      telemetryIssueCount:
          first.telemetryIssueCount > second.telemetryIssueCount
              ? first.telemetryIssueCount
              : second.telemetryIssueCount,
      telemetryBlockingCount:
          first.telemetryBlockingCount > second.telemetryBlockingCount
              ? first.telemetryBlockingCount
              : second.telemetryBlockingCount,
      deviceLogIssueCount:
          first.deviceLogIssueCount > second.deviceLogIssueCount
              ? first.deviceLogIssueCount
              : second.deviceLogIssueCount,
      deviceLogBlockingCount:
          first.deviceLogBlockingCount > second.deviceLogBlockingCount
              ? first.deviceLogBlockingCount
              : second.deviceLogBlockingCount,
    );
  }

  static IntegrationSmokeScenarioReport _toScenarioReport(
    Map<String, dynamic> artifact,
  ) {
    final probe = _asMap(artifact['probe']);
    final telemetry = _asMap(artifact['telemetry']);
    final thresholdReport = _asMap(telemetry['thresholdReport']);
    final invariants = _asMap(artifact['invariants']);
    final failure = _asMap(artifact['failure']);
    final artifactStatus = _asMap(artifact['artifactStatus']);
    final deviceLog = _asMap(artifact['deviceLog']);
    final deviceLogSummary = _asMap(deviceLog['summary']);

    final issues = _asList(thresholdReport['issues']);
    final telemetryBlockingCount = issues.where((issue) {
      final issueMap = _asMap(issue);
      return issueMap['severity'] == 'blocking';
    }).length;
    final deviceLogIssueCount = _asInt(deviceLogSummary['issueCount']);
    final deviceLogBlockingCount = _asInt(deviceLogSummary['blockingCount']);

    return IntegrationSmokeScenarioReport(
      scenario: (artifact['scenario'] ?? '').toString().trim(),
      currentRoute: (probe['currentRoute'] ?? '').toString(),
      previousRoute: (probe['previousRoute'] ?? '').toString(),
      hasFailure: failure.isNotEmpty,
      hasScreenshot: (failure['screenshotPath'] ?? '').toString().isNotEmpty,
      artifactExported: artifactStatus['exported'] == true,
      artifactReason: (artifactStatus['reason'] ?? '').toString(),
      invariantCount: _asInt(invariants['count']),
      telemetryIssueCount: issues.length,
      telemetryBlockingCount: telemetryBlockingCount,
      deviceLogIssueCount: deviceLogIssueCount,
      deviceLogBlockingCount: deviceLogBlockingCount,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, entry) => MapEntry(key.toString(), _cloneValue(entry)),
      );
    }
    return const <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return value.map(_cloneValue).toList(growable: false);
    }
    return const <dynamic>[];
  }

  static dynamic _cloneValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, entry) => MapEntry(key.toString(), _cloneValue(entry)),
      );
    }
    if (value is List) {
      return value.map(_cloneValue).toList(growable: false);
    }
    return value;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
