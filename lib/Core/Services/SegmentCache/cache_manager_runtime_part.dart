part of 'cache_manager.dart';

extension _SegmentCacheManagerRuntimeX on SegmentCacheManager {
  Future<void> init() async {
    _isReady = false;
    final appDir = await getApplicationSupportDirectory();
    _cacheDir = '${appDir.path}/hls_cache';
    await Directory(_cacheDir).create(recursive: true);
    await _loadIndex();
    unawaited(_recoverIndex());
    metrics.startPeriodicLog();
    _reconcileTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _reconcileTotalSize();
    });
    _isReady = true;
  }

  bool get isReady => _isReady;
  String get cacheDir => _cacheDir;
  int get entryCount => _index.entries.length;
  int get totalSizeBytes => _index.totalSizeBytes;
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
      streamUsageBytes: _index.totalSizeBytes,
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
      watchProgress: existing.watchProgress,
      state: existing.state,
    );
    _markDirty();
  }

  void markPlaying(String docID) {
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

  void _scheduleEvictionIfNeeded() {
    if (_index.totalSizeBytes <= _softLimitBytes) return;
    if (_evictionInFlight != null) return;

    final target = _index.totalSizeBytes > _hardLimitBytes
        ? _hardLimitBytes
        : _softLimitBytes;

    _evictionInFlight = evictIfNeeded(targetBytes: target).whenComplete(() {
      _evictionInFlight = null;
    });
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
