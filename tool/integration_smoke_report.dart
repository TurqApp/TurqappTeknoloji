import 'dart:convert';
import 'dart:io';

import 'package:turqappv2/Core/Services/integration_smoke_reporter.dart';

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);
  final inputDir = parsed['input-dir'];
  final outputPath = parsed['output'];
  final failOnBlocking = _isTruthy(parsed['fail-on-blocking']);

  if (inputDir == null || outputPath == null) {
    stderr.writeln(
      'Usage: dart run tool/integration_smoke_report.dart --input-dir <dir> --output <file>',
    );
    exitCode = 64;
    return;
  }

  final directory = Directory(inputDir);
  if (!directory.existsSync()) {
    stderr.writeln('Integration smoke artifact directory not found: $inputDir');
    exitCode = 66;
    return;
  }

  final artifacts = <Map<String, dynamic>>[];
  await for (final entity in directory.list()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final raw = await entity.readAsString();
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      stderr.writeln(
        '[integration-smoke-report] skipping malformed artifact '
        '${entity.path}: $error',
      );
      continue;
    }
    if (decoded is! Map) continue;
    artifacts.add(Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>()));
  }

  final report = IntegrationSmokeReporter.buildReport(artifacts);
  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report.toJson()),
  );

  stdout.writeln(
    '[integration-smoke-report] scenarios=${report.scenarioCount} blocking=${report.blockingScenarioCount} failures=${report.failureCount}',
  );
  for (final scenario in report.scenarios) {
    stdout.writeln(
      '[integration-smoke-report] ${scenario.scenario} route=${scenario.currentRoute} invariants=${scenario.invariantCount} telemetryBlocking=${scenario.telemetryBlockingCount} failure=${scenario.hasFailure}',
    );
  }

  if (failOnBlocking && report.hasBlockingSignals) {
    stderr.writeln(
      '[integration-smoke-report] blocking smoke signals detected; failing by request',
    );
    exitCode = 2;
  }
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

bool _isTruthy(String? value) {
  if (value == null) return false;
  switch (value.toLowerCase().trim()) {
    case '1':
    case 'true':
    case 'yes':
    case 'y':
    case 'on':
      return true;
    default:
      return false;
  }
}
