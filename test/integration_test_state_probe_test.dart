import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_state_probe.dart';

void main() {
  test('state probe returns unregistered snapshots when controllers are absent',
      () {
    final snapshot = IntegrationTestStateProbe.snapshot();

    expect(snapshot['currentRoute'], isA<String>());
    expect((snapshot['feed'] as Map<String, dynamic>)['registered'], isFalse);
    expect((snapshot['short'] as Map<String, dynamic>)['registered'], isFalse);
    expect(
      (snapshot['notifications'] as Map<String, dynamic>)['registered'],
      isFalse,
    );
  });
}
