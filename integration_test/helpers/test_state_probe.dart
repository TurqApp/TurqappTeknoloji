import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_state_probe.dart';

Map<String, dynamic> readIntegrationProbe() {
  return IntegrationTestStateProbe.snapshot();
}

Map<String, dynamic> readSurfaceProbe(String surface) {
  final snapshot = readIntegrationProbe();
  final payload = snapshot[surface];
  expect(payload, isA<Map<String, dynamic>>());
  return Map<String, dynamic>.from(payload as Map<String, dynamic>);
}

void expectSurfaceRegistered(String surface) {
  final payload = readSurfaceProbe(surface);
  expect(payload['registered'], isTrue,
      reason: '$surface controller not registered');
}

void expectCenteredIndexValid(
  String surface, {
  required String indexField,
  required String countField,
}) {
  final payload = readSurfaceProbe(surface);
  final count = (payload[countField] as num?)?.toInt() ?? 0;
  final index = (payload[indexField] as num?)?.toInt() ?? -1;
  if (count <= 0) return;
  expect(index, greaterThanOrEqualTo(0), reason: '$surface index negative');
  expect(index, lessThan(count), reason: '$surface index out of range');
}

void expectSelectedNavIndex(int expectedIndex) {
  final payload = readSurfaceProbe('navBar');
  expect(payload['registered'], isTrue,
      reason: 'navBar controller not registered');
  expect(
    (payload['selectedIndex'] as num?)?.toInt(),
    expectedIndex,
    reason: 'unexpected navBar selected index',
  );
}
