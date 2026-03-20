import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);
  final smokePath = parsed['smoke-input'];
  final telemetryPath = parsed['telemetry-input'];
  final outputPath = parsed['output'];

  if (outputPath == null) {
    stderr.writeln(
      'Usage: dart run tool/release_alert_bundle.dart --output <file> [--smoke-input <file>] [--telemetry-input <file>]',
    );
    exitCode = 64;
    return;
  }

  final smoke = await _readJsonFile(smokePath);
  final telemetry = await _readJsonFile(telemetryPath);

  final smokeSummary = _asMap(smoke['summary']);
  final telemetrySummary = _asMap(telemetry['summary']);
  final smokeScenarios = _asList(smoke['scenarios']);
  final telemetryIssues = _asList(telemetry['issues']);
  final smokeBlockingCount = _asInt(smokeSummary['blockingScenarioCount']);
  final telemetryBlocking = telemetrySummary['hasBlocking'] == true;
  final smokeFailures = _asInt(smokeSummary['failureCount']);
  final telemetryIssueCount = _asInt(telemetrySummary['issueCount']);
  final severity = _resolveSeverity(
    smokeFailures: smokeFailures,
    smokeBlockingCount: smokeBlockingCount,
    telemetryBlocking: telemetryBlocking,
    telemetryIssueCount: telemetryIssueCount,
  );
  final headline = _buildHeadline(
    severity: severity,
    smokeFailures: smokeFailures,
    smokeBlockingCount: smokeBlockingCount,
    telemetryBlocking: telemetryBlocking,
    telemetryIssueCount: telemetryIssueCount,
  );
  final topSignals = _collectTopSignals(
    smokeScenarios: smokeScenarios,
    telemetryIssues: telemetryIssues,
  );
  final nextActions = _suggestNextActions(
    smokeFailures: smokeFailures,
    smokeBlockingCount: smokeBlockingCount,
    telemetryBlocking: telemetryBlocking,
    telemetryIssueCount: telemetryIssueCount,
  );

  final payload = <String, dynamic>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'sources': <String, dynamic>{
      'smokeReport': smokePath ?? '',
      'telemetryReport': telemetryPath ?? '',
    },
    'summary': <String, dynamic>{
      'severity': severity,
      'headline': headline,
      'hasBlockingSignals': smokeBlockingCount > 0 || telemetryBlocking,
      'smokeFailureCount': smokeFailures,
      'smokeBlockingScenarioCount': smokeBlockingCount,
      'telemetryBlocking': telemetryBlocking,
      'telemetryIssueCount': telemetryIssueCount,
    },
    'topSignals': topSignals,
    'nextActions': nextActions,
    'smoke': smoke,
    'telemetry': telemetry,
  };

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );

  stdout.writeln(
    '[release-alert-bundle] severity=$severity blocking=${payload['summary']?['hasBlockingSignals'] == true} smokeFailures=$smokeFailures smokeBlocking=$smokeBlockingCount telemetryBlocking=$telemetryBlocking',
  );
}

String _resolveSeverity({
  required int smokeFailures,
  required int smokeBlockingCount,
  required bool telemetryBlocking,
  required int telemetryIssueCount,
}) {
  if (smokeFailures > 0 || smokeBlockingCount > 0 || telemetryBlocking) {
    return 'blocking';
  }
  if (telemetryIssueCount > 0) {
    return 'warning';
  }
  return 'ok';
}

String _buildHeadline({
  required String severity,
  required int smokeFailures,
  required int smokeBlockingCount,
  required bool telemetryBlocking,
  required int telemetryIssueCount,
}) {
  if (severity == 'blocking') {
    return 'Release gate blocking: smokeFailures=$smokeFailures smokeBlocking=$smokeBlockingCount telemetryBlocking=$telemetryBlocking';
  }
  if (severity == 'warning') {
    return 'Release gate warning: telemetryIssues=$telemetryIssueCount';
  }
  return 'Release gate healthy';
}

List<Map<String, dynamic>> _collectTopSignals({
  required List<dynamic> smokeScenarios,
  required List<dynamic> telemetryIssues,
}) {
  final signals = <Map<String, dynamic>>[];

  for (final scenarioRaw in smokeScenarios.take(5)) {
    final scenario = _asMap(scenarioRaw);
    final hasFailure = scenario['hasFailure'] == true;
    final telemetryBlockingCount =
        _asInt(scenario['telemetryBlockingCount']);
    final invariantCount = _asInt(scenario['invariantCount']);
    if (!hasFailure && telemetryBlockingCount == 0 && invariantCount == 0) {
      continue;
    }
    signals.add(<String, dynamic>{
      'type': 'smoke',
      'scenario': (scenario['scenario'] ?? '').toString(),
      'hasFailure': hasFailure,
      'telemetryBlockingCount': telemetryBlockingCount,
      'invariantCount': invariantCount,
    });
  }

  for (final issueRaw in telemetryIssues.take(5 - signals.length)) {
    final issue = _asMap(issueRaw);
    signals.add(<String, dynamic>{
      'type': 'telemetry',
      'surface': (issue['surface'] ?? '').toString(),
      'code': (issue['code'] ?? '').toString(),
      'severity': (issue['severity'] ?? '').toString(),
    });
  }

  return signals;
}

List<String> _suggestNextActions({
  required int smokeFailures,
  required int smokeBlockingCount,
  required bool telemetryBlocking,
  required int telemetryIssueCount,
}) {
  final actions = <String>[];
  if (smokeFailures > 0) {
    actions.add('Fix failing smoke scenarios before release');
  }
  if (smokeBlockingCount > 0) {
    actions.add('Review blocking smoke scenarios and invariant violations');
  }
  if (telemetryBlocking) {
    actions.add('Investigate blocking telemetry thresholds on feed/short');
  } else if (telemetryIssueCount > 0) {
    actions.add('Review warning telemetry thresholds before release');
  }
  if (actions.isEmpty) {
    actions.add('No blocking signals detected');
  }
  return actions;
}

Future<Map<String, dynamic>> _readJsonFile(String? path) async {
  if (path == null || path.trim().isEmpty) {
    return const <String, dynamic>{};
  }
  final file = File(path);
  if (!file.existsSync()) {
    return const <String, dynamic>{};
  }
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) {
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  return const <String, dynamic>{};
}

Map<String, String> _parseArgs(List<String> args) {
  final parsed = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final current = args[i];
    if (!current.startsWith('--')) continue;
    final key = current.substring(2);
    final next = i + 1 < args.length ? args[i + 1] : null;
    if (next == null || next.startsWith('--')) continue;
    parsed[key] = next;
    i += 1;
  }
  return parsed;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return const <String, dynamic>{};
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}
