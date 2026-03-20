import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';

void main() {
  test('records empty-after-refresh violations when prior snapshot existed',
      () {
    final guard = RuntimeInvariantGuard();

    guard.assertNotEmptyAfterRefresh(
      surface: 'feed',
      invariantKey: 'snapshot_visible_after_filter',
      hadSnapshot: true,
      previousCount: 5,
      nextCount: 0,
    );

    expect(guard.recentViolations, hasLength(1));
    expect(
      guard.recentViolations.single.invariantKey,
      'snapshot_visible_after_filter',
    );
  });

  test('records centered selection mismatch when expected doc still exists',
      () {
    final guard = RuntimeInvariantGuard();

    guard.assertCenteredSelection(
      surface: 'profile',
      invariantKey: 'resume_centered_post',
      centeredIndex: 0,
      docIds: const <String>['a', 'b', 'c'],
      expectedDocId: 'c',
    );

    expect(guard.recentViolations, hasLength(1));
    expect(
      guard.recentViolations.single.message,
      'Centered doc changed although previous doc still exists',
    );
  });
}
