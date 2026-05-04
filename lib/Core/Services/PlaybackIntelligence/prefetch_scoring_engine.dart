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
  final bool sessionIsAudible;
  final bool sessionHasStableFocus;

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
    required this.sessionIsAudible,
    required this.sessionHasStableFocus,
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
      sessionIsAudible: context.sessionIsAudible,
      sessionHasStableFocus: context.sessionHasStableFocus,
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
      if (distance == 1) {
        score += 55;
      } else if (distance <= 3) {
        score += 34;
      } else if (distance <= 5) {
        score += 10;
      }
    }

    score -= distance * 25;

    if (!context.isOnWiFi && context.targetIndex > context.currentIndex) {
      if (distance <= 3) {
        score += 42;
      } else if (distance <= 5) {
        score += 10;
      }
    }

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

    if (signal.stableFocusSession &&
        context.targetIndex > context.currentIndex) {
      if (distance <= 2) {
        score += 14;
      } else if (distance <= 4) {
        score += 6;
      }
    }

    if (signal.audibleSession && context.targetIndex > context.currentIndex) {
      if (distance <= 2) {
        score += 10;
      } else if (distance <= 4) {
        score += 4;
      }
    }

    if (signal.audibleSession &&
        signal.stableFocusSession &&
        context.targetIndex > context.currentIndex &&
        distance <= 2) {
      score += 8;
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
      if (context.targetIndex > context.currentIndex && distance <= 3) {
        score += 16;
      }
    } else if (usefulness.deepCached) {
      score -= 6;
    }

    return score;
  }
}
