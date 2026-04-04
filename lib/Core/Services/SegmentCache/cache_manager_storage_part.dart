part of 'cache_manager.dart';

extension SegmentCacheManagerStoragePart on SegmentCacheManager {
  void _markDirty() {
    _persistDirty = true;
    _persistTimer ??= Timer(const Duration(seconds: 5), () async {
      _persistTimer = null;
      if (_persistDirty) {
        _persistDirty = false;
        await persistIndex();
      }
    });
  }

  /// Index'i JSON olarak disk'e yaz.
  Future<void> persistIndex() async {
    try {
      final file = File('$_cacheDir/index.json');
      final json = jsonEncode(_index.toJson());
      final tmpFile = File('${file.path}.tmp');
      await tmpFile.writeAsString(json, flush: true);
      try {
        await tmpFile.rename(file.path);
      } on FileSystemException {
        await file.parent.create(recursive: true);
        await file.writeAsString(json, flush: true);
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }
      }
      final nextLength = await file.exists() ? await file.length() : 0;
      _indexMetadataBytes = nextLength;
    } catch (e) {
      debugPrint('[CacheManager] Index persist error: $e');
    }
  }

  Future<void> _loadIndex() async {
    final file = File('$_cacheDir/index.json');
    try {
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        await file.delete();
        _index = CacheIndex();
        return;
      }
      final json = Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
      final rawEntryCount = (json['entries'] as Map?)?.length ?? 0;
      _index = CacheIndex.fromJson(json);
      final prunedEntryCount = rawEntryCount - _index.entries.length;
      if (prunedEntryCount > 0) {
        debugPrint(
            '[CacheManager] Index load pruned $prunedEntryCount corrupt entries');
        _markDirty();
      }
      _reconcileTotalSize();
      await _refreshMetadataUsage();
      debugPrint(
          '[CacheManager] Index loaded: ${_index.entries.length} entries, '
          '${CacheMetrics.formatBytes(_index.totalSizeBytes)}');
    } catch (e) {
      debugPrint('[CacheManager] Index load error (starting fresh): $e');
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      _index = CacheIndex();
      _playlistMetadataBytes = 0;
      _indexMetadataBytes = 0;
    }
  }

  /// Startup'ta index vs disk tutarlılığını kontrol et.
  Future<void> _recoverIndex() async {
    await _cleanTempFiles(Directory(_cacheDir));

    final toRemove = <String>[];
    for (final entry in _index.entries.entries) {
      final dir = Directory('$_cacheDir/Posts/${entry.key}');
      if (!await dir.exists()) {
        toRemove.add(entry.key);
        continue;
      }

      final segToRemove = <String>[];
      for (final seg in entry.value.segments.entries) {
        if (!File(seg.value.diskPath).existsSync()) {
          segToRemove.add(seg.key);
        }
      }
      for (final k in segToRemove) {
        final removed = entry.value.segments.remove(k);
        if (removed != null) {
          entry.value.totalSizeBytes -= removed.sizeBytes;
          _index.totalSizeBytes -= removed.sizeBytes;
        }
      }
    }

    for (final k in toRemove) {
      final entry = _index.entries.remove(k);
      if (entry != null) {
        _index.totalSizeBytes -= entry.totalSizeBytes;
      }
    }

    if (_index.totalSizeBytes < 0) {
      debugPrint(
          '[CacheManager] Recovery: totalSizeBytes was negative (${_index.totalSizeBytes}), reconciling');
      _reconcileTotalSize();
    }

    final emptyEntries = _index.entries.entries
        .where((e) => e.value.segments.isEmpty)
        .map((e) => e.key)
        .toList();
    for (final k in emptyEntries) {
      _index.entries.remove(k);
    }

    if (toRemove.isNotEmpty || emptyEntries.isNotEmpty) {
      debugPrint(
          '[CacheManager] Recovery: removed ${toRemove.length} stale + ${emptyEntries.length} empty entries');
      _markDirty();
    }
    await _refreshMetadataUsage();
  }

  Future<void> _refreshMetadataUsage() async {
    var playlistBytes = 0;
    var indexBytes = 0;
    final root = Directory(_cacheDir);
    if (!await root.exists()) {
      _playlistMetadataBytes = 0;
      _indexMetadataBytes = 0;
      return;
    }
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (path.endsWith('.tmp')) {
        continue;
      }
      int length;
      try {
        length = await entity.length();
      } on FileSystemException {
        continue;
      }
      if (path.endsWith('/index.json')) {
        indexBytes += length;
        continue;
      }
      if (path.endsWith('.m3u8')) {
        playlistBytes += length;
      }
    }
    _playlistMetadataBytes = playlistBytes;
    _indexMetadataBytes = indexBytes;
  }

  /// totalSizeBytes'ı tüm segment boyutlarından yeniden hesaplar.
  void _reconcileTotalSize() {
    int entryTotal = 0;
    for (final entry in _index.entries.values) {
      int segTotal = 0;
      for (final seg in entry.segments.values) {
        segTotal += seg.sizeBytes;
      }
      if (entry.totalSizeBytes != segTotal) {
        entry.totalSizeBytes = segTotal;
      }
      entryTotal += segTotal;
    }
    if (_index.totalSizeBytes != entryTotal) {
      debugPrint(
          '[CacheManager] Reconcile: totalSizeBytes ${_index.totalSizeBytes} → $entryTotal');
      _index.totalSizeBytes = entryTotal;
      _markDirty();
    }
  }

  Future<void> _cleanTempFiles(Directory dir) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.tmp')) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  /// Tüm cache içeriğini diskten ve index'ten temizler.
  Future<void> clearAllCache() async {
    final root = Directory(_cacheDir);
    if (await root.exists()) {
      await for (final entity in root.list()) {
        final name = entity.path.split('/').last;
        if (name == 'index.json') continue;
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    }

    _index = CacheIndex();
    _recentlyPlayed.clear();
    _playlistMetadataBytes = 0;
    _indexMetadataBytes = 0;
    metrics.reset();
    await persistIndex();
    debugPrint('[CacheManager] All cache cleared');
  }

  /// Kullanıcının tükettiği içerikleri cache'ten temizler.
  Future<void> clearConsumedCache({double progressThreshold = 0.50}) async {
    final toRemove = <VideoCacheEntry>[];
    for (final entry in _index.entries.values) {
      final consumed = entry.state == VideoCacheState.watched ||
          entry.watchProgress >= progressThreshold;
      if (!consumed) continue;
      if (entry.state == VideoCacheState.playing) continue;
      toRemove.add(entry);
    }

    if (toRemove.isEmpty) return;

    for (final entry in toRemove) {
      await _evictEntry(entry);
    }

    _recentlyPlayed.removeWhere(
      (docID) => !_index.entries.containsKey(docID),
    );

    debugPrint(
      '[CacheManager] Consumed cache cleared: ${toRemove.length} entries',
    );
  }

  /// Kullanıcı cache kotasını runtime'da uygular.
  Future<void> setUserLimitGB(int gb) async {
    final profile = storageBudgetProfileForPlanGb(gb);

    _userHardLimitBytes = profile.streamCacheHardStopBytes;
    _userSoftLimitBytes = profile.streamCacheSoftStopBytes;

    if (_SegmentCacheManagerRuntimeX(this).totalTrackedUsageBytes >
        profile.streamCacheHardStopBytes) {
      await evictIfNeeded(
        targetBytes: _segmentTargetBytesForQuota(
          profile.streamCacheSoftStopBytes,
        ),
      );
    }

    debugPrint(
      '[CacheManager] User cache quota applied: ${profile.planGb}GB '
      '(soft=${CacheMetrics.formatBytes(profile.streamCacheSoftStopBytes)}, '
      'hard=${CacheMetrics.formatBytes(profile.streamCacheHardStopBytes)})',
    );
  }
}
