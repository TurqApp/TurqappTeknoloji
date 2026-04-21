import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/startup_surface_order_service.dart';

void main() {
  test('forceNew startup session rotates feed seed', () async {
    const namespace = 'feed_refresh_contract_test';

    beginStartupSurfaceSession(
      sessionNamespace: namespace,
      forceNew: true,
    );
    final firstSeed = startupSurfaceSessionSeed(sessionNamespace: namespace);

    await Future<void>.delayed(const Duration(milliseconds: 1));

    beginStartupSurfaceSession(
      sessionNamespace: namespace,
      forceNew: true,
    );
    final secondSeed = startupSurfaceSessionSeed(sessionNamespace: namespace);

    expect(secondSeed, isNot(equals(firstSeed)));
  });
}
