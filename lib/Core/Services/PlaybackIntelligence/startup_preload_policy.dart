import 'package:flutter/foundation.dart' show TargetPlatform;

import 'playback_surface_policy.dart';

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
    return PlaybackSurfacePolicy.useTightAndroidWarmProfile(
      platform: isAndroid ? TargetPlatform.android : TargetPlatform.iOS,
    );
  }

  static int warmReadySegmentsForOffset(
    int playableOffset, {
    required bool isAndroid,
    required bool isOnCellular,
  }) {
    final platform = isAndroid ? TargetPlatform.android : TargetPlatform.iOS;
    if (useTightCellularWarmProfile(
      isAndroid: isAndroid,
      isOnCellular: isOnCellular,
    )) {
      if (playableOffset <= 0) {
        return activeReadySegments;
      }
      final limit = PlaybackSurfacePolicy.feedWarmFirstSegmentAheadCount(
        platform: platform,
        isFeedStyleSurface: true,
        isOnCellular: isOnCellular,
        defaultCount: aheadFirstSegmentCount,
      );
      return playableOffset <= limit ? 1 : 0;
    }
    final baseReadySegments = readySegmentsForAheadOffset(playableOffset);
    if (platform == TargetPlatform.iOS && playableOffset <= 2) {
      return baseReadySegments > neighborReadySegments
          ? baseReadySegments
          : neighborReadySegments;
    }
    return baseReadySegments;
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
      final limit = PlaybackSurfacePolicy.feedStartupWarmPlayableCount(
        platform: isAndroid ? TargetPlatform.android : TargetPlatform.iOS,
        isOnCellular: isOnCellular,
        defaultCount: startupWarmCount,
      );
      return playableRank < limit ? 1 : 0;
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
      return PlaybackSurfacePolicy.feedStartupWarmPlayableCount(
        platform: isAndroid ? TargetPlatform.android : TargetPlatform.iOS,
        isOnCellular: isOnCellular,
        defaultCount: defaultCount,
      );
    }
    return defaultCount;
  }
}
