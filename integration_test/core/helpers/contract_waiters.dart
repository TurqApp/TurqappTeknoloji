import 'package:flutter_test/flutter_test.dart';

import 'test_state_probe.dart';
import 'transient_error_policy.dart';

Future<Map<String, dynamic>> waitForSurfaceProbeContract(
  WidgetTester tester,
  String surface,
  bool Function(Map<String, dynamic>) predicate, {
  int maxPumps = 16,
  Duration step = const Duration(milliseconds: 250),
  String? reason,
  String context = 'surface contract',
}) async {
  for (var i = 0; i < maxPumps; i++) {
    final payload = readSurfaceProbe(surface);
    if (predicate(payload)) {
      return payload;
    }
    await tester.pump(step);
    drainExpectedTesterExceptions(tester, context: context);
  }
  final payload = readSurfaceProbe(surface);
  if (predicate(payload)) {
    return payload;
  }
  throw TestFailure(
    reason ?? 'Surface probe did not reach expected state: $surface',
  );
}
