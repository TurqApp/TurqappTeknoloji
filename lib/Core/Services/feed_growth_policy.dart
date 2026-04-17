class FeedGrowthPolicy {
  const FeedGrowthPolicy._();

  static const int postsPerGroup = 3;
  static const int renderSlotsPerGroup = 4;
  static const int groupsPerBlock = 5;
  static const int hotPrefetchGroupCount = 3;
  static const int startupWarmGroupCount = 2;
  static const int growthRunwayGroupCount = 3;

  static const int postSlotsPerBlock = postsPerGroup * groupsPerBlock;
  static const int renderSlotsPerBlock = renderSlotsPerGroup * groupsPerBlock;
  static const int growthRunwayPostCount =
      postsPerGroup * growthRunwayGroupCount;

  static int initialPageFetchTriggerCount(int pageFetchLimit) {
    final trigger = pageFetchLimit - growthRunwayPostCount;
    return trigger > postsPerGroup ? trigger : postsPerGroup;
  }

  static int advancePageFetchTrigger({
    required int currentTriggerCount,
    required int viewedCount,
    required int pageFetchLimit,
  }) {
    if (pageFetchLimit <= 0) return currentTriggerCount;
    var nextTrigger = currentTriggerCount;
    while (nextTrigger <= viewedCount) {
      nextTrigger += pageFetchLimit;
    }
    return nextTrigger;
  }
}
