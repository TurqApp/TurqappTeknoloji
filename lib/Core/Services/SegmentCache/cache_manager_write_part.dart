part of 'cache_manager.dart';

extension SegmentCacheManagerWritePart on SegmentCacheManager {
  /// Segment'i disk'e yaz, index'i güncelle.
  /// Per-key lock ile aynı segment için eş zamanlı yazımı engeller.
  Future<File> writeSegment(
      String docID, String segmentKey, Uint8List bytes) async {
    final lockKey = '$docID/$segmentKey';
    final clonedBytes = Uint8List.fromList(bytes);

    final existing = _writeInFlight[lockKey];
    if (existing != null) return existing;

    final future = _writeSegmentInternal(docID, segmentKey, clonedBytes);
    _writeInFlight[lockKey] = future;
    try {
      return await future;
    } finally {
      _writeInFlight.remove(lockKey);
    }
  }

  Future<File> _writeSegmentInternal(
      String docID, String segmentKey, Uint8List bytes) async {
    _index.entries.putIfAbsent(
      docID,
      () => VideoCacheEntry(
        docID: docID,
        masterPlaylistUrl: '',
        state: VideoCacheState.fetching,
      ),
    );

    final entry = _index.entries[docID]!;
    final relativePath = 'Posts/$docID/hls/$segmentKey';
    final file = File('$_cacheDir/$relativePath');
    await file.parent.create(recursive: true);

    final tmpFile = File('${file.path}.tmp');
    await tmpFile.writeAsBytes(bytes, flush: false);
    try {
      await tmpFile.rename(file.path);
    } on FileSystemException {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: false);
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    }

    final oldSeg = entry.segments[segmentKey];
    if (oldSeg != null) {
      entry.totalSizeBytes -= oldSeg.sizeBytes;
      _index.totalSizeBytes -= oldSeg.sizeBytes;
    }

    final segment = CachedSegment(
      segmentUri: segmentKey,
      diskPath: file.path,
      sizeBytes: bytes.length,
      cachedAt: DateTime.now(),
    );
    entry.segments[segmentKey] = segment;
    entry.totalSizeBytes += bytes.length;
    entry.lastAccessedAt = DateTime.now();
    _index.totalSizeBytes += bytes.length;

    if (entry.isFullyCached) {
      entry.state = VideoCacheState.ready;
    } else if (entry.segments.isNotEmpty) {
      entry.state = VideoCacheState.partial;
    }

    _markDirty();
    _scheduleEvictionIfNeeded();

    return file;
  }

  /// M3U8 playlist'i disk'e yaz (index'e segment olarak eklenmez).
  Future<File> writePlaylist(String relativePath, String content) async {
    final file = File('$_cacheDir/$relativePath');
    await file.parent.create(recursive: true);
    final tmpFile = File('${file.path}.tmp');
    await tmpFile.writeAsString(content, flush: false);
    try {
      await tmpFile.rename(file.path);
    } on FileSystemException {
      await file.parent.create(recursive: true);
      await file.writeAsString(content, flush: false);
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    }
    return file;
  }

  /// Entry'nin master playlist URL'sini ve toplam segment sayısını güncelle.
  void updateEntryMeta(String docID, String masterUrl, int totalSegmentCount) {
    final entry = _index.entries[docID];
    if (entry == null) return;

    if (entry.masterPlaylistUrl.isEmpty) {
      _index.entries[docID] = VideoCacheEntry(
        docID: docID,
        masterPlaylistUrl: masterUrl,
        segments: entry.segments,
        totalSegmentCount: totalSegmentCount,
        totalSizeBytes: entry.totalSizeBytes,
        lastAccessedAt: entry.lastAccessedAt,
        watchProgress: entry.watchProgress,
        state: entry.state,
      );
    } else {
      entry.totalSegmentCount = totalSegmentCount;
    }
    _markDirty();
  }
}
