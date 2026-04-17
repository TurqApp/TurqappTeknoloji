import 'dart:math' as math;

class ShortGrowthPolicy {
  const ShortGrowthPolicy._();

  static const int initialBlockSize = 15;
  static const int growthStride = 15;
  static const int growthRunwayCount = 9;

  static const int stageOneLimit = 60;
  static const int stageTwoLimit = 120;
  static const int stageThreeLimit = 180;
  static const int stageFourLimit = 240;

  static const int stageTwoViewedTrigger = 50;
  static const int stageThreeViewedTrigger = 110;
  static const int stageFourViewedTrigger = 170;

  static int targetCountForViewedCount(int viewedCount) {
    if (viewedCount >= stageFourViewedTrigger) {
      final steps =
          1 + ((viewedCount - stageFourViewedTrigger) ~/ growthStride);
      return math.min(
        stageFourLimit,
        stageThreeLimit + (steps * growthStride),
      );
    }
    if (viewedCount >= stageThreeViewedTrigger) {
      final steps =
          1 + ((viewedCount - stageThreeViewedTrigger) ~/ growthStride);
      return math.min(
        stageThreeLimit,
        stageTwoLimit + (steps * growthStride),
      );
    }
    if (viewedCount >= stageTwoViewedTrigger) {
      final steps =
          1 + ((viewedCount - stageTwoViewedTrigger) ~/ growthStride);
      return math.min(
        stageTwoLimit,
        stageOneLimit + (steps * growthStride),
      );
    }
    if (viewedCount >= 36) return stageOneLimit;
    if (viewedCount >= 21) return 45;
    if (viewedCount >= 6) return 30;
    return initialBlockSize;
  }
}
