part of 'cache_manager.dart';

extension SegmentCacheManagerEvictionPart on SegmentCacheManager {
  VideoCacheEntry? _findEvictionCandidate({bool preferLowQuality = false}) {
    VideoCacheEntry? worst;
    double worstScore = double.infinity;

    Iterable<VideoCacheEntry> candidates = _index.entries.values;
    if (preferLowQuality) {
      final lowQuality = candidates.where(_isLowQualityEntry).toList();
      if (lowQuality.isNotEmpty) {
        candidates = lowQuality;
      }
    }

    for (final entry in candidates) {
      final score = _evictionScore(entry);
      if (score < worstScore) {
        worstScore = score;
        worst = entry;
      }
    }
    return worst;
  }

  double _evictionScore(VideoCacheEntry entry) {
    return EvictionScoringEngine.score(
      EvictionScoreContext(
        state: entry.state,
        lastAccessedAt: entry.lastAccessedAt,
        isRecentlyPlayed: _recentlyPlayed.contains(entry.docID),
        watchProgress: entry.watchProgress,
        cachedSegmentCount: entry.cachedSegmentCount,
        totalSegmentCount: entry.totalSegmentCount,
        totalSizeBytes: entry.totalSizeBytes,
      ),
    );
  }

  bool _isLowQualityEntry(VideoCacheEntry entry) {
    if (entry.state == VideoCacheState.playing) return false;
    if (_recentlyPlayed.contains(entry.docID)) return false;
    if (entry.cachedSegmentCount <= 2) return true;
    if (entry.totalSegmentCount <= 0) return entry.cachedSegmentCount <= 3;
    final ratio = entry.cachedSegmentCount / entry.totalSegmentCount;
    if (ratio < 0.20) return true;
    if (entry.watchProgress <= 0.10 &&
        entry.state == VideoCacheState.partial &&
        entry.cachedSegmentCount <= 3) {
      return true;
    }
    return false;
  }

  Future<void> _evictEntry(VideoCacheEntry entry) async {
    final dir = Directory('$_cacheDir/Posts/${entry.docID}');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    _index.totalSizeBytes -= entry.totalSizeBytes;
    _index.entries.remove(entry.docID);
    metrics.recordEviction();
    _markDirty();

    debugPrint(
      '[CacheManager] Evicted ${entry.docID} (${entry.totalSizeBytes} bytes)',
    );
  }
}
