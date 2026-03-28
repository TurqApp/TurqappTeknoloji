import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/feed_playback_selection_policy.dart';

void main() {
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
}
