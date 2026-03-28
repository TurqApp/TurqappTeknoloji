import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Services/feed_playback_selection_policy.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
      'resolveCenteredIndex keeps current target when next card is only marginally stronger',
      () {
    final target = FeedPlaybackSelectionPolicy.resolveCenteredIndex(
      visibleFractions: const <int, double>{
        0: 0.82,
        1: 0.88,
      },
      currentIndex: 0,
      lastCenteredIndex: 0,
      itemCount: 2,
      canAutoplayIndex: (_) => true,
      stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
    );

    expect(target, 0);
  });

  test(
      'resolveCenteredIndex switches once the next card clearly dominates visibility',
      () {
    final target = FeedPlaybackSelectionPolicy.resolveCenteredIndex(
      visibleFractions: const <int, double>{
        0: 0.50,
        1: 0.86,
      },
      currentIndex: 0,
      lastCenteredIndex: 0,
      itemCount: 2,
      canAutoplayIndex: (_) => true,
      stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
    );

    expect(target, 1);
  });

  test('retains recently activated Android target while it is still visible',
      () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final retain =
        FeedPlaybackSelectionPolicy.shouldRetainRecentlyActivatedTarget(
      lastCommandAt: DateTime.now().subtract(const Duration(milliseconds: 120)),
      lastCommandDocId: 'doc-1',
      currentDocId: 'doc-1',
      isCurrentTargetActive: true,
      currentFraction: 0.41,
      stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
    );

    expect(retain, isTrue);
  });

  test('does not retain Android target once stickiness window expires', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final retain =
        FeedPlaybackSelectionPolicy.shouldRetainRecentlyActivatedTarget(
      lastCommandAt: DateTime.now().subtract(const Duration(milliseconds: 560)),
      lastCommandDocId: 'doc-1',
      currentDocId: 'doc-1',
      isCurrentTargetActive: true,
      currentFraction: 0.41,
      stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
    );

    expect(retain, isFalse);
  });
}
