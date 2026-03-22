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

  test('records optimistic mutation when no items matched request', () {
    final guard = RuntimeInvariantGuard();

    guard.assertMutationMatched(
      surface: 'notifications',
      invariantKey: 'optimistic_mark_read_matched_none',
      requestedCount: 2,
      matchedCount: 0,
      mutationName: 'markRead',
    );

    expect(guard.recentViolations, hasLength(1));
    expect(
      guard.recentViolations.single.invariantKey,
      'optimistic_mark_read_matched_none',
    );
  });

  test('records count overflow when observed count exceeds limit', () {
    final guard = RuntimeInvariantGuard();

    guard.assertCountWithinLimit(
      surface: 'short',
      invariantKey: 'active_player_overflow',
      observedCount: 4,
      maxAllowed: 2,
      counterName: 'activePlayers',
    );

    expect(guard.recentViolations, hasLength(1));
    expect(
      guard.recentViolations.single.invariantKey,
      'active_player_overflow',
    );
  });
}
