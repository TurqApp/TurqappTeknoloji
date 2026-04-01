import 'dart:convert';
import 'dart:io';

import 'package:turqappv2/Core/Services/device_log_reporter.dart';

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);
  final inputPath = parsed['input'];
  final outputPath = parsed['output'];
  final deviceId = (parsed['device-id'] ?? '').trim();
  final platform = (parsed['platform'] ?? 'android').trim();
  final packageName = (parsed['package-name'] ?? '').trim();
  final processId = (parsed['process-id'] ?? '').trim();

  if (inputPath == null || outputPath == null || deviceId.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/device_log_report.dart --input <file> --output <file> --device-id <id> [--platform android|ios] [--package-name <name>] [--process-id <pid>]',
    );
    exitCode = 64;
    return;
  }

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Device log input not found: $inputPath');
    exitCode = 66;
    return;
  }

  final rawLog = await inputFile.readAsString();
  final report = DeviceLogReporter.buildReport(
    rawLog,
    deviceId: deviceId,
    platform: platform,
    packageName: packageName,
    processId: processId,
  );

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report.toJson()),
  );

  final summary = report.summary;
  stdout.writeln(
    '[device-log-report] issues=${summary['issueCount']} blocking=${summary['hasBlocking']} triage=${summary['triageState']}',
  );
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
