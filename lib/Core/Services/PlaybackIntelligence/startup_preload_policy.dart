class StartupPreloadPolicy {
  const StartupPreloadPolicy._();

  // Splash / startup
  static const int startupWarmCount = 5;

  // Active playback
  static const int activeReadySegments = 3;
  static const int neighborReadySegments = 3;

  // Forward preload horizon
  static const int aheadFirstSegmentCount = 5;
  static const int secondSegmentReadySegments = 2;
  static const List<int> secondSegmentAheadOffsets = <int>[2, 3, 5];

  static int readySegmentsForAheadOffset(int playableOffset) {
    if (playableOffset <= 0) {
      return activeReadySegments;
    }
    if (secondSegmentAheadOffsets.contains(playableOffset)) {
      return secondSegmentReadySegments;
    }
    if (playableOffset <= aheadFirstSegmentCount) {
      return 1;
    }
    return 0;
  }

  static int startupReadySegmentsForRank(int playableRank) {
    if (playableRank < startupWarmCount) {
      return 1;
    }
    return 0;
  }

  static bool useTightCellularWarmProfile({
    required bool isAndroid,
    required bool isOnCellular,
  }) {
    return isAndroid && isOnCellular;
  }

  static int warmReadySegmentsForOffset(
    int playableOffset, {
    required bool isAndroid,
    required bool isOnCellular,
  }) {
    if (useTightCellularWarmProfile(
      isAndroid: isAndroid,
      isOnCellular: isOnCellular,
    )) {
      if (playableOffset <= 0) {
        return activeReadySegments;
      }
      return playableOffset <= 3 ? 1 : 0;
    }
    return readySegmentsForAheadOffset(playableOffset);
  }

  static int startupWarmReadySegmentsForRank(
    int playableRank, {
    required bool isAndroid,
    required bool isOnCellular,
  }) {
    if (useTightCellularWarmProfile(
      isAndroid: isAndroid,
      isOnCellular: isOnCellular,
    )) {
      return playableRank < 4 ? 1 : 0;
    }
    return startupReadySegmentsForRank(playableRank);
  }

  static int warmPlayableCount(
    int defaultCount, {
    required bool isAndroid,
    required bool isOnCellular,
  }) {
    if (useTightCellularWarmProfile(
      isAndroid: isAndroid,
      isOnCellular: isOnCellular,
    )) {
      return 4;
    }
    return defaultCount;
  }
}
