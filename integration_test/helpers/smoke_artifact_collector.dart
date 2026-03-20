import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/runtime_health_exporter.dart';

import 'test_state_probe.dart';

class SmokeArtifactCollector {
  const SmokeArtifactCollector._();

  static Future<void> runScenario(
    String scenarioName,
    WidgetTester tester,
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
      tester: tester,
      error: caughtError,
      stackTrace: caughtStackTrace,
    );

    if (caughtError != null && caughtStackTrace != null) {
      Error.throwWithStackTrace(caughtError, caughtStackTrace);
    }
  }

  static Future<void> writeArtifact(
    String scenarioName, {
    WidgetTester? tester,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final screenshotPath = error == null
        ? null
        : await _captureFailureScreenshot(
            scenarioName,
            tester: tester,
          );
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
          if (screenshotPath != null) 'screenshotPath': screenshotPath,
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

  static Future<String?> _captureFailureScreenshot(
    String scenarioName, {
    WidgetTester? tester,
  }) async {
    final binding = IntegrationTestWidgetsFlutterBinding.instance;
    final fileName = '${_sanitizeFileName(scenarioName)}.png';
    final outputFile = File('artifacts/integration_smoke/$fileName');
    try {
      await outputFile.parent.create(recursive: true);
      await binding.convertFlutterSurfaceToImage();
      if (tester != null) {
        await tester.pump();
      }
      final bytes = await binding.takeScreenshot(
        _sanitizeFileName(scenarioName),
      );
      await outputFile.writeAsBytes(bytes, flush: true);
      return outputFile.path;
    } catch (_) {
      return null;
    }
  }

  static String _sanitizeFileName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
