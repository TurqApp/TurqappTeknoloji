import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/runtime_health_exporter.dart';

import 'test_state_probe.dart';

class SmokeArtifactCollector {
  const SmokeArtifactCollector._();

  static Future<void> runScenario(
    String scenarioName,
    Future<void> Function() body,
  ) async {
    Object? caughtError;
    StackTrace? caughtStackTrace;
    try {
      await body();
    } catch (error, stackTrace) {
      caughtError = error;
      caughtStackTrace = stackTrace;
    }

    await writeArtifact(
      scenarioName,
      error: caughtError,
      stackTrace: caughtStackTrace,
    );

    if (caughtError != null && caughtStackTrace != null) {
      Error.throwWithStackTrace(caughtError, caughtStackTrace);
    }
  }

  static Future<void> writeArtifact(
    String scenarioName, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final outputFile = File(
      'artifacts/integration_smoke/${_sanitizeFileName(scenarioName)}.json',
    );
    await outputFile.parent.create(recursive: true);
    final payload = <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'scenario': scenarioName,
      'probe': readIntegrationProbe(),
      'telemetry': _readTelemetry(),
      if (error != null) ...<String, dynamic>{
        'failure': <String, dynamic>{
          'error': '$error',
          if (stackTrace != null) 'stackTrace': '$stackTrace',
        },
      },
    };
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  static Map<String, dynamic> _readTelemetry() {
    if (!Get.isRegistered<PlaybackKpiService>()) {
      return const <String, dynamic>{'registered': false};
    }
    return <String, dynamic>{
      'registered': true,
      ...RuntimeHealthExporter.exportFromKpiService(
        Get.find<PlaybackKpiService>(),
      ),
    };
  }

  static String _sanitizeFileName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
