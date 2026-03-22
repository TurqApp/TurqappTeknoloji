import 'dart:convert';
import 'dart:io';

import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy.dart';

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);
  final inputPath = parsed['input'];
  final outputPath = parsed['output'];
  final failOnBlocking = _isTruthy(parsed['fail-on-blocking']);

  if (inputPath == null || outputPath == null) {
    stderr.writeln(
      'Usage: dart run tool/telemetry_threshold_report.dart --input <file> --output <file>',
    );
    exitCode = 64;
    return;
  }

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Telemetry input not found: $inputPath');
    exitCode = 66;
    return;
  }

  final raw = jsonDecode(await inputFile.readAsString());
  if (raw is! Map) {
    stderr.writeln('Telemetry input must be a JSON object');
    exitCode = 65;
    return;
  }

  final surfacesRaw = raw['surfaces'];
  if (surfacesRaw is! List) {
    stderr.writeln('Telemetry input must contain a surfaces array');
    exitCode = 65;
    return;
  }

  final snapshots = surfacesRaw
      .whereType<Map>()
      .map((item) => SurfaceTelemetrySnapshot.fromJson(
            Map<String, dynamic>.from(item.cast<dynamic, dynamic>()),
          ))
      .where((snapshot) => snapshot.surface.isNotEmpty)
      .toList(growable: false);

  final report = TelemetryThresholdPolicy.evaluateSnapshots(snapshots);
  final payload = <String, dynamic>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'surfaceCount': snapshots.length,
    'summary': <String, dynamic>{
      'hasIssues': report.hasIssues,
      'hasBlocking': report.hasBlocking,
      'issueCount': report.issues.length,
    },
    'issues':
        report.issues.map((issue) => issue.toJson()).toList(growable: false),
  };

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );

  stdout.writeln(
    '[telemetry-threshold-report] issues=${report.issues.length} blocking=${report.hasBlocking}',
  );
  for (final issue in report.issues) {
    stdout.writeln(
      '[telemetry-threshold-report] ${issue.severity.name.toUpperCase()} ${issue.surface} ${issue.code}',
    );
  }

  if (failOnBlocking && report.hasBlocking) {
    stderr.writeln(
      '[telemetry-threshold-report] blocking issues detected; failing by request',
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
