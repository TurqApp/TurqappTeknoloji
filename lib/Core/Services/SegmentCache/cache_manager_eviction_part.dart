part of 'cache_manager.dart';

const Duration _userInteractionEvictionGracePeriod = Duration(hours: 6);
const int _shortOfflineReserveFloor = 24;
const int _feedOfflineReserveFloor = 18;

extension SegmentCacheManagerEvictionPart on SegmentCacheManager {
  bool _isEmptyEntry(VideoCacheEntry entry) =>
      entry.totalSizeBytes <= 0 && entry.segments.isEmpty;

  int _reservedShortCount() => _index.entries.values
      .where((entry) => entry.reservedForShortAt != null)
      .length;

  int _reservedFeedCount() => _index.entries.values
      .where((entry) => entry.reservedForFeedAt != null)
      .length;

  bool _isReserveProtected(
    VideoCacheEntry entry, {
    required int reservedShortCount,
    required int reservedFeedCount,
  }) {
    final protectsShort = entry.reservedForShortAt != null &&
        reservedShortCount <= _shortOfflineReserveFloor;
    final protectsFeed = entry.reservedForFeedAt != null &&
        reservedFeedCount <= _feedOfflineReserveFloor;
    return protectsShort || protectsFeed;
  }

  Future<void> purgeExpiredEntries() async {
    final now = DateTime.now();
    final reservedShortCount = _reservedShortCount();
    final reservedFeedCount = _reservedFeedCount();
    final expired = _index.entries.values
        .where(
          (entry) => !_isReserveProtected(
            entry,
            reservedShortCount: reservedShortCount,
            reservedFeedCount: reservedFeedCount,
          ),
        )
        .where((entry) => _shouldPurgeExpiredEntry(entry, now: now))
        .toList(growable: false);
    if (expired.isEmpty) return;

    for (final entry in expired) {
      await _evictEntry(entry);
    }

    _recentlyPlayed.removeWhere(
      (docID) => !_index.entries.containsKey(docID),
    );
    debugPrint(
      '[CacheManager] Expired cache purged: ${expired.length} entries',
    );
  }

  VideoCacheEntry? _findEvictionCandidate({bool preferLowQuality = false}) {
    VideoCacheEntry? worst;
    double worstScore = double.infinity;
    final now = DateTime.now();
    final reservedShortCount = _reservedShortCount();
    final reservedFeedCount = _reservedFeedCount();

    Iterable<VideoCacheEntry> candidates = _index.entries.values.where(
      (entry) {
        final userInteractionAt = entry.lastUserInteractionAt;
        if (userInteractionAt == null) {
          return true;
        }
        return now.difference(userInteractionAt) >=
            _userInteractionEvictionGracePeriod;
      },
    );
    final nonProtectedCandidates = candidates
        .where(
          (entry) => !_isReserveProtected(
            entry,
            reservedShortCount: reservedShortCount,
            reservedFeedCount: reservedFeedCount,
          ),
        )
        .toList(growable: false);
    if (nonProtectedCandidates.isNotEmpty) {
      candidates = nonProtectedCandidates;
    }
    if (preferLowQuality) {
      final lowQuality = candidates.where(_isLowQualityEntry).toList();
      if (lowQuality.isNotEmpty) {
        candidates = lowQuality;
      }
    }

    final emptyCandidates = candidates.where(_isEmptyEntry).toList()
      ..sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));
    if (emptyCandidates.isNotEmpty) {
      return emptyCandidates.first;
    }

    final watchedCandidates = candidates
        .where(
          (entry) =>
              entry.state == VideoCacheState.watched &&
              !_recentlyPlayed.contains(entry.docID),
        )
        .toList()
      ..sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));
    if (watchedCandidates.isNotEmpty) {
      return watchedCandidates.first;
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

  bool _shouldPurgeExpiredEntry(
    VideoCacheEntry entry, {
    required DateTime now,
  }) {
    if (entry.state == VideoCacheState.playing) return false;
    final userInteractionAt = entry.lastUserInteractionAt;
    if (userInteractionAt == null) return false;
    if (now.difference(userInteractionAt) <
        _userInteractionEvictionGracePeriod) {
      return false;
    }
    if (entry.state == VideoCacheState.watched) {
      return true;
    }
    if (entry.totalSegmentCount <= 0) {
      return entry.cachedSegmentCount > 2 && entry.watchProgress > 0.10;
    }
    final currentSegment = HlsSegmentPolicy.estimateCurrentSegmentFromProgress(
      progress: entry.watchProgress,
      totalSegments: entry.totalSegmentCount,
    );
    return currentSegment >= 3;
  }

  Future<void> _evictEntry(VideoCacheEntry entry) async {
    final dir = Directory('$_cacheDir/Posts/${entry.docID}');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    _index.totalSizeBytes -= entry.totalSizeBytes;
    _index.entries.remove(entry.docID);
    await _refreshMetadataUsage();
    _markDirty();
    if (_index.totalSizeBytes < 0) {
      _index.totalSizeBytes = 0;
    }

    if (_isEmptyEntry(entry)) {
      debugPrint('[CacheManager] Pruned empty entry ${entry.docID}');
      return;
    }

    metrics.recordEviction();
    debugPrint(
      '[CacheManager] Evicted ${entry.docID} (${entry.totalSizeBytes} bytes)',
    );
  }
}
