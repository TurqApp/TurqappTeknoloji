import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/runtime_health_exporter.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';

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

    await _cleanupPersistentControllers(tester);

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
    final artifactDirectory = await _resolveArtifactDirectory();
    final screenshotPath = error == null
        ? null
        : await _captureFailureScreenshot(
            scenarioName,
            artifactDirectory: artifactDirectory,
            tester: tester,
          );
    final outputFile = File(
      '${artifactDirectory.path}/${_sanitizeFileName(scenarioName)}.json',
    );
    final payload = <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'scenario': scenarioName,
      'artifactDirectory': artifactDirectory.path,
      'probe': readIntegrationProbe(),
      'telemetry': _readTelemetry(),
      'invariants': _readInvariants(),
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

  static Map<String, dynamic> _readInvariants() {
    if (!Get.isRegistered<RuntimeInvariantGuard>()) {
      return const <String, dynamic>{'registered': false};
    }
    final guard = Get.find<RuntimeInvariantGuard>();
    return <String, dynamic>{
      'registered': true,
      'count': guard.recentViolations.length,
      'violations': guard.recentViolations
          .map((violation) => violation.toJson())
          .toList(growable: false),
    };
  }

  static Future<String?> _captureFailureScreenshot(
    String scenarioName, {
    required Directory artifactDirectory,
    WidgetTester? tester,
  }) async {
    final binding = IntegrationTestWidgetsFlutterBinding.instance;
    final fileName = '${_sanitizeFileName(scenarioName)}.png';
    final outputFile = File('${artifactDirectory.path}/$fileName');
    try {
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

  static Future<Directory> _resolveArtifactDirectory() async {
    final fallbackBase = await getApplicationSupportDirectory();
    final fallbackDirectory = Directory(
      '${fallbackBase.path}/integration_smoke',
    );
    try {
      final repoDirectory = Directory('artifacts/integration_smoke');
      await repoDirectory.create(recursive: true);
      return repoDirectory;
    } catch (_) {
      await fallbackDirectory.create(recursive: true);
      return fallbackDirectory;
    }
  }

  static String _sanitizeFileName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static Future<void> _cleanupPersistentControllers(
    WidgetTester? tester,
  ) async {
    try {
      if (Get.isRegistered<NavBarController>()) {
        await Get.delete<NavBarController>(force: true);
      }
      if (tester != null) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    } catch (_) {}
  }
}
