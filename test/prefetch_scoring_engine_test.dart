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
      ),
    );

    expect(resume, greaterThan(consumed));
  });
}
