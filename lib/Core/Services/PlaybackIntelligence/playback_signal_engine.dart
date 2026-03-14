class PlaybackSignalSnapshot {
  final double normalizedWatchProgress;
  final double resumeProbability;
  final bool likelyConsumed;
  final bool likelyUnstarted;

  const PlaybackSignalSnapshot({
    required this.normalizedWatchProgress,
    required this.resumeProbability,
    required this.likelyConsumed,
    required this.likelyUnstarted,
  });
}

class PlaybackSignalEngine {
  static PlaybackSignalSnapshot fromWatchProgress(double rawProgress) {
    final progress = rawProgress.clamp(0.0, 1.0);

    if (progress >= 0.98) {
      return const PlaybackSignalSnapshot(
        normalizedWatchProgress: 0.98,
        resumeProbability: 0.05,
        likelyConsumed: true,
        likelyUnstarted: false,
      );
    }

    if (progress >= 0.90) {
      return PlaybackSignalSnapshot(
        normalizedWatchProgress: progress,
        resumeProbability: 0.20,
        likelyConsumed: true,
        likelyUnstarted: false,
      );
    }

    if (progress >= 0.15) {
      return PlaybackSignalSnapshot(
        normalizedWatchProgress: progress,
        resumeProbability: 0.90,
        likelyConsumed: false,
        likelyUnstarted: false,
      );
    }

    if (progress >= 0.03) {
      return PlaybackSignalSnapshot(
        normalizedWatchProgress: progress,
        resumeProbability: 0.45,
        likelyConsumed: false,
        likelyUnstarted: false,
      );
    }

    return PlaybackSignalSnapshot(
      normalizedWatchProgress: progress,
      resumeProbability: 0.10,
      likelyConsumed: false,
      likelyUnstarted: true,
    );
  }
}
