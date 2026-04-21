part of 'cache_manager.dart';

extension _SegmentCacheManagerRuntimeX on SegmentCacheManager {
  Future<void> init() async {
    _isReady = false;
    final appDir = await getApplicationSupportDirectory();
    _cacheDir = '${appDir.path}/hls_cache';
    await Directory(_cacheDir).create(recursive: true);
    await _loadIndex();
    _resetWatchStateForSessionStart();
    await clearConsumedCache(source: 'session_init');
    unawaited(_recoverAndPurgeExpiredEntries());
    metrics.startPeriodicLog();
    _reconcileTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(_runPeriodicMaintenance());
    });
    _isReady = true;
  }

  void _resetWatchStateForSessionStart() {
    var resetCount = 0;
    for (final entry in _index.entries.values) {
      final hadProgress = entry.watchProgress > 0.0;
      final wasWatchedLikeState = entry.state == VideoCacheState.watched ||
          entry.state == VideoCacheState.playing;
      if (!hadProgress && !wasWatchedLikeState) {
        continue;
      }
      entry.watchProgress = 0.0;
      entry.state = _restingStateForEntry(entry);
      resetCount++;
    }

    _recentlyPlayed.clear();
    _lastPersistedProgress.clear();
    _lastPersistedProgressAt.clear();

    if (resetCount <= 0) return;
    _markDirty();
    debugPrint(
      '[CacheManager] Session watch state reset: $resetCount entries',
    );
  }

  Future<void> _recoverAndPurgeExpiredEntries() async {
    try {
      await _recoverIndex();
      _normalizeStalePlayingEntries(maxIdle: Duration.zero);
      await purgeExpiredEntries();
    } catch (e) {
      debugPrint('[CacheManager] Recovery/purge failed: $e');
    }
  }

  Future<void> _runPeriodicMaintenance() async {
    try {
      _reconcileTotalSize();
      _normalizeStalePlayingEntries();
      await purgeExpiredEntries();
    } catch (e) {
      debugPrint('[CacheManager] Periodic maintenance failed: $e');
    }
  }

  void _normalizeStalePlayingEntries({
    Duration maxIdle = const Duration(minutes: 15),
  }) {
    final now = DateTime.now();
    var normalizedCount = 0;
    for (final entry in _index.entries.values) {
      if (entry.state != VideoCacheState.playing) continue;
      if (now.difference(entry.lastAccessedAt) < maxIdle) continue;
      entry.state = _restingStateForEntry(entry);
      normalizedCount++;
    }
    if (normalizedCount <= 0) return;
    _markDirty();
    debugPrint(
      '[CacheManager] Normalized stale playing entries: $normalizedCount',
    );
  }

  VideoCacheState _restingStateForEntry(VideoCacheEntry entry) {
    if (entry.watchProgress >= 0.9) {
      return VideoCacheState.watched;
    }
    if (entry.isFullyCached) {
      return VideoCacheState.ready;
    }
    if (entry.cachedSegmentCount > 0) {
      return VideoCacheState.partial;
    }
    return VideoCacheState.uncached;
  }

  bool get isReady => _isReady;
  String get cacheDir => _cacheDir;
  int get entryCount => _index.entries.length;
  int get totalSizeBytes => _index.totalSizeBytes;
  int get metadataUsageBytes => _playlistMetadataBytes + _indexMetadataBytes;
  int get totalTrackedUsageBytes => totalSizeBytes + metadataUsageBytes;
  int get cachedVideoCount =>
      _index.entries.values.where((e) => e.cachedSegmentCount > 0).length;
  int get totalSegmentCount =>
      _index.entries.values.fold(0, (sum, e) => sum + e.cachedSegmentCount);
  List<String> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  int get softLimitBytes => _softLimitBytes;
  int get hardLimitBytes => _hardLimitBytes;
  int get _softLimitBytes =>
      _userSoftLimitBytes ?? ReadBudgetRegistry.segmentCacheSoftLimitBytes;
  int get _hardLimitBytes =>
      _userHardLimitBytes ?? ReadBudgetRegistry.segmentCacheHardLimitBytes;

  int get _recentPlayCount {
    final remoteFloor = ReadBudgetRegistry.segmentCacheRecentProtectCountValue;
    final budgetManager = StorageBudgetManager.maybeFind();
    if (budgetManager == null) return remoteFloor;
    return budgetManager.recentProtectionWindow(
      streamUsageBytes: totalTrackedUsageBytes,
      remoteFloor: remoteFloor,
    );
  }

  File? getSegmentFile(String docID, String segmentKey) {
    final entry = _index.entries[docID];
    if (entry == null) return null;
    final seg = entry.segments[segmentKey];
    if (seg == null) return null;
    return File(seg.diskPath);
  }

  File? getPlaylistFile(String relativePath) {
    final file = File('$_cacheDir/$relativePath');
    return file.existsSync() ? file : null;
  }

  VideoCacheEntry? getEntry(String docID) => _index.entries[docID];

  void cachePostCards(Iterable<PostsModel> posts) {
    var changed = false;
    for (final post in posts) {
      final docId = post.docID.trim();
      final playbackUrl = post.playbackUrl.trim();
      if (docId.isEmpty || playbackUrl.isEmpty) {
        continue;
      }
      final cardData = post.toMap();
      final existing = _index.entries[docId];
      if (existing == null) {
        _index.entries[docId] = VideoCacheEntry(
          docID: docId,
          masterPlaylistUrl: playbackUrl,
          cardData: cardData,
        );
        changed = true;
        continue;
      }
      if (existing.masterPlaylistUrl.isEmpty) {
        _index.entries[docId] = VideoCacheEntry(
          docID: docId,
          masterPlaylistUrl: playbackUrl,
          segments: existing.segments,
          cardData: cardData,
          totalSegmentCount: existing.totalSegmentCount,
          totalSizeBytes: existing.totalSizeBytes,
          lastAccessedAt: existing.lastAccessedAt,
          lastUserInteractionAt: existing.lastUserInteractionAt,
          servedInShortAt: existing.servedInShortAt,
          servedInFeedAt: existing.servedInFeedAt,
          feedConsumedAt: existing.feedConsumedAt,
          shortConsumedAt: existing.shortConsumedAt,
          reservedForShortAt: existing.reservedForShortAt,
          reservedForFeedAt: existing.reservedForFeedAt,
          watchProgress: existing.watchProgress,
          state: existing.state,
        );
      } else {
        existing.cardData = cardData;
      }
      changed = true;
    }
    if (changed) {
      _markDirty();
    }
  }

  void cacheHlsEntry(String docID, String masterPlaylistUrl) {
    final normalizedDocId = docID.trim();
    final normalizedUrl = canonicalizeHlsCdnUrl(masterPlaylistUrl);
    final relativePath = hlsRelativePathFromUrlOrPath(normalizedUrl);
    if (normalizedDocId.isEmpty ||
        normalizedUrl.isEmpty ||
        relativePath == null) {
      return;
    }

    final existing = _index.entries[normalizedDocId];
    if (existing == null) {
      _index.entries[normalizedDocId] = VideoCacheEntry(
        docID: normalizedDocId,
        masterPlaylistUrl: normalizedUrl,
      );
      _markDirty();
      return;
    }

    if (existing.masterPlaylistUrl == normalizedUrl) {
      return;
    }

    _index.entries[normalizedDocId] = VideoCacheEntry(
      docID: normalizedDocId,
      masterPlaylistUrl: normalizedUrl,
      segments: existing.segments,
      cardData: existing.cardData,
      totalSegmentCount: existing.totalSegmentCount,
      totalSizeBytes: existing.totalSizeBytes,
      lastAccessedAt: existing.lastAccessedAt,
      lastUserInteractionAt: existing.lastUserInteractionAt,
      servedInShortAt: existing.servedInShortAt,
      servedInFeedAt: existing.servedInFeedAt,
      feedConsumedAt: existing.feedConsumedAt,
      shortConsumedAt: existing.shortConsumedAt,
      reservedForShortAt: existing.reservedForShortAt,
      reservedForFeedAt: existing.reservedForFeedAt,
      watchProgress: existing.watchProgress,
      state: existing.state,
    );
    _markDirty();
  }

  void markPlaying(String docID) {
    for (final candidate in _index.entries.values) {
      if (candidate.docID == docID) continue;
      if (candidate.state != VideoCacheState.playing) continue;
      candidate.state = _restingStateForEntry(candidate);
    }
    final entry = _index.entries[docID];
    if (entry == null) return;
    entry.state = VideoCacheState.playing;
    final now = DateTime.now();
    entry.lastAccessedAt = now;
    entry.lastUserInteractionAt = now;
    _recentlyPlayed.remove(docID);
    _recentlyPlayed.add(docID);
    if (_recentlyPlayed.length > _recentPlayCount) {
      _recentlyPlayed.removeAt(0);
    }
    _markDirty();
  }

  void updateWatchProgress(String docID, double progress) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    final normalized = progress.clamp(0.0, 1.0);
    entry.watchProgress = normalized;
    final now = DateTime.now();
    entry.lastAccessedAt = now;
    entry.lastUserInteractionAt = now;
    if (normalized >= 0.9 && entry.state == VideoCacheState.playing) {
      entry.state = VideoCacheState.watched;
    }

    final lastProgress = _lastPersistedProgress[docID] ?? -1.0;
    final lastAt = _lastPersistedProgressAt[docID];
    final changedEnough = (normalized - lastProgress).abs() >= 0.03;
    final timeEnough = lastAt == null || now.difference(lastAt).inSeconds >= 6;
    final reachedEdge = normalized >= 0.98 || normalized <= 0.02;

    if (changedEnough || timeEnough || reachedEdge) {
      _lastPersistedProgress[docID] = normalized;
      _lastPersistedProgressAt[docID] = now;
      _markDirty();
    }
  }

  void touchEntry(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    entry.lastAccessedAt = DateTime.now();
    _markDirty();
  }

  void touchUserEntry(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    final now = DateTime.now();
    entry.lastAccessedAt = now;
    entry.lastUserInteractionAt = now;
    _markDirty();
  }

  void markServedInShort(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    final now = DateTime.now();
    entry.lastAccessedAt = now;
    entry.lastUserInteractionAt = now;
    entry.servedInShortAt ??= now;
    entry.reservedForShortAt = null;
    _markDirty();
  }

  void markServedInFeed(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    final now = DateTime.now();
    entry.lastAccessedAt = now;
    entry.lastUserInteractionAt = now;
    entry.servedInFeedAt ??= now;
    entry.reservedForFeedAt = null;
    _markDirty();
  }

  void markFeedConsumed(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    final wasAlreadyConsumed = entry.feedConsumedAt != null;
    final now = DateTime.now();
    entry.lastAccessedAt = now;
    entry.lastUserInteractionAt = now;
    entry.feedConsumedAt ??= now;
    _markDirty();
    if (!wasAlreadyConsumed) {
      _flushDirtyIndexNow();
    }
  }

  void markShortConsumed(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    final wasAlreadyConsumed = entry.shortConsumedAt != null;
    final now = DateTime.now();
    entry.lastAccessedAt = now;
    entry.lastUserInteractionAt = now;
    entry.shortConsumedAt ??= now;
    _markDirty();
    if (!wasAlreadyConsumed) {
      _flushDirtyIndexNow();
    }
  }

  void markReservedForShort(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    final now = DateTime.now();
    entry.lastAccessedAt = now;
    entry.reservedForShortAt ??= now;
    _markDirty();
  }

  void markReservedForFeed(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    final now = DateTime.now();
    entry.lastAccessedAt = now;
    entry.reservedForFeedAt ??= now;
    _markDirty();
  }

  void _scheduleEvictionIfNeeded() {
    if (totalTrackedUsageBytes <= _hardLimitBytes) return;
    if (_evictionInFlight != null) return;

    final target = _segmentTargetBytesForQuota(_softLimitBytes);

    _evictionInFlight = evictIfNeeded(targetBytes: target).whenComplete(() {
      _evictionInFlight = null;
    });
  }

  int _segmentTargetBytesForQuota(int quotaBytes) {
    final metadataBytes = metadataUsageBytes;
    final target = quotaBytes - metadataBytes;
    return target < 0 ? 0 : target;
  }

  Future<void> disposeRuntime() async {
    _isReady = false;
    _persistTimer?.cancel();
    _reconcileTimer?.cancel();
    metrics.stopPeriodicLog();
    if (_persistDirty) {
      _persistDirty = false;
      await persistIndex();
    }
  }
}
