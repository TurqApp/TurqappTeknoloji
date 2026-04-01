import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);
  final smokePath = parsed['smoke-input'];
  final telemetryPath = parsed['telemetry-input'];
  final deviceLogPath = parsed['device-log-input'];
  final outputPath = parsed['output'];

  if (outputPath == null) {
    stderr.writeln(
      'Usage: dart run tool/release_alert_bundle.dart --output <file> [--smoke-input <file>] [--telemetry-input <file>] [--device-log-input <file>]',
    );
    exitCode = 64;
    return;
  }

  final smoke = await _readJsonFile(smokePath);
  final telemetry = await _readJsonFile(telemetryPath);
  final deviceLog = await _readJsonFile(deviceLogPath);

  final smokeSummary = _asMap(smoke['summary']);
  final telemetrySummary = _asMap(telemetry['summary']);
  final deviceLogSummary = _asMap(deviceLog['summary']);
  final smokeScenarios = _asList(smoke['scenarios']);
  final telemetryIssues = _asList(telemetry['issues']);
  final deviceLogIssues = _asList(deviceLog['issues']);
  final smokeBlockingCount = _asInt(smokeSummary['blockingScenarioCount']);
  final telemetryBlocking = telemetrySummary['hasBlocking'] == true;
  final deviceLogBlocking = deviceLogSummary['hasBlocking'] == true;
  final smokeFailures = _asInt(smokeSummary['failureCount']);
  final telemetryIssueCount = _asInt(telemetrySummary['issueCount']);
  final deviceLogIssueCount = _asInt(deviceLogSummary['issueCount']);
  final adminReportRequired = deviceLogSummary['adminReportRequired'] == true;
  final triageState = (deviceLogSummary['triageState'] ?? '').toString();
  final severity = _resolveSeverity(
    smokeFailures: smokeFailures,
    smokeBlockingCount: smokeBlockingCount,
    telemetryBlocking: telemetryBlocking,
    telemetryIssueCount: telemetryIssueCount,
    deviceLogBlocking: deviceLogBlocking,
    deviceLogIssueCount: deviceLogIssueCount,
  );
  final headline = _buildHeadline(
    severity: severity,
    smokeFailures: smokeFailures,
    smokeBlockingCount: smokeBlockingCount,
    telemetryBlocking: telemetryBlocking,
    telemetryIssueCount: telemetryIssueCount,
    deviceLogBlocking: deviceLogBlocking,
    deviceLogIssueCount: deviceLogIssueCount,
  );
  final topSignals = _collectTopSignals(
    smokeScenarios: smokeScenarios,
    telemetryIssues: telemetryIssues,
    deviceLogIssues: deviceLogIssues,
  );
  final nextActions = _suggestNextActions(
    smokeFailures: smokeFailures,
    smokeBlockingCount: smokeBlockingCount,
    telemetryBlocking: telemetryBlocking,
    telemetryIssueCount: telemetryIssueCount,
    deviceLogBlocking: deviceLogBlocking,
    deviceLogIssueCount: deviceLogIssueCount,
    adminReportRequired: adminReportRequired,
  );

  final payload = <String, dynamic>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'sources': <String, dynamic>{
      'smokeReport': smokePath ?? '',
      'telemetryReport': telemetryPath ?? '',
      'deviceLogReport': deviceLogPath ?? '',
    },
    'summary': <String, dynamic>{
      'severity': severity,
      'headline': headline,
      'hasBlockingSignals':
          smokeBlockingCount > 0 || telemetryBlocking || deviceLogBlocking,
      'smokeFailureCount': smokeFailures,
      'smokeBlockingScenarioCount': smokeBlockingCount,
      'telemetryBlocking': telemetryBlocking,
      'telemetryIssueCount': telemetryIssueCount,
      'deviceLogBlocking': deviceLogBlocking,
      'deviceLogIssueCount': deviceLogIssueCount,
      'adminReportRequired': adminReportRequired,
      'triageState': triageState,
    },
    'topSignals': topSignals,
    'nextActions': nextActions,
    'smoke': smoke,
    'telemetry': telemetry,
    'deviceLog': deviceLog,
  };

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );

  stdout.writeln(
    '[release-alert-bundle] severity=$severity blocking=${payload['summary']?['hasBlockingSignals'] == true} smokeFailures=$smokeFailures smokeBlocking=$smokeBlockingCount telemetryBlocking=$telemetryBlocking deviceLogBlocking=$deviceLogBlocking',
  );
}

String _resolveSeverity({
  required int smokeFailures,
  required int smokeBlockingCount,
  required bool telemetryBlocking,
  required int telemetryIssueCount,
  required bool deviceLogBlocking,
  required int deviceLogIssueCount,
}) {
  if (smokeFailures > 0 ||
      smokeBlockingCount > 0 ||
      telemetryBlocking ||
      deviceLogBlocking) {
    return 'blocking';
  }
  if (telemetryIssueCount > 0 || deviceLogIssueCount > 0) {
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
  required bool deviceLogBlocking,
  required int deviceLogIssueCount,
}) {
  if (severity == 'blocking') {
    return 'Release gate blocking: smokeFailures=$smokeFailures smokeBlocking=$smokeBlockingCount telemetryBlocking=$telemetryBlocking deviceLogBlocking=$deviceLogBlocking';
  }
  if (severity == 'warning') {
    return 'Release gate warning: telemetryIssues=$telemetryIssueCount deviceLogIssues=$deviceLogIssueCount';
  }
  return 'Release gate healthy';
}

List<Map<String, dynamic>> _collectTopSignals({
  required List<dynamic> smokeScenarios,
  required List<dynamic> telemetryIssues,
  required List<dynamic> deviceLogIssues,
}) {
  final signals = <Map<String, dynamic>>[];

  for (final scenarioRaw in smokeScenarios.take(5)) {
    final scenario = _asMap(scenarioRaw);
    final hasFailure = scenario['hasFailure'] == true;
    final telemetryBlockingCount = _asInt(scenario['telemetryBlockingCount']);
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

  for (final issueRaw in deviceLogIssues.take(5 - signals.length)) {
    final issue = _asMap(issueRaw);
    signals.add(<String, dynamic>{
      'type': 'device_log',
      'code': (issue['code'] ?? '').toString(),
      'severity': (issue['severity'] ?? '').toString(),
      'message': (issue['message'] ?? '').toString(),
      'count': _asInt(issue['count']),
      'tag': (issue['tag'] ?? '').toString(),
    });
  }

  return signals;
}

List<String> _suggestNextActions({
  required int smokeFailures,
  required int smokeBlockingCount,
  required bool telemetryBlocking,
  required int telemetryIssueCount,
  required bool deviceLogBlocking,
  required int deviceLogIssueCount,
  required bool adminReportRequired,
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
  if (deviceLogBlocking) {
    actions
        .add('Review blocking device log findings with admin before patching');
  } else if (deviceLogIssueCount > 0) {
    actions.add(
        'Present device log findings to admin before fixing runtime issues');
  }
  if (adminReportRequired) {
    actions.add('Keep device-derived fixes behind admin review first');
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
