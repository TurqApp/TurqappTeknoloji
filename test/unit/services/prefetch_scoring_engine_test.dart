import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/prefetch_scoring_engine.dart';

void main() {
  test('higher base priority scores above lower priority', () {
    final higher = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 0,
        currentIndex: 5,
        targetIndex: 6,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.2,
        watchProgress: 0.0,
        cachedSegmentCount: 0,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 0.0,
        sessionCompletionRate: 0.0,
        sessionRebufferRatio: 0.0,
        sessionHasFirstFrame: false,
        sessionIsAudible: false,
        sessionHasStableFocus: false,
      ),
    );
    final lower = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 2,
        currentIndex: 5,
        targetIndex: 6,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.2,
        watchProgress: 0.0,
        cachedSegmentCount: 0,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 0.0,
        sessionCompletionRate: 0.0,
        sessionRebufferRatio: 0.0,
        sessionHasFirstFrame: false,
        sessionIsAudible: false,
        sessionHasStableFocus: false,
      ),
    );

    expect(higher, greaterThan(lower));
  });

  test('nearer target scores above farther target within same priority', () {
    final near = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 0,
        currentIndex: 5,
        targetIndex: 6,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.2,
        watchProgress: 0.0,
        cachedSegmentCount: 0,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 0.0,
        sessionCompletionRate: 0.0,
        sessionRebufferRatio: 0.0,
        sessionHasFirstFrame: false,
        sessionIsAudible: false,
        sessionHasStableFocus: false,
      ),
    );
    final far = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 0,
        currentIndex: 5,
        targetIndex: 10,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.2,
        watchProgress: 0.0,
        cachedSegmentCount: 0,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 0.0,
        sessionCompletionRate: 0.0,
        sessionRebufferRatio: 0.0,
        sessionHasFirstFrame: false,
        sessionIsAudible: false,
        sessionHasStableFocus: false,
      ),
    );

    expect(near, greaterThan(far));
  });

  test('resume candidates score above already consumed items', () {
    final resume = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 1,
        currentIndex: 5,
        targetIndex: 6,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.2,
        watchProgress: 0.45,
        cachedSegmentCount: 2,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 0.0,
        sessionCompletionRate: 0.0,
        sessionRebufferRatio: 0.0,
        sessionHasFirstFrame: false,
        sessionIsAudible: false,
        sessionHasStableFocus: false,
      ),
    );
    final consumed = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 1,
        currentIndex: 5,
        targetIndex: 6,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.2,
        watchProgress: 0.95,
        cachedSegmentCount: 9,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 0.0,
        sessionCompletionRate: 0.0,
        sessionRebufferRatio: 0.0,
        sessionHasFirstFrame: false,
        sessionIsAudible: false,
        sessionHasStableFocus: false,
      ),
    );

    expect(resume, greaterThan(consumed));
  });

  test('non-ready cache scores above already startup-ready cache', () {
    final notReady = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 1,
        currentIndex: 5,
        targetIndex: 6,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.2,
        watchProgress: 0.0,
        cachedSegmentCount: 0,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 0.0,
        sessionCompletionRate: 0.0,
        sessionRebufferRatio: 0.0,
        sessionHasFirstFrame: false,
        sessionIsAudible: false,
        sessionHasStableFocus: false,
      ),
    );
    final ready = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 1,
        currentIndex: 5,
        targetIndex: 6,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.2,
        watchProgress: 0.0,
        cachedSegmentCount: 3,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 0.0,
        sessionCompletionRate: 0.0,
        sessionRebufferRatio: 0.0,
        sessionHasFirstFrame: false,
        sessionIsAudible: false,
        sessionHasStableFocus: false,
      ),
    );

    expect(notReady, greaterThan(ready));
  });

  test('engaged active session boosts near-ahead prefetch', () {
    final neutral = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 0,
        currentIndex: 5,
        targetIndex: 6,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.6,
        watchProgress: 0.25,
        cachedSegmentCount: 0,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 0.0,
        sessionCompletionRate: 0.0,
        sessionRebufferRatio: 0.0,
        sessionHasFirstFrame: false,
        sessionIsAudible: false,
        sessionHasStableFocus: false,
      ),
    );
    final engaged = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 0,
        currentIndex: 5,
        targetIndex: 6,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.6,
        watchProgress: 0.25,
        cachedSegmentCount: 0,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 4.2,
        sessionCompletionRate: 0.22,
        sessionRebufferRatio: 0.05,
        sessionHasFirstFrame: true,
        sessionIsAudible: false,
        sessionHasStableFocus: false,
      ),
    );

    expect(engaged, greaterThan(neutral));
  });

  test('audible stable session boosts near-ahead jobs further', () {
    final neutral = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 0,
        currentIndex: 5,
        targetIndex: 6,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.6,
        watchProgress: 0.22,
        cachedSegmentCount: 0,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 3.2,
        sessionCompletionRate: 0.14,
        sessionRebufferRatio: 0.05,
        sessionHasFirstFrame: true,
        sessionIsAudible: false,
        sessionHasStableFocus: false,
      ),
    );
    final boosted = PrefetchScoringEngine.score(
      const PrefetchScoreContext(
        basePriority: 0,
        currentIndex: 5,
        targetIndex: 6,
        isOnWiFi: true,
        mobileSeedMode: false,
        feedReadyRatio: 0.6,
        watchProgress: 0.22,
        cachedSegmentCount: 0,
        totalSegmentCount: 10,
        sessionWatchTimeSeconds: 3.2,
        sessionCompletionRate: 0.14,
        sessionRebufferRatio: 0.05,
        sessionHasFirstFrame: true,
        sessionIsAudible: true,
        sessionHasStableFocus: true,
      ),
    );

    expect(boosted, greaterThan(neutral));
  });
}
