class CacheUsefulnessSnapshot {
  final double fillRatio;
  final bool startupReady;
  final bool sparseCache;
  final bool deepCached;

  const CacheUsefulnessSnapshot({
    required this.fillRatio,
    required this.startupReady,
    required this.sparseCache,
    required this.deepCached,
  });
}

class CacheUsefulnessEngine {
  static CacheUsefulnessSnapshot fromSegments({
    required int cachedSegmentCount,
    required int totalSegmentCount,
  }) {
    final cached = cachedSegmentCount < 0 ? 0 : cachedSegmentCount;
    final total = totalSegmentCount < 0 ? 0 : totalSegmentCount;

    final fillRatio = total > 0 ? (cached / total).clamp(0.0, 1.0) : 0.0;
    final startupReady = cached >= 2;
    final sparseCache = cached <= 2 || (total > 0 && fillRatio < 0.20);
    final deepCached = total > 0 && fillRatio >= 0.80;

    return CacheUsefulnessSnapshot(
      fillRatio: fillRatio,
      startupReady: startupReady,
      sparseCache: sparseCache,
      deepCached: deepCached,
    );
  }
}
