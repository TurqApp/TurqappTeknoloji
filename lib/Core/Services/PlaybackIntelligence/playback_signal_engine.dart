class PlaybackSignalSnapshot {
  final double normalizedWatchProgress;
  final double resumeProbability;
  final bool likelyConsumed;
  final bool likelyUnstarted;
  final bool engagedSession;
  final bool unstableSession;

  const PlaybackSignalSnapshot({
    required this.normalizedWatchProgress,
    required this.resumeProbability,
    required this.likelyConsumed,
    required this.likelyUnstarted,
    required this.engagedSession,
    required this.unstableSession,
  });
}

class PlaybackSignalEngine {
  static PlaybackSignalSnapshot fromWatchProgress(double rawProgress) {
    return fromRuntimeSignals(rawProgress: rawProgress);
  }

  static PlaybackSignalSnapshot fromRuntimeSignals({
    required double rawProgress,
    double sessionWatchTimeSeconds = 0.0,
    double sessionCompletionRate = 0.0,
    double sessionRebufferRatio = 0.0,
    bool sessionHasFirstFrame = false,
  }) {
    final progress = rawProgress.clamp(0.0, 1.0);
    final watchTime = sessionWatchTimeSeconds.clamp(0.0, double.infinity);
    final completion = sessionCompletionRate.clamp(0.0, 1.0);
    final rebufferRatio = sessionRebufferRatio.clamp(0.0, 1.0);
    final engagedSession = sessionHasFirstFrame &&
        watchTime >= 2.5 &&
        completion >= 0.05 &&
        completion < 0.98 &&
        rebufferRatio < 0.45;
    final unstableSession =
        sessionHasFirstFrame && watchTime >= 1.0 && rebufferRatio >= 0.45;

    if (progress >= 0.98) {
      return PlaybackSignalSnapshot(
        normalizedWatchProgress: 0.98,
        resumeProbability: 0.05,
        likelyConsumed: true,
        likelyUnstarted: false,
        engagedSession: false,
        unstableSession: unstableSession,
      );
    }

    if (progress >= 0.90) {
      return PlaybackSignalSnapshot(
        normalizedWatchProgress: progress,
        resumeProbability: 0.20,
        likelyConsumed: true,
        likelyUnstarted: false,
        engagedSession: false,
        unstableSession: unstableSession,
      );
    }

    if (progress >= 0.15) {
      return PlaybackSignalSnapshot(
        normalizedWatchProgress: progress,
        resumeProbability: 0.90,
        likelyConsumed: false,
        likelyUnstarted: false,
        engagedSession: engagedSession,
        unstableSession: unstableSession,
      );
    }

    if (progress >= 0.03) {
      return PlaybackSignalSnapshot(
        normalizedWatchProgress: progress,
        resumeProbability: 0.45,
        likelyConsumed: false,
        likelyUnstarted: false,
        engagedSession: engagedSession,
        unstableSession: unstableSession,
      );
    }

    return PlaybackSignalSnapshot(
      normalizedWatchProgress: progress,
      resumeProbability: 0.10,
      likelyConsumed: false,
      likelyUnstarted: true,
      engagedSession: engagedSession,
      unstableSession: unstableSession,
    );
  }
}
