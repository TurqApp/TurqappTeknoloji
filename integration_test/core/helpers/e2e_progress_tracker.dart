import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

import 'e2e_matrix_logger.dart';

class E2EProgressTracker {
  const E2EProgressTracker._();

  static Future<void> recordStep(
    WidgetTester tester, {
    required String scenario,
    required String step,
    String status = 'in_progress',
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    await E2EMatrixLogger.logStep(
      tester,
      scenario: scenario,
      step: step,
    );

    final payload = <String, dynamic>{
      'at': DateTime.now().toUtc().toIso8601String(),
      'scenario': scenario,
      'step': step,
      'status': status,
      if (extra.isNotEmpty) 'extra': extra,
    };

    final directory = await _resolveDirectory();
    final latest = File('${directory.path}/${_safeName(scenario)}_latest.json');
    final history =
        File('${directory.path}/${_safeName(scenario)}_history.jsonl');
    final encoded = jsonEncode(payload);
    await latest.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await history.writeAsString('$encoded\n',
        mode: FileMode.append, flush: true);
    debugPrint('[e2e-progress] $encoded');
  }

  static Future<void> markDone(
    WidgetTester tester, {
    required String scenario,
  }) async {
    await recordStep(
      tester,
      scenario: scenario,
      step: 'done',
      status: 'completed',
    );
  }

  static Future<void> markFailure(
    WidgetTester tester, {
    required String scenario,
    required String step,
    required Object error,
  }) async {
    await recordStep(
      tester,
      scenario: scenario,
      step: step,
      status: 'failed',
      extra: <String, dynamic>{'error': '$error'},
    );
  }

  static Future<Directory> _resolveDirectory() async {
    final fallbackBase = await getApplicationSupportDirectory();
    final fallbackDirectory = Directory('${fallbackBase.path}/e2e_progress');
    try {
      final repoDirectory = Directory('artifacts/integration_smoke');
      await repoDirectory.create(recursive: true);
      return repoDirectory;
    } catch (_) {
      await fallbackDirectory.create(recursive: true);
      return fallbackDirectory;
    }
  }

  static String _safeName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
