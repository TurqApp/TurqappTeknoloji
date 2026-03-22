import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/eviction_scoring_engine.dart';
import 'package:turqappv2/Core/Services/SegmentCache/models.dart';

void main() {
  test('playing entries remain strongly protected', () {
    final score = EvictionScoringEngine.score(
      EvictionScoreContext(
        state: VideoCacheState.playing,
        lastAccessedAt: DateTime.now(),
        isRecentlyPlayed: true,
        watchProgress: 0.5,
        cachedSegmentCount: 4,
        totalSegmentCount: 10,
        totalSizeBytes: 20 * 1024 * 1024,
      ),
    );

    expect(score, 1000.0);
  });

  test('watched large entries score lower than recent ready entries', () {
    final watched = EvictionScoringEngine.score(
      EvictionScoreContext(
        state: VideoCacheState.watched,
        lastAccessedAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRecentlyPlayed: false,
        watchProgress: 0.95,
        cachedSegmentCount: 12,
        totalSegmentCount: 12,
        totalSizeBytes: 100 * 1024 * 1024,
      ),
    );

    final readyRecent = EvictionScoringEngine.score(
      EvictionScoreContext(
        state: VideoCacheState.ready,
        lastAccessedAt: DateTime.now(),
        isRecentlyPlayed: true,
        watchProgress: 0.2,
        cachedSegmentCount: 6,
        totalSegmentCount: 12,
        totalSizeBytes: 25 * 1024 * 1024,
      ),
    );

    expect(watched, lessThan(readyRecent));
  });
}
