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
      _userSoftLimitBytes ??
      _remote?.cacheSoftLimitBytes ??
      CacheIndex.softLimitBytes;
  int get _hardLimitBytes =>
      _userHardLimitBytes ??
      _remote?.cacheHardLimitBytes ??
      CacheIndex.maxSizeBytes;

  int get _recentPlayCount {
    final remoteFloor = _remote?.cacheRecentProtectCount ?? 3;
    final budgetManager = StorageBudgetManager.maybeFind();
    if (budgetManager == null) return remoteFloor;
    return budgetManager.recentProtectionWindow(
      streamUsageBytes: _index.totalSizeBytes,
      remoteFloor: remoteFloor,
    );
  }

  VideoRemoteConfigService? get _remote => maybeFindVideoRemoteConfigService();

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

  void markPlaying(String docID) {
    final entry = _index.entries[docID];
    if (entry == null) return;
    entry.state = VideoCacheState.playing;
    entry.lastAccessedAt = DateTime.now();
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
    entry.lastAccessedAt = DateTime.now();
    if (normalized >= 0.9 && entry.state == VideoCacheState.playing) {
      entry.state = VideoCacheState.watched;
    }

    final lastProgress = _lastPersistedProgress[docID] ?? -1.0;
    final lastAt = _lastPersistedProgressAt[docID];
    final now = DateTime.now();
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
