class IntegrationSmokeScenarioReport {
  const IntegrationSmokeScenarioReport({
    required this.scenario,
    required this.currentRoute,
    required this.previousRoute,
    required this.hasFailure,
    required this.hasScreenshot,
    required this.invariantCount,
    required this.telemetryIssueCount,
    required this.telemetryBlockingCount,
  });

  final String scenario;
  final String currentRoute;
  final String previousRoute;
  final bool hasFailure;
  final bool hasScreenshot;
  final int invariantCount;
  final int telemetryIssueCount;
  final int telemetryBlockingCount;

  bool get hasBlockingSignal =>
      hasFailure || invariantCount > 0 || telemetryBlockingCount > 0;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'scenario': scenario,
      'currentRoute': currentRoute,
      'previousRoute': previousRoute,
      'hasFailure': hasFailure,
      'hasScreenshot': hasScreenshot,
      'invariantCount': invariantCount,
      'telemetryIssueCount': telemetryIssueCount,
      'telemetryBlockingCount': telemetryBlockingCount,
      'hasBlockingSignal': hasBlockingSignal,
    };
  }
}

class IntegrationSmokeReport {
  const IntegrationSmokeReport({
    required this.scenarioCount,
    required this.failureCount,
    required this.screenshotCount,
    required this.invariantViolationCount,
    required this.telemetryIssueCount,
    required this.telemetryBlockingCount,
    required this.blockingScenarioCount,
    required this.scenarios,
  });

  final int scenarioCount;
  final int failureCount;
  final int screenshotCount;
  final int invariantViolationCount;
  final int telemetryIssueCount;
  final int telemetryBlockingCount;
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
    final scenarios = artifacts
        .map(_toScenarioReport)
        .where((scenario) => scenario.scenario.isNotEmpty)
        .toList(growable: false);
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
    final blockingScenarioCount =
        scenarios.where((scenario) => scenario.hasBlockingSignal).length;

    return IntegrationSmokeReport(
      scenarioCount: scenarios.length,
      failureCount: failureCount,
      screenshotCount: screenshotCount,
      invariantViolationCount: invariantViolationCount,
      telemetryIssueCount: telemetryIssueCount,
      telemetryBlockingCount: telemetryBlockingCount,
      blockingScenarioCount: blockingScenarioCount,
      scenarios: scenarios,
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

    final issues = _asList(thresholdReport['issues']);
    final telemetryBlockingCount = issues.where((issue) {
      final issueMap = _asMap(issue);
      return issueMap['severity'] == 'blocking';
    }).length;

    return IntegrationSmokeScenarioReport(
      scenario: (artifact['scenario'] ?? '').toString().trim(),
      currentRoute: (probe['currentRoute'] ?? '').toString(),
      previousRoute: (probe['previousRoute'] ?? '').toString(),
      hasFailure: failure.isNotEmpty,
      hasScreenshot: (failure['screenshotPath'] ?? '').toString().isNotEmpty,
      invariantCount: _asInt(invariants['count']),
      telemetryIssueCount: issues.length,
      telemetryBlockingCount: telemetryBlockingCount,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, entry) => MapEntry(key.toString(), entry),
      );
    }
    return const <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const <dynamic>[];
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
