import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/cache_usefulness_engine.dart';

void main() {
  test('startup ready requires at least two cached segments', () {
    final snapshot = CacheUsefulnessEngine.fromSegments(
      cachedSegmentCount: 2,
      totalSegmentCount: 10,
    );

    expect(snapshot.startupReady, isTrue);
    expect(snapshot.sparseCache, isTrue);
  });

  test('deep cached detects high fill ratio', () {
    final snapshot = CacheUsefulnessEngine.fromSegments(
      cachedSegmentCount: 9,
      totalSegmentCount: 10,
    );

    expect(snapshot.deepCached, isTrue);
    expect(snapshot.fillRatio, greaterThan(0.8));
  });
}
