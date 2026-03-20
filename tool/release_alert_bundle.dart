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
  final smokeBlockingCount = _asInt(smokeSummary['blockingScenarioCount']);
  final telemetryBlocking = telemetrySummary['hasBlocking'] == true;
  final smokeFailures = _asInt(smokeSummary['failureCount']);

  final payload = <String, dynamic>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'sources': <String, dynamic>{
      'smokeReport': smokePath ?? '',
      'telemetryReport': telemetryPath ?? '',
    },
    'summary': <String, dynamic>{
      'hasBlockingSignals': smokeBlockingCount > 0 || telemetryBlocking,
      'smokeFailureCount': smokeFailures,
      'smokeBlockingScenarioCount': smokeBlockingCount,
      'telemetryBlocking': telemetryBlocking,
      'telemetryIssueCount': _asInt(telemetrySummary['issueCount']),
    },
    'smoke': smoke,
    'telemetry': telemetry,
  };

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );

  stdout.writeln(
    '[release-alert-bundle] blocking=${payload['summary']?['hasBlockingSignals'] == true} smokeFailures=$smokeFailures smokeBlocking=$smokeBlockingCount telemetryBlocking=$telemetryBlocking',
  );
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
