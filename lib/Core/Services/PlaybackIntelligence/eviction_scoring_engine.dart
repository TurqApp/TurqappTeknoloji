import 'package:turqappv2/Core/Services/SegmentCache/models.dart';

import 'cache_usefulness_engine.dart';
import 'playback_signal_engine.dart';

class EvictionScoreContext {
  final VideoCacheState state;
  final DateTime lastAccessedAt;
  final bool isRecentlyPlayed;
  final double watchProgress;
  final int cachedSegmentCount;
  final int totalSegmentCount;
  final int totalSizeBytes;

  const EvictionScoreContext({
    required this.state,
    required this.lastAccessedAt,
    required this.isRecentlyPlayed,
    required this.watchProgress,
    required this.cachedSegmentCount,
    required this.totalSegmentCount,
    required this.totalSizeBytes,
  });
}

class EvictionScoringEngine {
  static double score(EvictionScoreContext context) {
    final signal =
        PlaybackSignalEngine.fromWatchProgress(context.watchProgress);
    final usefulness = CacheUsefulnessEngine.fromSegments(
      cachedSegmentCount: context.cachedSegmentCount,
      totalSegmentCount: context.totalSegmentCount,
    );
    if (context.state == VideoCacheState.playing) return 1000.0;

    double score;
    switch (context.state) {
      case VideoCacheState.evictable:
        score = 0;
        break;
      case VideoCacheState.watched:
        score = 10;
        break;
      case VideoCacheState.partial:
        score = 20;
        break;
      case VideoCacheState.fetching:
        score = 25;
        break;
      case VideoCacheState.ready:
        score = 30;
        break;
      default:
        score = 5;
        break;
    }

    final ageMs =
        DateTime.now().difference(context.lastAccessedAt).inMilliseconds;
    if (ageMs < 60000) {
      score += 50;
    } else if (ageMs < 300000) {
      score += 30;
    }

    if (context.isRecentlyPlayed) {
      score += 200;
    }

    score += signal.resumeProbability * 25;

    if (signal.likelyConsumed) {
      score -= 5;
    } else if (signal.likelyUnstarted &&
        context.state == VideoCacheState.partial) {
      score -= 5;
    }

    if (usefulness.startupReady && !signal.likelyConsumed) {
      score += 8;
    }
    if (usefulness.deepCached && signal.likelyConsumed) {
      score -= 6;
    }

    final sizeMb = context.totalSizeBytes / (1024 * 1024);
    if (sizeMb >= 80) {
      score -= 8;
    } else if (sizeMb >= 40) {
      score -= 4;
    }

    return score;
  }
}
