class ShortFetchPolicy {
  const ShortFetchPolicy._();

  static const int maxPageScans = 8;
  static const bool fallbackToAffinityWhenSparse = true;
  static const bool fallbackToLatestWhenEmpty = true;
  static const bool fallbackToLatestWhenAffinitySparse = true;

  static int pageSizeForLoad({
    required int currentCount,
    required int initialPageSize,
    required int bufferedPageSize,
  }) {
    if (currentCount <= 0) {
      return initialPageSize;
    }
    return bufferedPageSize;
  }

  static int minimumSelectedCountForLoad({
    required int currentCount,
    required int initialBlockSize,
    required int pageSize,
  }) {
    if (currentCount <= 0) {
      return initialBlockSize < pageSize ? initialBlockSize : pageSize;
    }
    return pageSize;
  }

  static bool shouldRefreshAfterStartupSurface({
    required bool startedEmpty,
    required bool seededFreshSession,
    required bool hasShorts,
    required bool isRefreshing,
    required bool isLoading,
    required bool allowBackgroundRefresh,
  }) {
    if (!allowBackgroundRefresh ||
        !seededFreshSession ||
        !hasShorts ||
        isRefreshing ||
        isLoading) {
      return false;
    }
    return !startedEmpty;
  }
}
