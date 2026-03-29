import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'native_exoplayer_probe.dart';
import 'test_state_probe.dart';

class E2EMatrixLogger {
  const E2EMatrixLogger._();

  static Future<void> logStep(
    WidgetTester tester, {
    required String scenario,
    required String step,
  }) async {
    final probe = readIntegrationProbe();
    Map<String, dynamic> native = const <String, dynamic>{};
    if (supportsNativeExoSmoke) {
      native = await readNativeExoSmokeSnapshot();
    }

    final payload = <String, dynamic>{
      'scenario': scenario,
      'step': step,
      'probe': probe,
      'nativeExo': native,
    };

    debugPrint('[e2e-matrix] ${jsonEncode(payload)}');
  }
}
