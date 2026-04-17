class ShortFetchPolicy {
  const ShortFetchPolicy._();

  static const int maxPageScans = 8;
  static const bool fallbackToAffinityWhenSparse = true;
  static const bool fallbackToLatestWhenEmpty = true;
}
