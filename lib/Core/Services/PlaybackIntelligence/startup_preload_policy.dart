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
}
