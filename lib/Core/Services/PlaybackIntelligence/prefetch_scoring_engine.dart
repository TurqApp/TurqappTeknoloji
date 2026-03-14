import 'cache_usefulness_engine.dart';
import 'playback_signal_engine.dart';

class PrefetchScoreContext {
  final int basePriority;
  final int currentIndex;
  final int targetIndex;
  final bool isOnWiFi;
  final bool mobileSeedMode;
  final double feedReadyRatio;
  final double watchProgress;
  final int cachedSegmentCount;
  final int totalSegmentCount;
  final double sessionWatchTimeSeconds;
  final double sessionCompletionRate;
  final double sessionRebufferRatio;
  final bool sessionHasFirstFrame;

  const PrefetchScoreContext({
    required this.basePriority,
    required this.currentIndex,
    required this.targetIndex,
    required this.isOnWiFi,
    required this.mobileSeedMode,
    required this.feedReadyRatio,
    required this.watchProgress,
    required this.cachedSegmentCount,
    required this.totalSegmentCount,
    required this.sessionWatchTimeSeconds,
    required this.sessionCompletionRate,
    required this.sessionRebufferRatio,
    required this.sessionHasFirstFrame,
  });
}

class PrefetchScoringEngine {
  static double score(PrefetchScoreContext context) {
    final signal = PlaybackSignalEngine.fromRuntimeSignals(
      rawProgress: context.watchProgress,
      sessionWatchTimeSeconds: context.sessionWatchTimeSeconds,
      sessionCompletionRate: context.sessionCompletionRate,
      sessionRebufferRatio: context.sessionRebufferRatio,
      sessionHasFirstFrame: context.sessionHasFirstFrame,
    );
    final usefulness = CacheUsefulnessEngine.fromSegments(
      cachedSegmentCount: context.cachedSegmentCount,
      totalSegmentCount: context.totalSegmentCount,
    );
    final distance = (context.targetIndex - context.currentIndex).abs();

    double score;
    switch (context.basePriority) {
      case 0:
        score = 1000;
        break;
      case 1:
        score = 700;
        break;
      default:
        score = 400;
        break;
    }

    if (context.targetIndex == context.currentIndex) {
      score += 30;
    }

    if (context.targetIndex > context.currentIndex) {
      score += 20;
    }

    score -= distance * 25;

    if (context.isOnWiFi) {
      score += 15;
    }

    if (context.mobileSeedMode) {
      score -= 10;
    }

    if (context.feedReadyRatio < 0.5) {
      score += 20;
    }

    score += signal.resumeProbability * 40;

    if (signal.likelyConsumed) {
      score -= 10;
    }

    if (signal.engagedSession && context.targetIndex > context.currentIndex) {
      if (distance <= 2) {
        score += 16;
      } else if (distance <= 5) {
        score += 8;
      }
    }

    if (signal.unstableSession && context.targetIndex > context.currentIndex) {
      if (distance >= 3) {
        score -= 8;
      } else {
        score -= 4;
      }
    }

    if (!usefulness.startupReady) {
      score += 18;
    } else if (usefulness.deepCached) {
      score -= 6;
    }

    return score;
  }
}
