import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';

void main() {
  test(
      'records notification delete overflow when more items are removed than requested',
      () {
    final guard = RuntimeInvariantGuard();

    guard.record(
      surface: 'notifications',
      invariantKey: 'optimistic_delete_removed_too_many',
      message: 'Optimistic delete removed more notifications than requested',
      payload: const <String, dynamic>{
        'removedCount': 3,
        'requestedCount': 1,
      },
    );

    expect(guard.recentViolations, hasLength(1));
    expect(
      guard.recentViolations.single.invariantKey,
      'optimistic_delete_removed_too_many',
    );
  });
}
